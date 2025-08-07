import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que inyecta una instancia del TareaRepository.
final tareaRepositoryProvider = Provider<TareaRepository>((ref) {
  return TareaRepository();
});

/// Repositorio para gestión de tareas
class TareaRepository extends BaseRepository<ModeloTarea> {
  @override
  String get tableName => 'tareas';
  
  @override
  String get repositoryName => 'TareaRepository';
  
  @override
  ModeloTarea fromJson(Map<String, dynamic> json) {
    return ModeloTarea.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloTarea entity) {
    return {
      'id': entity.id,
      'titulo': entity.titulo,
      'descripcion': entity.descripcion,
      'curso_id': entity.cursoId,
      'fecha_entrega': entity.fechaEntrega.toIso8601String(),
      'estado': entity.estado,
      'fecha_creacion': entity.fechaCreacion.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloTarea entity) {
    return entity.id;
  }

  Future<List<ModeloTarea>> obtenerTareas({
    String? cursoId,
    String? estado,
  }) async {
    try {
      final filtros = <String, dynamic>{};
      if (cursoId != null) {
        filtros['curso_id'] = cursoId;
      }
      if (estado != null) {
        filtros['estado'] = estado;
      }

      final respuesta = await supabase
          .from('tareas')
          .select('*, cursos!inner(*)')
          .match(cursoId != null ? {'curso_id': cursoId} : {})
          .match(estado != null ? {'estado': estado} : {})
          .order('fecha_entrega', ascending: true);

      ApiLogger.logGet(
        table: 'tareas',
        statusCode: 200,
        response: respuesta,
        filters: filtros,
      );

      return (respuesta as List)
          .map((json) => ModeloTarea.fromJson(json))
          .toList();
    } catch (e, s) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'tareas',
        error: e,
        additionalInfo: 'Filtros: curso=$cursoId, estado=$estado',
      );
      debugPrint('ERROR obtenerTareas: $e');
      debugPrint('STACK obtenerTareas: $s');
      rethrow;
    }
  }

  Future<ModeloTarea?> obtenerTareaPorId(String id) async {
    return obtenerPorId(id);
  }

  Future<List<ModeloEntrega>> obtenerEntregasPorTarea(String tareaId) async {
    try {
      final respuesta = await supabase
          .from('entregas')
          .select('*, estudiantes!inner(nombre_completo, correo_electronico)')
          .match({'tarea_id': tareaId})
          .order('fecha_entrega', ascending: false);

      ApiLogger.logGet(
        table: 'entregas',
        statusCode: 200,
        response: respuesta,
        filters: {'tarea_id': tareaId},
      );
          
      return (respuesta as List)
          .map((json) => ModeloEntrega.fromJson(json))
          .toList();
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'entregas',
        error: e,
        additionalInfo: 'tarea_id: $tareaId',
      );
      rethrow;
    }
  }

  Future<ModeloTarea> crearTarea(Map<String, dynamic> datos) async {
    try {
      final datosRequest = {
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'fecha_entrega': datos['fecha_entrega'],
        'puntos_maximos': datos['puntos_maximos'],
        'curso_id': datos['curso_id'],
      };

      final result = await supabase
          .from('tareas')
          .insert(datosRequest)
          .select('*, cursos!inner(*)')
          .single();

      ApiLogger.logPost(
        table: 'tareas',
        statusCode: 201,
        response: result,
        requestBody: datosRequest,
      );

      return ModeloTarea.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'POST',
        table: 'tareas',
        error: e,
        additionalInfo: 'Datos: $datos',
      );
      rethrow;
    }
  }

  Future<ModeloTarea> actualizarTarea(String id, Map<String, dynamic> datos) async {
    try {
      final datosRequest = {
        'titulo': datos['titulo'],
        'descripcion': datos['descripcion'],
        'fecha_entrega': datos['fecha_entrega'],
        'puntos_maximos': datos['puntos_maximos'],
        'curso_id': datos['curso_id'],
      };

      final result = await supabase
          .from('tareas')
          .update(datosRequest)
          .eq('id', id)
          .select('*, cursos!inner(*)')
          .single();

      ApiLogger.logUpdate(
        table: 'tareas',
        statusCode: 200,
        response: result,
        requestBody: datosRequest,
      );

      return ModeloTarea.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPDATE',
        table: 'tareas',
        error: e,
        additionalInfo: 'ID: $id, Datos: $datos',
      );
      rethrow;
    }
  }

  Future<void> eliminarTarea(String id) async {
    try {
      final result = await supabase
          .from('tareas')
          .delete()
          .match({'id': id});

      ApiLogger.logDelete(
        table: 'tareas',
        statusCode: 204,
        response: result,
        id: id,
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'DELETE',
        table: 'tareas',
        error: e,
        additionalInfo: 'ID: $id',
      );
      rethrow;
    }
  }

  Future<void> calificarEntrega({
    required String tareaId,
    required String estudianteId,
    required double calificacion,
    String? comentario,
    required String estado,
  }) async {
    try {
      final datosRequest = {
        'tarea_id': tareaId,
        'estudiante_id': estudianteId,
        'calificacion': calificacion,
        'comentario_profesor': comentario,
        'fecha_entrega': DateTime.now().toIso8601String(),
        'estado': estado,
      };

      // Upsert: Actualiza si existe, si no, inserta.
      final result = await supabase.from('entregas').upsert(datosRequest, onConflict: 'tarea_id, estudiante_id');

      ApiLogger.logUpdate(
        table: 'entregas',
        statusCode: 200,
        response: result,
        requestBody: datosRequest,
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPSERT',
        table: 'entregas',
        error: e,
        additionalInfo: 'tarea: $tareaId, estudiante: $estudianteId, calificacion: $calificacion',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTareasConEntregas() async {
    try {
      final data = await supabase
          .from('tareas')
          .select();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error al cargar las tareas: $e');
    }
  }
}
