# Pruebas Unitarias - Seguimiento de Construcción

Este proyecto incluye un conjunto completo de pruebas unitarias organizadas en la carpeta `test/`.

## 📁 Estructura de Pruebas

```
test/
├── models/
│   ├── project_test.dart          # Tests del modelo Project
│   └── material_item_test.dart    # Tests del modelo MaterialItem
├── services/
│   └── gemini_service_test.dart   # Tests del servicio Gemini
├── providers/
│   └── theme_provider_test.dart   # Tests del provider de temas
├── utils/
│   ├── date_utils_test.dart       # Tests de utilidades de fecha
│   └── validation_test.dart       # Tests de validaciones
├── widgets/
│   └── auth_wrapper_test.dart     # Tests básicos de widgets
├── integration/
│   └── project_workflow_test.dart # Tests de integración
├── login_test.dart                # Tests de login (existente)
└── register_test.dart             # Tests de registro (existente)
```

## 🧪 Cobertura de Pruebas

### 1. **Modelos** (models/)
- **project_test.dart** (16 tests)
  - Creación de instancias
  - Cálculo de duración en días
  - Días transcurridos y restantes
  - Progreso temporal
  - Detección de retrasos
  - Conversión a Map
  - Valores por defecto

- **material_item_test.dart** (17 tests)
  - Creación de instancias
  - Cálculo de cantidad restante
  - Porcentaje de uso
  - Costos totales
  - Manejo de overuse
  - Conversión a Map
  - Valores por defecto

### 2. **Providers** (providers/)
- **theme_provider_test.dart** (9 tests)
  - Validación de colores
  - Configuración del tema
  - Material Design 3
  - Color scheme

### 3. **Servicios** (services/)
- **gemini_service_test.dart** (3 tests)
  - Validación de API Key
  - Constantes del servicio

### 4. **Utilidades** (utils/)
- **date_utils_test.dart** (7 tests)
  - Diferencia de fechas
  - Comparación de fechas
  - Manejo de fechas futuras/pasadas
  - Cálculo de progreso

- **validation_test.dart** (múltiples tests)
  - Validación de email
  - Validación de contraseña
  - Validación de teléfono
  - Validación de números
  - Validación de cadenas
  - Validación de rangos de fechas
  - Validación de porcentajes

### 5. **Widgets** (widgets/)
- **auth_wrapper_test.dart** (7 tests)
  - Pruebas básicas de widgets
  - Interacción con botones
  - Campos de texto
  - StatefulWidgets

### 6. **Integración** (integration/)
- **project_workflow_test.dart** (6 tests)
  - Ciclo de vida completo de proyectos
  - Detección de retrasos
  - Seguimiento de materiales
  - Control de presupuesto
  - Detección de sobreuso de materiales

## 🚀 Ejecutar las Pruebas

### Ejecutar todas las pruebas
```bash
flutter test
```

### Ejecutar un archivo específico
```bash
flutter test test/models/project_test.dart
```

### Ejecutar pruebas con cobertura
```bash
flutter test --coverage
```

### Ejecutar pruebas de una carpeta específica
```bash
flutter test test/models/
flutter test test/services/
flutter test test/utils/
```

## 📊 Resultados Actuales

```
✅ 71 tests pasados exitosamente
⏭️  2 tests saltados (requieren configuración de .env)
```

## 🔧 Configuración

Las pruebas están configuradas en `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.0.17
  flutter_lints: ^5.0.0
```

## 📝 Tipos de Tests Incluidos

1. **Tests Unitarios**: Prueban funciones y métodos individuales
2. **Tests de Modelos**: Verifican la lógica de negocio
3. **Tests de Widgets**: Verifican el comportamiento de la UI
4. **Tests de Integración**: Verifican flujos completos

## 💡 Mejores Prácticas Implementadas

- ✅ Nombres descriptivos de tests
- ✅ Organización por características
- ✅ Tests independientes
- ✅ Casos de borde cubiertos
- ✅ Valores por defecto verificados
- ✅ Manejo de errores probado
- ✅ Documentación clara

## 🎯 Casos de Prueba Importantes

### Proyecto
- Cálculo correcto de duración
- Detección de retrasos en proyectos
- Progreso temporal preciso
- Estados válidos del proyecto

### Materiales
- Seguimiento de inventario
- Cálculo de costos
- Detección de sobreuso
- Cantidad restante nunca negativa

### Validaciones
- Email válido/inválido
- Contraseñas seguras
- Números positivos
- Rangos de fechas válidos
- Porcentajes entre 0-100%

## 🔄 Continuous Integration

Estas pruebas están listas para integrarse en un pipeline CI/CD:

```yaml
# Ejemplo para GitHub Actions
- name: Run tests
  run: flutter test
  
- name: Check coverage
  run: flutter test --coverage
```

## 📈 Próximos Pasos

- [ ] Agregar tests para más servicios
- [ ] Aumentar cobertura de widgets
- [ ] Tests E2E con integration_test
- [ ] Configurar CI/CD
- [ ] Agregar tests de rendimiento

## 🤝 Contribuir

Al agregar nuevas funcionalidades, asegúrate de:
1. Crear tests correspondientes
2. Mantener la cobertura de tests
3. Seguir la estructura de carpetas
4. Documentar casos especiales

---

**Total de Tests**: 71 ✅  
**Estado**: Todos los tests pasando 🟢  
**Última actualización**: Diciembre 2025
