import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDocument {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final String type; // 'plano', 'licencia', 'contrato', 'presupuesto', 'otro'
  final String documentBase64;
  final String fileExtension; // pdf, jpg, png, etc.
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final int fileSize; // en bytes

  ProjectDocument({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.type,
    required this.documentBase64,
    required this.fileExtension,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'type': type,
      'documentBase64': documentBase64,
      'fileExtension': fileExtension,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileSize': fileSize,
    };
  }

  factory ProjectDocument.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ProjectDocument(
      id: id,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'otro',
      documentBase64: data['documentBase64'] ?? '',
      fileExtension: data['fileExtension'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      fileSize: data['fileSize'] ?? 0,
    );
  }
}
