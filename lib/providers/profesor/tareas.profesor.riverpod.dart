import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el Repositorio
final tareaProfesorRepositoryProvider = Provider((ref) => TareaRepository());

// StateNotifierProvider para gestionar el estado y las acciones por cursoId
final tareasProfesorProvider = StateNotifierProvider.family<
    TareasProfesorNotifier, AsyncValue<List<ModeloTarea>>, String>((ref, cursoId) {
  final repository = ref.watch(tareaProfesorRepositoryProvider);
  return TareasProfesorNotifier(repository, cursoId);
});

// StateNotifier actualizado para trabajar solo con cursoId
class TareasProfesorNotifier extends StateNotifier<AsyncValue<List<ModeloTarea>>> {

  TareasProfesorNotifier(this._repository, this._cursoId) : super(const AsyncLoading()) {
    _cargarTareas();
  }
  final TareaRepository _repository;
  final String _cursoId;

  Future<void> _cargarTareas() async {
    try {
      final tareas = await _repository.obtenerTareas(cursoId: _cursoId);
      state = AsyncData(tareas);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> crearTarea(Map<String, dynamic> datos) async {
    state = const AsyncLoading();
    try {
      await _repository.crearTarea({...datos, 'curso_id': _cursoId});
      await _cargarTareas();
    } catch (e, s) {
      state = AsyncError(e, s);
      throw Exception('Error al crear la tarea: $e'); 
    }
  }

  Future<void> actualizarTarea(String id, Map<String, dynamic> datos) async {
    state = const AsyncLoading();
    try {
      await _repository.actualizarTarea(id, {...datos, 'curso_id': _cursoId});
      await _cargarTareas();
    } catch (e, s) {
      state = AsyncError(e, s);
      throw Exception('Error al actualizar la tarea: $e');
    }
  }
  
  void refrescar() {
    _cargarTareas();
  }
}
 