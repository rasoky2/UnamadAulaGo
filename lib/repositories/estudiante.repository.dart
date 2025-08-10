import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';

class EstudianteRepository extends BaseRepository<EstudianteAdmin> {
  @override
  String get tableName => 'estudiantes';
  
  @override
  String get repositoryName => 'EstudianteRepository';
  
  @override
  EstudianteAdmin fromJson(Map<String, dynamic> json) {
    return EstudianteAdmin.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(EstudianteAdmin entity) {
    return entity.toJson();
  }
  
  @override
  String getId(EstudianteAdmin entity) {
    return entity.id.toString();
  }

  // CRUD básico compatible con BaseRepository
  Future<List<EstudianteAdmin>> obtenerTodos() async {
    final result = await obtener();
    return result.items;
  }

  Future<List<EstudianteAdmin>> obtenerEstudiantes() async {
    return obtenerTodos();
  }

  Future<EstudianteAdmin?> obtenerEstudiantePorId(int id) async {
    return obtenerPorId(id.toString());
  }

  /// Obtiene un estudiante por su usuario_id (ID en la tabla usuarios)
  Future<EstudianteAdmin?> obtenerEstudiantePorUsuarioId(int usuarioId) async {
    try {
      debugPrint('[EstudianteRepository] Buscando estudiante con usuario_id: $usuarioId');

      final response = await supabase
          .from(tableName)
          .select()
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      if (response != null) {
        ApiLogger.logGet(
          table: tableName,
          statusCode: 200,
          response: {'found': true, 'usuario_id': usuarioId},
          filters: {'usuario_id': usuarioId},
        );
        return EstudianteAdmin.fromJson(response);
      } else {
        ApiLogger.logGet(
          table: tableName,
          statusCode: 404,
          response: {'found': false, 'usuario_id': usuarioId},
          filters: {'usuario_id': usuarioId},
        );
        return null;
      }
    } catch (e) {
      ApiLogger.logError(
        operation: 'obtenerEstudiantePorUsuarioId',
        table: tableName,
        error: e,
        additionalInfo: 'usuario_id: $usuarioId',
      );
      rethrow;
    }
  }

  Future<EstudianteAdmin> crearEstudiante(EstudianteAdmin estudiante) async {
    return crear(estudiante.toJson());
  }

  Future<EstudianteAdmin> actualizarEstudiante(int id, EstudianteAdmin estudiante) async {
    return actualizar(id.toString(), estudiante.toJson());
  }

  Future<bool> eliminarEstudiante(int id) async {
    await eliminar(id.toString());
      return true;
  }

  /// Actualiza la contraseña del estudiante y, si corresponde, del usuario vinculado
  Future<void> actualizarContrasena({
    required int estudianteId,
    required String nuevaContrasena,
    int? usuarioId,
  }) async {
    try {
      // Actualizar en tabla estudiantes
      await supabase
          .from(tableName)
          .update({'contrasena_hash': nuevaContrasena})
          .eq('id', estudianteId);

      // Si tenemos usuario_id, actualizar también en usuarios
      if (usuarioId != null) {
        await supabase
            .from('usuarios')
            .update({'contrasena_hash': nuevaContrasena})
            .eq('id', usuarioId);
      } else {
        // Intentar obtener usuario_id si no se pasó
        final resp = await supabase
            .from(tableName)
            .select('usuario_id')
            .eq('id', estudianteId)
            .maybeSingle();
        final uid = resp != null && resp['usuario_id'] != null
            ? int.tryParse(resp['usuario_id'].toString())
            : null;
        if (uid != null) {
          await supabase
              .from('usuarios')
              .update({'contrasena_hash': nuevaContrasena})
              .eq('id', uid);
        }
      }
    } catch (e) {
      ApiLogger.logError(
        operation: 'actualizarContrasena',
        table: tableName,
        error: e,
        additionalInfo: 'estudianteId: $estudianteId, usuarioId: $usuarioId',
      );
      rethrow;
    }
  }

  /// Actualiza contraseña buscando por código de estudiante (y código de usuario igual)
  Future<void> actualizarContrasenaPorCodigo({
    required String codigoEstudiante,
    required String nuevaContrasena,
  }) async {
    try {
      // Estudiantes por código_estudiante
      await supabase
          .from(tableName)
          .update({'contrasena_hash': nuevaContrasena})
          .eq('codigo_estudiante', codigoEstudiante);

      // Usuarios por código_usuario
      await supabase
          .from('usuarios')
          .update({'contrasena_hash': nuevaContrasena})
          .eq('codigo_usuario', codigoEstudiante);
    } catch (e) {
      ApiLogger.logError(
        operation: 'actualizarContrasenaPorCodigo',
        table: tableName,
        error: e,
        additionalInfo: 'codigo: $codigoEstudiante',
      );
      rethrow;
    }
  }
}

