import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:seguimiento_de_construcion/providers/theme_provider.dart';

void main() {
  group('AppColors Tests', () {
    test('Primary color values should be correct', () {
      expect(AppColors.primary50, const Color(0xFFE5E5FF));
      expect(AppColors.primary100, const Color(0xFFCCCCFF));
      expect(AppColors.primary200, const Color(0xFF9999FF));
      expect(AppColors.primary300, const Color(0xFF6666FF));
      expect(AppColors.primary400, const Color(0xFF3333FF));
      expect(AppColors.primary500, const Color(0xFF0000FF));
      expect(AppColors.primary600, const Color(0xFF0000CC));
      expect(AppColors.primary700, const Color(0xFF000099));
      expect(AppColors.primary800, const Color(0xFF000066));
      expect(AppColors.primary900, const Color(0xFF000033));
    });

    test('Primary swatch should contain all shades', () {
      expect(AppColors.primarySwatch[50], AppColors.primary50);
      expect(AppColors.primarySwatch[100], AppColors.primary100);
      expect(AppColors.primarySwatch[200], AppColors.primary200);
      expect(AppColors.primarySwatch[300], AppColors.primary300);
      expect(AppColors.primarySwatch[400], AppColors.primary400);
      expect(AppColors.primarySwatch[500], AppColors.primary500);
      expect(AppColors.primarySwatch[600], AppColors.primary600);
      expect(AppColors.primarySwatch[700], AppColors.primary700);
      expect(AppColors.primarySwatch[800], AppColors.primary800);
      expect(AppColors.primarySwatch[900], AppColors.primary900);
    });

    test('Primary swatch value should be primary500', () {
      expect(AppColors.primarySwatch.value, 0xFF0000FF);
    });
  });

  group('ThemeProvider Tests', () {
    test('Theme should use Material 3', () {
      final theme = ThemeProvider.theme;
      expect(theme.useMaterial3, true);
    });

    test('Theme brightness should be light', () {
      final theme = ThemeProvider.theme;
      expect(theme.brightness, Brightness.light);
    });

    test('Theme should have correct primary color', () {
      final theme = ThemeProvider.theme;
      expect(theme.colorScheme.primary, AppColors.primary500);
    });

    test('Theme should have correct secondary color', () {
      final theme = ThemeProvider.theme;
      expect(theme.colorScheme.secondary, AppColors.primary300);
    });

    test('Theme color scheme should be configured correctly', () {
      final theme = ThemeProvider.theme;
      final colorScheme = theme.colorScheme;

      expect(colorScheme.primary, AppColors.primary500);
      expect(colorScheme.secondary, AppColors.primary300);
      expect(colorScheme.primaryContainer, AppColors.primary100);
      expect(colorScheme.secondaryContainer, AppColors.primary200);
      expect(colorScheme.surface, Colors.white);
      expect(colorScheme.background, AppColors.primary50);
    });

    test('Theme should be non-null and valid', () {
      final theme = ThemeProvider.theme;
      expect(theme, isNotNull);
      expect(theme, isA<ThemeData>());
    });

    test('AppBar theme should inherit from color scheme', () {
      final theme = ThemeProvider.theme;
      expect(theme.appBarTheme, isNotNull);
    });

    test('Color scheme brightness should be light', () {
      final theme = ThemeProvider.theme;
      expect(theme.colorScheme.brightness, Brightness.light);
    });
  });
}
