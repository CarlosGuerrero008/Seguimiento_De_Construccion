# Instrucciones para Actualizar Reglas de Firebase

## Errores Identificados en las Capturas de Pantalla:

1. **Error al crear reporte**: 
   ```
   Error: [cloud_firestore/unknown] Invalid data. FieldValue.serverTimestamp() can only be used with set() and update()
   ```

2. **Error al leer documentos**:
   ```
   Error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
   ```

## Solución Completa

### Paso 1: Actualizar Reglas de Firestore

1. Ve a Firebase Console: https://console.firebase.google.com/
2. Selecciona tu proyecto
3. En el menú lateral, ve a **Firestore Database**
4. Haz clic en la pestaña **Reglas**
5. **REEMPLAZA TODO EL CONTENIDO** con las reglas del archivo `firestore.rules`
6. Haz clic en **Publicar**

### Paso 2: Verificar que las Reglas se Aplicaron

Después de publicar, deberías ver un mensaje de confirmación. Las reglas incluyen:

✅ **user_images** - Imágenes de perfil (YA EXISTÍA)
✅ **users** - Datos de usuarios
✅ **projects** - Proyectos de construcción
✅ **projectUsers** - Relación usuarios-proyectos
✅ **invitations** - Invitaciones a proyectos
✅ **projectSections** - Secciones de obra
✅ **dailyReports** - Reportes diarios
✅ **projectDocuments** - Documentación del proyecto (NUEVO)

### Paso 3: Desplegar las Reglas desde la Terminal (Alternativa)

Si tienes Firebase CLI instalado, puedes ejecutar:

```bash
firebase deploy --only firestore:rules
```

## Explicación de las Reglas

### 1. Proyectos (projects)
- **Lectura**: Solo usuarios que pertenezcan al proyecto
- **Creación**: Cualquier usuario autenticado
- **Actualización/Eliminación**: Solo el administrador del proyecto

### 2. Secciones (projectSections)
- **Lectura**: Usuarios del proyecto
- **Creación/Actualización**: Cualquier usuario autenticado del proyecto
- **Eliminación**: Solo el administrador

### 3. Reportes Diarios (dailyReports)
- **Lectura**: Todos los usuarios autenticados
- **Creación**: Cualquier usuario autenticado
- **Actualización/Eliminación**: Solo el contratista que lo creó

### 4. Documentos (projectDocuments)
- **Lectura**: Usuarios del proyecto
- **Creación**: Cualquier usuario del proyecto (límite 5MB)
- **Actualización**: Solo quien lo subió
- **Eliminación**: Quien lo subió o el administrador del proyecto

### 5. Invitaciones (invitations)
- **Lectura**: El invitado o quien invitó
- **Creación**: Cualquier usuario autenticado
- **Actualización**: Solo el invitado (para aceptar/rechazar)
- **Eliminación**: Quien invitó o el invitado

## Notas Importantes

⚠️ **Las reglas anteriores (user_images) se mantienen** - No se pierde ninguna funcionalidad existente.

⚠️ **Seguridad**: Las reglas implementan un modelo de seguridad robusto donde:
- Solo usuarios autenticados pueden acceder a datos
- Los usuarios solo ven proyectos a los que pertenecen
- Los administradores tienen control total de sus proyectos
- Los documentos tienen límite de tamaño para prevenir abuso

## Troubleshooting

Si después de actualizar las reglas sigues teniendo problemas:

1. **Verifica que el usuario esté autenticado**: `FirebaseAuth.instance.currentUser != null`
2. **Verifica que exista la relación en projectUsers**: El usuario debe estar agregado al proyecto
3. **Verifica los timestamps**: Usa `FieldValue.serverTimestamp()` solo en operaciones `add()` o `update()`, nunca en `where()` o queries
4. **Revisa la consola de Firebase**: Ve a la sección de uso de Firestore para ver logs de acceso denegado

## Ejemplo de Uso Correcto de Timestamps

❌ **INCORRECTO**:
```dart
await FirebaseFirestore.instance.collection('dailyReports').add({
  'createdAt': FieldValue.serverTimestamp(),
  'lastUpdated': FieldValue.serverTimestamp(), // Causa error
});
```

✅ **CORRECTO**:
```dart
await FirebaseFirestore.instance.collection('dailyReports').add({
  'createdAt': FieldValue.serverTimestamp(),
  // 'lastUpdated' se agrega en update(), no en create
});
```

O mejor aún, crear primero y luego actualizar si es necesario.
