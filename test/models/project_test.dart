import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seguimiento_de_construcion/models/project.dart';

void main() {
  group('Project Model Tests', () {
    test('Constructor should create a valid Project instance', () {
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'A test construction project',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        createdAt: DateTime.now(),
        location: 'Test Location',
        client: 'Test Client',
        budget: 100000.0,
        status: 'En curso',
      );

      expect(project.id, '123');
      expect(project.name, 'Test Project');
      expect(project.description, 'A test construction project');
      expect(project.type, 'Privada');
      expect(project.adminId, 'admin123');
      expect(project.workers, 10);
      expect(project.location, 'Test Location');
      expect(project.client, 'Test Client');
      expect(project.budget, 100000.0);
      expect(project.status, 'En curso');
    });

    test('durationInDays should calculate correct duration', () {
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        createdAt: DateTime.now(),
      );

      expect(project.durationInDays, 30);
    });

    test('elapsedDays should return 0 if project has not started', () {
      final futureDate = DateTime.now().add(Duration(days: 10));
      final project = Project(
        id: '123',
        name: 'Future Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: futureDate,
        endDate: futureDate.add(Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      expect(project.elapsedDays, 0);
    });

    test('remainingDays should return 0 if project has ended', () {
      final pastDate = DateTime.now().subtract(Duration(days: 30));
      final project = Project(
        id: '123',
        name: 'Past Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: pastDate.subtract(Duration(days: 30)),
        endDate: pastDate,
        createdAt: DateTime.now(),
      );

      expect(project.remainingDays, 0);
    });

    test('timeProgress should calculate correct progress percentage', () {
      final now = DateTime.now();
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: now.subtract(Duration(days: 50)),
        endDate: now.add(Duration(days: 50)),
        createdAt: DateTime.now(),
      );

      expect(project.timeProgress, closeTo(50.0, 1.0));
    });

    test('timeProgress should not exceed 100%', () {
      final now = DateTime.now();
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: now.subtract(Duration(days: 200)),
        endDate: now.subtract(Duration(days: 50)),
        createdAt: DateTime.now(),
      );

      expect(project.timeProgress, 100.0);
    });

    test('isDelayed should return true when actual progress is less than time progress', () {
      final now = DateTime.now();
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: now.subtract(Duration(days: 50)),
        endDate: now.add(Duration(days: 50)),
        createdAt: DateTime.now(),
      );

      expect(project.isDelayed(30.0), true);
      expect(project.isDelayed(60.0), false);
    });

    test('toMap should convert Project to Map correctly', () {
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'A test project',
        type: 'Pública',
        adminId: 'admin123',
        workers: 15,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        createdAt: DateTime(2024, 1, 1),
        location: 'Test Location',
        client: 'Test Client',
        budget: 200000.0,
        status: 'Completado',
      );

      final map = project.toMap();

      expect(map['name'], 'Test Project');
      expect(map['description'], 'A test project');
      expect(map['type'], 'Pública');
      expect(map['adminId'], 'admin123');
      expect(map['workers'], 15);
      expect(map['location'], 'Test Location');
      expect(map['client'], 'Test Client');
      expect(map['budget'], 200000.0);
      expect(map['status'], 'Completado');
      expect(map['startDate'], isA<Timestamp>());
      expect(map['endDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('Default status should be "En curso"', () {
      final project = Project(
        id: '123',
        name: 'Test Project',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin123',
        workers: 10,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        createdAt: DateTime.now(),
      );

      expect(project.status, 'En curso');
    });
  });
}
