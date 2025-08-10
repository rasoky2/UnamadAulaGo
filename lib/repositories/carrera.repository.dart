import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/repositories/base.repository.dart';

/// Repositorio para gestión de carreras
class CarreraRepository extends BaseRepository<ModeloCarrera> {
  @override
  String get tableName => 'carreras';
  
  @override
  String get repositoryName => 'CarreraRepository';
  
  @override
  ModeloCarrera fromJson(Map<String, dynamic> json) {
    return ModeloCarrera.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloCarrera entity) {
    return {
      'id': entity.id,
      'codigo': entity.codigo,
      'nombre': entity.nombre,
      'descripcion': entity.descripcion,
      'duracion_semestres': entity.duracionSemestres,
      'director_nombre': entity.directorNombre,
      'director_email': entity.directorEmail,
      'facultad_id': entity.facultadId,
      'fecha_creacion': entity.fechaCreacion.toIso8601String(),
    };
  }

  @override
  String getId(ModeloCarrera entity) {
    return entity.id.toString();
  }

  // CRUD básico
  Future<List<ModeloCarrera>> obtenerCarreras() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<ModeloCarrera?> obtenerCarreraPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloCarrera> crearCarrera(ModeloCarrera carrera) async {
    return crear(carrera.toJson());
  }

  Future<ModeloCarrera> actualizarCarrera(int id, ModeloCarrera carrera) async {
    return actualizar(id.toString(), carrera.toJson());
  }

  Future<bool> eliminarCarrera(int id) async {
    await eliminar(id.toString());
    return true;
  }
}
