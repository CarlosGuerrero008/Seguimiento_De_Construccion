import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SectionDetailsScreen extends StatefulWidget {
  final String sectionId;
  final Map<String, dynamic> sectionData;
  final String projectId;

  SectionDetailsScreen({
    required this.sectionId,
    required this.sectionData,
    required this.projectId,
  });

  @override
  _SectionDetailsScreenState createState() => _SectionDetailsScreenState();
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionData['name'] ?? 'Detalles de Sección'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _showDeleteSectionDialog(),
            tooltip: 'Eliminar sección',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            SizedBox(height: 16),
            _buildDailyReportsSection(),
            SizedBox(height: 80), // Espacio para el FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReportDialog,
        icon: Icon(Icons.add_photo_alternate),
        label: Text('Nuevo Reporte'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildProgressCard() {
    double progress = (widget.sectionData['progressPercentage'] ?? 0).toDouble();
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progreso Actual',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (widget.sectionData['description'] != null &&
                          widget.sectionData['description'].toString().isNotEmpty)
                        Text(
                          widget.sectionData['description'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 10.0,
                  percent: progress / 100,
                  center: Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  progressColor: progress < 30 ? Colors.red :
                               progress < 70 ? Colors.orange : Colors.green,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Reportes Diarios',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('dailyReports')
              .where('sectionId', isEqualTo: widget.sectionId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error al cargar reportes: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay reportes aún',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Presiona "Nuevo Reporte" para agregar uno',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Ordenar reportes manualmente por fecha (más reciente primero)
            final reports = snapshot.data!.docs;
            reports.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bTime = (bData['date'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime); // Descendente (más reciente primero)
            });
            
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final doc = reports[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return _buildReportCard(doc.id, data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> data) {
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    // Soportar tanto photoUrls (antiguo) como photosBase64 (nuevo)
    final photoUrls = List<String>.from(data['photoUrls'] ?? []);
    final photosBase64 = List<String>.from(data['photosBase64'] ?? []);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${data['progressAdded']}%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (data['contractorName'] != null)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Contratista: ${data['contractorName']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            SizedBox(height: 8),
            Text(
              data['description'] ?? 'Sin descripción',
              style: TextStyle(fontSize: 15),
            ),
            if (data['latitude'] != null && data['longitude'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Lat: ${data['latitude'].toStringAsFixed(6)}, Lon: ${data['longitude'].toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (photosBase64.isNotEmpty || photoUrls.isNotEmpty) ...[
              SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photosBase64.isNotEmpty ? photosBase64.length : photoUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => photosBase64.isNotEmpty 
                            ? _showImageDialogBase64(photosBase64[index])
                            : _showImageDialog(photoUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: photosBase64.isNotEmpty
                              ? Image.memory(
                                  base64Decode(photosBase64[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error),
                                    );
                                  },
                                )
                              : Image.network(
                                  photoUrls[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteReportDialog(reportId),
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Imagen'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialogBase64(String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Imagen'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            InteractiveViewer(
              child: Image.memory(
                base64Decode(base64String),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReportDialog() {
    final descriptionController = TextEditingController();
    final progressController = TextEditingController();
    List<File> selectedImages = [];
    Position? currentPosition;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Crear Reporte Diario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción del avance',
                    hintText: 'Describe el trabajo realizado',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: progressController,
                  decoration: InputDecoration(
                    labelText: 'Porcentaje de avance',
                    hintText: 'Ej: 5',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final ImagePicker picker = ImagePicker();
                            final List<XFile> images = await picker.pickMultiImage();
                            setState(() {
                              selectedImages = images.map((img) => File(img.path)).toList();
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al seleccionar imágenes: $e')),
                            );
                          }
                        },
                        icon: Icon(Icons.photo_library),
                        label: Text('Seleccionar fotos'),
                      ),
                    ),
                  ],
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('${selectedImages.length} foto(s) seleccionada(s)'),
                ],
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final position = await _getCurrentLocation();
                      setState(() {
                        currentPosition = position;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ubicación obtenida')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al obtener ubicación: $e')),
                      );
                    }
                  },
                  icon: Icon(Icons.location_on),
                  label: Text(
                    currentPosition != null 
                      ? 'Ubicación obtenida ✓' 
                      : 'Obtener ubicación GPS'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPosition != null ? Colors.green : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor agrega una descripción')),
                  );
                  return;
                }

                final progressValue = double.tryParse(progressController.text.trim());
                if (progressValue == null || progressValue < 0 || progressValue > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ingresa un porcentaje válido (0-100)')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createReport(
                  descriptionController.text.trim(),
                  progressValue,
                  selectedImages,
                  currentPosition,
                );
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están deshabilitados');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisos de ubicación denegados permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _createReport(
    String description,
    double progressAdded,
    List<File> images,
    Position? position,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Creando reporte...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Convertir imágenes a Base64 (comprimidas)
      List<String> photoBase64List = [];
      if (images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          try {
            // Comprimir la imagen antes de convertirla a Base64
            final compressedBytes = await FlutterImageCompress.compressWithFile(
              images[i].path,
              quality: 50, // Reducir calidad para ahorrar espacio
              minWidth: 800,
              minHeight: 800,
            );
            
            if (compressedBytes != null) {
              // Convertir a Base64
              final base64String = base64Encode(compressedBytes);
              photoBase64List.add(base64String);
            }
          } catch (e) {
            print('Error procesando imagen $i: $e');
            // Continuar con las demás imágenes
          }
        }
      }

      // Obtener nombre del usuario
      String contractorName = user?.displayName ?? user?.email ?? 'Usuario';

      // Crear reporte en Firestore con imágenes en Base64
      await FirebaseFirestore.instance.collection('dailyReports').add({
        'projectId': widget.projectId,
        'sectionId': widget.sectionId,
        'date': FieldValue.serverTimestamp(),
        'description': description,
        'photosBase64': photoBase64List, // Guardamos Base64 en lugar de URLs
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'contractorId': user!.uid,
        'contractorName': contractorName,
        'progressAdded': progressAdded,
      });

      // Actualizar el progreso de la sección
      final currentProgress = (widget.sectionData['progressPercentage'] ?? 0).toDouble();
      final newProgress = (currentProgress + progressAdded).clamp(0.0, 100.0);
      
      await FirebaseFirestore.instance
          .collection('projectSections')
          .doc(widget.sectionId)
          .update({
        'progressPercentage': newProgress,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Cerrar indicador de carga
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Actualizar la vista
      setState(() {
        widget.sectionData['progressPercentage'] = newProgress;
      });
    } catch (e) {
      // Cerrar indicador de carga si hay error
      Navigator.pop(context);
      
      print('Error completo al crear reporte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear reporte: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _showDeleteReportDialog(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Reporte'),
        content: Text('¿Estás seguro de que deseas eliminar este reporte? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteReport(reportId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('dailyReports').doc(reportId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar reporte: $e')),
      );
    }
  }

  void _showDeleteSectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Sección'),
        content: Text('¿Estás seguro de que deseas eliminar esta sección y todos sus reportes? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSection();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSection() async {
    try {
      // Eliminar todos los reportes de la sección
      final reports = await FirebaseFirestore.instance
          .collection('dailyReports')
          .where('sectionId', isEqualTo: widget.sectionId)
          .get();
      
      for (var doc in reports.docs) {
        await doc.reference.delete();
      }

      // Eliminar la sección
      await FirebaseFirestore.instance
          .collection('projectSections')
          .doc(widget.sectionId)
          .delete();

      Navigator.pop(context, true); // Regresar con resultado true
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sección eliminada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar sección: $e')),
      );
    }
  }
}
