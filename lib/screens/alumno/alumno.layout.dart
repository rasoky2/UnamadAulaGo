import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/providers/alumno/home.alumno.riverpod.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/screens/alumno/cursos.alumno.screen.dart';
import 'package:aulago/screens/alumno/home.alumno.screen.dart';
import 'package:aulago/screens/alumno/widgets/perfil.alumno.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moony_nav_bar/moony_nav_bar.dart';

final seccionAlumnoProvider = StateProvider<int>((ref) => 0);

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
    Widget contenido;
    switch (seccion) {
      case 0:
        contenido = const PantallaInicioAlumno();
        break;
      case 1:
        contenido = const PantallaCursosAlumno();
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
        periodosAsync: ref.watch(periodosAcademicosProvider),
        periodoSeleccionado: ref.read(periodoSeleccionadoProvider),
        ref: ref,
      ),
      mobileBody: contenido,
      desktopBody: Row(
        children: [
          AlumnoSidebar(
            onSeccionSeleccionada: (i) => ref.read(seccionAlumnoProvider.notifier).state = i,
            seccionActual: seccion,
            estudiante: ref.read(proveedorAuthProvider).usuario,
            periodosAsync: ref.watch(periodosAcademicosProvider),
            periodoSeleccionado: ref.read(periodoSeleccionadoProvider),
            ref: ref,
          ),
          Expanded(child: contenido),
        ],
      ),
      bottomNavigationBar: esMovil ? MoonyNavigationBar(
        items: <NavigationBarItem>[
          NavigationBarItem(
            icon: Icons.house_rounded,
            onTap: () {
              debugPrint('📱 AlumnoLayout: Moony navigation tapped: 0');
              ref.read(seccionAlumnoProvider.notifier).state = 0;
            },
          ),
          NavigationBarItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            onTap: () {
              debugPrint('📱 AlumnoLayout: Moony navigation tapped: 1');
              ref.read(seccionAlumnoProvider.notifier).state = 1;
            },
          ),
          NavigationBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            onTap: () {
              debugPrint('📱 AlumnoLayout: Moony navigation tapped: 2');
              ref.read(seccionAlumnoProvider.notifier).state = 2;
            },
          ),
        ],
        style: MoonyNavStyle(
          activeColor: AppConstants.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
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
    final cursosAsync = ref.watch(cursosAlumnoProvider);
    final cursoSeleccionadoId = ref.watch(cursoAlumnoStateProvider).cursoSeleccionadoId;
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
                      ),
                      const SizedBox(height: 2),
                      if (estudiante.toJson().containsKey('codigoEstudiante'))
                        Text('Código: 24${estudiante.toJson()['codigoEstudiante']}'),
                      Text(
                        'Alumnos',
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
                      cursosAsync.when(
                        data: (cursos) => Column(
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
                              ref.read(seccionAlumnoProvider.notifier).state = 1;
                              ref.read(cursoAlumnoStateProvider.notifier).seleccionarCurso(curso.curso.id);
                            },
                            selected: cursoSeleccionadoId == curso.curso.id,
                          )).toList(),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, s) => const ListTile(title: Text('Error al cargar cursos', style: TextStyle(color: Colors.red))),
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