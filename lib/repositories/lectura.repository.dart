import 'package:aulago/models/lectura.model.dart';
import 'package:aulago/repositories/base.repository.dart';

class LecturaRepository extends BaseRepository<Lectura> {
  @override
  String get tableName => 'lecturas';

  @override
  String get repositoryName => 'LecturaRepository';

  @override
  Lectura fromJson(Map<String, dynamic> json) => Lectura.fromJson(json);

  @override
  Map<String, dynamic> toJson(Lectura entity) => entity.toJson();

  @override
  String getId(Lectura entity) => entity.id.toString();

  Future<List<Lectura>> obtenerLecturas() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<Lectura> crearLectura(Lectura lectura) async {
    return crear(lectura.toJson());
  }

  Future<Lectura> actualizarLectura(int id, Lectura lectura) async {
    return actualizar(id.toString(), lectura.toJson());
  }

  Future<bool> eliminarLectura(int id) async {
    await eliminar(id.toString());
    return true;
  }
}


