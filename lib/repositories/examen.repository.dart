import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/examen.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

/// Repositorio para gestión de exámenes
class ExamenRepository extends BaseRepository<ModeloExamen> {
  @override
  String get tableName => 'examenes';
  
  @override
  String get repositoryName => 'ExamenRepository';
  
  @override
  ModeloExamen fromJson(Map<String, dynamic> json) {
    return ModeloExamen.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloExamen entity) {
    return {
      'id': entity.id,
      'titulo': entity.titulo,
      'descripcion': entity.descripcion,
      'fecha_disponible': entity.fechaDisponible.toIso8601String(),
      'fecha_limite': entity.fechaLimite.toIso8601String(),
      'fecha_creacion': entity.fechaCreacion.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloExamen entity) {
    return entity.id;
  }

  /// Obtener exámenes de un curso
  Future<List<ModeloExamen>> obtenerExamenesPorCurso(String cursoId) async {
    try {
      final filtros = {'curso_id': cursoId};

      final respuesta = await supabase
          .from('examenes')
          .select()
          .match(filtros)
          .order('fecha_disponible', ascending: true);

      ApiLogger.logGet(
        table: 'examenes',
        statusCode: 200,
        response: respuesta,
        filters: filtros,
      );

      return (respuesta as List)
          .map((json) => ModeloExamen.fromJson(json))
          .toList();
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'examenes',
        error: e,
        additionalInfo: 'curso_id: $cursoId',
      );
      rethrow;
    }
  }

  /// Obtener un examen por ID
  Future<ModeloExamen?> obtenerExamenPorId(String id) async {
    return obtenerPorId(id);
  }

  /// Crear un nuevo examen
  Future<ModeloExamen> crearExamen(Map<String, dynamic> datos) async {
    return crear(datos);
  }

  /// Actualizar un examen existente
  Future<ModeloExamen> actualizarExamen(String id, Map<String, dynamic> datos) async {
    try {
      final respuesta = await supabase
          .from('examenes')
          .update(datos)
          .match({'id': id})
          .select()
          .single();

      ApiLogger.logUpdate(
        table: 'examenes',
        statusCode: 200,
        response: respuesta,
        requestBody: datos,
      );

      return ModeloExamen.fromJson(respuesta);
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPDATE',
        table: 'examenes',
        error: e,
        additionalInfo: 'ID: $id, Datos: $datos',
      );
      rethrow;
    }
  }

  /// Eliminar un examen
  Future<void> eliminarExamen(String id) async {
    try {
      final result = await supabase
          .from('examenes')
          .delete()
          .match({'id': id});

      ApiLogger.logDelete(
        table: 'examenes',
        statusCode: 204,
        response: result,
        id: id,
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'DELETE',
        table: 'examenes',
        error: e,
        additionalInfo: 'ID: $id',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerExamenesConEntregas(String grupoClaseId) async {
    try {
      final parametros = {'p_grupo_clase_id': grupoClaseId};

      final result = await supabase.rpc(
        'obtener_examenes_con_entregas',
        params: parametros,
      );

      ApiLogger.logRpc(
        functionName: 'obtener_examenes_con_entregas',
        statusCode: 200,
        response: result,
        params: parametros,
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'RPC',
        table: 'obtener_examenes_con_entregas',
        error: e,
        additionalInfo: 'grupo_clase_id: $grupoClaseId',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesChatGrupal(String grupoClaseId) async {
    try {
      final parametros = {'p_grupo_clase_id': grupoClaseId};

      final result = await supabase.rpc(
        'obtener_mensajes_chat_grupal',
        params: parametros,
      );

      ApiLogger.logRpc(
        functionName: 'obtener_mensajes_chat_grupal',
        statusCode: 200,
        response: result,
        params: parametros,
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'RPC',
        table: 'obtener_mensajes_chat_grupal',
        error: e,
        additionalInfo: 'grupo_clase_id: $grupoClaseId',
      );
      rethrow;
    }
  }

  /// Obtener entregas de un examen por examenId (como ModeloEntrega)
  Future<List<ModeloEntrega>> obtenerEntregasPorExamen(String examenId) async {
    try {
      final respuesta = await supabase
          .from('entregas')
          .select()
          .eq('examen_id', examenId);

      ApiLogger.logGet(
        table: 'entregas',
        statusCode: 200,
        response: respuesta,
        filters: {'examen_id': examenId},
      );

      return (respuesta as List)
          .map((json) => ModeloEntrega.fromJson(json))
          .toList();
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'entregas',
        error: e,
        additionalInfo: 'examen_id: $examenId',
      );
      rethrow;
    }
  }
} 