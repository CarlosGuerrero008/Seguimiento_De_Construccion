import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProjectChatbotScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectChatbotScreen({
    Key? key,
    required this.projectId,
    required this.projectData,
  }) : super(key: key);

  @override
  _ProjectChatbotScreenState createState() => _ProjectChatbotScreenState();
}

class _ProjectChatbotScreenState extends State<ProjectChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isInitialized = false;
  String _projectContext = '';

  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no está configurada en el archivo .env');
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    _initializeContext();
  }

  Future<void> _initializeContext() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Iniciando carga de contexto del proyecto: ${widget.projectId}');

      // Obtener todas las secciones
      List<Map<String, dynamic>> sections = [];
      try {
        final sectionsSnapshot = await FirebaseFirestore.instance
            .collection('projectSections')
            .where('projectId', isEqualTo: widget.projectId)
            .get();

        sections = sectionsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Sin nombre',
            'progress': data['progressPercentage'] ?? 0,
            'description': data['description'] ?? '',
          };
        }).toList();
        print('✅ Secciones cargadas: ${sections.length}');
      } catch (e) {
        print('❌ Error cargando secciones: $e');
      }

      // Obtener materiales - buscar en todas las secciones
      List<Map<String, dynamic>> materials = [];
      try {
        // Buscar materiales directamente por projectId
        var materialsSnapshot = await FirebaseFirestore.instance
            .collection('materials')
            .where('projectId', isEqualTo: widget.projectId)
            .get();

        // Si no hay materiales con projectId, buscar por sectionId
        if (materialsSnapshot.docs.isEmpty && sections.isNotEmpty) {
          print('⚠️ No hay materiales con projectId, buscando por secciones...');
          for (var section in sections) {
            final sectionMaterials = await FirebaseFirestore.instance
                .collection('materials')
                .where('sectionId', isEqualTo: section['id'])
                .get();
            materialsSnapshot = sectionMaterials;
            if (materialsSnapshot.docs.isNotEmpty) break;
          }
        }

        materials = materialsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'] ?? 'Sin nombre',
            'quantityUsed': data['quantityUsed'] ?? 0,
            'quantityPlanned': data['quantityPlanned'] ?? 0,
            'unit': data['unit'] ?? 'und',
            'status': data['status'] ?? 'Pendiente',
            'cost': ((data['quantityUsed'] ?? 0) * (data['unitCost'] ?? 0)).toDouble(),
          };
        }).toList();
        print('✅ Materiales cargados: ${materials.length}');
      } catch (e) {
        print('❌ Error cargando materiales: $e');
      }

      // Obtener reportes para estadísticas
      List<Map<String, dynamic>> reports = [];
      try {
        final reportsSnapshot = await FirebaseFirestore.instance
            .collection('dailyReports')
            .where('projectId', isEqualTo: widget.projectId)
            .get();

        reports = reportsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'date': (data['date'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A',
            'contractor': data['contractorName'] ?? 'Desconocido',
            'section': data['sectionName'] ?? 'N/A',
            'progress': data['progressAdded'] ?? 0,
            'description': data['description'] ?? '',
          };
        }).toList();
        print('✅ Reportes cargados: ${reports.length}');
      } catch (e) {
        print('❌ Error cargando reportes: $e');
      }

      // Calcular estadísticas de manera segura
      double avgProgress = 0;
      if (sections.isNotEmpty) {
        try {
          avgProgress = sections.fold(0.0, (sum, s) => sum + ((s['progress'] ?? 0) as num).toDouble()) / sections.length;
        } catch (e) {
          print('❌ Error calculando progreso promedio: $e');
          avgProgress = 0;
        }
      }

      double totalMaterialsCost = 0;
      try {
        totalMaterialsCost = materials.fold(0.0, (sum, m) => sum + ((m['cost'] ?? 0) as num).toDouble());
      } catch (e) {
        print('❌ Error calculando costo de materiales: $e');
      }

      Set<String> contractorsSet = {};
      try {
        contractorsSet = reports.map((r) => (r['contractor'] ?? 'Desconocido') as String).toSet();
      } catch (e) {
        print('❌ Error obteniendo contratistas: $e');
      }
      final contractors = contractorsSet.toList();

      // Calcular fechas y plazos de manera segura
      DateTime startDate;
      DateTime endDate;

      try {
        startDate = widget.projectData['startDate'] != null
            ? (widget.projectData['startDate'] as Timestamp).toDate()
            : DateTime.now();
        endDate = widget.projectData['endDate'] != null
            ? (widget.projectData['endDate'] as Timestamp).toDate()
            : DateTime.now().add(Duration(days: 90));
      } catch (e) {
        print('❌ Error parseando fechas: $e');
        startDate = DateTime.now();
        endDate = DateTime.now().add(Duration(days: 90));
      }

      final totalDays = endDate.difference(startDate).inDays.abs();
      final elapsedDays = DateTime.now().difference(startDate).inDays.abs();
      final remainingDays = endDate.difference(DateTime.now()).inDays;
      final expectedProgress = totalDays > 0 ? (elapsedDays / totalDays * 100).clamp(0, 100) : 0;
      final delayDays = avgProgress < expectedProgress
          ? ((expectedProgress - avgProgress) / 100 * totalDays).round().abs()
          : 0;

      final estimatedCompletionDays = avgProgress > 5
          ? ((100 - avgProgress) / (avgProgress / elapsedDays.clamp(1, double.infinity))).round()
          : 999;

      // Crear contexto del proyecto
      _projectContext = '''
CONTEXTO DEL PROYECTO:

**INFORMACIÓN GENERAL:**
- Nombre: ${widget.projectData['name']}
- Tipo: ${widget.projectData['type'] ?? 'No especificado'}
- Descripción: ${widget.projectData['description'] ?? 'Sin descripción'}
- Trabajadores: ${widget.projectData['workers'] ?? 'No especificado'}

**CRONOGRAMA:**
- Fecha Inicio: ${startDate.toString().split(' ')[0]}
- Fecha Fin Prevista: ${endDate.toString().split(' ')[0]}
- Días Totales: $totalDays
- Días Transcurridos: $elapsedDays
- Días Restantes: $remainingDays

**PROGRESO:**
- Progreso Actual: ${avgProgress.toStringAsFixed(1)}%
- Progreso Esperado: ${expectedProgress.toStringAsFixed(1)}%
- ${delayDays > 0 ? 'Retraso: $delayDays días' : 'A tiempo'}
- Estimación para completar: ${estimatedCompletionDays > 900 ? 'No calculable' : '$estimatedCompletionDays días más'}

**SECCIONES (${sections.length}):**
${sections.map((s) => '- ${s['name']}: ${s['progress']}% - ${s['description']}').join('\n')}

**MATERIALES (${materials.length}):**
Costo total invertido: \$${totalMaterialsCost.toStringAsFixed(2)}
${materials.take(10).map((m) => '- ${m['name']}: ${m['quantityUsed']}/${m['quantityPlanned']} ${m['unit']} - ${m['status']} - \$${(m['cost'] as num).toStringAsFixed(2)}').join('\n')}
${materials.length > 10 ? '... y ${materials.length - 10} materiales más' : ''}

**EQUIPO DE TRABAJO:**
- Total de Reportes: ${reports.length}
- Contratistas: ${contractors.join(', ')}

**ÚLTIMOS REPORTES:**
${reports.take(5).map((r) => '- ${r['date']}: ${r['contractor']} en ${r['section']} (+${r['progress']}%) - ${r['description']}').join('\n')}
''';

      print('✅ Contexto del proyecto cargado exitosamente');
      print('   - Secciones: ${sections.length}');
      print('   - Materiales: ${materials.length}');
      print('   - Reportes: ${reports.length}');
      print('   - Progreso: ${avgProgress.toStringAsFixed(1)}%');

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Mensaje de bienvenida
      _messages.add(ChatMessage(
        text: '¡Hola! Soy tu asistente del proyecto "${widget.projectData['name']}".\n\n'
            '📊 Datos cargados:\n'
            '• ${sections.length} secciones\n'
            '• ${materials.length} materiales\n'
            '• ${reports.length} reportes\n'
            '• Progreso: ${avgProgress.toStringAsFixed(1)}%\n\n'
            'Puedo ayudarte con:\n'
            '• Estado y progreso del proyecto\n'
            '• Información de secciones\n'
            '• Materiales y costos\n'
            '• Cronograma y estimaciones\n'
            '• Reportes y contratistas\n\n'
            '¿Qué te gustaría saber?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      setState(() {});

    } catch (e, stackTrace) {
      print('❌ Error fatal en initializeContext: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos del proyecto. Revisa la consola para más detalles.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _initializeContext,
            ),
          ),
        );

        // Agregar mensaje de error en el chat
        _messages.add(ChatMessage(
          text: '⚠️ Error al cargar datos del proyecto.\n\n'
              'Esto puede deberse a:\n'
              '• Problemas de conexión\n'
              '• Permisos de Firestore\n'
              '• Datos del proyecto incompletos\n\n'
              'Presiona el botón de actualizar (↻) arriba para reintentar.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('Asistente IA - ${widget.projectData['name']}'),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeContext,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos del proyecto...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.blue
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Pregunta sobre el proyecto...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            child: Icon(Icons.send),
            mini: true,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isInitialized) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();

    // Mostrar indicador de escritura
    setState(() {
      _messages.add(ChatMessage(
        text: '...',
        isUser: false,
        timestamp: DateTime.now(),
        isTyping: true,
      ));
    });

    try {
      print('💬 Enviando pregunta a IA: $userMessage');

      final prompt = '''
$_projectContext

PREGUNTA DEL USUARIO: $userMessage

INSTRUCCIONES:
- Responde SOLO basándote en el contexto del proyecto proporcionado arriba
- Sé específico y proporciona números exactos cuando sea posible
- Si la pregunta es sobre una sección específica, busca esa sección en el contexto
- Si preguntan por progreso, menciona el porcentaje exacto
- Si preguntan por retrasos, menciona los días exactos
- Si preguntan por materiales, proporciona costos y cantidades
- Si preguntan por contratistas, menciona quién ha estado trabajando
- Si preguntan por estimaciones, calcula basándote en el progreso actual
- Si la información no está en el contexto, di claramente que no tienes esa información
- Responde de manera profesional pero amigable
- Usa formato claro y organizado
- Incluye emojis para hacer la respuesta más visual

RESPUESTA:
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('La IA no generó respuesta');
      }

      final aiResponse = response.text!;
      print('✅ Respuesta recibida: ${aiResponse.length} caracteres');

      // Remover indicador de escritura
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    } catch (e, stackTrace) {
      print('❌ Error al enviar mensaje: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _messages.removeLast();

        String errorMessage = '⚠️ No pude procesar tu pregunta.\n\n';

        if (e.toString().contains('API key')) {
          errorMessage += 'Problema con la clave API de Google AI.\n\n'
              'Verifica:\n'
              '• Que la clave API sea válida\n'
              '• Que tengas créditos disponibles\n'
              '• Que la API esté habilitada';
        } else if (e.toString().contains('quota')) {
          errorMessage += 'Se ha excedido la cuota de la API.\n\n'
              'Espera unos minutos e intenta de nuevo.';
        } else if (e.toString().contains('network')) {
          errorMessage += 'Problema de conexión.\n\n'
              'Verifica tu conexión a internet.';
        } else {
          errorMessage += 'Error: ${e.toString()}\n\n'
              'Por favor intenta de nuevo.';
        }

        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });
}
