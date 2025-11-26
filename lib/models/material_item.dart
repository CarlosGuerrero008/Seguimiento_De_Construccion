import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialItem {
  final String id;
  final String sectionId;
  final String name;
  final String unit; // unidad: m3, kg, unidades, etc.
  final double quantityNeeded;
  final double quantityAvailable;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  MaterialItem({
    required this.id,
    required this.sectionId,
    required this.name,
    required this.unit,
    required this.quantityNeeded,
    required this.quantityAvailable,
    this.notes,
    required this.createdAt,
    this.lastUpdated,
  });

  bool get isAvailable => quantityAvailable >= quantityNeeded;
  
  double get availabilityPercentage => 
      quantityNeeded > 0 ? (quantityAvailable / quantityNeeded * 100).clamp(0.0, 100.0) : 100.0;

  Map<String, dynamic> toMap() {
    return {
      'sectionId': sectionId,
      'name': name,
      'unit': unit,
      'quantityNeeded': quantityNeeded,
      'quantityAvailable': quantityAvailable,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory MaterialItem.fromFirestore(String id, Map<String, dynamic> data) {
    return MaterialItem(
      id: id,
      sectionId: data['sectionId'] ?? '',
      name: data['name'] ?? '',
      unit: data['unit'] ?? 'unidades',
      quantityNeeded: (data['quantityNeeded'] ?? 0).toDouble(),
      quantityAvailable: (data['quantityAvailable'] ?? 0).toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate() 
          : null,
    );
  }
}
