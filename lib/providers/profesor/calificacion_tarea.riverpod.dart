import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Modelo de datos combinado para la vista
class CalificacionTareaData {

  const CalificacionTareaData({
    required this.tarea,
    required this.entregas,
    required this.estudiantes,
  });
  final ModeloTarea tarea;
  final List<ModeloEntrega> entregas;
  final List<EstudianteAdmin> estudiantes;
}

// 2. StateNotifier
class CalificacionTareaNotifier extends StateNotifier<AsyncValue<CalificacionTareaData>> {

  CalificacionTareaNotifier(this._tareaRepo, this._estudianteRepo, this._tareaId)
      : super(const AsyncLoading()) {
    _cargarDatos();
  }
  final TareaRepository _tareaRepo;
  final EstudianteRepository _estudianteRepo;
  final String _tareaId;

  Future<void> _cargarDatos() async {
    state = const AsyncLoading();
    try {
      final tarea = await _tareaRepo.obtenerTareaPorId(_tareaId);
      if (tarea == null) {
        throw Exception('No se pudo encontrar la tarea.');
      }

      final entregas = await _tareaRepo.obtenerEntregasPorTarea(_tareaId);
      final estudiantes = await _estudianteRepo.obtenerEstudiantesPorCurso(tarea.cursoId);

      state = AsyncData(CalificacionTareaData(
        tarea: tarea,
        entregas: entregas,
        estudiantes: estudiantes,
      ));
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> calificar({
    required String estudianteId,
    required double calificacion,
    String? comentario,
    EstadoEntrega? estado,
  }) async {
    try {
      await _tareaRepo.calificarEntrega(
        tareaId: _tareaId,
        estudianteId: estudianteId,
        calificacion: calificacion,
        comentario: comentario,
        estado: estado != null ? estadoEntregaToString(estado) : (calificacion == 0.0 ? estadoEntregaToString(EstadoEntrega.noEntregado) : estadoEntregaToString(EstadoEntrega.calificado)),
      );
      await _cargarDatos(); // Recargar para mostrar la nueva nota
    } catch (e) {
      // Re-lanzar para que la UI lo maneje
      throw Exception('Error al guardar la calificación: $e');
    }
  }

  void refrescar() {
    _cargarDatos();
  }
}

// 3. Provider
final _estudianteRepositoryProvider = Provider((ref) => EstudianteRepository());

final calificacionTareaProvider = StateNotifierProvider.family
    .autoDispose<CalificacionTareaNotifier, AsyncValue<CalificacionTareaData>, String>(
        (ref, tareaId) {
  final tareaRepo = ref.watch(tareaRepositoryProvider);
  final estudianteRepo = ref.watch(_estudianteRepositoryProvider);
  return CalificacionTareaNotifier(tareaRepo, estudianteRepo, tareaId);
}); 