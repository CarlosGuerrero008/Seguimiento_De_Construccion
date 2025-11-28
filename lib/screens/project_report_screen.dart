import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';
import '../services/pdf_generator_service.dart';

class ProjectReportScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectReportScreen({
    Key? key,
    required this.projectId,
    required this.projectData,
  }) : super(key: key);

  @override
  _ProjectReportScreenState createState() => _ProjectReportScreenState();
}

class _ProjectReportScreenState extends State<ProjectReportScreen> {
  final GeminiService _geminiService = GeminiService();
  final PDFGeneratorService _pdfService = PDFGeneratorService();

  bool _isGenerating = false;
  bool _isCompleted = false;
  Map<String, dynamic>? _reportData;
  String _currentStep = '';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte Completo del Proyecto'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 20),
            if (!_isGenerating && !_isCompleted) _buildGenerateButton(),
            if (_isGenerating) _buildProgressIndicator(),
            if (_isCompleted && _reportData != null) _buildReportPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reporte Ejecutivo Completo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('Proyecto', widget.projectData['name'] ?? 'N/A'),
            _buildInfoRow('Tipo', widget.projectData['type'] ?? 'N/A'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Este reporte incluirá:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildFeature('Análisis de todas las secciones del proyecto'),
                  _buildFeature('Evaluación de materiales y costos'),
                  _buildFeature('Análisis de cronograma y retrasos'),
                  _buildFeature('Desempeño de contratistas'),
                  _buildFeature('Proyecciones y recomendaciones'),
                  _buildFeature('Reporte ejecutivo con IA'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _generateReport,
        icon: Icon(Icons.auto_awesome, size: 28),
        label: Text(
          'GENERAR REPORTE COMPLETO',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(
              value: _progress,
              strokeWidth: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 20),
            Text(
              _currentStep,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    final delayDays = _reportData?['delayDays'] ?? 0;
    final avgProgress = _reportData?['averageProgress'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          color: Colors.green.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Reporte Generado!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        'El análisis completo del proyecto se completó exitosamente',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Resumen rápido
        Card(
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUMEN RÁPIDO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '${avgProgress.toStringAsFixed(1)}%',
                        'Progreso',
                        Icons.show_chart,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '${_reportData?['totalSections'] ?? 0}',
                        'Secciones',
                        Icons.construction,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '\$${(_reportData?['materialsCost'] ?? 0).toStringAsFixed(0)}',
                        'Materiales',
                        Icons.inventory,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        delayDays > 0 ? '$delayDays días' : 'A tiempo',
                        'Cronograma',
                        Icons.calendar_today,
                        delayDays > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Informe ejecutivo
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INFORME EJECUTIVO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider(),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade700
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Text(
                    _reportData?['executiveSummary'] ?? 'No disponible',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportToPDF,
                icon: Icon(Icons.picture_as_pdf),
                label: Text('EXPORTAR PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReport,
                icon: Icon(Icons.share),
                label: Text('COMPARTIR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600]
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _currentStep = 'Obteniendo secciones del proyecto...';
      _progress = 0.1;
    });

    try {
      // Obtener todas las secciones
      final sectionsSnapshot = await FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      final sections = sectionsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      print('=== DEBUG REPORTE ===');
      print('Total secciones encontradas: ${sections.length}');
      for (var section in sections) {
        print('Sección: ${section['name']}, Progreso: ${section['progressPercentage']}%');
      }

      setState(() {
        _currentStep = 'Obteniendo materiales...';
        _progress = 0.3;
      });

      // Obtener todos los materiales
      final materialsSnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      final allMaterials = materialsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      setState(() {
        _currentStep = 'Obteniendo reportes diarios...';
        _progress = 0.5;
      });

      // Obtener reportes diarios por sección
      Map<String, List<Map<String, dynamic>>> sectionReports = {};
      for (var section in sections) {
        final reportsSnapshot = await FirebaseFirestore.instance
            .collection('dailyReports')
            .where('sectionId', isEqualTo: section['id'])
            .get();

        sectionReports[section['id']] = reportsSnapshot.docs
            .map((doc) => doc.data())
            .toList();
      }

      setState(() {
        _currentStep = 'Generando análisis con IA...';
        _progress = 0.7;
      });

      print('Materiales totales: ${allMaterials.length}');
      print('Project Data: ${widget.projectData}');

      // Generar reporte completo
      final reportData = await _geminiService.generateCompleteProjectReport(
        projectData: widget.projectData,
        sections: sections,
        allMaterials: allMaterials,
        sectionReports: sectionReports,
      );

      print('=== DATOS DEL REPORTE GENERADO ===');
      print('Progreso: ${reportData['averageProgress']}%');
      print('Secciones: ${reportData['totalSections']}');
      print('Costo materiales: ${reportData['materialsCost']}');
      print('Delay días: ${reportData['delayDays']}');
      print('==================================');

      setState(() {
        _currentStep = '¡Completado!';
        _progress = 1.0;
        _reportData = reportData;
        _isGenerating = false;
        _isCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Reporte completo generado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportToPDF() async {
    if (_reportData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener datos del usuario actual
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic>? userData;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        userData = userDoc.data();
      }

      final pdfFile = await _pdfService.generateCompleteProjectReportPDF(_reportData!, userData);
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('PDF Generado'),
            ],
          ),
          content: Text('El reporte PDF se ha generado exitosamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _pdfService.sharePDF(pdfFile, widget.projectData['name'] ?? 'Proyecto');
              },
              icon: Icon(Icons.share),
              label: Text('Compartir'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _pdfService.printPDF(pdfFile);
              },
              icon: Icon(Icons.print),
              label: Text('Imprimir'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareReport() async {
    if (_reportData == null) return;

    try {
      // Obtener datos del usuario actual
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic>? userData;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        userData = userDoc.data();
      }

      final pdfFile = await _pdfService.generateCompleteProjectReportPDF(_reportData!, userData);
      await _pdfService.sharePDF(pdfFile, widget.projectData['name'] ?? 'Proyecto');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
