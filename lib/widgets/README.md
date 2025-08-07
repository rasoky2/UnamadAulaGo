# Widgets Reutilizables de AulaGo - UNAMAD

## 📚 UnamadLayout

Widget principal que replica fielmente el diseño del aula virtual de UNAMAD. Incluye:

- **Header superior** con logo UNAMAD, navegación e información del usuario
- **Breadcrumb** opcional con navegación
- **Panel lateral** de navegación del curso (cuando aplica)
- **Área de contenido** flexible

### ✨ Características

- ✅ Diseño idéntico al aula virtual oficial de UNAMAD
- ✅ Header con logo, iconos de navegación y datos del usuario
- ✅ Breadcrumb automático
- ✅ Panel lateral de navegación con contadores
- ✅ Botón "Regresar" integrado
- ✅ Responsive y optimizado para web/PC

### 🔧 Uso Básico

```dart
UnamadLayout(
  titulo: 'Calendario',
  nombreUsuario: 'GONZALES FLORES, JHORDY JAMES',
  tipoUsuario: 'Alumnos',
  breadcrumb: 'Inicio / DESARROLLO DE APLICACIONES WEB I / Calendario',
  contenido: MiContenido(),
)
```

### 🎯 Uso Avanzado con Panel Lateral

```dart
UnamadLayout(
  titulo: 'Tareas',
  nombreUsuario: estudiante.nombreCompleto,
  tipoUsuario: 'Alumnos',
  breadcrumb: 'Inicio / Cursos / ${curso.nombre} / Tareas',
  cursoActual: 'DESARROLLO DE APLICACIONES WEB I',
  subtitulo: 'SANDOVAL ACOSTA LUIS',
  mostrarRegreso: true,
  onRegresarPressed: () => Navigator.pop(context),
  menuItems: [
    UnamadMenuItem(
      titulo: 'Anuncios',
      icono: Icons.campaign_outlined,
      onTap: () => _navegarAnuncios(),
    ),
    UnamadMenuItem(
      titulo: 'Tareas',
      icono: Icons.assignment_outlined,
      activo: true, // Opción actualmente seleccionada
      contador: 3, // Badge con número
      onTap: () {},
    ),
    UnamadMenuItem(
      titulo: 'Exámenes',
      icono: Icons.quiz_outlined,
      contador: 2,
      onTap: () => _navegarExamenes(),
    ),
  ],
  contenido: _construirContenidoTareas(),
)
```

### 📋 Parámetros

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `titulo` | `String` | ✅ | Título principal de la pantalla |
| `contenido` | `Widget` | ✅ | Widget del contenido principal |
| `nombreUsuario` | `String` | ✅ | Nombre completo del usuario |
| `subtitulo` | `String?` | ❌ | Subtítulo (ej: nombre del profesor) |
| `tipoUsuario` | `String` | ❌ | Tipo de usuario (Alumnos, Profesores, Admin) |
| `breadcrumb` | `String?` | ❌ | Ruta de navegación |
| `menuItems` | `List<UnamadMenuItem>` | ❌ | Items del menú lateral |
| `cursoActual` | `String?` | ❌ | Nombre del curso actual |
| `onRegresarPressed` | `VoidCallback?` | ❌ | Acción del botón regresar |
| `mostrarRegreso` | `bool` | ❌ | Mostrar botón regresar (false por defecto) |

---

## 🎯 UnamadMenuItem

Clase para definir elementos del menú lateral de navegación.

### 🔧 Uso

```dart
UnamadMenuItem(
  titulo: 'Foros',
  icono: Icons.forum_outlined,
  activo: true,
  contador: 5,
  onTap: () => Navigator.pushNamed(context, '/foros'),
)
```

### 📋 Propiedades

| Propiedad | Tipo | Descripción |
|-----------|------|-------------|
| `titulo` | `String` | Texto del menu item |
| `icono` | `IconData` | Icono del menu item |
| `onTap` | `VoidCallback?` | Acción al hacer clic |
| `activo` | `bool` | Si está actualmente seleccionado |
| `contador` | `int?` | Badge numérico opcional |

---

## 🎨 UnamadCard

Widget de tarjeta con el estilo oficial de UNAMAD.

### ✨ Características

- ✅ Bordes redondeados (6px)
- ✅ Sombra sutil
- ✅ Padding configurable
- ✅ Margin configurable
- ✅ Elevación ajustable

### 🔧 Uso

```dart
UnamadCard(
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      Text('Título'),
      Text('Contenido de la tarjeta'),
    ],
  ),
)
```

---

## 🔲 UnamadButton

Botón con estilo oficial de UNAMAD.

### ✨ Características

