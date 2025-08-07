# AlumnoNavbar Widget

Widget de navegación personalizado para pantallas de alumno que proporciona una barra de navegación consistente con funcionalidades comunes.

## Características

- **Navegación al Dashboard**: Botón dedicado para regresar al dashboard principal
- **Menú de Perfil**: Avatar del usuario con menú desplegable
- **Notificaciones**: Acceso rápido a notificaciones
- **Personalizable**: Permite títulos personalizados y acciones adicionales

## Uso Básico

```dart
import '../../widgets/navigation/alumno.navbar.widget.dart';

class MiPantalla extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlumnoNavbar(
        titulo: 'Mi Pantalla',
        mostrarRegresar: true,
      ),
      body: // contenido...
    );
  }
}
```

## Parámetros

### titulo (String, requerido)
El título que se mostrará en la barra de navegación.

### mostrarRegresar (bool, opcional)
- `true`: Muestra el botón de dashboard para regresar (por defecto)
- `false`: Oculta el botón de regresar (útil para dashboard principal)

### onRegresarPersonalizado (VoidCallback?, opcional)
Función personalizada para el botón de regresar. Si no se proporciona, navega al dashboard.

### accionesAdicionales (List<Widget>?, opcional)
Lista de widgets adicionales para mostrar en la barra de acciones.

## Ejemplos

### Dashboard Principal
```dart
appBar: const AlumnoNavbar(
  titulo: 'UNAMAD - Dashboard',
  mostrarRegresar: false,
),
```

### Pantalla de Cursos
```dart
appBar: const AlumnoNavbar(
  titulo: 'Cursos',
  mostrarRegresar: true,
),
```

### Con Acciones Personalizadas
```dart
appBar: AlumnoNavbar(
  titulo: 'Tareas',
  mostrarRegresar: true,
  accionesAdicionales: [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () => // agregar tarea,
    ),
  ],
),
```

### Con Navegación Personalizada
```dart
appBar: AlumnoNavbar(
  titulo: 'Configuración',
  mostrarRegresar: true,
  onRegresarPersonalizado: () {
    // Lógica personalizada antes de regresar
    Navigator.of(context).pop();
  },
),
```

## Funcionalidades del Menú

El widget incluye automáticamente:

1. **Botón Dashboard**: Navega al dashboard principal
2. **Notificaciones**: Muestra diálogo de notificaciones  
3. **Menú de Perfil** con opciones:
   - Mi Perfil
   - Configuración
   - Ayuda
   - Cerrar Sesión

## Integración con Riverpod

El widget utiliza automáticamente el `proveedorAuthProvider` para:
- Obtener información del usuario autenticado
- Generar iniciales para el avatar
- Manejar el cierre de sesión

## Notas

- El widget implementa `PreferredSizeWidget` y puede usarse directamente como `appBar`
- Se integra automáticamente con el sistema de autenticación existente
- Proporciona navegación consistente en toda la aplicación
- Usa los colores y estilos definidos en `AppConstants` 