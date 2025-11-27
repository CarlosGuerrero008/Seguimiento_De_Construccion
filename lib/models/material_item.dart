import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialItem {
  final String id;
  final String projectId;
  final String? sectionId; // Opcional: null = material general del proyecto
  final String name;
  final String? description;
  final String unit; // m³, m², kg, unidades, etc.
  final double quantityPlanned;
  final double quantityUsed;
  final double? unitCost;
  final String? supplier;
  final DateTime? deliveryDate;
  final String status; // Pendiente, En tránsito, Entregado, Agotado
  final DateTime createdAt;

  MaterialItem({
    required this.id,
    required this.projectId,
    this.sectionId,
    required this.name,
    this.description,
    required this.unit,
    required this.quantityPlanned,
    this.quantityUsed = 0,
    this.unitCost,
    this.supplier,
    this.deliveryDate,
    this.status = 'Pendiente',
    required this.createdAt,
  });

  factory MaterialItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MaterialItem(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      sectionId: data['sectionId'],
      name: data['name'] ?? '',
      description: data['description'],
      unit: data['unit'] ?? 'unidades',
      quantityPlanned: (data['quantityPlanned'] ?? 0).toDouble(),
      quantityUsed: (data['quantityUsed'] ?? 0).toDouble(),
      unitCost: data['unitCost']?.toDouble(),
      supplier: data['supplier'],
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'Pendiente',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'sectionId': sectionId,
      'name': name,
      'description': description,
      'unit': unit,
      'quantityPlanned': quantityPlanned,
      'quantityUsed': quantityUsed,
      'unitCost': unitCost,
      'supplier': supplier,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Cantidad restante
  double get quantityRemaining {
    return (quantityPlanned - quantityUsed).clamp(0, double.infinity);
  }

  // Porcentaje utilizado (puede ser > 100% si se usa más de lo planificado)
  double get usagePercentage {
    if (quantityPlanned == 0) return 0;
    return ((quantityUsed / quantityPlanned) * 100);
  }

  // Costo total planificado
  double get totalPlannedCost {
    if (unitCost == null) return 0;
    return quantityPlanned * unitCost!;
  }

  // Costo total usado
  double get totalUsedCost {
    if (unitCost == null) return 0;
    return quantityUsed * unitCost!;
  }

  MaterialItem copyWith({
    String? id,
    String? projectId,
    String? sectionId,
    String? name,
    String? description,
    String? unit,
    double? quantityPlanned,
    double? quantityUsed,
    double? unitCost,
    String? supplier,
    DateTime? deliveryDate,
    String? status,
    DateTime? createdAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantityPlanned: quantityPlanned ?? this.quantityPlanned,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
