import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que obtiene las tareas para un grupo de clase específico.
/// Usado por la vista del profesor.
final tareasProvider =
    FutureProvider.family<List<ModeloTarea>, String>((ref, cursoId) async {
  // Usamos el repositorio en lugar de acceso directo a Supabase
  final repository = ref.read(tareaRepositoryProvider);
  return repository.obtenerTareas(cursoId: cursoId);
});

/// Provider que obtiene todas las tareas de los cursos en los que
/// el alumno actual está matriculado.
final tareasAlumnoProvider = FutureProvider<List<ModeloTarea>>((ref) async {
  // Observa el provider que ya obtiene los cursos del alumno (con las tareas incluidas)
  final cursosDetalladosAsyncValue = ref.watch(cursosAlumnoProvider);

  return cursosDetalladosAsyncValue.when(
    data: (cursosDetallados) {
      // Aplanamos la lista de tareas de todos los cursos detallados
      final todasLasTareas = cursosDetallados
          .where((detalle) => detalle.tareas != null && detalle.tareas!.isNotEmpty)
          .expand((detalle) => detalle.tareas!)
          .toList()

      // Opcional: ordenar las tareas por fecha de entrega
      ..sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));

      return todasLasTareas;
    },
    loading: () => [], // Devuelve una lista vacía mientras carga
    error: (err, stack) {
      // Manejar el error, tal vez registrarlo o devolver una lista vacía
      debugPrint('Error al obtener tareas del alumno: $err');
      return [];
    },
  );
});

/// Provider que obtiene tareas con entregas para un estudiante específico
final tareasConEntregasProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String grupoClaseId, String estudianteId})>((ref, params) async {
  final repository = ref.read(tareaRepositoryProvider);
  return repository.obtenerTareasConEntregas();
});

/// Provider que obtiene una tarea específica por ID
final tareaDetalleProvider = FutureProvider.family<ModeloTarea?, String>((ref, tareaId) async {
  final repository = ref.read(tareaRepositoryProvider);
  return repository.obtenerTareaPorId(tareaId);
}); 