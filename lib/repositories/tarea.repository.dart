import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/base.repository.dart';

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

  Future<ModeloTarea?> obtenerTareaPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloTarea> crearTarea(ModeloTarea tarea) async {
    return crear(tarea.toJson());
  }

  Future<ModeloTarea> actualizarTarea(int id, ModeloTarea tarea) async {
    return actualizar(id.toString(), tarea.toJson());
  }

  Future<bool> eliminarTarea(int id) async {
    await eliminar(id.toString());
    return true;
  }
}
