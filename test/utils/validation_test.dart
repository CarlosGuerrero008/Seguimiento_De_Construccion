import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validation Tests', () {
    group('Email Validation', () {
      bool isValidEmail(String email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return emailRegex.hasMatch(email);
      }

      test('Valid email addresses should pass', () {
        expect(isValidEmail('test@example.com'), true);
        expect(isValidEmail('user.name@domain.co'), true);
        expect(isValidEmail('user_name@domain.com'), true);
        expect(isValidEmail('user-name@domain.com'), true);
      });

      test('Invalid email addresses should fail', () {
        expect(isValidEmail(''), false);
        expect(isValidEmail('invalid'), false);
        expect(isValidEmail('invalid@'), false);
        expect(isValidEmail('@domain.com'), false);
        expect(isValidEmail('invalid@domain'), false);
        expect(isValidEmail('invalid domain@test.com'), false);
      });
    });

    group('Password Validation', () {
      bool isValidPassword(String password) {
        // Mínimo 8 caracteres
        return password.length >= 8;
      }

      test('Valid passwords should pass', () {
        expect(isValidPassword('12345678'), true);
        expect(isValidPassword('Password123'), true);
        expect(isValidPassword('VeryLongPassword123!'), true);
      });

      test('Invalid passwords should fail', () {
        expect(isValidPassword(''), false);
        expect(isValidPassword('123'), false);
        expect(isValidPassword('short'), false);
        expect(isValidPassword('1234567'), false);
      });
    });

    group('Phone Number Validation', () {
      bool isValidPhone(String phone) {
        final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
        return phoneRegex.hasMatch(phone);
      }

      test('Valid phone numbers should pass', () {
        expect(isValidPhone('1234567890'), true);
        expect(isValidPhone('+1234567890'), true);
        expect(isValidPhone('123-456-7890'), true);
        expect(isValidPhone('(123) 456-7890'), true);
      });

      test('Invalid phone numbers should fail', () {
        expect(isValidPhone(''), false);
        expect(isValidPhone('123'), false);
        expect(isValidPhone('abc'), false);
      });
    });

    group('Number Validation', () {
      bool isPositiveNumber(String value) {
        final number = double.tryParse(value);
        return number != null && number > 0;
      }

      test('Positive numbers should pass', () {
        expect(isPositiveNumber('1'), true);
        expect(isPositiveNumber('100'), true);
        expect(isPositiveNumber('1.5'), true);
        expect(isPositiveNumber('999.99'), true);
      });

      test('Non-positive numbers should fail', () {
        expect(isPositiveNumber('0'), false);
        expect(isPositiveNumber('-1'), false);
        expect(isPositiveNumber('-100'), false);
        expect(isPositiveNumber('abc'), false);
        expect(isPositiveNumber(''), false);
      });
    });

    group('String Validation', () {
      bool isNotEmpty(String? value) {
        return value != null && value.trim().isNotEmpty;
      }

      test('Non-empty strings should pass', () {
        expect(isNotEmpty('text'), true);
        expect(isNotEmpty('Hello World'), true);
        expect(isNotEmpty('123'), true);
      });

      test('Empty strings should fail', () {
        expect(isNotEmpty(null), false);
        expect(isNotEmpty(''), false);
        expect(isNotEmpty('   '), false);
        expect(isNotEmpty('\t\n'), false);
      });
    });

    group('Date Validation', () {
      bool isValidDateRange(DateTime start, DateTime end) {
        return end.isAfter(start);
      }

      test('Valid date ranges should pass', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 12, 31);
        expect(isValidDateRange(start, end), true);
      });

      test('Invalid date ranges should fail', () {
        final start = DateTime(2024, 12, 31);
        final end = DateTime(2024, 1, 1);
        expect(isValidDateRange(start, end), false);
      });

      test('Same date should fail', () {
        final date = DateTime(2024, 1, 1);
        expect(isValidDateRange(date, date), false);
      });
    });

    group('Percentage Validation', () {
      bool isValidPercentage(double value) {
        return value >= 0 && value <= 100;
      }

      test('Valid percentages should pass', () {
        expect(isValidPercentage(0), true);
        expect(isValidPercentage(50), true);
        expect(isValidPercentage(100), true);
        expect(isValidPercentage(75.5), true);
      });

      test('Invalid percentages should fail', () {
        expect(isValidPercentage(-1), false);
        expect(isValidPercentage(-10), false);
        expect(isValidPercentage(101), false);
        expect(isValidPercentage(150), false);
      });
    });
  });
}
