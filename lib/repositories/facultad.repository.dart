import 'package:aulago/repositories/base.repository.dart';

class FacultadRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get tableName => 'facultades';
  
  @override
  String get repositoryName => 'FacultadRepository';
  
  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) {
    return json;
  }
  
  @override
  Map<String, dynamic> toJson(Map<String, dynamic> entity) {
    return entity;
  }

  @override
  String getId(Map<String, dynamic> entity) {
    return entity['id'].toString();
  }

  // CRUD básico
  Future<List<Map<String, dynamic>>> obtenerFacultades() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<Map<String, dynamic>?> obtenerFacultadPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<Map<String, dynamic>> crearFacultad(Map<String, dynamic> facultad) async {
    return crear(facultad);
  }

  Future<Map<String, dynamic>> actualizarFacultad(int id, Map<String, dynamic> facultad) async {
    return actualizar(id.toString(), facultad);
  }

  Future<bool> eliminarFacultad(int id) async {
    await eliminar(id.toString());
    return true;
  }
} 