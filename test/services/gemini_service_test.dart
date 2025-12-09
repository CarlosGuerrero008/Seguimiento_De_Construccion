import 'package:flutter_test/flutter_test.dart';
import 'package:seguimiento_de_construcion/services/gemini_service.dart';

void main() {
  group('GeminiService Tests', () {
    test('GeminiService should require API key', () {
      // Este test verifica que el servicio requiere una API key configurada
      // En un entorno de prueba real, necesitarías mockear dotenv
      expect(() => GeminiService(), throwsException);
    }, skip: 'Requiere configuración de .env con GEMINI_API_KEY');

    test('analyzeConstructionImage should throw without API key', () async {
      // Test para verificar el manejo de errores sin API key
      try {
        GeminiService();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('GEMINI_API_KEY'));
      }
    }, skip: 'Requiere configuración de .env con GEMINI_API_KEY');
  });

  group('GeminiService Constants', () {
    test('Fallback model should be correct', () {
      expect(GeminiService.kGeminiFallbackModel, 'gemini-2.5-flash');
    });
  });
}
