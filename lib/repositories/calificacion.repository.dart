import 'package:aulago/models/calificacion.model.dart';
import 'package:aulago/repositories/base.repository.dart';

class CalificacionRepository extends BaseRepository<Calificacion> {
  @override
  String get tableName => 'calificaciones';

  @override
  String get repositoryName => 'CalificacionRepository';

  @override
  Calificacion fromJson(Map<String, dynamic> json) => Calificacion.fromJson(json);

  @override
  Map<String, dynamic> toJson(Calificacion entity) => entity.toJson();

  @override
  String getId(Calificacion entity) => entity.id.toString();

  // CRUD básico
  Future<List<Calificacion>> obtenerCalificaciones() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<Calificacion?> obtenerCalificacionPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<Calificacion> crearCalificacion(Calificacion calificacion) async {
    return crear(calificacion.toJson());
  }

  Future<Calificacion> actualizarCalificacion(int id, Calificacion calificacion) async {
    return actualizar(id.toString(), calificacion.toJson());
  }

  Future<bool> eliminarCalificacion(int id) async {
    await eliminar(id.toString());
    return true;
  }
}
