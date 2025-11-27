# 🏗️ Sistema de Seguimiento de Construcción Civil - Seguimientos

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.7.2-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue)

**Aplicación profesional para la gestión integral de proyectos de construcción civil**

[Características](#características) •
[Instalación](#instalación) •
[Uso](#uso) •
[Arquitectura](#arquitectura) •
[Contribuir](#contribuir)

</div>

---

## 📋 Descripción

Seguimientos es una aplicación móvil completa desarrollada en Flutter para el seguimiento y gestión de proyectos de construcción civil. Permite a administradores, supervisores y contratistas colaborar en tiempo real, documentar avances con evidencia fotográfica, gestionar materiales y generar reportes detallados.

## ✨ Características

### 🎯 Gestión de Proyectos
- ✅ Creación y administración de múltiples proyectos
- ✅ Clasificación por tipo (Privada, Pública, Mixta)
- ✅ Seguimiento de fechas de inicio y fin
- ✅ Gestión de presupuesto y costos
- ✅ Asignación de cliente y ubicación
- ✅ Control de trabajadores asignados

### 📊 Dashboard Analítico
- 📈 Estadísticas en tiempo real del proyecto
- 📉 Gráficos de progreso por sección
- ⏱️ Análisis de tiempo vs. progreso real
- 🚨 Alertas de proyectos retrasados
- 📸 Contador de reportes y fotografías
- 👷 Estadísticas por contratista

### 🏗️ Secciones de Obra
- ➕ División del proyecto en secciones (Cimentación, Estructura, Acabados, etc.)
- 📊 Progreso individual por sección
- 🎨 Indicadores visuales coloridos (rojo/naranja/verde)
- ✏️ Descripción detallada de cada sección
- 🗑️ Eliminación segura con confirmación

### 📝 Reportes Diarios
- 📷 Múltiples fotos por reporte
- 📍 Captura automática de GPS
- 🔄 Actualización automática del progreso
- 👤 Registro del contratista responsable
- 📅 Ordenamiento cronológico
- 💾 Almacenamiento en Base64 (tier gratuito de Firestore)

### 🗺️ Geolocalización
- 📍 Registro de ubicación GPS en cada reporte
- 📋 Copiar coordenadas al portapapeles
- 🗺️ Visualización en Google Maps
- 🔗 Generación de URLs compartibles

### 🤖 Reportes con Inteligencia Artificial (NEW!)
- 🧠 Análisis automático de imágenes con Google Gemini AI
- 🔍 Evaluación de calidad y progreso del trabajo
- ⚠️ Detección de riesgos y problemas
- 📊 Validación del progreso reportado
- 💡 Recomendaciones profesionales automáticas
- 📄 Generación de PDF profesional con análisis IA
- 🎯 Resumen ejecutivo inteligente
- 📈 Análisis de tendencias de progreso

### 📦 Gestión de Materiales
- 📋 Inventario completo de materiales
- 💰 Control de costos unitarios y totales
- 📊 Seguimiento de cantidad planificada vs. utilizada
- 🏪 Registro de proveedores
- 📅 Control de fechas de entrega
- 🏷️ Estados: Pendiente, En tránsito, Entregado, Agotado
- 🔍 Filtros por estado
- ✏️ Edición y actualización en tiempo real

### 👥 Gestión de Usuarios
- 👤 Sistema de autenticación con Firebase Auth
- 📧 Invitaciones por correo electrónico
- 🎭 Roles: Admin, Supervisor, Contratista
- 🔔 Panel de invitaciones pendientes
- ✅ Aceptar/Rechazar invitaciones

### 🎨 Interfaz de Usuario
- 🌓 Modo oscuro/claro
- 📱 Diseño responsive
- 🎯 Navegación intuitiva
- 💅 Material Design 3
- ⚡ Carga rápida y optimizada

## 🚀 Instalación

### Prerrequisitos

```bash
flutter --version  # >= 3.7.2
dart --version     # >= 3.0.0
```

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/seguimiento_de_construccion.git
cd seguimiento_de_construccion
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilitar:
   - Firebase Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage (opcional)
3. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
4. Colocar los archivos en las carpetas correspondientes:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 4. Configurar reglas de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Proyectos
    match /projects/{projectId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Secciones
    match /projectSections/{sectionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Reportes diarios
    match /dailyReports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null &&
                      request.resource.data.contractorId == request.auth.uid;
      allow update, delete: if request.auth != null;
    }

    // Materiales
    match /materials/{materialId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Usuarios del proyecto
    match /projectUsers/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Invitaciones
    match /invitations/{invitationId} {
      allow read: if request.auth != null &&
                    (request.auth.uid == resource.data.userId ||
                     request.auth.uid == resource.data.invitedBy);
      allow create, update: if request.auth != null;
      allow delete: if request.auth != null &&
                     request.auth.uid == resource.data.userId;
    }

    // Usuarios
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 5. Ejecutar la aplicación

```bash
# Android
flutter run

# iOS (requiere Mac con Xcode)
cd ios && pod install && cd ..
flutter run
```

## 📱 Uso

### Crear un Proyecto

1. Inicia sesión con tu cuenta
2. En la pantalla principal, presiona **"CREAR PROYECTO"**
3. Completa la información:
   - Nombre del proyecto
   - Descripción
   - Tipo de obra (Privada/Pública/Mixta)
   - Número de trabajadores
   - Fechas de inicio y fin
4. Presiona **"Crear"**

### Agregar Secciones

1. Abre el proyecto
2. Desplázate hasta **"Secciones de la Obra"**
3. Presiona el botón **"+"**
4. Ingresa nombre y descripción
5. La sección se crea con 0% de progreso

### Crear Reportes Diarios

1. Entra a una sección
2. Presiona **"Nuevo Reporte"**
3. Agrega:
   - Descripción del trabajo realizado
   - Porcentaje de avance (0-100)
   - Fotos desde galería
   - Ubicación GPS actual
4. Presiona **"Guardar"**
5. El progreso de la sección se actualiza automáticamente

### Ver Dashboard

1. Abre un proyecto
2. Presiona **"VER DASHBOARD"**
3. Visualiza:
   - Resumen del proyecto
   - Línea de tiempo
   - Progreso general vs. tiempo
   - Estadísticas de reportes
   - Gráfico por secciones

### Gestionar Materiales

1. Abre un proyecto
2. Presiona **"GESTIONAR MATERIALES"**
3. Agrega materiales con:
   - Nombre y descripción
   - Cantidad planificada y unidad
   - Costo unitario
   - Proveedor y fecha de entrega
   - Estado
4. Actualiza cantidad utilizada según el consumo

### Generar Reporte con IA

1. Entra a una sección con reportes
2. Presiona el botón morado **"GENERAR REPORTE CON IA"**
3. Espera mientras la IA analiza:
   - Todas las imágenes de los reportes
   - Descripción y progreso reportado
   - Calidad y cumplimiento de normas
4. Revisa el resumen ejecutivo generado
5. Opciones disponibles:
   - **Exportar PDF**: Genera documento profesional
   - **Compartir**: Comparte el reporte
   - **Imprimir**: Envía a impresora

### Invitar Usuarios

1. Abre un proyecto (como administrador)
2. Presiona **"Invitar Usuario al Proyecto"**
3. Ingresa:
   - Correo electrónico del usuario
   - Rol (Contratista/Supervisor)
4. El usuario recibirá la invitación en su panel de notificaciones

## 🏛️ Arquitectura

### Estructura del Proyecto

```
lib/
├── models/                    # Modelos de datos
│   ├── project.dart          # Modelo de Proyecto
│   ├── project_section.dart  # Modelo de Sección
│   ├── daily_report.dart     # Modelo de Reporte
│   └── material_item.dart    # Modelo de Material
├── screens/                   # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── section_details_screen.dart
│   ├── project_dashboard_screen.dart
│   └── materials_management_screen.dart
├── widgets/                   # Componentes reutilizables
│   ├── custom_input.dart
│   ├── detail_item.dart
│   ├── profile_option.dart
│   ├── image_service.dart
│   └── invitation_list_panel.dart
└── main.dart                  # Punto de entrada

```

### Tecnologías Utilizadas

| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| Flutter | 3.7.2+ | Framework de UI |
| Firebase Auth | 5.5.2 | Autenticación |
| Cloud Firestore | 5.6.6 | Base de datos |
| Geolocator | 10.1.0 | GPS y ubicación |
| FL Chart | 0.65.0 | Gráficos |
| Percent Indicator | 4.2.3 | Indicadores de progreso |
| Image Picker | 1.1.2 | Selección de imágenes |
| Intl | 0.19.0 | Formato de fechas |
| Google Generative AI | 0.4.6 | IA Gemini para análisis |
| PDF | 3.11.1 | Generación de PDFs |
| Printing | 5.13.2 | Impresión de documentos |
| Share Plus | 10.0.3 | Compartir archivos |

### Colecciones de Firestore

```
📁 projects/
  └── {projectId}/
      ├── name: string
      ├── description: string
      ├── type: string
      ├── adminId: string
      ├── workers: number
      ├── startDate: timestamp
      ├── endDate: timestamp
      ├── location: string
      ├── client: string
      ├── budget: number
      └── status: string

📁 projectSections/
  └── {sectionId}/
      ├── projectId: string
      ├── name: string
      ├── description: string
      ├── progressPercentage: number (0-100)
      ├── createdAt: timestamp
      └── lastUpdated: timestamp

📁 dailyReports/
  └── {reportId}/
      ├── projectId: string
      ├── sectionId: string
      ├── date: timestamp
      ├── description: string
      ├── photosBase64: array[string]
      ├── latitude: number
      ├── longitude: number
      ├── contractorId: string
      ├── contractorName: string
      └── progressAdded: number

📁 materials/
  └── {materialId}/
      ├── projectId: string
      ├── name: string
      ├── description: string
      ├── unit: string
      ├── quantityPlanned: number
      ├── quantityUsed: number
      ├── unitCost: number
      ├── supplier: string
      ├── deliveryDate: timestamp
      ├── status: string
      └── createdAt: timestamp

📁 projectUsers/
  └── {userId}/
      ├── projectId: string
      ├── userId: string
      └── role: string

📁 invitations/
  └── {invitationId}/
      ├── projectId: string
      ├── userId: string
      ├── role: string
      ├── status: string (pending/accepted/rejected)
      ├── invitedBy: string
      └── invitedAt: timestamp
```

## 🎯 Funcionalidades Recién Implementadas

- [x] 🤖 **Análisis de imágenes con IA Google Gemini**
- [x] 📄 **Exportación de reportes a PDF profesional**
- [x] 🧠 **Resumen ejecutivo generado por IA**
- [x] 📦 **Sistema completo de gestión de materiales**
- [x] 📊 **Dashboard analítico con gráficos**
- [x] 🗺️ **Integración con Google Maps**

## 🎯 Próximas Mejoras

- [ ] 📅 Calendario y cronograma de actividades
- [ ] 📧 Notificaciones push en tiempo real
- [ ] 🔍 Búsqueda avanzada con filtros múltiples
- [ ] 📊 Gráficos de evolución temporal
- [ ] 🗺️ Mapa interactivo con todos los puntos GPS
- [ ] 👷 Gestión de asistencia de personal
- [ ] 💵 Control de pagos y nómina
- [ ] 📦 Integración con proveedores
- [ ] ☁️ Sincronización offline
- [ ] 🎥 Análisis de video con IA

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

**Desarrollado con ❤️ para optimizar la gestión de proyectos de construcción civil**

---

<div align="center">

### ⭐ Si te gusta este proyecto, dale una estrella en GitHub!

</div>
