// Eliminados providers antiguos de alumno; ahora usamos repos y estado local
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/screens/alumno/cursos.alumno.screen.dart';
import 'package:aulago/screens/alumno/home.alumno.screen.dart';
import 'package:aulago/screens/alumno/widgets/perfil.alumno.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:moony_nav_bar/moony_nav_bar.dart';

final seccionAlumnoProvider = StateProvider<int>((ref) => 0);

// Importamos los providers del sistema de cursos
final cursoSeleccionadoAlumnoProvider = StateProvider<int?>((ref) => null);

/// Widget de layout reutilizable que replica el diseño oficial de UNAMAD
/// Incluye header superior, panel lateral de navegación y área de contenido
class UnamadLayout extends ConsumerWidget {

  const UnamadLayout({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.contenido,
    required this.nombreUsuario,
    this.tipoUsuario = 'Alumnos',
    this.breadcrumb,
    this.menuItems = const [],
    this.cursoActual,
    this.onRegresarPressed,
    this.mostrarRegreso = false,
  });
  final String titulo;
  final String? subtitulo;
  final Widget contenido;
  final String nombreUsuario;
  final String tipoUsuario;
  final String? breadcrumb;
  final List<UnamadMenuItem> menuItems;
  final String? cursoActual;
  final VoidCallback? onRegresarPressed;
  final bool mostrarRegreso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    final seccion = ref.watch(seccionAlumnoProvider);
    final cursoSeleccionado = ref.watch(cursoSeleccionadoAlumnoProvider);
    
    // Si está en la sección de cursos Y tiene un curso seleccionado, mostrar solo el layout del curso
    if (seccion == 1 && cursoSeleccionado != null) {
      return const PantallaCursosAlumno();
    }
    
    Widget contenido;
    switch (seccion) {
      case 0:
        contenido = const PantallaInicioAlumno();
        break;
      case 1:
        // Mostrar selector de cursos dentro del layout principal
        contenido = const _SelectorCursosWidget();
        break;
      case 2:
        contenido = const PerfilAlumnoWidget();
        break;
      default:
        contenido = const PantallaInicioAlumno();
    }
    
    return ResponsiveScaffold(
      drawer: esMovil ? null : AlumnoSidebar(
        onSeccionSeleccionada: (i) => ref.read(seccionAlumnoProvider.notifier).state = i,
        seccionActual: seccion,
        estudiante: ref.read(proveedorAuthProvider).usuario,
        periodosAsync: const AsyncValue.data([]),
        periodoSeleccionado: null,
        ref: ref,
      ),
      mobileBody: contenido,
      desktopBody: Row(
        children: [
          AlumnoSidebar(
            onSeccionSeleccionada: (i) => ref.read(seccionAlumnoProvider.notifier).state = i,
            seccionActual: seccion,
            estudiante: ref.read(proveedorAuthProvider).usuario,
            periodosAsync: const AsyncValue.data([]),
            periodoSeleccionado: null,
            ref: ref,
          ),
          Expanded(child: contenido),
        ],
      ),
      bottomNavigationBar: esMovil ? NavigationBar(
        selectedIndex: seccion,
        onDestinationSelected: (index) {
          ref.read(seccionAlumnoProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.house_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Cursos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ) : null,
    );
  }






  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('titulo', titulo))
    ..add(StringProperty('subtitulo', subtitulo))
    ..add(StringProperty('nombreUsuario', nombreUsuario))
    ..add(StringProperty('tipoUsuario', tipoUsuario))
    ..add(StringProperty('breadcrumb', breadcrumb))
    ..add(IterableProperty<UnamadMenuItem>('menuItems', menuItems))
    ..add(StringProperty('cursoActual', cursoActual))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onRegresarPressed', onRegresarPressed))
    ..add(DiagnosticsProperty<bool>('mostrarRegreso', mostrarRegreso));
  }
}

/// Clase para definir elementos del menú lateral
class UnamadMenuItem {

  const UnamadMenuItem({
    required this.titulo,
    required this.icono,
    this.onTap,
    this.activo = false,
    this.contador,
  });
  final String titulo;
  final IconData icono;
  final VoidCallback? onTap;
  final bool activo;
  final int? contador;
}

