import 'package:aulago/models/calificacion.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/repositories/entrega.repository.dart';
import 'package:aulago/repositories/examen_entrega.repository.dart';
import 'package:flutter/foundation.dart';

class CalificacionRepository extends BaseRepository<Calificacion> {
  final EntregaRepository _entregaRepo = EntregaRepository();
  final ExamenEntregaRepository _examenEntregaRepo = ExamenEntregaRepository();

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

  // ==================== MÉTODOS CRUD BÁSICOS ====================

  /// Obtiene todas las calificaciones
  Future<List<Calificacion>> obtenerCalificaciones() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  /// Obtiene calificaciones por curso
  Future<List<Calificacion>> obtenerCalificacionesPorCurso(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo calificaciones para curso: $cursoId');
      
      final response = await supabase
          .from(tableName)
          .select()
          .eq('curso_id', cursoId)
          .order('fecha_calificacion', ascending: false);

      final calificaciones = response.map(fromJson).toList();
      debugPrint('[$repositoryName] ✅ ${calificaciones.length} calificaciones obtenidas para curso $cursoId');
      return calificaciones;
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al obtener calificaciones por curso: $e');
      rethrow;
    }
  }

  /// Obtiene calificaciones unificadas usando función SQL optimizada
  Future<List<CalificacionUnificada>> obtenerCalificacionesUnificadasPorCurso(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo calificaciones unificadas para curso: $cursoId (SQL optimizado)');
      
      // Usar función SQL optimizada que obtiene todo en una sola consulta
      final response = await supabase
          .rpc('obtener_calificaciones_unificadas_curso', params: {'p_curso_id': cursoId});
      
      final calificaciones = <CalificacionUnificada>[];
      
      for (final row in response) {
        calificaciones.add(CalificacionUnificada(
          id: row['id'],
          estudianteId: row['estudiante_id'],
          tareaId: row['tarea_id'],
          examenId: row['examen_id'],
          cursoId: row['curso_id'] ?? cursoId,
          puntosObtenidos: (row['puntos_obtenidos'] as num).toDouble(),
          puntosTotales: (row['puntos_totales'] as num).toDouble(),
          fechaCalificacion: DateTime.parse(row['fecha_calificacion']),
          calificadoPor: row['calificado_por'],
          fuente: row['fuente'],
          // Información adicional para optimizar la UI
          estudianteNombre: row['estudiante_nombre'],
          estudianteCodigo: row['estudiante_codigo'],
          evaluacionTitulo: row['evaluacion_titulo'],
          evaluacionTipo: row['evaluacion_tipo'],
        ));
      }
      
      debugPrint('[$repositoryName] ✅ ${calificaciones.length} calificaciones unificadas obtenidas (SQL optimizado)');
      return calificaciones;
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al obtener calificaciones unificadas (SQL optimizado): $e');
      // Fallback al método anterior si la función SQL falla
      debugPrint('[$repositoryName] 🔄 Usando método fallback...');
      return _obtenerCalificacionesUnificadasFallback(cursoId);
    }
  }

  /// Método fallback para obtener calificaciones (método anterior)
  Future<List<CalificacionUnificada>> _obtenerCalificacionesUnificadasFallback(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Usando método fallback para curso: $cursoId');
      
      final calificaciones = <CalificacionUnificada>[];
      
      // 1. Obtener calificaciones de la tabla calificaciones
      final calificacionesTabla = await obtenerCalificacionesPorCurso(cursoId);
      for (final cal in calificacionesTabla) {
        calificaciones.add(CalificacionUnificada(
          id: cal.id,
          estudianteId: cal.estudianteId,
          tareaId: cal.tareaId,
          examenId: cal.examenId,
          cursoId: cal.cursoId ?? cursoId,
          puntosObtenidos: cal.puntosObtenidos,
          puntosTotales: cal.puntosTotales,
          fechaCalificacion: cal.fechaCalificacion,
          calificadoPor: cal.calificadoPor,
          fuente: 'tabla_calificaciones',
        ));
      }
      
      // 2. Obtener calificaciones de entregas de tareas
      final entregas = await _entregaRepo.obtenerEntregas();
      for (final entrega in entregas) {
        if (entrega.calificacion != null) {
          // Verificar si ya existe en la tabla de calificaciones
          final existe = calificaciones.any((c) => 
            c.tareaId == entrega.tareaId && 
            c.estudianteId == entrega.estudianteId
          );
          
          if (!existe) {
            calificaciones.add(CalificacionUnificada(
              id: entrega.id,
              estudianteId: entrega.estudianteId,
              tareaId: entrega.tareaId,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Valor por defecto, se debería obtener de la tarea
              fechaCalificacion: entrega.fechaActualizacion ?? entrega.fechaEntrega,
              fuente: 'entrega_tarea',
            ));
          }
        }
      }
      
      // 3. Obtener calificaciones de entregas de exámenes
      final examenesEntregas = await _examenEntregaRepo.obtener(limite: 1000, offset: 0);
      for (final entrega in examenesEntregas.items) {
        if (entrega.calificacion != null) {
          // Verificar si ya existe en la tabla de calificaciones
          final existe = calificaciones.any((c) => 
            c.examenId == entrega.examenId && 
            c.estudianteId == entrega.estudianteId
          );
          
          if (!existe) {
            calificaciones.add(CalificacionUnificada(
              id: entrega.id,
              estudianteId: entrega.estudianteId,
              examenId: entrega.examenId,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Valor por defecto, se debería obtener del examen
              fechaCalificacion: entrega.fechaFin ?? entrega.fechaInicio,
              fuente: 'entrega_examen',
            ));
          }
        }
      }
      
      debugPrint('[$repositoryName] ✅ ${calificaciones.length} calificaciones unificadas obtenidas (fallback)');
      return calificaciones;
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error en método fallback: $e');
      rethrow;
    }
  }

  /// Sincroniza calificaciones usando función SQL optimizada
  Future<void> sincronizarCalificaciones(int cursoId) async {
    try {
      debugPrint('[$repositoryName] 🔥 INICIANDO SINCRONIZACIÓN SQL OPTIMIZADA para curso: $cursoId');
      
      // Intentar múltiples veces con la función SQL antes de usar fallback
      for (int intento = 1; intento <= 3; intento++) {
        try {
          debugPrint('[$repositoryName] Intento $intento de 3 usando función SQL...');
          
          final response = await supabase
              .rpc('sincronizar_calificaciones_curso', params: {'p_curso_id': cursoId});
          
          debugPrint('[$repositoryName] ✅ Sincronización SQL exitosa: $response registros procesados');
          return; // Salir si es exitoso
        } catch (e) {
          debugPrint('[$repositoryName] ❌ Intento $intento falló: $e');
          if (intento < 3) {
            debugPrint('[$repositoryName] ⏳ Esperando $intento segundo(s) antes del siguiente intento...');
            await Future.delayed(Duration(seconds: intento)); // Espera progresiva
          }
        }
      }
      
      // Si todos los intentos fallan, usar fallback
      debugPrint('[$repositoryName] 🚨 Todos los intentos SQL fallaron, usando fallback...');
      await _sincronizarCalificacionesFallback(cursoId);
      
    } catch (e) {
      debugPrint('[$repositoryName] 💥 Error crítico en sincronización: $e');
      // No rethrow para evitar que falle toda la sincronización
    }
  }

  /// Método fallback para sincronización (método anterior)
  Future<void> _sincronizarCalificacionesFallback(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Sincronizando calificaciones para curso: $cursoId (fallback)');
      
      // 1. Sincronizar calificaciones de tareas
      final entregas = await _entregaRepo.obtenerEntregas();
      for (final entrega in entregas) {
        if (entrega.calificacion != null) {
          // Verificar si existe en la tabla de calificaciones
          final existe = await _existeCalificacion(entrega.tareaId, null, entrega.estudianteId);
          
          if (!existe) {
            try {
              // Crear nueva calificación
              final calificacion = Calificacion.crear(
                estudianteId: entrega.estudianteId,
                tareaId: entrega.tareaId,
                cursoId: cursoId,
                puntosObtenidos: entrega.calificacion!,
                puntosTotales: 20.0, // Se debería obtener de la tarea
                fechaCalificacion: entrega.fechaActualizacion ?? entrega.fechaEntrega,
              );
              await crearCalificacion(calificacion);
              debugPrint('[$repositoryName] ✅ Calificación de tarea sincronizada para estudiante ${entrega.estudianteId}');
            } catch (e) {
              debugPrint('[$repositoryName] ⚠️ Error al sincronizar calificación de tarea: $e');
              // Continuar con la siguiente calificación
            }
          }
        }
      }
      
      // 2. Sincronizar calificaciones de exámenes
      final examenesEntregas = await _examenEntregaRepo.obtener(limite: 1000, offset: 0);
      for (final entrega in examenesEntregas.items) {
        if (entrega.calificacion != null) {
          // Verificar si existe en la tabla de calificaciones
          final existe = await _existeCalificacion(null, entrega.examenId, entrega.estudianteId);
          
          if (!existe) {
            try {
              // Crear nueva calificación
              final calificacion = Calificacion.crear(
                estudianteId: entrega.estudianteId,
                examenId: entrega.examenId,
                cursoId: cursoId,
                puntosObtenidos: entrega.calificacion!,
                puntosTotales: 20.0, // Se debería obtener del examen
                fechaCalificacion: entrega.fechaFin ?? entrega.fechaInicio,
              );
              await crearCalificacion(calificacion);
              debugPrint('[$repositoryName] ✅ Calificación de examen sincronizada para estudiante ${entrega.estudianteId}');
            } catch (e) {
              debugPrint('[$repositoryName] ⚠️ Error al sincronizar calificación de examen: $e');
              // Continuar con la siguiente calificación
            }
          }
        }
      }
      
      debugPrint('[$repositoryName] ✅ Sincronización completada (fallback)');
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error en sincronización fallback: $e');
      // No rethrow para evitar que falle toda la sincronización
    }
  }

  /// Verifica si existe una calificación
  Future<bool> _existeCalificacion(int? tareaId, int? examenId, int estudianteId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('id')
          .eq('estudiante_id', estudianteId)
          .eq('tarea_id', tareaId ?? '')
          .eq('examen_id', examenId ?? '')
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
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

  /// Obtiene estadísticas del curso usando función SQL optimizada
  Future<Map<String, dynamic>> obtenerEstadisticasCurso(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo estadísticas del curso: $cursoId (SQL optimizado)');
      
      final response = await supabase
          .rpc('obtener_estadisticas_curso', params: {'p_curso_id': cursoId});
      
      if (response.isNotEmpty) {
        final stats = response.first;
        return {
          'totalEstudiantes': stats['total_estudiantes'],
          'totalEvaluaciones': stats['total_evaluaciones'],
          'promedioGeneral': stats['promedio_general'].toDouble(),
          'totalAprobados': stats['total_aprobados'],
          'totalReprobados': stats['total_reprobados'],
          'ultimaActividad': DateTime.parse(stats['ultima_actividad']),
        };
      }
      
      // Valores por defecto si no hay datos
      return {
        'totalEstudiantes': 0,
        'totalEvaluaciones': 0,
        'promedioGeneral': 0.0,
        'totalAprobados': 0,
        'totalReprobados': 0,
        'ultimaActividad': DateTime.now(),
      };
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al obtener estadísticas: $e');
      // Valores por defecto en caso de error
      return {
        'totalEstudiantes': 0,
        'totalEvaluaciones': 0,
        'promedioGeneral': 0.0,
        'totalAprobados': 0,
        'totalReprobados': 0,
        'ultimaActividad': DateTime.now(),
      };
    }
  }

  /// Obtiene estadísticas del dashboard usando función SQL optimizada
  Future<Map<String, dynamic>> obtenerEstadisticasDashboard(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo estadísticas del dashboard para curso: $cursoId (SQL optimizado)');
      
      final response = await supabase
          .rpc('obtener_estadisticas_dashboard_curso', params: {'p_curso_id': cursoId});
      
      if (response.isNotEmpty) {
        final stats = response.first;
        return {
          'totalEstudiantes': stats['total_estudiantes'],
          'totalEvaluaciones': stats['total_evaluaciones'],
          'promedioGeneral': (stats['promedio_general'] as num).toDouble(),
          'totalAprobados': stats['total_aprobados'],
          'totalReprobados': stats['total_reprobados'],
          'ultimaActividad': DateTime.parse(stats['ultima_actividad']),
        };
      }
      
      // Valores por defecto si no hay datos
      return {
        'totalEstudiantes': 0,
        'totalEvaluaciones': 0,
        'promedioGeneral': 0.0,
        'totalAprobados': 0,
        'totalReprobados': 0,
        'ultimaActividad': DateTime.now(),
      };
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al obtener estadísticas del dashboard: $e');
      // Valores por defecto en caso de error
      return {
        'totalEstudiantes': 0,
        'totalEvaluaciones': 0,
        'promedioGeneral': 0.0,
        'totalAprobados': 0,
        'totalReprobados': 0,
        'ultimaActividad': DateTime.now(),
      };
    }
  }

  /// Elimina todas las calificaciones asociadas a una tarea específica
  /// Útil para eliminación en cascada cuando se elimina una tarea
  Future<bool> eliminarCalificacionesPorTarea(int tareaId) async {
    try {
      debugPrint('[$repositoryName] 🗑️ Eliminando calificaciones para tarea: $tareaId');
      
      // Buscar y eliminar calificaciones que tengan tarea_id = tareaId
      await supabase
          .from(tableName)
          .delete()
          .eq('tarea_id', tareaId);
      
      debugPrint('[$repositoryName] ✅ Calificaciones eliminadas para tarea $tareaId');
      return true;
      
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al eliminar calificaciones por tarea: $e');
      rethrow;
    }
  }

  /// Elimina todas las calificaciones asociadas a un examen específico
  /// Útil para eliminación en cascada cuando se elimina un examen
  Future<bool> eliminarCalificacionesPorExamen(int examenId) async {
    try {
      debugPrint('[$repositoryName] 🗑️ Eliminando calificaciones para examen: $examenId');
      
      // Buscar y eliminar calificaciones que tengan examen_id = examenId
      await supabase
          .from(tableName)
          .delete()
          .eq('examen_id', examenId);
      
      debugPrint('[$repositoryName] ✅ Calificaciones eliminadas para examen $examenId');
      return true;
      
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al eliminar calificaciones por examen: $e');
      rethrow;
    }
  }
}

