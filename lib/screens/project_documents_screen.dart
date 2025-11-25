import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/project_document.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  ProjectDocumentsScreen({
    required this.projectId,
    required this.projectName,
  });

  @override
  _ProjectDocumentsScreenState createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? _selectedDocumentType;

  final Map<String, IconData> documentTypeIcons = {
    'plano': Icons.architecture,
    'licencia': Icons.verified_user,
    'contrato': Icons.description,
    'presupuesto': Icons.attach_money,
    'otro': Icons.insert_drive_file,
  };

  final Map<String, Color> documentTypeColors = {
    'plano': Colors.blue,
    'licencia': Colors.green,
    'contrato': Colors.orange,
    'presupuesto': Colors.purple,
    'otro': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentación - ${widget.projectName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddDocumentDialog,
            tooltip: 'Agregar documento',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDocumentTypeFilter(),
          Expanded(child: _buildDocumentsList()),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', null),
            SizedBox(width: 8),
            _buildFilterChip('Planos', 'plano'),
            SizedBox(width: 8),
            _buildFilterChip('Licencias', 'licencia'),
            SizedBox(width: 8),
            _buildFilterChip('Contratos', 'contrato'),
            SizedBox(width: 8),
            _buildFilterChip('Presupuestos', 'presupuesto'),
            SizedBox(width: 8),
            _buildFilterChip('Otros', 'otro'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = _selectedDocumentType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDocumentType = selected ? type : null;
        });
      },
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildDocumentsList() {
    Query query = FirebaseFirestore.instance
        .collection('projectDocuments')
        .where('projectId', isEqualTo: widget.projectId);

    if (_selectedDocumentType != null) {
      query = query.where('type', isEqualTo: _selectedDocumentType);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay documentos registrados',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Presiona + para agregar uno',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final document = ProjectDocument.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
            return _buildDocumentCard(document);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(ProjectDocument document) {
    final icon = documentTypeIcons[document.type] ?? Icons.insert_drive_file;
    final color = documentTypeColors[document.type] ?? Colors.grey;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(document.uploadedAt);
    final fileSizeKB = (document.fileSize / 1024).toStringAsFixed(2);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDocumentDetails(document),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (document.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        document.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          document.uploadedByName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${document.fileExtension.toUpperCase()} • $fileSizeKB KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Ver documento'),
                      ],
                    ),
                    value: 'view',
                  ),
                  if (document.uploadedBy == user?.uid)
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                      value: 'delete',
                    ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    _showDocumentDetails(document);
                  } else if (value == 'delete') {
                    _confirmDeleteDocument(document);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentDetails(ProjectDocument document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: documentTypeColors[document.type] ?? Colors.grey,
                child: Row(
                  children: [
                    Icon(
                      documentTypeIcons[document.type] ?? Icons.insert_drive_file,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        document.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (document.description.isNotEmpty) ...[
                        Text(
                          'Descripción:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(document.description),
                        SizedBox(height: 16),
                      ],
                      Text(
                        'Tipo: ${_getDocumentTypeName(document.type)}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Subido por: ${document.uploadedByName}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(document.uploadedAt)}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tamaño: ${(document.fileSize / 1024).toStringAsFixed(2)} KB',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 24),
                      if (_isImageFile(document.fileExtension)) ...[
                        Text(
                          'Vista previa:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(document.documentBase64),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  documentTypeIcons[document.type] ?? Icons.insert_drive_file,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Archivo ${document.fileExtension.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Vista previa no disponible',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(extension.toLowerCase());
  }

  String _getDocumentTypeName(String type) {
    const typeNames = {
      'plano': 'Plano',
      'licencia': 'Licencia',
      'contrato': 'Contrato',
      'presupuesto': 'Presupuesto',
      'otro': 'Otro',
    };
    return typeNames[type] ?? 'Otro';
  }

  void _confirmDeleteDocument(ProjectDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el documento "${document.name}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDocument(document.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projectDocuments')
          .doc(documentId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento eliminado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar documento: $e')),
      );
    }
  }

  void _showAddDocumentDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'plano';
    File? selectedFile;
    String? fileName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Agregar Documento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de documento',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'plano', child: Text('Plano')),
                    DropdownMenuItem(value: 'licencia', child: Text('Licencia')),
                    DropdownMenuItem(value: 'contrato', child: Text('Contrato')),
                    DropdownMenuItem(value: 'presupuesto', child: Text('Presupuesto')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del documento',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        selectedFile = File(image.path);
                        fileName = image.name;
                      });
                    }
                  },
                  icon: Icon(Icons.attach_file),
                  label: Text('Seleccionar archivo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 45),
                  ),
                ),
                if (fileName != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName!,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor ingresa un nombre')),
                  );
                  return;
                }
                
                if (selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor selecciona un archivo')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _uploadDocument(
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                  selectedType,
                  selectedFile!,
                );
              },
              child: Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(
    String name,
    String description,
    String type,
    File file,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Leer archivo y convertir a base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileSize = bytes.length;

      // Limitar tamaño (5MB)
      if (fileSize > 5 * 1024 * 1024) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El archivo es demasiado grande (máximo 5MB)')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('projectDocuments').add({
        'projectId': widget.projectId,
        'name': name,
        'description': description,
        'type': type,
        'documentBase64': base64String,
        'fileExtension': fileExtension,
        'uploadedBy': user!.uid,
        'uploadedByName': user!.displayName ?? user!.email ?? 'Usuario',
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSize': fileSize,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento agregado exitosamente')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar documento: $e')),
      );
    }
  }
}
