import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/providers/profesor/cursos.profesor.riverpod.dart' as cursos_riverpod;
import 'package:aulago/screens/profesor/cursos.profesor.screen.dart';
import 'package:aulago/screens/profesor/widgets/calificaciones.profesor.widget.dart';
import 'package:aulago/screens/profesor/widgets/estudiantes.profesor.widget.dart';
import 'package:aulago/screens/profesor/widgets/examenes.profesor.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moony_nav_bar/moony_nav_bar.dart';

// Provider para manejar el índice de la página actual del profesor
final indiceNavegacionProfesorProvider = StateProvider<int>((ref) => 0);

class ProfesorLayout extends ConsumerStatefulWidget {

  const ProfesorLayout({
    super.key,
    required this.titulo,
  });
  final String titulo;

  @override
  ConsumerState<ProfesorLayout> createState() => _ProfesorLayoutState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('titulo', titulo));
  }
}

class _ProfesorLayoutState extends ConsumerState<ProfesorLayout> {
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Inicializar el provider en 0 (página de inicio)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(indiceNavegacionProfesorProvider.notifier).state = 0;
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
        return 'Inicio';
      case 1:
        return 'Mis Cursos';
      case 2:
        return 'Calificaciones';
      case 3:
        return 'Estudiantes';
      case 4:
        return 'Tareas';
      default:
        return 'Panel del Profesor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoAuth = ref.watch(proveedorAuthProvider);
    final indiceActual = ref.watch(indiceNavegacionProfesorProvider);
    final esMovil = MediaQuery.of(context).size.width < 768;
    final esTablet = MediaQuery.of(context).size.width < 1024;

    debugPrint('📱 ProfesorLayout: Build - esMovil: $esMovil, esTablet: $esTablet, indiceActual: $indiceActual');

