import 'package:aulago/models/foro.model.dart';
import 'package:aulago/repositories/base.repository.dart';

class ForoRepository extends BaseRepository<Foro> {
  @override
  String get tableName => 'foros';

  @override
  String get repositoryName => 'ForoRepository';

  @override
  Foro fromJson(Map<String, dynamic> json) => Foro.fromJson(json);

  @override
  Map<String, dynamic> toJson(Foro entity) => entity.toJson();

  @override
  String getId(Foro entity) => entity.id.toString();

  // CRUD básico delegando en BaseRepository
  Future<List<Foro>> obtenerForos() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<Foro?> obtenerForoPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<Foro> crearForo(Foro foro) async {
    return crear(foro.toJson());
  }

  Future<Foro> actualizarForo(int id, Foro foro) async {
    return actualizar(id.toString(), foro.toJson());
  }

  Future<bool> eliminarForo(int id) async {
    await eliminar(id.toString());
    return true;
  }
}