# 🤖 Guía de Instalación - Sistema de IA con Gemini

## 📦 Instalación de Dependencias

Después de actualizar el archivo `pubspec.yaml`, ejecuta:

```bash
flutter pub get
```

## ⚙️ Configuración de la API de Gemini

La aplicación ya incluye la API key de Google Gemini configurada en:
- **Archivo**: `lib/services/gemini_service.dart`
- **API Key**: `AIzaSyAh6dcpBBUs82UdyUt_ESbzV6ni8qWBks8`

### ⚠️ Nota de Seguridad

Para producción, se recomienda:

1. **Almacenar la API key en variables de entorno:**

```dart
// Usar flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // ...
}
```

2. **Crear archivo `.env` en la raíz del proyecto:**

```env
GEMINI_API_KEY=AIzaSyAh6dcpBBUs82UdyUt_ESbzV6ni8qWBks8
```

3. **Agregar `.env` al `.gitignore`**

## 🚀 Funcionalidades de IA Implementadas

### 1. Análisis de Imágenes

La IA analiza cada imagen de construcción y proporciona:
- ✅ Tipo de trabajo identificado
- ✅ Estado del trabajo
- ✅ Calidad aparente
- ✅ Materiales visibles
- ✅ Riesgos detectados
- ✅ Cumplimiento de seguridad
- ✅ Estimación de progreso

### 2. Validación de Progreso

Compara el progreso reportado por el contratista con:
- 📸 Evidencia fotográfica
- 📊 Análisis visual de avance
- ⚠️ Coherencia con descripción

### 3. Generación de Reportes

Crea reportes profesionales que incluyen:
- 📄 Resumen ejecutivo
- 🔍 Análisis detallado por reporte
- 💡 Recomendaciones técnicas
- ⚠️ Observaciones críticas
- 📈 Tendencias de progreso

### 4. Exportación a PDF

Genera documentos PDF profesionales con:
- 🎨 Diseño corporativo
- 📊 Gráficos de progreso
- 📸 Análisis de cada imagen
- 📝 Conclusiones de IA

## 📱 Uso de la Funcionalidad

### Generar Reporte con IA

1. **Navega a una sección del proyecto**
   - Desde Home → Proyecto → Sección

2. **Presiona el botón morado "GENERAR REPORTE CON IA"**
   - Ubicado debajo de la tarjeta de progreso

3. **Espera el análisis**
   - La IA procesará todas las imágenes
   - Puede tomar 30-60 segundos dependiendo del número de reportes

4. **Revisa el resumen ejecutivo**
   - Lee el análisis generado por la IA
   - Verifica las recomendaciones

5. **Exporta el reporte**
   - Botón "EXPORTAR PDF": Genera documento profesional
   - Botón "COMPARTIR": Comparte vía WhatsApp, Email, etc.
   - Botón "IMPRIMIR": Envía a impresora

## 🔧 Permisos Necesarios

### Android

Ya configurados en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS

Ya configurados en `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Para compartir reportes PDF</string>
```

## 🎯 Ejemplo de Uso

### Caso de Uso: Inspector de Obra

1. **Situación**: El supervisor necesita validar el progreso reportado
2. **Acción**: Genera reporte con IA desde la sección "Cimentación"
3. **Resultado**:
   - La IA detecta que el progreso reportado (80%) es coherente con las imágenes
   - Identifica materiales utilizados: concreto, acero de refuerzo
   - Detecta cumplimiento de normas de seguridad
   - Sugiere verificar curado del concreto en próxima visita
4. **Beneficio**: Validación objetiva respaldada por IA

## 🛠️ Solución de Problemas

### Error: "API key not valid"

**Solución**: Verifica que la API key esté configurada correctamente en `gemini_service.dart`

### Error: "Failed to generate report"

**Solución**:
- Verifica conexión a internet
- Asegúrate de que haya reportes con imágenes en la sección
- Revisa que las imágenes estén en formato Base64 válido

### PDF no se genera

**Solución**:
- Verifica permisos de almacenamiento
- Asegúrate de tener espacio disponible en el dispositivo
- Actualiza la librería `pdf` a la última versión

## 📊 Límites y Consideraciones

### Límites de la API Gemini (Free Tier)

- ✅ **60 solicitudes por minuto**
- ✅ **1,500 solicitudes por día**
- ✅ **1 millón de tokens por mes**

### Optimizaciones Implementadas

- 🎯 Se analizan máximo 3 imágenes por reporte
- 🎯 Las imágenes se comprimen antes de enviar
- 🎯 Se usa modelo Gemini 1.5 Flash (más rápido)

### Recomendaciones

- ⚡ Generar reportes en WiFi para mejor velocidad
- 💾 Los reportes PDF se guardan temporalmente
- 🔄 Compartir inmediatamente para evitar pérdida

## 🎓 Recursos Adicionales

- [Google AI Studio](https://aistudio.google.com/)
- [Documentación Gemini API](https://ai.google.dev/docs)
- [Flutter PDF Package](https://pub.dev/packages/pdf)
- [Google Generative AI Dart](https://pub.dev/packages/google_generative_ai)

## 💡 Tips Profesionales

1. **Fotos de calidad**: Toma fotos nítidas y bien iluminadas para mejor análisis
2. **Contexto completo**: Incluye vista general y detalles en los reportes
3. **Descripciones claras**: Ayuda a la IA con descripciones precisas
4. **Reportes regulares**: Genera reportes periódicamente para mejor seguimiento

---

**¿Problemas o sugerencias?** Abre un issue en GitHub o contacta al equipo de desarrollo.
