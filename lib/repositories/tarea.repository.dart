import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

class TareaRepository extends BaseRepository<ModeloTarea> {
  @override
  String get tableName => 'tareas';
  
  @override
  String get repositoryName => 'TareaRepository';
  
  @override
  ModeloTarea fromJson(Map<String, dynamic> json) {
    return ModeloTarea.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloTarea entity) {
    return entity.toJson();
  }

  @override
  String getId(ModeloTarea entity) {
    return entity.id.toString();
  }

  // CRUD básico
  Future<List<ModeloTarea>> obtenerTareas() async {
    final result = await obtener();
    return result.items;
  }

  Future<List<ModeloTarea>> obtenerTareasPorCurso(int cursoId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select()
          .eq('curso_id', cursoId)
          .order('fecha_entrega', ascending: true);
      
      return (response as List).map((json) => fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error al obtener tareas por curso: $e');
      rethrow;
    }
  }

  Future<ModeloTarea?> obtenerTareaPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloTarea> crearTarea(ModeloTarea tarea) async {
    // Para crear, solo enviamos los campos editables
    return crear(tarea.toJsonEditable());
  }

  Future<ModeloTarea> actualizarTarea(int id, ModeloTarea tarea) async {
    // Para actualizar, solo enviamos los campos editables
    return actualizar(id.toString(), tarea.toJsonEditable());
  }

  Future<bool> eliminarTarea(int id) async {
    await eliminar(id.toString());
    return true;
  }
}
