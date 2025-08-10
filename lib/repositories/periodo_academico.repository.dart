import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

/// Repositorio para gestión de períodos académicos
class PeriodoAcademicoRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get tableName => 'periodos_academicos';
  
  @override
  String get repositoryName => 'PeriodoAcademicoRepository';
  
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

  /// Obtener períodos académicos
  Future<List<Map<String, dynamic>>> obtenerPeriodosAcademicos() async {
    try {
      final respuesta = await supabase
          .from('periodos_academicos')
          .select()
          .order('anio', ascending: false)
          .order('semestre', ascending: false);

      ApiLogger.logGet(
        table: 'periodos_academicos',
        statusCode: 200,
        response: respuesta,
      );

      return List<Map<String, dynamic>>.from(respuesta);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'periodos_academicos',
        error: e,
      );
      rethrow;
    }
  }
} 