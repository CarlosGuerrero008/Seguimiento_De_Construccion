import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectSection {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final double progressPercentage; // 0-100
  final DateTime createdAt;
  final DateTime? lastUpdated;
  
  ProjectSection({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    this.progressPercentage = 0.0,
    required this.createdAt,
    this.lastUpdated,
  });
  
  factory ProjectSection.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProjectSection(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'progressPercentage': progressPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }
  
  ProjectSection copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    double? progressPercentage,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ProjectSection(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
