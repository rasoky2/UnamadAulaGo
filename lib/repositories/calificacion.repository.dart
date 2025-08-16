import 'package:aulago/models/calificacion.model.dart';
import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/examen_entrega.model.dart';
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

  /// Obtiene calificaciones unificadas (entregas + tabla calificaciones)
  Future<List<CalificacionUnificada>> obtenerCalificacionesUnificadasPorCurso(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo calificaciones unificadas para curso: $cursoId');
      
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
              examenId: null,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Valor por defecto, se debería obtener de la tarea
              fechaCalificacion: entrega.fechaActualizacion ?? entrega.fechaEntrega,
              calificadoPor: null,
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
              tareaId: null,
              examenId: entrega.examenId,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Valor por defecto, se debería obtener del examen
              fechaCalificacion: entrega.fechaFin ?? entrega.fechaInicio,
              calificadoPor: null,
              fuente: 'entrega_examen',
            ));
          }
        }
      }
      
      debugPrint('[$repositoryName] ✅ ${calificaciones.length} calificaciones unificadas obtenidas');
      return calificaciones;
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error al obtener calificaciones unificadas: $e');
      rethrow;
    }
  }

  /// Sincroniza calificaciones entre entregas y tabla de calificaciones
  Future<void> sincronizarCalificaciones(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Sincronizando calificaciones para curso: $cursoId');
      
      // 1. Sincronizar calificaciones de tareas
      final entregas = await _entregaRepo.obtenerEntregas();
      for (final entrega in entregas) {
        if (entrega.calificacion != null) {
          // Verificar si existe en la tabla de calificaciones
          final existe = await _existeCalificacion(entrega.tareaId, null, entrega.estudianteId);
          
          if (!existe) {
            // Crear nueva calificación
            final calificacion = Calificacion.crear(
              estudianteId: entrega.estudianteId,
              tareaId: entrega.tareaId,
              examenId: null,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Se debería obtener de la tarea
              fechaCalificacion: entrega.fechaActualizacion ?? entrega.fechaEntrega,
            );
            await crearCalificacion(calificacion);
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
            // Crear nueva calificación
            final calificacion = Calificacion.crear(
              estudianteId: entrega.estudianteId,
              tareaId: null,
              examenId: entrega.examenId,
              cursoId: cursoId,
              puntosObtenidos: entrega.calificacion!,
              puntosTotales: 20.0, // Se debería obtener del examen
              fechaCalificacion: entrega.fechaFin ?? entrega.fechaInicio,
            );
            await crearCalificacion(calificacion);
          }
        }
      }
      
      debugPrint('[$repositoryName] ✅ Sincronización completada');
    } catch (e) {
      debugPrint('[$repositoryName] ❌ Error en sincronización: $e');
      rethrow;
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
    );
  }

  /// Calcula la nota sobre 20
  double get notaSobre20 => (puntosObtenidos / puntosTotales) * 20;

  /// Determina si está aprobado (nota >= 11)
  bool get aprobado => notaSobre20 >= 11;
}
