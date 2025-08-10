import 'package:aulago/models/examen_entrega.model.dart';
import 'package:aulago/models/pregunta_examen.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

class ExamenEntregaRepository extends BaseRepository<ExamenEntrega> {
  @override
  String get tableName => 'examenes_entregas';

  @override
  String get repositoryName => 'ExamenEntregaRepository';

  @override
  ExamenEntrega fromJson(Map<String, dynamic> json) => ExamenEntrega.fromJson(json);

  @override
  Map<String, dynamic> toJson(ExamenEntrega entity) => entity.toJson();

  @override
  String getId(ExamenEntrega entity) => entity.id.toString();

  /// Obtiene todas las entregas de un examen con información del estudiante
  Future<List<Map<String, dynamic>>> obtenerEntregasConEstudiante(int examenId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo entregas para examen: $examenId');
      
      final response = await supabase
          .from(tableName)
          .select('''
            *,
            estudiantes!inner(
              id,
              nombre_completo,
              codigo_estudiante,
              correo_electronico,
              foto_perfil_url
            )
          ''')
          .eq('examen_id', examenId)
          .order('calificacion', ascending: false);

      debugPrint('[$repositoryName] Entregas obtenidas: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[$repositoryName] Error al obtener entregas: $e');
      rethrow;
    }
  }

  /// Obtiene las preguntas de un examen
  Future<List<PreguntaExamen>> obtenerPreguntasExamen(int examenId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo preguntas para examen: $examenId');
      
      final response = await supabase
          .from('preguntas_examen')
          .select()
          .eq('examen_id', examenId)
          .order('id');

      final preguntas = response.map(PreguntaExamen.fromJson).toList();
      debugPrint('[$repositoryName] Preguntas obtenidas: ${preguntas.length}');
      return preguntas;
    } catch (e) {
      debugPrint('[$repositoryName] Error al obtener preguntas: $e');
      rethrow;
    }
  }

  /// Obtiene estadísticas de un examen
  Future<Map<String, dynamic>> obtenerEstadisticasExamen(int examenId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo estadísticas para examen: $examenId');
      
      final response = await supabase
          .from(tableName)
          .select('calificacion, estado')
          .eq('examen_id', examenId);

      final entregas = response;
      final totalEntregas = entregas.length;
      final completadas = entregas.where((e) => e['estado'] == 'Completado').length;
      final calificaciones = entregas
          .where((e) => e['calificacion'] != null)
          .map((e) => (e['calificacion'] as num).toDouble())
          .toList();

      double promedioCalificacion = 0;
      double mejorCalificacion = 0;
      double peorCalificacion = 0;

      if (calificaciones.isNotEmpty) {
        promedioCalificacion = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
        mejorCalificacion = calificaciones.reduce((a, b) => a > b ? a : b);
        peorCalificacion = calificaciones.reduce((a, b) => a < b ? a : b);
      }

      final estadisticas = {
        'total_entregas': totalEntregas,
        'completadas': completadas,
        'pendientes': totalEntregas - completadas,
        'promedio_calificacion': promedioCalificacion,
        'mejor_calificacion': mejorCalificacion,
        'peor_calificacion': peorCalificacion,
        'porcentaje_aprobacion': calificaciones.where((c) => c >= 11).length / (calificaciones.isEmpty ? 1 : calificaciones.length) * 100,
      };

      debugPrint('[$repositoryName] Estadísticas calculadas: $estadisticas');
      return estadisticas;
    } catch (e) {
      debugPrint('[$repositoryName] Error al obtener estadísticas: $e');
      rethrow;
    }
  }

  /// Califica un examen manualmente (si es necesario)
  Future<ExamenEntrega> calificarExamen({
    required int entregaId,
    required double calificacion,
  }) async {
    try {
      debugPrint('[$repositoryName] Calificando examen ID: $entregaId con nota: $calificacion');

      final response = await supabase
          .from(tableName)
          .update({
            'calificacion': calificacion,
            'estado': 'Completado',
          })
          .eq('id', entregaId)
          .select()
          .single();

      final entregaActualizada = fromJson(response);
      debugPrint('[$repositoryName] Examen calificado exitosamente');
      return entregaActualizada;
    } catch (e) {
      debugPrint('[$repositoryName] Error al calificar examen: $e');
      rethrow;
    }
  }
}