/// Modelo unificado para calificaciones de diferentes fuentes
class CalificacionUnificada {
  CalificacionUnificada({
    required this.id,
    required this.estudianteId,
    this.tareaId,
    this.examenId,
    required this.cursoId,
    required this.puntosObtenidos,
    required this.puntosTotales,
    required this.fechaCalificacion,
    this.calificadoPor,
    required this.fuente,
    this.estudianteNombre,
    this.estudianteCodigo,
    this.evaluacionTitulo,
    this.evaluacionTipo,
  });

  final int id;
  final int estudianteId;
  final int? tareaId;
  final int? examenId;
  final int cursoId;
  final double puntosObtenidos;
  final double puntosTotales;
  final DateTime fechaCalificacion;
  final int? calificadoPor;
  final String fuente; // 'tabla_calificaciones', 'entrega_tarea', 'entrega_examen'
  
  // Campos adicionales para optimizar la UI (opcionales)
  final String? estudianteNombre;
  final String? estudianteCodigo;
  final String? evaluacionTitulo;
  final String? evaluacionTipo;

  /// Convierte a modelo Calificacion estándar
  Calificacion toCalificacion() {
    return Calificacion(
      id: id,
      estudianteId: estudianteId,
      tareaId: tareaId,
      examenId: examenId,
      cursoId: cursoId,
      puntosObtenidos: puntosObtenidos,
      puntosTotales: puntosTotales,
      fechaCalificacion: fechaCalificacion,
      calificadoPor: calificadoPor,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Calcula la nota sobre 20
  double get notaSobre20 => (puntosObtenidos / puntosTotales) * 20;

  /// Determina si está aprobado (nota >= 11)
  bool get aprobado => notaSobre20 >= 11;
}