- ✅ Estilo primario y outlined
- ✅ Iconos opcionales
- ✅ Colores personalizables
- ✅ Esquinas redondeadas (4px)

### 🔧 Uso

```dart
// Botón primario
UnamadButton(
  texto: 'Ingresar',
  icono: Icons.arrow_forward,
  onPressed: () => _ingresar(),
)

// Botón outline
UnamadButton(
  texto: 'Cancelar',
  outlined: true,
  onPressed: () => Navigator.pop(context),
)

// Botón personalizado
UnamadButton(
  texto: 'Eliminar',
  color: Colors.red,
  textColor: Colors.white,
  icono: Icons.delete,
  onPressed: () => _eliminar(),
)
```

### 📋 Parámetros

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `texto` | `String` | Texto del botón |
| `onPressed` | `VoidCallback?` | Acción al presionar |
| `color` | `Color?` | Color de fondo personalizado |
| `textColor` | `Color?` | Color del texto personalizado |
| `icono` | `IconData?` | Icono opcional |
| `outlined` | `bool` | Estilo outline (false por defecto) |

---

## 🎨 Paleta de Colores UNAMAD

Los widgets utilizan automáticamente los colores oficiales definidos en `AppConstants`:

```dart
class AppConstants {
  static const Color primaryColor = Color(0xFFE91E63);    // Fucsia UNAMAD
  static const Color secondaryColor = Color(0xFF2196F3);  // Azul
  static const Color accentColor = Color(0xFF4CAF50);     // Verde
  static const Color textPrimary = Color(0xFF212121);     // Negro principal
  static const Color textSecondary = Color(0xFF757575);   // Gris oscuro
  static const Color textTertiary = Color(0xFFBDBDBD);    // Gris claro
  static const Color backgroundLight = Color(0xFFF5F5F5); // Fondo claro
  static const Color cardColor = Colors.white;            // Fondo de tarjetas
}
```

---

## 💡 Ejemplos Completos

### 📄 Pantalla Simple

```dart
class MiPantalla extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiante = ref.watch(estudianteActualProvider);
    
    return UnamadLayout(
      titulo: 'Mi Pantalla',
      nombreUsuario: estudiante.nombreCompleto,
      breadcrumb: 'Inicio / Mi Pantalla',
      contenido: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            UnamadCard(
              child: Text('Contenido de ejemplo'),
            ),
            UnamadButton(
              texto: 'Acción',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

### 📚 Pantalla de Curso con Panel Lateral

```dart
class PantallaCurso extends ConsumerWidget {
  final String codigoCurso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UnamadLayout(
      titulo: 'DESARROLLO DE APLICACIONES WEB I',
      subtitulo: 'SANDOVAL ACOSTA LUIS',
      nombreUsuario: 'GONZALES FLORES, JHORDY JAMES',
      breadcrumb: 'Inicio / Cursos / ${codigoCurso}',
      cursoActual: 'DESARROLLO DE APLICACIONES WEB I',
      mostrarRegreso: true,
      onRegresarPressed: () => Navigator.pop(context),
      menuItems: [
        UnamadMenuItem(
          titulo: 'Unidades',
          icono: Icons.folder_outlined,
          activo: true,
          onTap: () {},
        ),
        UnamadMenuItem(
          titulo: 'Tareas',
          icono: Icons.assignment_outlined,
          contador: 3,
          onTap: () => _navegarTareas(),
        ),
        // ... más items
      ],
      contenido: _construirContenido(),
    );
  }
}
```

---

## ⚡ Tips y Mejores Prácticas

1. **Reutilización**: Usa `UnamadLayout` para todas las pantallas del proyecto
2. **Consistencia**: Mantén los mismos `menuItems` para pantallas relacionadas
3. **Navegación**: Usa `breadcrumb` para mejorar la orientación del usuario
4. **Estados**: Marca el `UnamadMenuItem` correcto como `activo: true`
5. **Contadores**: Usa `contador` en los menu items para mostrar notificaciones
6. **Colores**: Utiliza la paleta oficial de UNAMAD para mantener coherencia

---

## 🔄 Migración de Pantallas Existentes

Para migrar una pantalla existente a usar `UnamadLayout`:

### Antes:
```dart
Scaffold(
  appBar: AppBar(title: Text('Mi Pantalla')),
  body: MiContenido(),
)
```

### Después:
```dart
UnamadLayout(
  titulo: 'Mi Pantalla',
  nombreUsuario: usuario.nombre,
  breadcrumb: 'Inicio / Mi Pantalla',
  contenido: MiContenido(),
)
```

¡Los widgets están listos para usar y garantizan consistencia con el diseño oficial de UNAMAD! 🎉 