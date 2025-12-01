import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/document_service.dart';

class ProjectDocumentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDocumentsScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  State<ProjectDocumentsScreen> createState() =>
      _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Documentación'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        icon: _isUploading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Subiendo...' : 'Subir documento'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(isDark),
            SizedBox(height: 16),
            Expanded(child: _buildDocumentsList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.folder_open, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentación del proyecto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sube planos, contratos, manuales o guarda aquí los PDFs generados por IA.',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('Proyecto: ${widget.projectName}'),
                        backgroundColor:
                            isDark ? Colors.blueGrey[800] : Colors.blue[50],
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text('Acepta PDF, DOCX, imágenes'),
                        backgroundColor:
                            isDark ? Colors.blueGrey[800] : Colors.blue[50],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectDocuments')
          .where('projectId', isEqualTo: widget.projectId)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Aún no hay documentos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Usa el botón \"Subir documento\" para agregar archivos existentes\n'
                  'o guarda aquí los PDFs generados por IA.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final source = (data['source'] ?? 'manual').toString();
            final uploadedAt = (data['uploadedAt'] as Timestamp?)
                ?.toDate();

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: source == 'ia'
                      ? Colors.purple.withOpacity(0.15)
                      : Colors.blue.withOpacity(0.15),
                  child: Icon(
                    source == 'ia' ? Icons.auto_awesome : Icons.description,
                    color: source == 'ia' ? Colors.purple : Colors.blue,
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Documento',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      [
                        if (source == 'ia') 'Generado por IA' else 'Subido manual',
                        if (data['size'] != null)
                          _formatBytes((data['size'] as num).toInt()),
                        if (uploadedAt != null)
                          'Fecha: ${uploadedAt.day.toString().padLeft(2, '0')}/${uploadedAt.month.toString().padLeft(2, '0')}/${uploadedAt.year}',
                      ].join(' • '),
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    if (data['description'] != null &&
                        (data['description'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          data['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Copiar enlace',
                      icon: Icon(Icons.link),
                      onPressed: () =>
                          _copyLink(data['url']?.toString() ?? ''),
                    ),
                    IconButton(
                      tooltip: 'Compartir',
                      icon: Icon(Icons.share),
                      onPressed: () {
                        final url = data['url']?.toString();
                        if (url != null && url.isNotEmpty) {
                          Share.share(
                            'Documento del proyecto ${widget.projectName}: $url',
                            subject: data['name'] ?? 'Documento del proyecto',
                          );
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _copyLink(data['url']?.toString() ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      if (picked.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo leer el archivo seleccionado.')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debes iniciar sesión para subir archivos.')),
        );
        return;
      }

      setState(() => _isUploading = true);
      await _documentService.uploadDocument(
        projectId: widget.projectId,
        file: File(picked.path!),
        fileName: picked.name,
        uploadedBy: user.uid,
        source: 'manual',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento agregado a la documentación.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir documento: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final rawIndex = (math.log(bytes) / math.log(1024)).floor();
    final clampedIndex = rawIndex.clamp(0, suffixes.length - 1);
    final size = bytes / math.pow(1024, clampedIndex);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedIndex.toInt()]}';
  }

  Future<void> _copyLink(String url) async {
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }
}
