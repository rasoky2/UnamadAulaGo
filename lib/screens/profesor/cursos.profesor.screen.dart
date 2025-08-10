import 'package:aulago/models/curso.model.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/screens/profesor/widgets/calificaciones.profesor.widget.dart';
import 'package:aulago/screens/profesor/widgets/estudiantes.profesor.widget.dart';
import 'package:aulago/screens/profesor/widgets/informacion_tab.widget.dart';
import 'package:aulago/screens/profesor/widgets/tareas.profesor.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

export 'package:aulago/screens/profesor/widgets/tareas.profesor.widget.dart'
    show TareasTab;

final estudiantesCursoCountProvider = FutureProvider.family<int, int>((ref, cursoId) async {
  try {
    final repo = MatriculaRepository();
    final todasMatriculas = await repo.obtenerMatriculas();
    final matriculasCurso = todasMatriculas.where((m) => m.cursoId == cursoId).toList();
    return matriculasCurso.length;
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo estudiantes del curso $cursoId: $e');
    }
    return 0;
  }
});

final tareasCursoCountProvider = FutureProvider.family<int, int>((ref, cursoId) async {
  try {
    final repo = TareaRepository();
    final todasTareas = await repo.obtenerTareas();
    final tareasCurso = todasTareas.where((t) => t.cursoId == cursoId).toList();
    return tareasCurso.length;
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo tareas del curso $cursoId: $e');
    }
    return 0;
  }
});

final examenesCursoCountProvider = FutureProvider.family<int, int>((ref, cursoId) async {
  try {
    final repo = ExamenRepository();
    final todosExamenes = await repo.obtenerExamenes();
    final examenesCurso = todosExamenes.where((e) => e.cursoId == cursoId).toList();
    return examenesCurso.length;
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo exámenes del curso $cursoId: $e');
    }
    return 0;
  }
});

final unidadesCursoCountProvider = FutureProvider.family<int, int>((ref, cursoId) async {
  try {
    // Crear una instancia temporal de BaseRepository para acceder al cliente
    final tempRepo = TareaRepository(); // Usamos TareaRepository como base
    final response = await tempRepo.supabase
        .from('unidades_curso')
        .select('id')
        .eq('curso_id', cursoId);
    
    return response.length;
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo unidades del curso $cursoId: $e');
    }
    return 0;
  }
});

class PantallaGestionCurso extends ConsumerStatefulWidget {
  const PantallaGestionCurso({super.key, required this.curso});
  final ModeloCurso curso;

  @override
  ConsumerState<PantallaGestionCurso> createState() =>
      _PantallaGestionCursoState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCurso>('curso', curso));
  }
}

class _PantallaGestionCursoState extends ConsumerState<PantallaGestionCurso>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.curso.nombre, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(LucideIcons.bookCheck), text: 'Tareas'),
            Tab(icon: Icon(LucideIcons.users), text: 'Estudiantes'),
            Tab(icon: Icon(LucideIcons.graduationCap), text: 'Calificaciones'),
            Tab(icon: Icon(LucideIcons.info), text: 'Información'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TareasTab(cursoId: widget.curso.id.toString()),
          EstudiantesTab(cursoId: widget.curso.id.toString()),
          CalificacionesTab(cursoId: widget.curso.id.toString()),
          const InformacionTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref),
    );
  }
  
  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
     if (_tabController.index == 0) {
       return FloatingActionButton.extended(
        onPressed: () => mostrarDialogoTarea(context, ref, widget.curso.id.toString()),
        label: const Text('Crear Tarea'),
        icon: const Icon(LucideIcons.plus),
      );
     }
     return null;
  }
}

class CursoCardWidget extends ConsumerWidget {
  const CursoCardWidget({super.key, required this.curso});
  final ModeloCurso curso;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiantesCount = ref.watch(estudiantesCursoCountProvider(curso.id));
    final tareasCount = ref.watch(tareasCursoCountProvider(curso.id));
    final examenesCount = ref.watch(examenesCursoCountProvider(curso.id));
    final unidadesCount = ref.watch(unidadesCursoCountProvider(curso.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.book,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          curso.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              curso.codigoCurso,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Primera fila de estadísticas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: estudiantesCount.when(
                            data: (count) => Text('$count estudiantes', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            loading: () => const SizedBox(width: 40, height: 12, child: LinearProgressIndicator()),
                            error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: unidadesCount.when(
                            data: (count) => Text('$count unidades', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            loading: () => const SizedBox(width: 30, height: 12, child: LinearProgressIndicator()),
                            error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Segunda fila de estadísticas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: tareasCount.when(
                            data: (count) => Text('$count tareas', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            loading: () => const SizedBox(width: 30, height: 12, child: LinearProgressIndicator()),
                            error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 14,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: examenesCount.when(
                            data: (count) => Text('$count exámenes', style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            loading: () => const SizedBox(width: 30, height: 12, child: LinearProgressIndicator()),
                            error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCurso>('curso', curso));
  }
}