/// Widget para crear tarjetas de contenido estilo UNAMAD
class UnamadCard extends StatelessWidget {

  const UnamadCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevation ?? 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding))
    ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('margin', margin))
    ..add(DoubleProperty('elevation', elevation));
  }
}

/// Widget para botones estilo UNAMAD
class UnamadButton extends StatelessWidget {

  const UnamadButton({
    super.key,
    required this.texto,
    this.onPressed,
    this.color,
    this.textColor,
    this.icono,
    this.outlined = false,
  });
  final String texto;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icono;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? AppConstants.primaryColor;
    final foregroundColor = textColor ?? Colors.white;
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined ? Colors.transparent : backgroundColor,
        foregroundColor: outlined ? backgroundColor : foregroundColor,
        side: outlined ? BorderSide(color: backgroundColor) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: outlined ? 0 : 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('texto', texto))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed))
    ..add(ColorProperty('color', color))
    ..add(ColorProperty('textColor', textColor))
    ..add(DiagnosticsProperty<IconData?>('icono', icono))
    ..add(DiagnosticsProperty<bool>('outlined', outlined));
  }
} 

class ResponsiveScaffold extends StatelessWidget {

  const ResponsiveScaffold({
    required this.mobileBody,
    required this.desktopBody,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    super.key,
  });
  final Widget mobileBody;
  final Widget desktopBody;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: appBar,
      drawer: esMovil ? drawer : null,
      body: esMovil ? mobileBody : desktopBody,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
} 

class AlumnoSidebar extends ConsumerWidget {

  const AlumnoSidebar({
    required this.estudiante,
    required this.periodosAsync,
    required this.periodoSeleccionado,
    required this.ref,
    required this.onSeccionSeleccionada,
    required this.seccionActual,
    super.key,
  });
  final dynamic estudiante;
  final AsyncValue<List<Map<String, dynamic>>> periodosAsync;
  final Map<String, dynamic>? periodoSeleccionado;
  final WidgetRef ref;
  final void Function(int) onSeccionSeleccionada;
  final int seccionActual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    final codigo = ref.watch(codigoUsuarioProvider);
    final int? cursoSeleccionadoId = ref.watch(cursoSeleccionadoAlumnoProvider);
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppConstants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'UNAMAD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Avatar del estudiante
                      AvatarWidget(
                        fotoUrl: estudiante?.fotoPerfilUrl,
                        nombreCompleto: estudiante?.nombreCompleto ?? '',
                      ),
                      const SizedBox(width: 12),
                      // Información del estudiante
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante?.nombreCompleto ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (estudiante?.toJson().containsKey('codigoEstudiante') == true)
                              Text(
                                'Código: 24${estudiante.toJson()['codigoEstudiante']}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              'Estudiante',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                _construirItemMenu(context, ref, Icons.house, 'Inicio', seccionActual == 0, () => onSeccionSeleccionada(0)),
                // Cursos con submenú en escritorio
                if (!esMovil)
                  ExpansionTile(
                    leading: Icon(Icons.book, color: seccionActual == 1 ? AppConstants.primaryColor : AppConstants.textSecondary),
                    title: Text('Cursos', style: TextStyle(fontWeight: seccionActual == 1 ? FontWeight.w600 : FontWeight.normal, color: seccionActual == 1 ? AppConstants.primaryColor : AppConstants.textSecondary)),
                    initiallyExpanded: seccionActual == 1,
                    children: [
                      FutureBuilder<List<ModeloCursoDetallado>>(
                        future: MatriculaRepository().obtenerCursosMatriculadosPorCodigo(codigo),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const ListTile(
                              title: Text('Error al cargar cursos', style: TextStyle(color: Colors.red)),
                            );
                          }
                          final cursos = snapshot.data ?? const <ModeloCursoDetallado>[];
                          if (cursos.isEmpty) {
                            return const ListTile(
                              title: Text('No hay cursos matriculados'),
                            );
                          }
                          return Column(
                            children: cursos.map((curso) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 36, right: 8),
                              title: Text(
                                curso.curso.nombre,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cursoSeleccionadoId == curso.curso.id ? AppConstants.primaryColor : AppConstants.textSecondary,
                                  fontWeight: cursoSeleccionadoId == curso.curso.id ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = curso.curso.id;
                                ref.read(seccionAlumnoProvider.notifier).state = 1;
                              },
                              selected: cursoSeleccionadoId == curso.curso.id,
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                if (esMovil)
                  _construirItemMenu(context, ref, Icons.book, 'Cursos', seccionActual == 1, () => onSeccionSeleccionada(1)),
                const Divider(height: 32),
                _construirItemMenu(context, ref, Icons.person, 'Mi Perfil', seccionActual == 2, () => onSeccionSeleccionada(2)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período Académico',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '2025-I',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await ref.read(proveedorAuthProvider.notifier).cerrarSesion();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, size: 16, color: Colors.red),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemMenu(BuildContext context, WidgetRef ref, IconData icono, String titulo, bool activo, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icono,
          size: 20,
          color: activo ? AppConstants.primaryColor : AppConstants.textSecondary,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
            color: activo ? AppConstants.primaryColor : AppConstants.textSecondary,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: activo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        dense: true,
      ),
    );
  }
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('estudiante', estudiante))
    ..add(DiagnosticsProperty<AsyncValue<List<Map<String, dynamic>>>>('periodosAsync', periodosAsync))
    ..add(DiagnosticsProperty<Map<String, dynamic>?>('periodoSeleccionado', periodoSeleccionado))
    ..add(DiagnosticsProperty<WidgetRef>('ref', ref))
    ..add(ObjectFlagProperty<void Function(int p1)>.has('onSeccionSeleccionada', onSeccionSeleccionada))
    ..add(IntProperty('seccionActual', seccionActual));
  }
}

