import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestión de plataforma
class PlataformaRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get tableName => 'plataforma';
  
  @override
  String get repositoryName => 'PlataformaRepository';
  
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

  /// Obtener estadísticas generales de la plataforma
  Future<Map<String, int>> obtenerEstadisticasGenerales() async {
    try {
      debugPrint('PlataformaRepository: Obteniendo estadísticas generales...');
      
      // Obtener conteos usando consultas básicas
      final estudiantes = await supabase.from('estudiantes').select();
      final profesores = await supabase.from('profesores').select();
      final cursos = await supabase.from('cursos').select();
      
      final stats = {
        'totalEstudiantes': estudiantes.length,
        'totalProfesores': profesores.length,
        'totalCursos': cursos.length,
      };
      
      ApiLogger.logGet(
        table: 'estadisticas_generales',
        statusCode: 200,
        response: stats,
      );
      
      debugPrint('PlataformaRepository: Estadísticas obtenidas: $stats');
      return stats;
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'estadisticas_generales',
        error: e,
      );
      debugPrint('PlataformaRepository: Error al obtener estadísticas: $e');
      // En caso de error, devolver un mapa con ceros para no romper la UI.
      return {
        'totalEstudiantes': 0,
        'totalProfesores': 0,
        'totalCursos': 0,
      };
    }
  }
} 