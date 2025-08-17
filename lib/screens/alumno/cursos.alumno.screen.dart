import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/screens/alumno/alumno.layout.dart';
import 'package:aulago/screens/alumno/widgets/calendario.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/examenes.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/foros.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/lecturas.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/tareas.widget.dart';
import 'package:aulago/screens/alumno/widgets/unidades.widget.dart';
import 'package:aulago/screens/alumno/widgets/wiki.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moony_nav_bar/moony_nav_bar.dart';

// Provider para manejar el índice de navegación en los cursos del alumno
final indiceNavegacionCursoAlumnoProvider = StateProvider<int>((ref) => 0);

// Importamos el provider del layout principal
// final cursoSeleccionadoAlumnoProvider se define en alumno.layout.dart

class PantallaCursosAlumno extends ConsumerStatefulWidget {
  const PantallaCursosAlumno({super.key, this.initialCursoId});
  final int? initialCursoId;

  @override
  ConsumerState<PantallaCursosAlumno> createState() => _PantallaCursosAlumnoState();
}

class _PantallaCursosAlumnoState extends ConsumerState<PantallaCursosAlumno> {
  final CursoRepository _repo = CursoRepository();
  late Future<List<ModeloCursoDetallado>> _cursosFuture;
  late PageController _pageController;
  
