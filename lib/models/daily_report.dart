import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReport {
  final String id;
  final String projectId;
  final String sectionId;
  final DateTime date;
  final String description;
  final List<String> photoUrls; // URLs de Firebase Storage
  final double latitude;
  final double longitude;
  final String contractorId; // Usuario responsable
  final String contractorName; // Nombre del contratista
  final double progressAdded; // Porcentaje agregado ese día
  
  DailyReport({
    required this.id,
    required this.projectId,
    required this.sectionId,
    required this.date,
    required this.description,
    required this.photoUrls,
    required this.latitude,
    required this.longitude,
    required this.contractorId,
    required this.contractorName,
    required this.progressAdded,
  });
  
  factory DailyReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyReport(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      contractorId: data['contractorId'] ?? '',
      contractorName: data['contractorName'] ?? '',
      progressAdded: (data['progressAdded'] ?? 0.0).toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'sectionId': sectionId,
      'date': Timestamp.fromDate(date),
      'description': description,
      'photoUrls': photoUrls,
      'latitude': latitude,
      'longitude': longitude,
      'contractorId': contractorId,
      'contractorName': contractorName,
      'progressAdded': progressAdded,
    };
  }
  
  DailyReport copyWith({
    String? id,
    String? projectId,
    String? sectionId,
    DateTime? date,
    String? description,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    String? contractorId,
    String? contractorName,
    double? progressAdded,
  }) {
    return DailyReport(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      date: date ?? this.date,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contractorId: contractorId ?? this.contractorId,
      contractorName: contractorName ?? this.contractorName,
      progressAdded: progressAdded ?? this.progressAdded,
    );
  }
}
