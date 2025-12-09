import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../services/gemini_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/document_service.dart';
import '../providers/theme_provider.dart';

class AIReportScreen extends StatefulWidget {
  final String projectId;
  final String sectionId;
  final String sectionName;
  final Map<String, dynamic> sectionData;
  final Map<String, dynamic> projectData;

  const AIReportScreen({
    Key? key,
    required this.projectId,
    required this.sectionId,
    required this.sectionName,
    required this.sectionData,
    required this.projectData,
  }) : super(key: key);

  @override
  _AIReportScreenState createState() => _AIReportScreenState();
}

class _AIReportScreenState extends State<AIReportScreen> {
  final GeminiService _geminiService = GeminiService();
  final PDFGeneratorService _pdfService = PDFGeneratorService();
  final DocumentService _documentService = DocumentService();

  bool _isGenerating = false;
  bool _isCompleted = false;
  Map<String, dynamic>? _reportData;
  String _currentStep = '';
  double _progress = 0.0;
  bool _isSavingDocument = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte con IA'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Generación de Reporte con IA',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('Proyecto', widget.projectData['name'] ?? 'N/A'),
            _buildInfoRow('Sección', widget.sectionName),
            _buildInfoRow(
              'Progreso Actual',
              '${widget.sectionData['progressPercentage']?.toStringAsFixed(1) ?? '0'}%',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.purple.withOpacity(0.2) 
                    : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark 
                      ? Colors.purple.withOpacity(0.5) 
                      : Colors.purple.withOpacity(0.3)
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'El reporte incluirá:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildFeature('Análisis de todas las imágenes con IA'),
                  _buildFeature('Evaluación de calidad y progreso'),
                  _buildFeature('Detección de riesgos y problemas'),
                  _buildFeature('Recomendaciones profesionales'),
                  _buildFeature('Exportación a PDF profesional'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.purple),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
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
          'GENERAR REPORTE CON IA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(
              value: _progress,
              strokeWidth: 6,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          color: isDark 
              ? Colors.green.withOpacity(0.2) 
              : Colors.green.shade50,
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
                          color: isDark ? Colors.green.shade300 : Colors.green.shade900,
                        ),
                      ),
                      Text(
                        'El análisis con IA se completó exitosamente',
                        style: TextStyle(
                          color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUMEN EJECUTIVO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider(),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.primary500.withOpacity(0.2) 
                        : AppColors.primary50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _reportData?['executiveSummary'] ?? 'No disponible',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.description, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Reportes analizados: ${_reportData?['analyzedReports']?.length ?? 0}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _copyReportToClipboard,
            icon: Icon(Icons.copy),
            label: Text('COPIAR REPORTE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _currentStep = 'Obteniendo reportes...';
      _progress = 0.1;
    });

    try {
      // Obtener todos los reportes de la sección (sin orderBy para evitar índice compuesto)
      final reportsSnapshot = await FirebaseFirestore.instance
          .collection('dailyReports')
          .where('sectionId', isEqualTo: widget.sectionId)
          .get();

      setState(() {
        _currentStep = 'Preparando datos (${reportsSnapshot.docs.length} reportes)...';
        _progress = 0.2;
      });

      // Ordenar manualmente en memoria por fecha
      final reports = reportsSnapshot.docs
          .map((doc) => {...doc.data(), 'date': doc.data()['date']})
          .toList();

      reports.sort((a, b) {
        final dateA = a['date'] as Timestamp?;
        final dateB = b['date'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

      if (reports.isEmpty) {
        throw Exception('No hay reportes para analizar');
      }

      setState(() {
        _currentStep = 'Obteniendo materiales de la sección...';
        _progress = 0.3;
      });

      // Obtener materiales de la sección
      final materialsSnapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('sectionId', isEqualTo: widget.sectionId)
          .get();

      final sectionMaterials = materialsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      setState(() {
        _currentStep = 'Analizando imágenes con IA...';
        _progress = 0.5;
      });

      // Generar reporte con IA
      final reportData = await _geminiService.generateSectionReport(
        sectionName: widget.sectionName,
        sectionDescription: widget.sectionData['description'] ?? '',
        currentProgress: (widget.sectionData['progressPercentage'] ?? 0).toDouble(),
        dailyReports: reports,
        projectData: widget.projectData,
        sectionMaterials: sectionMaterials,
      );

      setState(() {
        _currentStep = 'Generando conclusiones...';
        _progress = 0.9;
      });

      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _reportData = reportData;
        _isGenerating = false;
        _isCompleted = true;
        _currentStep = '¡Completado!';
        _progress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Reporte generado con éxito'),
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

      final pdfFile = await _pdfService.generateSectionReportPDF(_reportData!, userData);
      Navigator.pop(context);

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
            onPressed: _isSavingDocument
                ? null
                : () => _savePdfToDocumentation(pdfFile),
            icon: _isSavingDocument
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.folder_open),
            label: Text(
              _isSavingDocument
                  ? 'Guardando...'
                  : 'Guardar en documentación',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pdfService.sharePDF(pdfFile, widget.sectionName);
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyReportToClipboard() async {
    if (_reportData == null) return;

    try {
      final StringBuffer reportText = StringBuffer();
      
      reportText.writeln('=== REPORTE DE SECCIÓN CON IA ===');
      reportText.writeln('');
      reportText.writeln('Proyecto: ${widget.projectData['name'] ?? 'N/A'}');
      reportText.writeln('Sección: ${widget.sectionName}');
      reportText.writeln('Progreso Actual: ${widget.sectionData['progressPercentage']?.toStringAsFixed(1) ?? '0'}%');
      reportText.writeln('');
      reportText.writeln('--- RESUMEN EJECUTIVO ---');
      reportText.writeln(_reportData?['executiveSummary'] ?? 'No disponible');
      reportText.writeln('');
      reportText.writeln('Reportes analizados: ${_reportData?['analyzedReports']?.length ?? 0}');
      reportText.writeln('');
      reportText.writeln('Generado el: ${DateTime.now().toString()}');

      await Clipboard.setData(ClipboardData(text: reportText.toString()));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Reporte copiado al portapapeles'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al copiar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareReport() async {
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

      final pdfFile = await _pdfService.generateSectionReportPDF(_reportData!, userData);
      Navigator.pop(context);

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
            onPressed: _isSavingDocument
                ? null
                : () => _savePdfToDocumentation(pdfFile),
            icon: _isSavingDocument
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.folder_open),
            label: Text(
              _isSavingDocument
                  ? 'Guardando...'
                  : 'Guardar en documentación',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pdfService.sharePDF(pdfFile, widget.sectionName);
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePdfToDocumentation(File pdfFile) async {
    if (_isSavingDocument) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes iniciar sesión para guardar documentos.')),
      );
      return;
    }

    setState(() => _isSavingDocument = true);
    try {
      await _documentService.uploadDocument(
        projectId: widget.projectId,
        file: pdfFile,
        fileName:
            'reporte_${widget.sectionName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        uploadedBy: user.uid,
        source: 'ia',
        sectionId: widget.sectionId,
        description:
            'Reporte generado automáticamente para la sección ${widget.sectionName}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF guardado en la documentación del proyecto')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingDocument = false);
    }
  }
}
