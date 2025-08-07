# Widgets de Alumno

Esta carpeta contiene widgets reutilizables específicos para las pantallas del módulo de alumno.

## Widgets Disponibles

### ItemNavegacion

Widget reutilizable para crear items de navegación lateral en las pantallas de cursos, foros, tareas, etc.

**Propiedades:**
- `titulo` (String, requerido): Texto del item de navegación
- `icono` (IconData, requerido): Icono a mostrar
- `activo` (bool, opcional): Si el item está activo/seleccionado (default: false)
- `onTap` (VoidCallback?, opcional): Función a ejecutar al hacer tap

**Ejemplo de uso:**
```dart
ItemNavegacion(
  titulo: 'Foros',
  icono: Icons.forum_outlined,
  activo: true,
  onTap: () {
    // Navegar a foros
  },
)
```

**Características:**
- Estilo consistente con el diseño UNAMAD
- Resaltado visual para items activos
- Tamaño compacto para paneles laterales
- Soporte para callbacks de navegación

## Importación

Para usar estos widgets, importa el archivo barril:

```dart
import 'widgets/widgets.dart';
```

O importa widgets específicos:

```dart
import 'widgets/item_navegacion.widget.dart';
``` 