import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seguimiento_de_construcion/models/material_item.dart';

void main() {
  group('MaterialItem Model Tests', () {
    test('Constructor should create a valid MaterialItem instance', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        sectionId: 'sec123',
        name: 'Cemento',
        description: 'Cemento Portland tipo I',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 50.0,
        unitCost: 25.5,
        supplier: 'Proveedor ABC',
        deliveryDate: DateTime(2024, 1, 15),
        status: 'Entregado',
        createdAt: DateTime.now(),
      );

      expect(material.id, 'mat123');
      expect(material.projectId, 'proj123');
      expect(material.sectionId, 'sec123');
      expect(material.name, 'Cemento');
      expect(material.description, 'Cemento Portland tipo I');
      expect(material.unit, 'bolsas');
      expect(material.quantityPlanned, 100.0);
      expect(material.quantityUsed, 50.0);
      expect(material.unitCost, 25.5);
      expect(material.supplier, 'Proveedor ABC');
      expect(material.status, 'Entregado');
    });

    test('quantityRemaining should calculate correct remaining quantity', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 35.0,
        createdAt: DateTime.now(),
      );

      expect(material.quantityRemaining, 65.0);
    });

    test('quantityRemaining should not be negative', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 150.0, // Used more than planned
        createdAt: DateTime.now(),
      );

      expect(material.quantityRemaining, 0.0);
    });

    test('usagePercentage should calculate correct percentage', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 75.0,
        createdAt: DateTime.now(),
      );

      expect(material.usagePercentage, 75.0);
    });

    test('usagePercentage should return 0 when quantityPlanned is 0', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 0.0,
        quantityUsed: 10.0,
        createdAt: DateTime.now(),
      );

      expect(material.usagePercentage, 0.0);
    });

    test('usagePercentage can exceed 100% when overused', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 150.0,
        createdAt: DateTime.now(),
      );

      expect(material.usagePercentage, 150.0);
    });

    test('totalPlannedCost should calculate correctly', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        unitCost: 25.5,
        createdAt: DateTime.now(),
      );

      expect(material.totalPlannedCost, 2550.0);
    });

    test('totalPlannedCost should return 0 when unitCost is null', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        createdAt: DateTime.now(),
      );

      expect(material.totalPlannedCost, 0.0);
    });

    test('totalUsedCost should calculate correctly', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 75.0,
        unitCost: 25.5,
        createdAt: DateTime.now(),
      );

      expect(material.totalUsedCost, 1912.5);
    });

    test('totalUsedCost should return 0 when unitCost is null', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 75.0,
        createdAt: DateTime.now(),
      );

      expect(material.totalUsedCost, 0.0);
    });

    test('Default status should be "Pendiente"', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        createdAt: DateTime.now(),
      );

      expect(material.status, 'Pendiente');
    });

    test('Default quantityUsed should be 0', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        createdAt: DateTime.now(),
      );

      expect(material.quantityUsed, 0.0);
    });

    test('toMap should convert MaterialItem to Map correctly', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        sectionId: 'sec123',
        name: 'Cemento',
        description: 'Cemento Portland',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        quantityUsed: 50.0,
        unitCost: 25.5,
        supplier: 'Proveedor ABC',
        deliveryDate: DateTime(2024, 1, 15),
        status: 'Entregado',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = material.toMap();

      expect(map['projectId'], 'proj123');
      expect(map['sectionId'], 'sec123');
      expect(map['name'], 'Cemento');
      expect(map['description'], 'Cemento Portland');
      expect(map['unit'], 'bolsas');
      expect(map['quantityPlanned'], 100.0);
      expect(map['quantityUsed'], 50.0);
      expect(map['unitCost'], 25.5);
      expect(map['supplier'], 'Proveedor ABC');
      expect(map['deliveryDate'], isA<Timestamp>());
      expect(map['status'], 'Entregado');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('sectionId can be null for general project materials', () {
      final material = MaterialItem(
        id: 'mat123',
        projectId: 'proj123',
        name: 'Cemento',
        unit: 'bolsas',
        quantityPlanned: 100.0,
        createdAt: DateTime.now(),
      );

      expect(material.sectionId, isNull);
    });
  });
}