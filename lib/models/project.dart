import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final String type; // Privada, Pública, Mixta
  final String adminId;
  final int workers;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String? location;
  final String? client;
  final double? budget;
  final String status; // En curso, Pausado, Completado, Cancelado

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.adminId,
    required this.workers,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.location,
    this.client,
    this.budget,
    this.status = 'En curso',
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'Privada',
      adminId: data['adminId'] ?? '',
      workers: data['workers'] is String
          ? int.tryParse(data['workers']) ?? 0
          : (data['workers'] ?? 0),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'],
      client: data['client'],
      budget: data['budget']?.toDouble(),
      status: data['status'] ?? 'En curso',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'adminId': adminId,
      'workers': workers,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'client': client,
      'budget': budget,
      'status': status,
    };
  }

  // Calcular duración del proyecto en días
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }

  // Calcular días transcurridos
  int get elapsedDays {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return durationInDays;
    return now.difference(startDate).inDays;
  }

  // Calcular días restantes
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // Progreso temporal del proyecto (basado en fechas)
  double get timeProgress {
    if (durationInDays == 0) return 0;
    return (elapsedDays / durationInDays * 100).clamp(0, 100);
  }

  // Verificar si el proyecto está retrasado
  bool isDelayed(double actualProgress) {
    return actualProgress < timeProgress;
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? adminId,
    int? workers,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    String? location,
    String? client,
    double? budget,
    String? status,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      adminId: adminId ?? this.adminId,
      workers: workers ?? this.workers,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      client: client ?? this.client,
      budget: budget ?? this.budget,
      status: status ?? this.status,
    );
  }
}