    if (!estadoAuth.estaAutenticado || !estadoAuth.usuario!.esProfesor) {
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
    final usuario = ref.watch(proveedorAuthProvider).usuario!;
    
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              debugPrint('🔔 ProfesorLayout: Botón notificaciones presionado');
            },
            tooltip: 'Notificaciones',
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              radius: 16,
              child: Text(
                usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      drawer: _buildDrawerMovil(usuario),
      body: PageView(
        controller: _pageController,
        onPageChanged: (indice) {
          debugPrint('📄 ProfesorLayout: Página cambiada a índice: $indice');
          ref.read(indiceNavegacionProfesorProvider.notifier).state = indice;
        },
        children: _obtenerPaginas(),
      ),
      bottomNavigationBar: _buildBottomNavigation(indiceActual),
    );
  }

  Widget _buildLayoutDesktop(int indiceActual, bool esTablet) {
    final usuario = ref.watch(proveedorAuthProvider).usuario!;
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          _SidebarProfesor(
            usuario: usuario,
            esTablet: esTablet,
            onItemSeleccionado: (indice) {
              debugPrint('📂 ProfesorLayout: Item sidebar seleccionado: $indice');
              _pageController.animateToPage(
                indice,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              ref.read(indiceNavegacionProfesorProvider.notifier).state = indice;
            },
          ),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header superior
                _HeaderProfesor(
                  titulo: _obtenerTituloPorIndice(indiceActual),
                  usuario: usuario,
                ),
                
                // Contenido de la página
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (indice) {
                      debugPrint('📄 ProfesorLayout: Página desktop cambiada a índice: $indice');
                      ref.read(indiceNavegacionProfesorProvider.notifier).state = indice;
                    },
                    children: _obtenerPaginas(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMovil(usuario) {
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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Profesor',
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
          
          // Menú de navegación
          Expanded(
            child: _MenuNavegacionMovil(),
          ),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const Text(
              'Portal del Profesor - UNAMAD',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int indiceActual) {
    return MoonyNavigationBar(
      items: <NavigationBarItem>[
        NavigationBarItem(
          icon: Icons.home_rounded,
          onTap: () {
            debugPrint('📱 ProfesorLayout: Moony navigation tapped: 0');
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 0;
          },
        ),
        NavigationBarItem(
          icon: Icons.book_outlined,
          activeIcon: Icons.book,
          onTap: () {
            debugPrint('📱 ProfesorLayout: Moony navigation tapped: 1');
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 1;
          },
        ),
        NavigationBarItem(
          icon: Icons.grade_outlined,
          activeIcon: Icons.grade,
          onTap: () {
            debugPrint('📱 ProfesorLayout: Moony navigation tapped: 2');
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 2;
          },
        ),
        NavigationBarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          onTap: () {
            debugPrint('📱 ProfesorLayout: Moony navigation tapped: 3');
            _pageController.animateToPage(
              3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 3;
          },
        ),
        NavigationBarItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          onTap: () {
            debugPrint('📱 ProfesorLayout: Moony navigation tapped: 4');
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 4;
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
    return [
      _PaginaProfesorWrapper(child: _construirPaginaInicio()),
      _PaginaProfesorWrapper(child: _construirPaginaCursos()),
      _PaginaProfesorWrapper(child: _construirPaginaCalificaciones()),
      _PaginaProfesorWrapper(child: _construirPaginaEstudiantes()),
      _PaginaProfesorWrapper(child: _construirPaginaTareas()),
      _PaginaProfesorWrapper(child: _construirPaginaExamenes()),
    ];
  }

  // Constructores de páginas
  Widget _construirPaginaInicio() {
    // Reutilizar el contenido existente de home.profesor.screen.dart
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${err.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(
            child: Text('No tienes cursos asignados actualmente.'),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: cursos.length,
          itemBuilder: (context, index) {
            final curso = cursos[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          curso.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          curso.codigoCurso,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaGestionCurso(curso: curso),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.arrowRight, size: 16),
                          label: const Text('Gestionar'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirPaginaCursos() {
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    
    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${err.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tienes cursos asignados',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Los cursos aparecerán aquí cuando te asignen materias',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header con estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _EstadisticaCurso(
                      icono: Icons.book,
                      titulo: 'Total Cursos',
                      valor: cursos.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _EstadisticaCurso(
                      icono: Icons.schedule,
                      titulo: 'Período',
                      valor: '2025-I', // TODO: Obtener período actual
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _EstadisticaCurso(
                      icono: Icons.people,
                      titulo: 'Estudiantes',
                      valor: '24', // TODO: Calcular total de estudiantes
                    ),
                  ),
                ],
              ),
            ),

            // Lista de cursos expandida
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cursos.length,
                itemBuilder: (context, index) {
                  final curso = cursos[index];
                  return CursoCardWidget(curso: curso);
                },
                                      ),
                                    ),
                                  ],
        );
      },
    );
  }

  Widget _construirPaginaCalificaciones() {
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    final ValueNotifier<String?> cursoSeleccionadoId = ValueNotifier<String?>(null);

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${err.toString()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(child: Text('No tienes cursos asignados.'));
        }
        return ValueListenableBuilder<String?>(
          valueListenable: cursoSeleccionadoId,
          builder: (context, cursoId, _) {
            final cursoInicial = cursoId ?? cursos.first.id;
            if (cursoSeleccionadoId.value == null) {
              cursoSeleccionadoId.value = cursoInicial;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: cursoInicial,
                    isExpanded: true,
                    items: cursos.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.nombre} (${c.codigoCurso})'),
                    )).toList(),
                    onChanged: (nuevoId) {
                      if (nuevoId != null) {
                        cursoSeleccionadoId.value = nuevoId;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: CalificacionesTab(cursoId: cursoInicial),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirPaginaEstudiantes() {
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    final ValueNotifier<String?> cursoSeleccionadoId = ValueNotifier<String?>(null);
    
    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${err.toString()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(child: Text('No tienes cursos asignados.'));
        }
        return ValueListenableBuilder<String?>(
          valueListenable: cursoSeleccionadoId,
          builder: (context, cursoId, _) {
            final cursoInicial = cursoId ?? cursos.first.id;
            if (cursoSeleccionadoId.value == null) {
              cursoSeleccionadoId.value = cursoInicial;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: cursoInicial,
                    isExpanded: true,
                    items: cursos.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.nombre} (${c.codigoCurso})'),
                    )).toList(),
                    onChanged: (nuevoId) {
                      if (nuevoId != null) {
                        cursoSeleccionadoId.value = nuevoId;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: EstudiantesTab(cursoId: cursoInicial),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirPaginaTareas() {
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    // Estado local para el curso seleccionado
    final ValueNotifier<String?> cursoSeleccionadoId = ValueNotifier<String?>(null);

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${err.toString()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(child: Text('No tienes cursos asignados.'));
        }
        return ValueListenableBuilder<String?>(
          valueListenable: cursoSeleccionadoId,
          builder: (context, cursoId, _) {
            final cursoInicial = cursoId ?? cursos.first.id;
            if (cursoSeleccionadoId.value == null) {
              cursoSeleccionadoId.value = cursoInicial;
            }
            return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: cursoInicial,
                    isExpanded: true,
                    items: cursos.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.nombre} (${c.codigoCurso})'),
                    )).toList(),
                    onChanged: (nuevoId) {
                      if (nuevoId != null) {
                        cursoSeleccionadoId.value = nuevoId;
                      }
                    },
                  ),
                ),
                            Expanded(
                  child: TareasTab(cursoId: cursoInicial),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _construirPaginaExamenes() {
    final cursosAsync = ref.watch(cursos_riverpod.cursosProfesorProvider);
    final ValueNotifier<String?> cursoSeleccionadoId = ValueNotifier<String?>(null);

    return cursosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${err.toString()}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(cursos_riverpod.cursosProfesorProvider),
              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
      ),
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(child: Text('No tienes cursos asignados.'));
        }
        return ValueListenableBuilder<String?>(
          valueListenable: cursoSeleccionadoId,
          builder: (context, cursoId, _) {
            final cursoInicial = cursoId ?? cursos.first.id;
            if (cursoSeleccionadoId.value == null) {
              cursoSeleccionadoId.value = cursoInicial;
            }
            return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: cursoInicial,
                    isExpanded: true,
                    items: cursos.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.nombre} (${c.codigoCurso})'),
                    )).toList(),
                    onChanged: (nuevoId) {
                      if (nuevoId != null) {
                        cursoSeleccionadoId.value = nuevoId;
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ExamenesTab(cursoId: cursoInicial),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _manejarMenuUsuario(BuildContext context, String accion) {
    debugPrint('👤 ProfesorLayout: Acción de menú de usuario: $accion');
    if (accion == 'logout') {
      ref.read(proveedorAuthProvider.notifier).cerrarSesion();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

// Widget auxiliar para mostrar estadísticas de cursos
class _EstadisticaCurso extends StatelessWidget {

  const _EstadisticaCurso({
    required this.icono,
    required this.titulo,
    required this.valor,
  });
  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icono,
          size: 28,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('titulo', titulo))
    ..add(StringProperty('valor', valor));
  }
}

// Widget auxiliar para mostrar información
class _InfoItem extends StatelessWidget {

  const _InfoItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });
  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icono,
              size: 14,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('titulo', titulo))
    ..add(StringProperty('valor', valor));
  }
}

// Wrapper para las páginas
class _PaginaProfesorWrapper extends StatelessWidget {

  const _PaginaProfesorWrapper({required this.child});
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
}

// Sidebar para desktop
class _SidebarProfesor extends ConsumerWidget {

  const _SidebarProfesor({
    required this.usuario,
    required this.esTablet,
    required this.onItemSeleccionado,
  });
  final dynamic usuario;
  final bool esTablet;
  final Function(int) onItemSeleccionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionProfesorProvider);

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
          Container(
            padding: EdgeInsets.all(esTablet ? 16 : 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: esTablet ? 20 : 30,
                  backgroundColor: AppConstants.primaryColor,
                  child: Text(
                    usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : 'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: esTablet ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!esTablet) ...[
                  const SizedBox(height: 12),
                  Text(
                    usuario.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Profesor',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Menú de navegación
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: esTablet ? 8 : 16),
              child: Column(
                children: [
                  _ItemMenu(
                    icono: Icons.home,
                    titulo: esTablet ? 'Inicio' : 'Inicio',
                    indice: 0,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 0,
                    onTap: () => onItemSeleccionado(0),
                  ),
                  _ItemMenu(
                    icono: Icons.book,
                    titulo: 'Cursos',
                    indice: 1,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 1,
                    onTap: () => onItemSeleccionado(1),
                  ),
                  _ItemMenu(
                    icono: Icons.grade,
                    titulo: 'Calificaciones',
                    indice: 2,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 2,
                    onTap: () => onItemSeleccionado(2),
                  ),
                  _ItemMenu(
                    icono: Icons.people,
                    titulo: 'Estudiantes',
                    indice: 3,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 3,
                    onTap: () => onItemSeleccionado(3),
                  ),
                  _ItemMenu(
                    icono: Icons.assignment,
                    titulo: 'Tareas',
                    indice: 4,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 4,
                    onTap: () => onItemSeleccionado(4),
                  ),
                  _ItemMenu(
                    icono: Icons.assignment,
                    titulo: 'Exámenes',
                    indice: 5,
                    esCompacto: esTablet,
                    esActivo: indiceActual == 5,
                    onTap: () => onItemSeleccionado(5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('usuario', usuario))
    ..add(DiagnosticsProperty<bool>('esTablet', esTablet))
    ..add(ObjectFlagProperty<Function(int p1)>.has('onItemSeleccionado', onItemSeleccionado));
  }
}

// Header para desktop
class _HeaderProfesor extends ConsumerWidget {

  const _HeaderProfesor({
    required this.titulo,
    required this.usuario,
  });
  final String titulo;
  final dynamic usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const Text(
                  'Portal del Profesor - UNAMAD',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  debugPrint('🔔 HeaderProfesor: Botón notificaciones presionado');
                },
                tooltip: 'Notificaciones',
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                child: CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  child: Text(
                    usuario.nombreCompleto.isNotEmpty ? usuario.nombreCompleto[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Cerrar Sesión'),
                    ),
                  ),
                ],
                onSelected: (valor) => _manejarMenuUsuario(context, ref, valor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _manejarMenuUsuario(BuildContext context, WidgetRef ref, String accion) {
    if (accion == 'logout') {
      ref.read(proveedorAuthProvider.notifier).cerrarSesion();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('titulo', titulo))
    ..add(DiagnosticsProperty('usuario', usuario));
  }
}

// Item de menú
class _ItemMenu extends StatelessWidget {

  const _ItemMenu({
    required this.icono,
    required this.titulo,
    required this.indice,
    this.esCompacto = false,
    required this.esActivo,
    required this.onTap,
  });
  final IconData icono;
  final String titulo;
  final int indice;
  final bool esCompacto;
  final bool esActivo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: esActivo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: esCompacto ? 8 : 16,
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
    properties..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('titulo', titulo))
    ..add(IntProperty('indice', indice))
    ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
    ..add(DiagnosticsProperty<bool>('esActivo', esActivo));
  }
}

// Menú de navegación móvil
class _MenuNavegacionMovil extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionProfesorProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ItemMenuMovil(
          icono: Icons.home,
          titulo: 'Inicio',
          indice: 0,
          esActivo: indiceActual == 0,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 0;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.book,
          titulo: 'Mis Cursos',
          indice: 1,
          esActivo: indiceActual == 1,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 1;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.grade,
          titulo: 'Calificaciones',
          indice: 2,
          esActivo: indiceActual == 2,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 2;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.people,
          titulo: 'Estudiantes',
          indice: 3,
          esActivo: indiceActual == 3,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 3;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.assignment,
          titulo: 'Tareas',
          indice: 4,
          esActivo: indiceActual == 4,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 4;
            Navigator.of(context).pop();
          },
        ),
        _ItemMenuMovil(
          icono: Icons.assignment,
          titulo: 'Exámenes',
          indice: 5,
          esActivo: indiceActual == 5,
          onTap: () {
            ref.read(indiceNavegacionProfesorProvider.notifier).state = 5;
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// Item de menú móvil
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
    properties..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('titulo', titulo))
    ..add(IntProperty('indice', indice))
    ..add(DiagnosticsProperty<bool>('esActivo', esActivo))
    ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}
