import 'package:flutter_test/flutter_test.dart';
import 'package:seguimiento_de_construcion/models/project.dart';
import 'package:seguimiento_de_construcion/models/material_item.dart';

void main() {
  group('Project Workflow Integration Tests', () {
    test('Complete project lifecycle should work correctly', () {
      // 1. Crear proyecto
      final project = Project(
        id: 'proj001',
        name: 'Edificio Residencial',
        description: 'Construcción de edificio de 5 pisos',
        type: 'Privada',
        adminId: 'admin001',
        workers: 20,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 180)),
        createdAt: DateTime.now(),
        location: 'Lima, Perú',
        client: 'Cliente ABC',
        budget: 500000.0,
        status: 'En curso',
      );

      // Verificar proyecto creado
      expect(project.id, 'proj001');
      expect(project.name, 'Edificio Residencial');
      expect(project.status, 'En curso');
      expect(project.durationInDays, 180);

      // 2. Agregar materiales al proyecto
      final materials = [
        MaterialItem(
          id: 'mat001',
          projectId: project.id,
          name: 'Cemento',
          unit: 'bolsas',
          quantityPlanned: 500.0,
          quantityUsed: 100.0,
          unitCost: 25.0,
          createdAt: DateTime.now(),
        ),
        MaterialItem(
          id: 'mat002',
          projectId: project.id,
          name: 'Acero',
          unit: 'toneladas',
          quantityPlanned: 10.0,
          quantityUsed: 2.0,
          unitCost: 800.0,
          createdAt: DateTime.now(),
        ),
      ];

      // Verificar materiales
      expect(materials.length, 2);
      expect(materials[0].projectId, project.id);
      expect(materials[1].projectId, project.id);

      // 3. Calcular costos totales
      double totalPlannedCost = materials.fold(
        0,
        (sum, item) => sum + item.totalPlannedCost,
      );
      double totalUsedCost = materials.fold(
        0,
        (sum, item) => sum + item.totalUsedCost,
      );

      expect(totalPlannedCost, 20500.0); // 500*25 + 10*800
      expect(totalUsedCost, 4100.0); // 100*25 + 2*800

      // 4. Verificar progreso de materiales
      final cementUsage = materials[0].usagePercentage;
      final steelUsage = materials[1].usagePercentage;

      expect(cementUsage, 20.0);
      expect(steelUsage, 20.0);

      // 5. Verificar cantidad restante
      expect(materials[0].quantityRemaining, 400.0);
      expect(materials[1].quantityRemaining, 8.0);
    });

    test('Project delay detection should work correctly', () {
      final now = DateTime.now();
      final project = Project(
        id: 'proj002',
        name: 'Proyecto Retrasado',
        description: 'Test',
        type: 'Pública',
        adminId: 'admin001',
        workers: 15,
        startDate: now.subtract(Duration(days: 50)),
        endDate: now.add(Duration(days: 50)),
        createdAt: now,
      );

      // Tiempo esperado: 50%
      expect(project.timeProgress, closeTo(50.0, 1.0));

      // Progreso real menor: 30% - PROYECTO RETRASADO
      expect(project.isDelayed(30.0), true);

      // Progreso real mayor: 60% - PROYECTO ADELANTADO
      expect(project.isDelayed(60.0), false);
    });

    test('Material overuse should be detected', () {
      final material = MaterialItem(
        id: 'mat003',
        projectId: 'proj001',
        name: 'Arena',
        unit: 'm³',
        quantityPlanned: 50.0,
        quantityUsed: 75.0, // ¡Se usó más de lo planificado!
        unitCost: 80.0,
        createdAt: DateTime.now(),
      );

      expect(material.usagePercentage, 150.0);
      expect(material.quantityRemaining, 0.0);
      expect(material.totalUsedCost, greaterThan(material.totalPlannedCost));
    });

    test('Project budget tracking should work', () {
      final project = Project(
        id: 'proj003',
        name: 'Control de Presupuesto',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin001',
        workers: 10,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 90)),
        createdAt: DateTime.now(),
        budget: 100000.0,
      );

      final materials = [
        MaterialItem(
          id: 'mat004',
          projectId: project.id,
          name: 'Material 1',
          unit: 'unidades',
          quantityPlanned: 100.0,
          quantityUsed: 100.0,
          unitCost: 500.0,
          createdAt: DateTime.now(),
        ),
        MaterialItem(
          id: 'mat005',
          projectId: project.id,
          name: 'Material 2',
          unit: 'unidades',
          quantityPlanned: 50.0,
          quantityUsed: 50.0,
          unitCost: 300.0,
          createdAt: DateTime.now(),
        ),
      ];

      double totalSpent = materials.fold(
        0,
        (sum, item) => sum + item.totalUsedCost,
      );

      expect(totalSpent, 65000.0);
      expect(totalSpent, lessThan(project.budget!));
      
      double budgetRemaining = project.budget! - totalSpent;
      expect(budgetRemaining, 35000.0);
    });

    test('Project completion should be trackable', () {
      final project = Project(
        id: 'proj004',
        name: 'Proyecto Completado',
        description: 'Test',
        type: 'Privada',
        adminId: 'admin001',
        workers: 10,
        startDate: DateTime.now().subtract(Duration(days: 100)),
        endDate: DateTime.now().subtract(Duration(days: 10)),
        createdAt: DateTime.now(),
        status: 'Completado',
      );

      expect(project.status, 'Completado');
      expect(project.remainingDays, 0);
      expect(project.timeProgress, 100.0);
    });
  });
}
