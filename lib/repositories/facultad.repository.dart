import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

/// Repositorio para gestión de facultades
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
    return entity['id'] as String;
  }

  /// Obtener facultades para dropdown
  Future<List<Map<String, dynamic>>> obtenerFacultadesDropdown() async {
    try {
      final respuesta = await supabase
          .from('facultades')
          .select()
          .order('nombre');

      ApiLogger.logGet(
        table: 'facultades',
        statusCode: 200,
        response: respuesta,
      );

      return List<Map<String, dynamic>>.from(respuesta);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'facultades',
        error: e,
      );
      rethrow;
    }
  }
} 