// Widget para mostrar el selector de cursos dentro del layout principal
class _SelectorCursosWidget extends ConsumerStatefulWidget {
  const _SelectorCursosWidget();

  @override
  ConsumerState<_SelectorCursosWidget> createState() => _SelectorCursosWidgetState();
}

class _SelectorCursosWidgetState extends ConsumerState<_SelectorCursosWidget> {
  final CursoRepository _repo = CursoRepository();
  late Future<List<dynamic>> _cursosFuture;

  @override
  void initState() {
    super.initState();
    // Usar el mismo repositorio que en PantallaCursosAlumno
    _cursosFuture = _repo.obtenerCursosConProfesor();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;

    return Container(
      padding: EdgeInsets.all(esMovil ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Cursos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona un curso para acceder a sus herramientas',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _cursosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final cursosDetallados = snapshot.data ?? [];
                
                if (cursosDetallados.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes cursos disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (esMovil) {
                  return ListView.builder(
                    itemCount: cursosDetallados.length,
                    itemBuilder: (context, index) {
                      final cursoDetallado = cursosDetallados[index];
                      return _construirTarjetaCursoMovil(cursoDetallado);
                    },
                  );
                } else {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: cursosDetallados.length,
                    itemBuilder: (context, index) {
                      final cursoDetallado = cursosDetallados[index];
                      return _construirTarjetaCursoDesktop(cursoDetallado);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaCursoMovil(dynamic cursoDetallado) {
    final curso = cursoDetallado.curso;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Seleccionar el curso - esto activará el layout completo de cursos
          ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = curso.id;
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profesor: ${cursoDetallado.profesor?.nombreCompleto ?? 'No asignado'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (curso.codigoCurso.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          curso.codigoCurso,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaCursoDesktop(dynamic cursoDetallado) {
    final curso = cursoDetallado.curso;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Seleccionar el curso - esto activará el layout completo de cursos
          ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = curso.id;
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryColor.withValues(alpha: 0.1),
                AppConstants.primaryColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    curso.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profesor: ${cursoDetallado.profesor?.nombreCompleto ?? 'No asignado'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (curso.codigoCurso.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        curso.codigoCurso,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}