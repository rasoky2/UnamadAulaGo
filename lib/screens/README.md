# Arquitectura de Pantallas - AulaGo UNAMAD

## Estructura Organizacional por Roles

La arquitectura de pantallas está organizada por roles de usuario para facilitar el mantenimiento y desarrollo de funcionalidades específicas.

### 📚 **Alumno** (`/alumno`)
Pantallas y funcionalidades dirigidas a estudiantes:

- **Home Principal**: `home.alumno.screen.dart`
- **Cursos**: `/cursos`
  - Lista de cursos matriculados
  - Detalles del curso
  - Materiales y recursos
- **Evaluaciones**: `/evaluaciones`
  - Tareas pendientes
  - Exámenes y pruebas
  - Envío de trabajos
- **Calificaciones**: `/calificaciones`
  - Notas por curso
  - Historial académico
  - Promedio y estadísticas
- **Horarios**: `/horarios`
  - Horario de clases
  - Calendario académico
  - Recordatorios

### 👨‍🏫 **Profesor** (`/profesor`)
Pantallas y funcionalidades dirigidas a docentes:

- **Dashboard Principal**: `dashboard.profesor.screen.dart`
- **Cursos**: `/cursos`
  - Gestión de cursos asignados
  - Contenido y materiales
  - Configuración del curso
- **Evaluaciones**: `/evaluaciones`
  - Crear tareas y exámenes
  - Revisión y calificación
  - Rúbricas de evaluación
- **Estudiantes**: `/estudiantes`
  - Lista de estudiantes por curso
  - Seguimiento individual
  - Comunicación
- **Materiales**: `/materiales`
  - Subir recursos
  - Gestión de archivos
  - Videos y multimedia

### 👨‍💼 **Administrador** (`/admin`)
Pantallas y funcionalidades dirigidas al administrador del sistema:

- **Dashboard Principal**: `dashboard.admin.screen.dart`
- **Usuarios**: `/usuarios`
  - Gestión de estudiantes
  - Gestión de profesores
  - Roles y permisos
- **Académico**: `/academico`
  - Facultades y carreras
  - Cursos y materias
  - Períodos académicos
- **Sistema**: `/sistema`
  - Configuración general
  - Mantenimiento
  - Seguridad
- **Reportes**: `/reportes`
  - Estadísticas del sistema
  - Reportes académicos
  - Analytics

### 🔐 **Autenticación** (`/auth`)
Pantallas generales de autenticación:
- **Login**: `login.screen.dart`
- Recuperación de contraseña (futuro)
- Registro (futuro)

### 🔧 **Generales**
Pantallas compartidas:
- **Splash**: `splash.screen.dart`
- Configuración global
- Ayuda y soporte

## Convenciones de Nomenclatura

### Archivos de Pantalla
- **Formato**: `nombre.rol.screen.dart`
- **Ejemplos**: 
  - `home.alumno.screen.dart`
  - `cursos.profesor.screen.dart`
  - `usuarios.admin.screen.dart`

### Clases de Componentes
- **Formato**: `Pantalla[Funcionalidad][Rol]`
- **Ejemplos**:
  - `PantallaHomeAlumno`
  - `PantallaCursosProfesor`
  - `PantallaUsuariosAdmin`

### Estructura de Carpetas
```
lib/screens/
├── alumno/
│   ├── home.alumno.screen.dart
│   ├── cursos/
│   ├── evaluaciones/
│   ├── calificaciones/
│   └── horarios/
├── profesor/
│   ├── dashboard.profesor.screen.dart
│   ├── cursos/
│   ├── evaluaciones/
│   ├── estudiantes/
│   └── materiales/
├── admin/
│   ├── dashboard.admin.screen.dart
│   ├── usuarios/
│   ├── academico/
│   ├── sistema/
│   └── reportes/
├── auth/
│   └── login.screen.dart
├── splash.screen.dart
└── screens.dart (exports)
```

## Beneficios de esta Arquitectura

1. **🎯 Separación de Responsabilidades**: Cada rol tiene sus propias funcionalidades
2. **🔧 Mantenimiento Fácil**: Cambios específicos no afectan otros roles
3. **📈 Escalabilidad**: Fácil agregar nuevas funcionalidades por rol
4. **🔍 Navegación Clara**: Estructura intuitiva para desarrolladores
5. **🧪 Testing Dirigido**: Pruebas específicas por funcionalidad y rol

## Próximos Pasos

- [ ] Implementar navegación entre pantallas
- [ ] Crear providers específicos por rol
- [ ] Desarrollar pantallas secundarias
- [ ] Implementar permisos y validaciones
- [ ] Agregar tests unitarios por rol 