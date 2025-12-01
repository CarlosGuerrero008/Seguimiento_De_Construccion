import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> uploadDocument({
    required String projectId,
    required File file,
    required String fileName,
    required String uploadedBy,
    String source = 'manual',
    String? sectionId,
    String? description,
  }) async {
    final sanitizedName =
        fileName.replaceAll(RegExp(r'[^\w\.-]+'), '_');
    final storagePath =
        'projects/$projectId/documents/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    final metadata = {
      'projectId': projectId,
      'name': fileName,
      'path': storagePath,
      'url': downloadUrl,
      'size': await file.length(),
      'source': source,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
      'contentType': uploadTask.metadata?.contentType,
      if (sectionId != null) 'sectionId': sectionId,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    await _firestore.collection('projectDocuments').add(metadata);
    return metadata;
  }
}
