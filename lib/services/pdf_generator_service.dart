import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PDFGeneratorService {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat shortDateFormat = DateFormat('dd/MM/yyyy');

  /// Genera PDF del reporte de sección con análisis de IA
  Future<File> generateSectionReportPDF(
    Map<String, dynamic> reportData,
    Map<String, dynamic>? userData,
  ) async {
    final pdf = pw.Document();

    // Cargar fuentes
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(reportData, fontBold),
          pw.SizedBox(height: 20),
          if (userData != null) ...[
            _buildUserInfo(userData, font, fontBold),
            pw.SizedBox(height: 20),
          ],
          _buildProjectInfo(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildProgressSection(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildMaterialsSection(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildExecutiveSummary(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildDetailedReports(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildContractorsSection(reportData, font, fontBold),
        ],
        footer: (context) => _buildFooter(context, font),
      ),
    );

    // Guardar PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_${reportData['sectionName']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildUserInfo(
    Map<String, dynamic> userData,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL DIRECTOR DE OBRA',
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900),
          ),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow(
                  'Director:',
                  '${userData['name'] ?? ''} ${userData['apellidos'] ?? ''}'.trim(),
                  font,
                  fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow(
                  'Empresa:',
                  userData['company'] ?? 'N/A',
                  font,
                  fontBold,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _buildInfoRow(
                  'Cargo:',
                  userData['position'] ?? 'Director de Obra',
                  font,
                  fontBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeader(Map<String, dynamic> data, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORME TÉCNICO DE AVANCE DE OBRA',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sección: ${data['sectionName'] ?? 'N/A'}',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 16,
              color: PdfColors.blue100,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Análisis con Inteligencia Artificial - Sistema de Seguimiento de Construcción',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue100,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectInfo(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL PROYECTO',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.Divider(color: PdfColors.blue),
          pw.SizedBox(height: 8),
          _buildInfoRow('Proyecto:', data['projectName'] ?? 'N/A', font, fontBold),
          _buildInfoRow('Sección:', data['sectionName'] ?? 'N/A', font, fontBold),
          _buildInfoRow(
            'Fecha de generación:',
            data['generatedAt'] != null
                ? dateFormat.format(DateTime.parse(data['generatedAt']))
                : 'N/A',
            font,
            fontBold,
          ),
          _buildInfoRow(
            'Total de reportes:',
            '${data['totalReports'] ?? 0}',
            font,
            fontBold,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProgressSection(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final progress = (data['currentProgress'] ?? 0).toDouble();
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROGRESO ACTUAL',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  height: 30,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        width: (progress / 100) * 200,
                        decoration: pw.BoxDecoration(
                          color: progress < 30
                              ? PdfColors.red
                              : progress < 70
                                  ? PdfColors.orange
                                  : PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(15),
                        ),
                      ),
                      pw.Center(
                        child: pw.Text(
                          '${progress.toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: fontBold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: progress < 30
                  ? PdfColors.red100
                  : progress < 70
                      ? PdfColors.orange100
                      : PdfColors.green100,
            ),
            child: pw.Center(
              child: pw.Text(
                '${progress.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: progress < 30
                      ? PdfColors.red900
                      : progress < 70
                          ? PdfColors.orange900
                          : PdfColors.green900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMaterialsSection(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final materialsUsed = data['materialsUsed'] ?? 0;
    final materialsCost = (data['materialsCost'] ?? 0).toDouble();
    final materialsDetails = List<Map<String, dynamic>>.from(
      data['materialsDetails'] ?? [],
    );

    if (materialsUsed == 0 && materialsDetails.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'ANÁLISIS DE MATERIALES',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green200),
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox(
                    '$materialsUsed',
                    'Materiales',
                    PdfColors.green,
                    font,
                    fontBold,
                  ),
                  pw.SizedBox(width: 20),
                  _buildStatBox(
                    '\$${materialsCost.toStringAsFixed(2)}',
                    'Costo Total',
                    PdfColors.green700,
                    font,
                    fontBold,
                  ),
                ],
              ),
              if (materialsDetails.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.green300),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Detalle de Materiales:',
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                ...materialsDetails.take(10).map((material) {
                  final name = material['name'] ?? 'Sin nombre';
                  final quantityUsed = (material['quantityUsed'] ?? 0).toDouble();
                  final quantityPlanned = (material['quantityPlanned'] ?? 0).toDouble();
                  final unit = material['unit'] ?? 'und';
                  final status = material['status'] ?? 'Pendiente';
                  final percent = quantityPlanned > 0
                      ? (quantityUsed / quantityPlanned * 100)
                      : 0;

                  return pw.Container(
                    margin: pw.EdgeInsets.only(bottom: 6),
                    padding: pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            name,
                            style: pw.TextStyle(font: fontBold, fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '$quantityUsed/$quantityPlanned $unit',
                            style: pw.TextStyle(font: font, fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9,
                              color: percent >= 100 ? PdfColors.red : PdfColors.green,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            status,
                            style: pw.TextStyle(font: font, fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (materialsDetails.length > 10)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      '... y ${materialsDetails.length - 10} materiales más',
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildContractorsSection(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final contractors = List<String>.from(data['contractorsInvolved'] ?? []);

    if (contractors.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ASPECTOS ADMINISTRATIVOS',
                style: pw.TextStyle(font: fontBold, fontSize: 16),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.orange300),
              pw.SizedBox(height: 8),
              pw.Text(
                'Contratistas Involucrados:',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 6),
              ...contractors.map((contractor) => pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      contractor,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              )),
              pw.SizedBox(height: 12),
              pw.Text(
                'Control y Documentación:',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 6),
              _buildInfoRow(
                'Total de Reportes Diarios:',
                '${data['totalReports'] ?? 0}',
                font,
                fontBold,
              ),
              _buildInfoRow(
                'Total de Imágenes Analizadas con IA:',
                '${data['totalImages'] ?? 0}',
                font,
                fontBold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExecutiveSummary(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'INFORME TÉCNICO DE AVANCE - ANÁLISIS CON IA',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            data['executiveSummary'] ?? 'No disponible',
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailedReports(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final reports = List<Map<String, dynamic>>.from(
      data['analyzedReports'] ?? [],
    );

    if (reports.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPORTES DETALLADOS',
          style: pw.TextStyle(font: fontBold, fontSize: 16),
        ),
        pw.Divider(color: PdfColors.blue),
        pw.SizedBox(height: 10),
        ...reports.map((report) => _buildReportCard(report, font, fontBold)),
      ],
    );
  }

  pw.Widget _buildReportCard(
    Map<String, dynamic> report,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Fecha: ${report['date'] != null ? shortDateFormat.format((report['date'] as dynamic).toDate()) : 'N/A'}',
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green200,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    '+${report['progressAdded']}%',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.green900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Contratista:',
                  report['contractor'] ?? 'N/A',
                  font,
                  fontBold,
                ),
                pw.SizedBox(height: 4),
                _buildInfoRow(
                  'Fotos analizadas:',
                  '${report['photoCount'] ?? 0}',
                  font,
                  fontBold,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Descripción:',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  report['description'] ?? 'Sin descripción',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Análisis IA:',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        (report['aiAnalysis']?['summary'] ?? 'No disponible')
                            .toString()
                            .substring(
                              0,
                              ((report['aiAnalysis']?['summary'] ?? '')
                                          .toString()
                                          .length <
                                      300)
                                  ? (report['aiAnalysis']?['summary'] ?? '')
                                      .toString()
                                      .length
                                  : 300,
                            ),
                        style: pw.TextStyle(font: font, fontSize: 9),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: fontBold, fontSize: 10),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado con Seguimientos - Sistema de Seguimiento de Construcción',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Comparte el PDF generado
  Future<void> sharePDF(File pdfFile, String sectionName) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Reporte de Construcción - $sectionName',
      text: 'Reporte generado con análisis de IA por Seguimientos',
    );
  }

  /// Imprime el PDF
  Future<void> printPDF(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
    );
  }

  /// Genera PDF del reporte completo del proyecto
  Future<File> generateCompleteProjectReportPDF(
    Map<String, dynamic> reportData,
    Map<String, dynamic>? userData,
  ) async {
    final pdf = pw.Document();

    // Cargar fuentes
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          _buildProjectHeader(reportData, fontBold),
          pw.SizedBox(height: 20),
          if (userData != null) ...[
            _buildUserInfo(userData, font, fontBold),
            pw.SizedBox(height: 20),
          ],
          _buildProjectGeneralInfo(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildProjectStats(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildProjectSchedule(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildProjectExecutiveSummary(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildSectionsAnalysis(reportData, font, fontBold),
          pw.SizedBox(height: 20),
          _buildProjectAdministrative(reportData, font, fontBold),
        ],
        footer: (context) => _buildFooter(context, font),
      ),
    );

    // Guardar PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_proyecto_${reportData['projectName']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildProjectHeader(Map<String, dynamic> data, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORME TÉCNICO DE AVANCE DE OBRA',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 26,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'REPORTE GENERAL DEL PROYECTO',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.blue200,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              data['projectName'] ?? 'Proyecto',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Análisis Integral con Inteligencia Artificial - Sistema de Seguimiento de Construcción',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue100,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectGeneralInfo(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN GENERAL',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.Divider(color: PdfColors.purple),
          pw.SizedBox(height: 8),
          _buildInfoRow('Proyecto:', data['projectName'] ?? 'N/A', font, fontBold),
          _buildInfoRow('Tipo:', data['projectType'] ?? 'N/A', font, fontBold),
          _buildInfoRow(
            'Fecha de generación:',
            data['generatedAt'] != null
                ? dateFormat.format(DateTime.parse(data['generatedAt']))
                : 'N/A',
            font,
            fontBold,
          ),
          _buildInfoRow(
            'Secciones totales:',
            '${data['totalSections'] ?? 0}',
            font,
            fontBold,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectStats(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final avgProgress = (data['averageProgress'] ?? 0).toDouble();
    final delayDays = data['delayDays'] ?? 0;
    final materialsCost = (data['materialsCost'] ?? 0).toDouble();

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN EJECUTIVO',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  '${avgProgress.toStringAsFixed(1)}%',
                  'Progreso General',
                  avgProgress < 30 ? PdfColors.red :
                  avgProgress < 70 ? PdfColors.orange : PdfColors.green,
                  font,
                  fontBold,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  delayDays > 0 ? '$delayDays días' : 'A tiempo',
                  'Cronograma',
                  delayDays > 0 ? PdfColors.red : PdfColors.green,
                  font,
                  fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatBox(
                  '\$${materialsCost.toStringAsFixed(0)}',
                  'Inversión Materiales',
                  PdfColors.blue,
                  font,
                  fontBold,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildStatBox(
                  '${data['totalReports'] ?? 0}',
                  'Reportes Totales',
                  PdfColors.purple,
                  font,
                  fontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow(
            'Contratistas:',
            (data['contractors'] as List?)?.join(', ') ?? 'N/A',
            font,
            fontBold,
          ),
          _buildInfoRow(
            'Total de imágenes:',
            '${data['totalImages'] ?? 0}',
            font,
            fontBold,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(
    String value,
    String label,
    PdfColor color,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 18,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectSchedule(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final startDate = data['startDate'] != null
        ? DateTime.parse(data['startDate'])
        : DateTime.now();
    final endDate = data['endDate'] != null
        ? DateTime.parse(data['endDate'])
        : DateTime.now();
    final elapsedDays = data['elapsedDays'] ?? 0;
    final remainingDays = data['remainingDays'] ?? 0;
    final delayDays = data['delayDays'] ?? 0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SEGUIMIENTO DE CRONOGRAMA',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.Divider(color: PdfColors.blue),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Fecha de Inicio:',
                      shortDateFormat.format(startDate),
                      font,
                      fontBold,
                    ),
                    pw.SizedBox(height: 4),
                    _buildInfoRow(
                      'Fecha de Finalización:',
                      shortDateFormat.format(endDate),
                      font,
                      fontBold,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Días Transcurridos:',
                      '$elapsedDays días',
                      font,
                      fontBold,
                    ),
                    pw.SizedBox(height: 4),
                    _buildInfoRow(
                      'Días Restantes:',
                      '$remainingDays días',
                      font,
                      fontBold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: delayDays > 0 ? PdfColors.red50 : PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: delayDays > 0 ? PdfColors.red300 : PdfColors.green300,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  delayDays > 0 ? '⚠' : '✓',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: delayDays > 0 ? PdfColors.red : PdfColors.green,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  delayDays > 0
                      ? 'RETRASO ESTIMADO: $delayDays días'
                      : 'CRONOGRAMA DENTRO DEL PLAZO',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: delayDays > 0 ? PdfColors.red900 : PdfColors.green900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectAdministrative(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final contractors = List<String>.from(data['contractors'] ?? []);
    final totalReports = data['totalReports'] ?? 0;
    final totalImages = data['totalImages'] ?? 0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      padding: pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ASPECTOS ADMINISTRATIVOS',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
          pw.Divider(color: PdfColors.orange300),
          pw.SizedBox(height: 12),
          pw.Text(
            'Personal y Contratistas:',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          if (contractors.isNotEmpty)
            ...contractors.map((contractor) => pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 6,
                    height: 6,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    contractor,
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            )),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.orange200),
          pw.SizedBox(height: 8),
          pw.Text(
            'Control y Documentación:',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.orange300),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '$totalReports',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Reportes Diarios',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.orange300),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '$totalImages',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Imágenes Analizadas',
                        style: pw.TextStyle(font: font, fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'ℹ',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Toda la documentación ha sido verificada y analizada con Inteligencia Artificial',
                    style: pw.TextStyle(font: font, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectExecutiveSummary(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'INFORME TÉCNICO DE AVANCE - ANÁLISIS CON IA',
            style: pw.TextStyle(font: fontBold, fontSize: 16),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(8),
              bottomRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            data['executiveSummary'] ?? 'No disponible',
            style: pw.TextStyle(font: font, fontSize: 10, lineSpacing: 1.5),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionsAnalysis(
    Map<String, dynamic> data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final allSections = List<Map<String, dynamic>>.from(
      data['sectionsAnalysis'] ?? [],
    );

    if (allSections.isEmpty) {
      return pw.Container();
    }

    // Limitar a un máximo de 5 secciones para evitar PDFs demasiado largos
    final sections = allSections.take(5).toList();
    final hasMore = allSections.length > 5;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ANÁLISIS POR SECCIONES',
              style: pw.TextStyle(font: fontBold, fontSize: 16),
            ),
            if (hasMore)
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Mostrando 5 de ${allSections.length}',
                  style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.purple900),
                ),
              ),
          ],
        ),
        pw.Divider(color: PdfColors.purple),
        pw.SizedBox(height: 10),
        ...sections.map((section) => _buildSectionCard(section, font, fontBold)),
        if (hasMore) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            padding: pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.purple200),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'ℹ',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfColors.purple,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'Se omitieron ${allSections.length - 5} secciones adicionales. Para ver el reporte completo, genere reportes individuales por sección.',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.purple900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildSectionCard(
    Map<String, dynamic> section,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final progress = (section['progress'] ?? 0).toDouble();
    final color = progress < 30 ? PdfColors.red :
                  progress < 70 ? PdfColors.orange : PdfColors.green;

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(12),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  section['name'] ?? 'Sin nombre',
                  style: pw.TextStyle(font: fontBold, fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Estado: ${section['status'] ?? 'Desconocido'}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  'Reportes: ${section['reports'] ?? 0}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: color.shade(0.8),
            ),
            child: pw.Center(
              child: pw.Text(
                '${progress.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
