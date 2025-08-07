import 'package:aulago/models/curso.model.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/examen.repository.dart';
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

final estudiantesCursoCountProvider = FutureProvider.family<int, String>((ref, cursoId) async {
  final repo = EstudianteRepository();
  final estudiantes = await repo.obtenerEstudiantesPorCurso(cursoId);
  return estudiantes.length;
});

final tareasCursoCountProvider = FutureProvider.family<int, String>((ref, cursoId) async {
  final repo = TareaRepository();
  final tareas = await repo.obtenerTareas(cursoId: cursoId);
  return tareas.length;
});

final examenesCursoCountProvider = FutureProvider.family<int, String>((ref, cursoId) async {
  final repo = ExamenRepository();
  final examenes = await repo.obtenerExamenesPorCurso(cursoId);
  return examenes.length;
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
          TareasTab(cursoId: widget.curso.id),
          EstudiantesTab(cursoId: widget.curso.id),
          CalificacionesTab(cursoId: widget.curso.id),
          const InformacionTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref),
    );
  }
  
  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
     if (_tabController.index == 0) {
       return FloatingActionButton.extended(
        onPressed: () => mostrarDialogoTarea(context, ref, widget.curso.id),
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
            Row(
              children: [
                Container(
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
                      estudiantesCount.when(
                        data: (count) => Text('$count estudiantes', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                        loading: () => const SizedBox(width: 40, height: 12, child: LinearProgressIndicator()),
                        error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                      tareasCount.when(
                        data: (count) => Text('$count tareas', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                        loading: () => const SizedBox(width: 30, height: 12, child: LinearProgressIndicator()),
                        error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                      examenesCount.when(
                        data: (count) => Text('$count exámenes', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500)),
                        loading: () => const SizedBox(width: 30, height: 12, child: LinearProgressIndicator()),
                        error: (e, _) => const Text('-', style: TextStyle(color: Colors.red)),
                      ),
                    ],
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
