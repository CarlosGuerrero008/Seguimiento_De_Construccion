import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String kGeminiFallbackModel = 'gemini-2.5-flash';
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no está configurada en el archivo .env');
    }

    _model = GenerativeModel(
      model: kGeminiFallbackModel,
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: kGeminiFallbackModel,
      apiKey: _apiKey,
    );
  }

  /// Analiza una imagen de construcción y retorna información detallada
  Future<String> analyzeConstructionImage(Uint8List imageBytes) async {
    try {
      final prompt = '''
Analiza esta imagen de construcción civil y proporciona un análisis detallado profesional en español.
Incluye:
1. Tipo de trabajo/actividad que se observa (excavación, cimentación, estructura, acabados, etc.)
2. Estado actual del trabajo (inicio, en progreso, casi terminado, terminado)
3. Calidad aparente del trabajo (excelente, buena, regular, deficiente)
4. Materiales visibles utilizados
5. Posibles riesgos o problemas detectados
6. Cumplimiento aparente de normas de seguridad
7. Estimación de progreso (porcentaje aproximado)
8. Recomendaciones profesionales

Sé específico, técnico y profesional en tu análisis.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      return response.text ?? 'No se pudo analizar la imagen';
    } catch (e) {
      print('Error al analizar imagen: $e');
      return 'Error al analizar la imagen: $e';
    }
  }

  /// Analiza múltiples imágenes de un reporte
  Future<Map<String, dynamic>> analyzeMultipleImages(
    List<Uint8List> images,
    String description,
    double progressReported,
  ) async {
    try {
      List<String> analyses = [];

      for (int i = 0; i < images.length; i++) {
        final analysis = await analyzeConstructionImage(images[i]);
        analyses.add('**Imagen ${i + 1}:**\n$analysis');
      }

      final summaryPrompt = '''
Como ingeniero civil experto, analiza los siguientes datos de un reporte de construcción:

Descripción del contratista: "$description"
Progreso reportado: $progressReported%

Análisis de imágenes:
${analyses.join('\n\n')}

Proporciona un resumen ejecutivo profesional que incluya:
1. Validación del progreso reportado (¿es coherente con las imágenes?)
2. Resumen de actividades realizadas
3. Evaluación de calidad general
4. Observaciones críticas
5. Recomendaciones para el siguiente período
6. Progreso real estimado basado en las imágenes

Formato: Profesional y técnico, para un informe de construcción civil.
''';

      final content = [Content.text(summaryPrompt)];
      final response = await _model.generateContent(content);

      return {
        'individualAnalyses': analyses,
        'summary': response.text ?? 'No se pudo generar resumen',
        'analysisDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error en análisis múltiple: $e');
      return {
        'error': 'Error al analizar: $e',
        'individualAnalyses': [],
        'summary': 'Error al generar resumen',
      };
    }
  }

  /// Genera un reporte completo de una sección con análisis de IA
  Future<Map<String, dynamic>> generateSectionReport({
    required String sectionName,
    required String sectionDescription,
    required double currentProgress,
    required List<Map<String, dynamic>> dailyReports,
    required Map<String, dynamic> projectData,
    List<Map<String, dynamic>>? sectionMaterials,
  }) async {
    try {
      // Analizar todos los reportes
      List<Map<String, dynamic>> analyzedReports = [];
      Set<String> contractorsInvolved = {};

      for (var report in dailyReports) {
        final contractorName = report['contractorName'] ?? 'Desconocido';
        contractorsInvolved.add(contractorName);

        final photos = List<String>.from(report['photosBase64'] ?? []);
        if (photos.isEmpty) continue;

        // Convertir las primeras 3 fotos a Uint8List
        List<Uint8List> imageBytes = [];
        for (int i = 0; i < photos.length && i < 3; i++) {
          try {
            imageBytes.add(base64Decode(photos[i]));
          } catch (e) {
            print('Error decodificando imagen: $e');
          }
        }

        if (imageBytes.isNotEmpty) {
          final analysis = await analyzeMultipleImages(
            imageBytes,
            report['description'] ?? '',
            (report['progressAdded'] ?? 0).toDouble(),
          );

          analyzedReports.add({
            'date': report['date'],
            'contractor': contractorName,
            'description': report['description'],
            'progressAdded': report['progressAdded'],
            'aiAnalysis': analysis,
            'photoCount': photos.length,
          });
        }
      }

      // Preparar información de materiales
      String materialsInfo = '';
      double totalMaterialsCost = 0;
      int totalMaterialsUsed = 0;

      if (sectionMaterials != null && sectionMaterials.isNotEmpty) {
        totalMaterialsUsed = sectionMaterials.length;
        List<String> materialDetails = [];

        for (var material in sectionMaterials) {
          final name = material['name'] ?? 'Sin nombre';
          final quantityUsed = (material['quantityUsed'] ?? 0).toDouble();
          final quantityPlanned = (material['quantityPlanned'] ?? 0).toDouble();
          final unit = material['unit'] ?? 'unidades';
          final unitCost = (material['unitCost'] ?? 0).toDouble();
          final status = material['status'] ?? 'Pendiente';

          final cost = quantityUsed * unitCost;
          totalMaterialsCost += cost;

          final usagePercent = quantityPlanned > 0 ? (quantityUsed / quantityPlanned * 100) : 0;

          materialDetails.add(
            '- $name: $quantityUsed/$quantityPlanned $unit (${usagePercent.toStringAsFixed(1)}%) - Estado: $status - Costo: \$${cost.toStringAsFixed(2)}'
          );
        }

        materialsInfo = '''
**MATERIALES UTILIZADOS EN ESTA SECCIÓN:**
Total de materiales: $totalMaterialsUsed
Costo total de materiales usados: \$${totalMaterialsCost.toStringAsFixed(2)}

Detalle de materiales:
${materialDetails.join('\n')}
''';
      } else {
        materialsInfo = 'No hay materiales registrados para esta sección.';
      }

      // Generar resumen general de la sección siguiendo formato de Informe Técnico de Obra
      final sectionSummaryPrompt = '''
Como ingeniero director de proyecto de construcción civil, genera un INFORME TÉCNICO DE AVANCE DE OBRA profesional siguiendo el formato de informes técnicos oficiales de construcción:

═══════════════════════════════════════════════════════════════
📋 INFORMACIÓN GENERAL DEL PROYECTO
═══════════════════════════════════════════════════════════════
Proyecto: ${projectData['name']}
Sección Evaluada: $sectionName
Descripción de la Sección: $sectionDescription
Progreso Actual de la Sección: $currentProgress%
Total de Reportes Analizados: ${dailyReports.length}
Total de Imágenes Analizadas con IA: ${analyzedReports.fold(0, (sum, r) => sum + (r['photoCount'] as int))}
Contratistas Involucrados: ${contractorsInvolved.join(', ')}

$materialsInfo

═══════════════════════════════════════════════════════════════
📊 RESUMEN DE REPORTES DIARIOS ANALIZADOS
═══════════════════════════════════════════════════════════════
${analyzedReports.map((r) => '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Fecha: ${r['date']}
👷 Contratista: ${r['contractor']}
📊 Progreso Añadido: ${r['progressAdded']}%
📸 Imágenes Analizadas: ${r['photoCount']}
📝 Descripción del Trabajo: ${r['description']}

🤖 ANÁLISIS DE IA:
${r['aiAnalysis']['summary']}
''').join('\n')}

═══════════════════════════════════════════════════════════════

GENERA UN INFORME TÉCNICO PROFESIONAL Y EXTENSO CON LA SIGUIENTE ESTRUCTURA:

**1. INTRODUCCIÓN**
   - Breve introducción al informe de la sección
   - Objetivo del informe
   - Periodo evaluado basado en los ${dailyReports.length} reportes diarios

**2. DESCRIPCIÓN DE ACTIVIDADES EJECUTADAS**
   - Detalle específico de cada actividad realizada en la sección
   - Para cada actividad mencionar: qué se hizo, cómo se ejecutó, cantidades (si aplica)
   - Usar formato narrativo profesional describiendo el trabajo realizado

**3. AVANCE DE ACTIVIDADES Y CANTIDADES EJECUTADAS**
   - Progreso acumulado de la sección: $currentProgress%
   - Descripción detallada del avance por cada reporte diario
   - Evolución temporal del progreso
   - Comparación entre progreso reportado y evidencia fotográfica analizada con IA

**4. ANÁLISIS TÉCNICO DE CALIDAD**
   - Evaluación técnica detallada basada en las ${analyzedReports.fold(0, (sum, r) => sum + (r['photoCount'] as int))} imágenes analizadas con IA
   - Calidad de la ejecución observada (excelente/buena/regular/deficiente)
   - Cumplimiento de normas técnicas y especificaciones
   - Acabados y detalles constructivos
   - Observaciones sobre procesos constructivos

**5. ANÁLISIS DE MATERIALES**
   - Detalle de materiales utilizados en la sección
   - Cantidades usadas vs cantidades planificadas
   - Costo de materiales invertidos: \$${totalMaterialsCost.toStringAsFixed(2)}
   - Eficiencia en el uso de materiales
   - Estado actual de los materiales (en uso, agotados, pendientes)
   - Proyección de materiales adicionales necesarios

**6. ASPECTOS ADMINISTRATIVOS**
   - Personal y contratistas que trabajaron en la sección
   - Frecuencia y calidad de los reportes
   - Cumplimiento de compromisos contractuales
   - Observaciones sobre el desempeño de cada contratista

**7. METODOLOGÍA DE MEDICIÓN Y CUANTIFICACIÓN**
   - Explicar cómo se midió y cuantificó el avance
   - Herramientas utilizadas (topografía, medición directa, fotogrametría)
   - Proceso de verificación con análisis de IA

**8. SEGUIMIENTO DE CRONOGRAMA**
   - Evaluación del progreso según lo planificado
   - Estimación de días de adelanto o retraso
   - Ritmo de trabajo (días productivos vs días totales)
   - Proyección de tiempo para completar la sección al 100%
   - Factores que han afectado el cronograma

**9. RIESGOS, PROBLEMAS E IMPACTOS IDENTIFICADOS**
   - Problemas actuales detectados en la ejecución
   - Riesgos potenciales identificados
   - Áreas de preocupación o atención especial
   - Defectos o incumplimientos de especificaciones
   - Impacto ambiental y medidas de mitigación
   - Impacto social y comunicación con la comunidad

**10. INTERVENTORÍA Y SUPERVISIÓN**
   - Actividades de supervisión realizadas
   - Verificaciones técnicas ejecutadas
   - Control de calidad aplicado
   - Registro fotográfico y documentación

**11. RECOMENDACIONES TÉCNICAS**
   - Acciones correctivas inmediatas necesarias
   - Mejoras sugeridas para optimizar el proceso
   - Prioridades para los siguientes periodos
   - Refuerzos de personal o equipo requeridos

**12. CONCLUSIONES Y DICTAMEN PROFESIONAL**
   - Resumen ejecutivo del estado de la sección
   - Principales logros alcanzados en el periodo
   - Viabilidad de cumplir objetivos y metas
   - Proyección realista de finalización
   - Estimación de presupuesto final vs presupuesto ejecutado
   - Dictamen técnico profesional

FORMATO: Profesional, técnico, estilo informe oficial de ingeniería civil para entidades públicas.
LONGITUD: Extenso y completo, con todos los detalles y análisis relevantes.
TONO: Formal, técnico, objetivo, basado en evidencia fotográfica y datos.
''';

      final content = [Content.text(sectionSummaryPrompt)];
      final response = await _model.generateContent(content);

      return {
        'sectionName': sectionName,
        'currentProgress': currentProgress,
        'totalReports': dailyReports.length,
        'totalImages': analyzedReports.fold(0, (sum, r) => sum + (r['photoCount'] as int)),
        'analyzedReports': analyzedReports,
        'contractorsInvolved': contractorsInvolved.toList(),
        'materialsUsed': totalMaterialsUsed,
        'materialsCost': totalMaterialsCost,
        'materialsDetails': sectionMaterials ?? [],
        'executiveSummary': response.text ?? 'No se pudo generar el resumen',
        'generatedAt': DateTime.now().toIso8601String(),
        'projectName': projectData['name'],
      };
    } catch (e) {
      print('Error generando reporte de sección: $e');
      return {
        'error': 'Error al generar reporte: $e',
        'sectionName': sectionName,
        'currentProgress': currentProgress,
      };
    }
  }

  /// Genera análisis comparativo de progreso
  Future<String> analyzeProgressTrend(List<Map<String, dynamic>> reports) async {
    try {
      final dataPoints = reports.map((r) {
        return 'Fecha: ${r['date']}, Progreso: ${r['progressAdded']}%, Descripción: ${r['description']}';
      }).join('\n');

      final prompt = '''
Como analista de proyectos de construcción, analiza la tendencia de progreso:

$dataPoints

Proporciona:
1. Análisis de tendencia (acelerado, constante, desacelerado)
2. Productividad promedio
3. Predicción para completar al 100%
4. Factores que podrían estar afectando el rendimiento
5. Sugerencias para optimizar el progreso

Respuesta: Formato profesional y conciso.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo analizar la tendencia';
    } catch (e) {
      return 'Error al analizar tendencia: $e';
    }
  }

  /// Genera un reporte completo del proyecto con todas las secciones
  Future<Map<String, dynamic>> generateCompleteProjectReport({
    required Map<String, dynamic> projectData,
    required List<Map<String, dynamic>> sections,
    required List<Map<String, dynamic>> allMaterials,
    required Map<String, List<Map<String, dynamic>>> sectionReports,
  }) async {
    try {
      // Calcular estadísticas generales
      double totalProgress = 0;
      int totalReports = 0;
      int totalImages = 0;
      Set<String> allContractors = {};
      double totalMaterialsCost = 0;
      int totalMaterialsCount = allMaterials.length;

      // Procesar materiales
      for (var material in allMaterials) {
        final quantityUsed = (material['quantityUsed'] ?? 0).toDouble();
        final unitCost = (material['unitCost'] ?? 0).toDouble();
        totalMaterialsCost += quantityUsed * unitCost;
      }

      // Procesar secciones
      List<Map<String, dynamic>> sectionsAnalysis = [];
      for (var section in sections) {
        final sectionId = section['id'];
        final sectionProgress = (section['progressPercentage'] ?? 0).toDouble();
        totalProgress += sectionProgress;

        final reports = sectionReports[sectionId] ?? [];
        totalReports += reports.length;

        // Contar imágenes y contratistas
        for (var report in reports) {
          final photos = report['photosBase64'] as List?;
          if (photos != null) totalImages += photos.length;

          final contractor = report['contractorName'] ?? 'Desconocido';
          allContractors.add(contractor);
        }

        sectionsAnalysis.add({
          'name': section['name'],
          'progress': sectionProgress,
          'reports': reports.length,
          'status': sectionProgress < 30 ? 'Inicial' :
                   sectionProgress < 70 ? 'En Progreso' :
                   sectionProgress < 100 ? 'Avanzado' : 'Completado',
        });
      }

      final avgProgress = sections.isNotEmpty ? totalProgress / sections.length : 0;

      // Calcular fechas y plazos
      final startDate = projectData['startDate'] != null
          ? (projectData['startDate'] as Timestamp).toDate()
          : DateTime.now();
      final endDate = projectData['endDate'] != null
          ? (projectData['endDate'] as Timestamp).toDate()
          : DateTime.now().add(Duration(days: 90));

      final totalDays = endDate.difference(startDate).inDays;
      final elapsedDays = DateTime.now().difference(startDate).inDays;
      final remainingDays = endDate.difference(DateTime.now()).inDays;
      final expectedProgress = totalDays > 0 ? (elapsedDays / totalDays * 100) : 0;
      final delayDays = avgProgress < expectedProgress
          ? ((expectedProgress - avgProgress) / 100 * totalDays).round()
          : 0;

      // Generar prompt para análisis con IA siguiendo formato de Informe Técnico Oficial
      final projectPrompt = '''
Como director general de proyectos de construcción civil, genera un INFORME TÉCNICO DE AVANCE DE OBRA COMPLETO DEL PROYECTO siguiendo el formato oficial de informes técnicos para entidades públicas:

═══════════════════════════════════════════════════════════════
📋 FICHA TÉCNICA DEL PROYECTO
═══════════════════════════════════════════════════════════════
**INFORMACIÓN CONTRACTUAL:**
- Proyecto: ${projectData['name']}
- Tipo de Obra: ${projectData['type'] ?? 'No especificado'}
- Descripción: ${projectData['description'] ?? 'Sin descripción'}
- Personal: ${projectData['workers'] ?? 'No especificado'}

**CRONOGRAMA:**
- Fecha de Inicio: ${startDate.toString().split(' ')[0]}
- Fecha Fin Prevista: ${endDate.toString().split(' ')[0]}
- Plazo Total: $totalDays días
- Días Transcurridos: $elapsedDays días
- Días Restantes: $remainingDays días

**PROGRESO GENERAL:**
- Progreso Promedio Actual: ${avgProgress.toStringAsFixed(1)}%
- Progreso Esperado según Cronograma: ${expectedProgress.toStringAsFixed(1)}%
- Estado: ${delayDays > 0 ? '⚠️ RETRASO ESTIMADO: $delayDays días' : '✅ DENTRO DEL CRONOGRAMA'}

═══════════════════════════════════════════════════════════════
🏗️ ANÁLISIS POR SECCIONES DEL PROYECTO (${sections.length} secciones)
═══════════════════════════════════════════════════════════════
${sectionsAnalysis.map((s) => '''
▸ Sección: ${s['name']}
  • Progreso Actual: ${s['progress']}%
  • Estado: ${s['status']}
  • Reportes Diarios: ${s['reports']}
''').join('\n')}

═══════════════════════════════════════════════════════════════
📦 SEGUIMIENTO DE MATERIALES
═══════════════════════════════════════════════════════════════
- Total de Materiales Registrados: $totalMaterialsCount
- Inversión Total en Materiales: \$${totalMaterialsCost.toStringAsFixed(2)}

**Detalle de Principales Materiales:**
${allMaterials.take(20).map((m) {
  final name = m['name'] ?? 'Sin nombre';
  final used = (m['quantityUsed'] ?? 0).toDouble();
  final planned = (m['quantityPlanned'] ?? 0).toDouble();
  final unit = m['unit'] ?? 'unidades';
  final cost = used * (m['unitCost'] ?? 0).toDouble();
  final status = m['status'] ?? 'Pendiente';
  final percent = planned > 0 ? (used / planned * 100) : 0;
  return '  • $name: $used/$planned $unit (${percent.toStringAsFixed(1)}%) - \$${cost.toStringAsFixed(2)} - Estado: $status';
}).join('\n')}
${allMaterials.length > 20 ? '\n  ... y ${allMaterials.length - 20} materiales adicionales' : ''}

═══════════════════════════════════════════════════════════════
👷 ASPECTOS ADMINISTRATIVOS
═══════════════════════════════════════════════════════════════
- Total de Reportes Diarios Generados: $totalReports
- Registro Fotográfico Total: $totalImages imágenes
- Contratistas Participantes: ${allContractors.join(', ')}
- Documentación y Control: Completo con análisis de IA

═══════════════════════════════════════════════════════════════

GENERA UN INFORME TÉCNICO DE AVANCE DE OBRA PROFESIONAL Y EXTENSO CON LA SIGUIENTE ESTRUCTURA:

**1. INTRODUCCIÓN**
   - Contexto del informe de avance del proyecto
   - Objetivo del informe técnico
   - Periodo de evaluación cubierto
   - Alcance del informe

**2. GENERALIDADES DEL PROYECTO**
   - Descripción general del proyecto y su importancia
   - Información contractual relevante
   - Plazo y valor del contrato
   - Personal técnico involucrado (director de obra, residentes, supervisión)
   - Estructura organizacional del proyecto

**3. DESCRIPCIÓN GENERAL DEL PROYECTO**
   - Localización geográfica y contexto
   - Características principales de la obra
   - Beneficiarios y alcance social
   - Componentes principales del proyecto

**4. AVANCE GENERAL DE ACTIVIDADES**
   - Progreso global del proyecto: ${avgProgress.toStringAsFixed(1)}%
   - Comparación con cronograma esperado: ${expectedProgress.toStringAsFixed(1)}%
   - Resumen de actividades ejecutadas en el periodo
   - Descripción narrativa del avance por cada sección principal

**5. ANÁLISIS DETALLADO POR SECCIONES**
   - Para cada una de las ${sections.length} secciones del proyecto:
     * Nombre y descripción de la sección
     * Progreso actual y avance en el periodo
     * Actividades específicas ejecutadas
     * Calidad observada
     * Observaciones técnicas
   - Identificar secciones críticas o rezagadas
   - Secciones que lideran el avance
   - Interdependencias entre secciones

**6. SEGUIMIENTO FINANCIERO**
   - Presupuesto total del proyecto
   - Inversión ejecutada en materiales: \$${totalMaterialsCost.toStringAsFixed(2)}
   - Relación avance físico vs avance financiero
   - Eficiencia presupuestal
   - Proyección de costos para completar el proyecto
   - Análisis de mayores y menores cantidades (si aplica)

**7. ANÁLISIS DE MATERIALES**
   - Detalle de materiales principales utilizados
   - Cantidades ejecutadas vs cantidades planificadas
   - Eficiencia en el uso de materiales
   - Materiales agotados, en uso o pendientes
   - Costo de materiales por sección
   - Proyección de necesidades futuras de materiales

**8. SEGUIMIENTO DE CRONOGRAMA**
   - Análisis del cronograma: ${delayDays > 0 ? '$delayDays días de retraso' : 'Dentro del plazo'}
   - Días planificados vs días ejecutados
   - Causas de retrasos o adelantos
   - Ritmo de avance actual
   - Proyección realista de fecha de finalización
   - Plan de recuperación de tiempos (si hay retrasos)

**9. ASPECTOS ADMINISTRATIVOS**
   - Personal presente en obra
   - Control de seguridad social y dotación
   - Cumplimiento de obligaciones laborales
   - Desempeño de contratistas: ${allContractors.join(', ')}
   - Frecuencia y calidad de reportes diarios ($totalReports reportes)
   - Documentación fotográfica ($totalImages imágenes analizadas con IA)

**10. METODOLOGÍA DE MEDICIÓN Y CUANTIFICACIÓN**
   - Proceso de medición de cantidades ejecutadas
   - Herramientas utilizadas (topografía, medición directa, fotogrametría)
   - Verificación con análisis de inteligencia artificial
   - Sistema de control y registro

**11. INTERVENTORÍA Y SUPERVISIÓN DEL CONTRATO**
   - Actividades de interventoría realizadas
   - Verificaciones técnicas y de calidad
   - Control de especificaciones
   - Revisión de procesos constructivos
   - Comunicación con contratistas y administración
   - Comités de obra realizados

**12. ASPECTOS AMBIENTALES, SOCIALES E IMPACTO**
   - Mitigación del impacto ambiental
   - Manejo de residuos y escombros
   - Plan de gestión social
   - Comunicación con la comunidad
   - Socialización con veedurías
   - Mitigación de impactos en el entorno

**13. CALIDAD Y CUMPLIMIENTO NORMATIVO**
   - Evaluación general de calidad de las obras
   - Cumplimiento de especificaciones técnicas
   - Cumplimiento de normas de construcción
   - Control de calidad de materiales
   - Áreas que requieren refuerzo de calidad
   - No conformidades detectadas y acciones correctivas

**14. RIESGOS Y PROBLEMAS IDENTIFICADOS**
   - Riesgos técnicos identificados
   - Problemas actuales en ejecución
   - Riesgos de cronograma
   - Riesgos presupuestales
   - Medidas de mitigación implementadas
   - Plan de contingencia

**15. PLAN DE ACCIÓN Y RECOMENDACIONES**
   - Prioridades inmediatas para el siguiente periodo
   - Acciones correctivas necesarias
   - Estrategias para recuperar retrasos
   - Optimizaciones sugeridas
   - Refuerzos de personal o equipo requeridos
   - Mejoras en procesos constructivos

**16. PROYECCIONES Y CONCLUSIONES**
   - Resumen ejecutivo del estado global del proyecto
   - Principales logros alcanzados
   - Fecha estimada real de finalización
   - Presupuesto final proyectado
   - Viabilidad de cumplir objetivos contractuales
   - Nivel de confianza en las proyecciones
   - Dictamen técnico profesional final
   - Recomendaciones a la administración

**17. ANEXOS (Mencionar que se adjuntan)**
   - Registro fotográfico del periodo
   - Planillas de seguridad social
   - Informe SISO
   - Informe ambiental
   - Control de equipo y maquinaria

FORMATO: Profesional, técnico, estilo informe oficial de ingeniería civil para entidades públicas y contratación estatal.
LONGITUD: Extenso y completo, con todos los detalles técnicos y análisis necesarios para un informe oficial.
TONO: Formal, técnico, objetivo, basado en datos y evidencia.
ESTRUCTURA: Seguir el formato de informes técnicos de avance de obra para contratos públicos.
''';

      print('📤 Enviando prompt a Gemini (${projectPrompt.length} caracteres)...');
      final response = await _model.generateContent([Content.text(projectPrompt)]);
      print('✅ Respuesta recibida de Gemini');

      return {
        'projectName': projectData['name'],
        'projectType': projectData['type'],
        'totalSections': sections.length,
        'averageProgress': avgProgress,
        'expectedProgress': expectedProgress,
        'delayDays': delayDays,
        'totalReports': totalReports,
        'totalImages': totalImages,
        'contractors': allContractors.toList(),
        'totalMaterials': totalMaterialsCount,
        'materialsCost': totalMaterialsCost,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'elapsedDays': elapsedDays,
        'remainingDays': remainingDays,
        'sectionsAnalysis': sectionsAnalysis,
        'executiveSummary': response.text ?? 'No se pudo generar el resumen',
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      print('❌ Error generando reporte completo: $e');
      print('Stack trace: $stackTrace');

      // Calcular estadísticas básicas incluso si falla la IA
      double totalProgress = 0;
      for (var section in sections) {
        totalProgress += (section['progressPercentage'] ?? 0).toDouble();
      }
      final avgProgress = sections.isNotEmpty ? totalProgress / sections.length : 0;

      double totalMaterialsCost = 0;
      for (var material in allMaterials) {
        final quantityUsed = (material['quantityUsed'] ?? 0).toDouble();
        final unitCost = (material['unitCost'] ?? 0).toDouble();
        totalMaterialsCost += quantityUsed * unitCost;
      }

      return {
        'error': 'Error al generar análisis con IA: $e',
        'projectName': projectData['name'] ?? 'Proyecto',
        'projectType': projectData['type'] ?? 'No especificado',
        'totalSections': sections.length,
        'averageProgress': avgProgress,
        'expectedProgress': 0.0,
        'delayDays': 0,
        'totalReports': 0,
        'totalImages': 0,
        'contractors': [],
        'totalMaterials': allMaterials.length,
        'materialsCost': totalMaterialsCost,
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().toIso8601String(),
        'elapsedDays': 0,
        'remainingDays': 0,
        'sectionsAnalysis': [],
        'executiveSummary': 'Error al generar el resumen ejecutivo. Por favor, intente de nuevo.',
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }
}
