import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date Utilities Tests', () {
    test('DateTime difference should calculate days correctly', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final difference = endDate.difference(startDate).inDays;
      expect(difference, 30);
    });

    test('DateTime comparison should work correctly', () {
      final date1 = DateTime(2024, 1, 1);
      final date2 = DateTime(2024, 1, 15);
      final date3 = DateTime(2024, 1, 31);

      expect(date1.isBefore(date2), true);
      expect(date2.isAfter(date1), true);
      expect(date3.isAfter(date2), true);
      expect(date1.isBefore(date3), true);
    });

    test('DateTime should handle future dates', () {
      final now = DateTime.now();
      final future = now.add(Duration(days: 30));

      expect(future.isAfter(now), true);
      expect(now.isBefore(future), true);
    });

    test('DateTime should handle past dates', () {
      final now = DateTime.now();
      final past = now.subtract(Duration(days: 30));

      expect(past.isBefore(now), true);
      expect(now.isAfter(past), true);
    });

    test('Days calculation should handle same day', () {
      final date = DateTime(2024, 1, 15);
      final sameDate = DateTime(2024, 1, 15);

      expect(sameDate.difference(date).inDays, 0);
    });

    test('Progress calculation should be accurate', () {
      final total = 100;
      final completed = 75;
      final progress = (completed / total * 100);

      expect(progress, 75.0);
    });

    test('Progress should be clamped between 0 and 100', () {
      double clampProgress(double value) {
        return value.clamp(0.0, 100.0);
      }

      expect(clampProgress(-10), 0.0);
      expect(clampProgress(50), 50.0);
      expect(clampProgress(150), 100.0);
    });
  });
}
