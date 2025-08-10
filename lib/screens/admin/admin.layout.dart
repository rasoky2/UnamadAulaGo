import 'package:aulago/models/estadisticas_admin.model.dart';
import 'package:aulago/providers/admin/estadisticas.admin.riverpod.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/screens/admin/alumno.admin.screen.dart';
import 'package:aulago/screens/admin/carreras.admin.screen.dart';
import 'package:aulago/screens/admin/cursos.admin.screen.dart';
import 'package:aulago/screens/admin/extras.admin.screen.dart';
import 'package:aulago/screens/admin/matricula.admin.screen.dart';
import 'package:aulago/screens/admin/profesores.admin.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moony_nav_bar/moony_nav_bar.dart';

// Provider para manejar el índice de la página actual
final indiceNavegacionAdminProvider = StateProvider<int>((ref) => 0);

class AdminLayout extends ConsumerStatefulWidget {

  const AdminLayout({
    super.key,
    required this.titulo,
  });
  final String titulo;

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('titulo', titulo));
  }
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Inicializar el provider en 0 (página de inicio)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(indiceNavegacionAdminProvider.notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _obtenerTituloPorIndice(int indice) {
    switch (indice) {
      case 0:
        return 'Panel Principal';
      case 1:
        return 'Gestión de Estudiantes';
      case 2:
        return 'Gestión de Matrículas';
      case 3:
        return 'Gestión de Profesores';
      case 4:
        return 'Gestión de Cursos';
      case 5:
        return 'Gestión de Carreras';
      case 6:
        return 'Extras (Anuncios y Fechas)';
      default:
        return 'Panel Principal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoAuth = ref.watch(proveedorAuthProvider);
    final indiceActual = ref.watch(indiceNavegacionAdminProvider);
    final esMovil = MediaQuery.of(context).size.width < 768;
    final esTablet = MediaQuery.of(context).size.width < 1024;

    debugPrint('📱 AdminLayout: Build - esMovil: $esMovil, esTablet: $esTablet, indiceActual: $indiceActual');

    if (!estadoAuth.estaAutenticado) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (esMovil) {
      return _buildLayoutMovil(indiceActual);
    } else {
      return _buildLayoutDesktop(indiceActual, esTablet);
    }
  }

  Widget _buildLayoutMovil(int indiceActual) {
    debugPrint('📱 AdminLayout: Construyendo layout móvil');
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 1,
        title: Text(
          _obtenerTituloPorIndice(indiceActual),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Botón de notificaciones
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              debugPrint('🔔 AdminLayout: Botón notificaciones presionado');
            },
            tooltip: 'Notificaciones',
          ),
          // Menú de usuario
          PopupMenuButton<String>(
            icon: const AvatarWidget(
              nombreCompleto: 'Administrador',
              tipoUsuario: 'admin',
              radio: 16,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Cerrar Sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (valor) => _manejarMenuUsuario(context, valor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawerMovil(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (indice) {
          debugPrint('📄 AdminLayout: Página cambiada a índice: $indice');
          ref.read(indiceNavegacionAdminProvider.notifier).state = indice;
        },
        children: _obtenerPaginas(),
      ),
      bottomNavigationBar: _buildBottomNavigation(indiceActual),
    );
  }

  Widget _buildLayoutDesktop(int indiceActual, bool esTablet) {
    debugPrint('💻 AdminLayout: Construyendo layout desktop, esTablet: $esTablet');
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          _SidebarAdmin(
            esTablet: esTablet,
            onItemSeleccionado: (indice) {
              debugPrint('📂 AdminLayout: Item sidebar seleccionado: $indice');
              _pageController.animateToPage(
                indice,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              ref.read(indiceNavegacionAdminProvider.notifier).state = indice;
            },
          ),
          
          // Contenido principal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (indice) {
                debugPrint('📄 AdminLayout: Página desktop cambiada a índice: $indice');
                ref.read(indiceNavegacionAdminProvider.notifier).state = indice;
              },
              children: _obtenerPaginas(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMovil() {
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Panel Administrativo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'UNAMAD',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Estadísticas rápidas en drawer
          const SizedBox(height: 16),
          _EstadisticasRapidasMovil(),
          
          const SizedBox(height: 16),
          
          // Menú de navegación
          Expanded(
            child: _MenuNavegacionMovil(),
          ),
          
          // Información del usuario en drawer
          const _InfoUsuarioMovil(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int indiceActual) {
    return MoonyNavigationBar(
      items: <NavigationBarItem>[
        NavigationBarItem(
          icon: Icons.dashboard_rounded,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 0');
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 0;
          },
        ),
        NavigationBarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 1');
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 1;
          },
        ),
        NavigationBarItem(
          icon: Icons.school_outlined,
          activeIcon: Icons.school,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 2');
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 2;
          },
        ),
        NavigationBarItem(
          icon: Icons.person_add_outlined,
          activeIcon: Icons.person_add,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 3');
            _pageController.animateToPage(
              3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 3;
          },
        ),
        NavigationBarItem(
          icon: Icons.book_outlined,
          activeIcon: Icons.book,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 4');
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 4;
          },
        ),
        NavigationBarItem(
          icon: Icons.school_outlined,
          activeIcon: Icons.school,
          onTap: () {
            debugPrint('📱 AdminLayout: Moony navigation tapped: 5');
            _pageController.animateToPage(
              5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 5;
          },
        ),
        NavigationBarItem(
          icon: Icons.event_note,
          activeIcon: Icons.event,
          onTap: () {
            _pageController.animateToPage(
              6,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionAdminProvider.notifier).state = 6;
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
    );
  }

  List<Widget> _obtenerPaginas() {
    debugPrint('📄 AdminLayout: Obteniendo páginas para PageView');
    
    return [
      _PaginaAdminWrapper(child: _construirPaginaInicio()),
      _PaginaAdminWrapper(child: _construirPaginaEstudiantes()),
      _PaginaAdminWrapper(child: _construirPaginaMatriculas()),
      _PaginaAdminWrapper(child: _construirPaginaProfesores()),
      _PaginaAdminWrapper(child: _construirPaginaCursos()),
      _PaginaAdminWrapper(child: _construirPaginaCarreras()),
      const _PaginaAdminWrapper(child: PantallaExtrasAdmin()),
    ];
  }

  // Constructores de páginas lazy
  Widget _construirPaginaInicio() {
    debugPrint('🏠 AdminLayout: Construyendo página de inicio');
    return Consumer(
      builder: (context, ref, child) {
        final estadisticas = ref.watch(estadisticasAdminProvider);
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas principales
              _EstadisticasRapidas(estadisticas: estadisticas),
              
              const SizedBox(height: 32),
              
              // Resumen de actividad
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenido al Panel Administrativo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Desde aquí puedes gestionar estudiantes, profesores, cursos y matrículas. Utiliza la navegación lateral o el menú inferior para acceder a las diferentes secciones.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _AccesoRapido(
                            titulo: 'Estudiantes',
                            icono: Icons.people,
                            color: Colors.blue,
                            onTap: () => ref.read(indiceNavegacionAdminProvider.notifier).state = 1,
                          ),
                          _AccesoRapido(
                            titulo: 'Matrículas',
                            icono: Icons.school,
                            color: Colors.green,
                            onTap: () => ref.read(indiceNavegacionAdminProvider.notifier).state = 2,
                          ),
                          _AccesoRapido(
                            titulo: 'Profesores',
                            icono: Icons.person_add,
                            color: Colors.orange,
                            onTap: () => ref.read(indiceNavegacionAdminProvider.notifier).state = 3,
                          ),
                          _AccesoRapido(
                            titulo: 'Cursos',
                            icono: Icons.book,
                            color: Colors.purple,
                            onTap: () => ref.read(indiceNavegacionAdminProvider.notifier).state = 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirPaginaEstudiantes() {
    debugPrint('👥 AdminLayout: Construyendo página de estudiantes');
    return const PantallaEstudiantesAdmin();
  }

  Widget _construirPaginaMatriculas() {
    debugPrint('📚 AdminLayout: Construyendo página de matrículas');
    return const PantallaMatriculasAdmin();
  }

  Widget _construirPaginaProfesores() {
    debugPrint('👨‍🏫 AdminLayout: Construyendo página de profesores');
    return const PantallaProfesoresAdmin();
  }

  Widget _construirPaginaCursos() {
    debugPrint('📖 AdminLayout: Construyendo página de cursos');
    return const PantallaCursosAdmin();
  }

  Widget _construirPaginaCarreras() {
    debugPrint('🎓 AdminLayout: Construyendo página de carreras');
    return const PantallaCarrerasAdmin();
  }

  void _manejarMenuUsuario(BuildContext context, String accion) {
    debugPrint('👤 AdminLayout: Acción de menú de usuario: $accion');
    if (accion == 'logout') {
      ref.read(proveedorAuthProvider.notifier).cerrarSesion();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

// Wrapper para las páginas que agrega padding responsivo
class _PaginaAdminWrapper extends StatelessWidget {

  const _PaginaAdminWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esMovil = MediaQuery.of(context).size.width < 768;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(esMovil ? 16 : 24),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('child', child));
  }
}

class _SidebarAdmin extends ConsumerWidget {

  const _SidebarAdmin({
    required this.esTablet,
    required this.onItemSeleccionado,
  });
  final bool esTablet;
  final Function(int) onItemSeleccionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadisticas = ref.watch(estadisticasAdminProvider);

    return Container(
      width: esTablet ? 240 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo y título
          _LogoAdmin(esCompacto: esTablet),
          
          // Estadísticas rápidas
          if (!esTablet)
          _EstadisticasRapidas(estadisticas: estadisticas),
          
          // Menú de navegación
          Expanded(
            child: _MenuNavegacion(
              esCompacto: esTablet,
              onItemSeleccionado: onItemSeleccionado,
            ),
          ),
          
          // Información del usuario
          _InfoUsuario(esCompacto: esTablet),
          // Botón cerrar sesión
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                elevation: 0,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onPressed: () {
                ref.read(proveedorAuthProvider.notifier).cerrarSesion();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('esTablet', esTablet))
      ..add(ObjectFlagProperty<Function(int p1)>.has('onItemSeleccionado', onItemSeleccionado));
  }
}

class _LogoAdmin extends StatelessWidget {

  const _LogoAdmin({this.esCompacto = false});
  final bool esCompacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(esCompacto ? 16 : AppConstants.largePadding),
      child: Column(
        children: [
          Container(
            width: esCompacto ? 40 : 60,
            height: esCompacto ? 40 : 60,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(esCompacto ? 8 : 12),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: esCompacto ? 20 : 30,
            ),
          ),
          if (!esCompacto) ...[
          const SizedBox(height: 12),
          const Text(
            'Panel Administrativo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
              textAlign: TextAlign.center,
          ),
          const Text(
            'UNAMAD',
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('esCompacto', esCompacto));
  }
}

class _EstadisticasRapidas extends StatelessWidget {

  const _EstadisticasRapidas({required this.estadisticas});
  final EstadisticasAdmin estadisticas;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          const Text(
            'Sistema',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (estadisticas.cargando)
            const CircularProgressIndicator(strokeWidth: 2)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EstadisticaMini(
                  icono: Icons.school,
                  valor: estadisticas.totalEstudiantes,
                  color: Colors.blue,
                ),
                _EstadisticaMini(
                  icono: Icons.person_outline,
                  valor: estadisticas.totalProfesores,
                  color: Colors.green,
                ),
                _EstadisticaMini(
                  icono: Icons.book,
                  valor: estadisticas.totalCursos,
                  color: Colors.orange,
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EstadisticasAdmin>('estadisticas', estadisticas));
  }
}

class _EstadisticasRapidasMovil extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadisticas = ref.watch(estadisticasAdminProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (estadisticas.cargando)
            const CircularProgressIndicator(strokeWidth: 2)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EstadisticaMiniMovil(
                  icono: Icons.school,
                  valor: estadisticas.totalEstudiantes,
                  etiqueta: 'Estudiantes',
                  color: Colors.blue,
                ),
                _EstadisticaMiniMovil(
                  icono: Icons.person_outline,
                  valor: estadisticas.totalProfesores,
                  etiqueta: 'Profesores',
                  color: Colors.green,
                ),
                _EstadisticaMiniMovil(
                  icono: Icons.book,
                  valor: estadisticas.totalCursos,
                  etiqueta: 'Cursos',
                  color: Colors.orange,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EstadisticaMini extends StatelessWidget {

  const _EstadisticaMini({
    required this.icono,
    required this.valor,
    required this.color,
  });
  final IconData icono;
  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icono, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(IntProperty('valor', valor))
    ..add(ColorProperty('color', color));
  }
}

class _EstadisticaMiniMovil extends StatelessWidget {

  const _EstadisticaMiniMovil({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });
  final IconData icono;
  final int valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 10,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(IntProperty('valor', valor))
      ..add(StringProperty('etiqueta', etiqueta))
    ..add(ColorProperty('color', color));
  }
}

class _MenuNavegacion extends StatelessWidget {

  const _MenuNavegacion({
    this.esCompacto = false,
    required this.onItemSeleccionado,
  });
  final bool esCompacto;
  final Function(int) onItemSeleccionado;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: esCompacto ? 8 : AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Sección Dashboard
          if (!esCompacto) const _SeccionMenu('INICIO'),
          _ItemMenu(
            icono: Icons.dashboard,
            titulo: esCompacto ? 'Inicio' : 'Panel Principal',
            indice: 0,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(0),
          ),
          
          SizedBox(height: esCompacto ? 8 : AppConstants.defaultPadding),
          
          // Sección Gestión de Usuarios
          if (!esCompacto) const _SeccionMenu('GESTIÓN DE USUARIOS'),
          _ItemMenu(
            icono: Icons.people,
            titulo: 'Estudiantes',
            indice: 1,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(1),
          ),
          _ItemMenu(
            icono: Icons.school,
            titulo: 'Matrículas',
            indice: 2,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(2),
          ),
          _ItemMenu(
            icono: Icons.person_add,
            titulo: 'Profesores',
            indice: 3,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(3),
          ),
          
          SizedBox(height: esCompacto ? 8 : AppConstants.defaultPadding),
          
          // Sección Gestión Académica
          if (!esCompacto) const _SeccionMenu('GESTIÓN ACADÉMICA'),
          _ItemMenu(
            icono: Icons.book,
            titulo: 'Cursos',
            indice: 4,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(4),
          ),
          _ItemMenu(
            icono: Icons.school_outlined,
            titulo: 'Carreras',
            indice: 5,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(5),
          ),
          _ItemMenu(
            icono: Icons.event_note,
            titulo: 'Extras',
            indice: 6,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(6),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
      ..add(ObjectFlagProperty<Function(int p1)>.has('onItemSeleccionado', onItemSeleccionado));
  }
}

class _MenuNavegacionMovil extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionAdminProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ItemMenuMovil(
          icono: Icons.dashboard,
          titulo: 'Panel Principal',
          indice: 0,
          esActivo: indiceActual == 0,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 0 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 0;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.people,
          titulo: 'Estudiantes',
          indice: 1,
          esActivo: indiceActual == 1,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 1 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 1;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.school,
          titulo: 'Matrículas',
          indice: 2,
          esActivo: indiceActual == 2,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 2 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 2;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.person_add,
          titulo: 'Profesores',
          indice: 3,
          esActivo: indiceActual == 3,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 3 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 3;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.book,
          titulo: 'Cursos',
          indice: 4,
          esActivo: indiceActual == 4,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 4 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 4;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.school_outlined,
          titulo: 'Carreras',
          indice: 5,
          esActivo: indiceActual == 5,
          onTap: () {
            debugPrint('📱 MenuNavegacionMovil: Item 5 seleccionado');
            ref.read(indiceNavegacionAdminProvider.notifier).state = 5;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _SeccionMenu extends StatelessWidget {

  const _SeccionMenu(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppConstants.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('titulo', titulo));
  }
}

class _ItemMenu extends ConsumerWidget {

  const _ItemMenu({
    required this.icono,
    required this.titulo,
    required this.indice,
    this.esCompacto = false,
    required this.onTap,
  });
  final IconData icono;
  final String titulo;
  final int indice;
  final bool esCompacto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionAdminProvider);
    final esActivo = indiceActual == indice;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: esActivo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: () {
            debugPrint('🖱️ ItemMenu: Clicked $titulo (índice: $indice)');
            onTap();
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: esCompacto ? 8 : AppConstants.defaultPadding,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icono,
                  size: 18,
                  color: esActivo
                      ? AppConstants.primaryColor
                      : AppConstants.textSecondary,
                ),
                if (!esCompacto) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: esActivo ? FontWeight.w600 : FontWeight.normal,
                      color: esActivo
                          ? AppConstants.primaryColor
                            : AppConstants.textSecondary,
                    ),
                  ),
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(StringProperty('titulo', titulo))
      ..add(IntProperty('indice', indice))
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}

class _ItemMenuMovil extends StatelessWidget {

  const _ItemMenuMovil({
    required this.icono,
    required this.titulo,
    required this.indice,
    required this.esActivo,
    required this.onTap,
  });
  final IconData icono;
  final String titulo;
  final int indice;
  final bool esActivo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: esActivo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icono,
                  size: 20,
                  color: esActivo
                      ? AppConstants.primaryColor
                      : AppConstants.textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: esActivo ? FontWeight.w600 : FontWeight.normal,
                      color: esActivo
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('titulo', titulo))
      ..add(IntProperty('indice', indice))
      ..add(DiagnosticsProperty<bool>('esActivo', esActivo))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}



class _InfoUsuario extends StatelessWidget {

  const _InfoUsuario({this.esCompacto = false});
  final bool esCompacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(esCompacto ? 12 : AppConstants.defaultPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(
            nombreCompleto: 'Administrador',
            tipoUsuario: 'admin',
            radio: esCompacto ? 16 : 20,
          ),
          if (!esCompacto) ...[
            const SizedBox(width: 12),
            const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrador',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('esCompacto', esCompacto));
  }
}

class _InfoUsuarioMovil extends StatelessWidget {
  const _InfoUsuarioMovil();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: const Row(
        children: [
          AvatarWidget(
            nombreCompleto: 'Administrador',
            tipoUsuario: 'admin',
            radio: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  'admin@unamad.edu.pe',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {

  const _AccesoRapido({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.onTap,
  });
  final String titulo;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          debugPrint('🚀 AccesoRapido: Navegando a $titulo');
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('titulo', titulo))
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(ColorProperty('color', color))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
} 