  void _regresar() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = null;
    ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 0;
    ref.read(seccionAlumnoProvider.notifier).state = 0;
  }

  @override
  void initState() {
    super.initState();
    _cursosFuture = _repo.obtenerCursosConProfesor();
    _pageController = PageController();
    
    // Inicializar providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 0;
      if (widget.initialCursoId != null) {
        ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = widget.initialCursoId;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final estudiante = ref.watch(proveedorAuthProvider).usuario;
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    final indiceActual = ref.watch(indiceNavegacionCursoAlumnoProvider);
    final cursoSeleccionadoId = ref.watch(cursoSeleccionadoAlumnoProvider);

    debugPrint('🟢 Curso seleccionado: $cursoSeleccionadoId, Herramienta activa: $indiceActual');

    if (estudiante == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FutureBuilder<List<ModeloCursoDetallado>>(
      future: _cursosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final cursosDetallados = snapshot.data ?? [];

        if (esMovil) {
          // Si no hay curso seleccionado, mostrar lista de cursos
          if (cursoSeleccionadoId == null) {
            return _construirListaCursosMovil(cursosDetallados);
          } 
          // Si hay curso seleccionado, mostrar herramientas con navegación
          else {
            final cursoDetallado = cursosDetallados.firstWhere(
              (c) => c.curso.id == cursoSeleccionadoId,
              orElse: () => cursosDetallados.first,
            );
            return _construirVistaHerramientasMovil(cursoDetallado);
          }
        } else {
          // Desktop: mostrar interfaz completa
          return _construirVistaDesktop(cursosDetallados);
        }
      },
    );
  }

  // Método para construir la lista de cursos en móvil
  Widget _construirListaCursosMovil(List<ModeloCursoDetallado> cursosDetallados) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Selecciona un curso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          ...cursosDetallados.map((cursoDetallado) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _construirTarjetaCursoMovil(context, cursoDetallado),
          )),
        ],
      ),
    );
  }

  // Método para construir la vista de herramientas en móvil con navegación
  Widget _construirVistaHerramientasMovil(ModeloCursoDetallado cursoDetallado) {
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(cursoDetallado.curso.nombre),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _regresar,
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (indice) {
          ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = indice;
        },
        children: _obtenerPaginasHerramientas(cursoDetallado.curso.id),
      ),
      bottomNavigationBar: _construirBottomNavigation(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _regresar,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.home),
        label: const Text('Inicio'),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Método para construir la vista de desktop
  Widget _construirVistaDesktop(List<ModeloCursoDetallado> cursosDetallados) {
    final cursoSeleccionadoId = ref.watch(cursoSeleccionadoAlumnoProvider);
    
    // Si no hay curso seleccionado, mostrar lista de cursos para seleccionar
    if (cursoSeleccionadoId == null) {
      return _construirSelectorCursosDesktop(cursosDetallados);
    }
    
    if (cursosDetallados.isEmpty) {
      debugPrint('🟠 [DEBUG] No hay cursos disponibles para mostrar.');
      return const Center(child: Text('No tienes cursos disponibles.'));
    }
    
    final ModeloCursoDetallado cursoSeleccionado = cursosDetallados.firstWhere(
      (c) => c.curso.id == cursoSeleccionadoId,
      orElse: () => cursosDetallados.first,
    );
    
    debugPrint('🟣 Mostrando info de curso: ${cursoSeleccionado.curso.nombre}');
    return _construirContenidoCursoDetalle(context, cursoSeleccionado);
  }

  // Método para mostrar selector de cursos en desktop
  Widget _construirSelectorCursosDesktop(List<ModeloCursoDetallado> cursosDetallados) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: GridView.builder(
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
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir tarjeta de curso en desktop
  Widget _construirTarjetaCursoDesktop(ModeloCursoDetallado cursoDetallado) {
    final curso = cursoDetallado.curso;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = curso.id;
          ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 0;
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

  // Método para obtener las páginas de herramientas
  List<Widget> _obtenerPaginasHerramientas(int? cursoId) {
    return [
      UnidadesWidget(
        cursoId: (cursoId ?? 0).toString(),
        onRegresar: () {},
      ),
      const TareasWidget(),
      ExamenesWidget(
        cursoId: (cursoId ?? 0).toString(),
      ),
      ForosWidget(cursoId: (cursoId ?? 0).toString()),
      LecturasAlumnoWidget(cursoId: (cursoId ?? 0).toString()),
      CalendarioWidget(
        onRegresar: () {},
      ),
      WikiWidget(
        onRegresar: () {},
      ),
    ];
  }

  // Método para construir la navegación inferior en móvil
  Widget _construirBottomNavigation() {
    return MoonyNavigationBar(
      items: <NavigationBarItem>[
        NavigationBarItem(
          icon: Icons.book_outlined,
          activeIcon: Icons.book,
          onTap: () {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 0;
          },
        ),
        NavigationBarItem(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          onTap: () {
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 1;
          },
        ),
        NavigationBarItem(
          icon: Icons.quiz_outlined,
          activeIcon: Icons.quiz,
          onTap: () {
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 2;
          },
        ),
        NavigationBarItem(
          icon: Icons.forum_outlined,
          activeIcon: Icons.forum,
          onTap: () {
            _pageController.animateToPage(
              3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 3;
          },
        ),
        NavigationBarItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          onTap: () {
            _pageController.animateToPage(
              4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 4;
          },
        ),
        NavigationBarItem(
          icon: Icons.info_outline,
          activeIcon: Icons.info,
          onTap: () {
            _pageController.animateToPage(
              5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 5;
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

    Widget _construirContenidoCursoDetalle(BuildContext context, ModeloCursoDetallado cursoDetallado) {
    final curso = cursoDetallado.curso;
    return Row(
      children: [
        // Sidebar con herramientas mejorado
        Container(
          width: 300,
          decoration: BoxDecoration(
          color: Colors.white,
              border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
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
              // Botón de regreso
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: _regresar,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  label: const Text(
                    'Regresar a Inicio',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // Información del curso mejorada
        Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF072D3E),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF072D3E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Icono del curso
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nombre del curso
                      Text(
                      curso.nombre,
            style: const TextStyle(
                          color: Colors.white,
                        fontSize: 20,
              fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Código del curso
                    if (curso.codigoCurso.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          curso.codigoCurso,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Información del profesor
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profesor: ${cursoDetallado.profesor?.nombreCompleto ?? 'No asignado'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      ),
                      const SizedBox(height: 8),
                    // Información adicional
                    Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                      Text(
                          '${curso.creditos} créditos',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
          ),
        ],
      ),
                ),
              // Lista de herramientas mejorada
                Expanded(
                  child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
                    // Título de sección
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Herramientas del Curso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                      _construirItemHerramienta('unidades', 'Unidades', Icons.book_outlined),
                      _construirItemHerramienta('tareas', 'Tareas', Icons.assignment_outlined),
                      _construirItemHerramienta('examenes', 'Exámenes', Icons.quiz_outlined),
                      _construirItemHerramienta('foros', 'Foros', Icons.forum_outlined),
                      _construirItemHerramienta('lecturas', 'Lecturas', Icons.menu_book_outlined),
                      _construirItemHerramienta('calendario', 'Calendario', Icons.calendar_today_outlined),
                      _construirItemHerramienta('wiki', 'Wiki', Icons.info_outline),
                    ],
                ),
              ),
            ],
          ),
          ),
          // Área principal de contenido
          Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey.shade50,
            child: Material(
              color: Colors.transparent,
              child: _construirAreaPrincipal(curso.id),
            ),
          ),
        ),
      ],
    );
  }

  // Método para obtener la herramienta por índice
  String _obtenerHerramientaPorIndice(int indice) {
    switch (indice) {
      case 0: return 'unidades';
      case 1: return 'tareas';
      case 2: return 'examenes';
      case 3: return 'foros';
      case 4: return 'lecturas';
      case 5: return 'calendario';
      case 6: return 'wiki';
      default: return 'unidades';
    }
  }

  // Método para obtener el índice por herramienta
  int _obtenerIndicePorHerramienta(String herramienta) {
    switch (herramienta) {
      case 'unidades': return 0;
      case 'tareas': return 1;
      case 'examenes': return 2;
      case 'foros': return 3;
      case 'lecturas': return 4;
      case 'calendario': return 5;
      case 'wiki': return 6;
      default: return 0;
    }
  }

  Widget _construirItemHerramienta(String id, String titulo, IconData icono) {
    final indiceActual = ref.watch(indiceNavegacionCursoAlumnoProvider);
    final herramientaActiva = _obtenerHerramientaPorIndice(indiceActual);
    final isActive = herramientaActiva == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () {
            final nuevoIndice = _obtenerIndicePorHerramienta(id);
            ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = nuevoIndice;
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
              color: isActive 
                ? AppConstants.primaryColor.withValues(alpha: 0.1) 
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                  ? AppConstants.primaryColor 
                  : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
                    children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive 
                      ? AppConstants.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                  icono,
                  color: isActive ? AppConstants.primaryColor : Colors.grey[600],
                  size: 20,
                ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                  titulo,
                        style: TextStyle(
                    color: isActive ? AppConstants.primaryColor : Colors.grey[700],
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppConstants.primaryColor,
                    size: 16,
                      ),
                    ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _construirAreaPrincipal(int? cursoId) {
    final indiceActual = ref.watch(indiceNavegacionCursoAlumnoProvider);
    final herramienta = _obtenerHerramientaPorIndice(indiceActual);

    switch (herramienta) {
      case 'unidades':
        return UnidadesWidget(
          cursoId: (cursoId ?? 0).toString(),
          onRegresar: () {},
        );
      case 'tareas':
        return const TareasWidget();
      case 'examenes':
        return ExamenesWidget(
          cursoId: (cursoId ?? 0).toString(),
        );
      case 'foros':
        return ForosWidget(cursoId: (cursoId ?? 0).toString());
      case 'lecturas':
        return LecturasAlumnoWidget(cursoId: (cursoId ?? 0).toString());
      case 'calendario':
        return CalendarioWidget(
          onRegresar: () {},
        );
      case 'wiki':
        return WikiWidget(
          onRegresar: () {},
        );
      default:
        return UnidadesWidget(
          cursoId: (cursoId ?? 0).toString(),
          onRegresar: () {},
        );
    }
  }

  Widget _construirTarjetaCursoMovil(BuildContext context, ModeloCursoDetallado cursoDetallado) {
    final curso = cursoDetallado.curso;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Seleccionar el curso y navegar a las herramientas
          ref.read(cursoSeleccionadoAlumnoProvider.notifier).state = curso.id;
          ref.read(indiceNavegacionCursoAlumnoProvider.notifier).state = 0;
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  const SizedBox(width: 12),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
              Text(
                'Toca para acceder a las herramientas del curso',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
                  ),
                ),
              ),
    );
  }

} 