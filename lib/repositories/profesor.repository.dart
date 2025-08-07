import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/profesor_admin.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio para gestión de profesores
class ProfesorRepository extends BaseRepository<ProfesorAdmin> {
  @override
  String get tableName => 'profesores';
  
  @override
  String get repositoryName => 'ProfesorRepository';
  
  @override
  ProfesorAdmin fromJson(Map<String, dynamic> json) {
    return ProfesorAdmin.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ProfesorAdmin entity) {
    return {
      'id': entity.id,
      'codigo_profesor': entity.codigoProfesor,
      'nombre_completo': entity.nombreCompleto,
      'correo_electronico': entity.correoElectronico,
      'facultad_id': entity.facultadId,
      'especialidad': entity.especialidad,
    };
  }
  
  @override
  String getId(ProfesorAdmin entity) {
    return entity.id;
  }

  /// Obtener todos los profesores con filtros aplicados
  Future<({List<ProfesorAdmin> profesores, int total})> obtenerProfesores({
    String? filtroTexto,
    bool? filtroActivo,
    String? filtroFacultad,
    int limite = 10,
    int offset = 0,
  }) async {
    final filtros = <String, dynamic>{};
    if (filtroTexto != null) {
      filtros['texto'] = filtroTexto;
    }
    if (filtroActivo != null) {
      filtros['activo'] = filtroActivo;
    }
    if (filtroFacultad != null) {
      filtros['facultad'] = filtroFacultad;
    }
    filtros['limite'] = limite;
    filtros['offset'] = offset;

    var query = supabase
        .from('profesores')
        .select('*, usuarios(*), facultades(*)');

    if (filtroTexto != null && filtroTexto.isNotEmpty) {
      query = query.or(
          '''usuarios.nombre_completo.ilike.%$filtroTexto%,
             usuarios.codigo_usuario.ilike.%$filtroTexto%,
             usuarios.correo_electronico.ilike.%$filtroTexto%''');
    }

    if (filtroActivo != null) {
      query = query.eq('usuarios.activo', filtroActivo);
    }

    if (filtroFacultad != null && filtroFacultad.isNotEmpty) {
      query = query.eq('facultad_id', filtroFacultad);
    }

    try {
      final response = await query
          .range(offset, offset + limite - 1)
          .order('nombre_completo', referencedTable: 'usuarios')
          .count(CountOption.exact);

      ApiLogger.logGet(
        table: 'profesores',
        statusCode: 200,
        response: {'count': response.count, 'data_length': response.data.length},
        filters: filtros,
      );

      final profesores = <ProfesorAdmin>[];
      
      for (int i = 0; i < response.data.length; i++) {
        try {
          final profesorData = response.data[i];
          final profesor = ProfesorAdmin.fromJson(profesorData);
          profesores.add(profesor);
        } catch (e) {
          ApiLogger.logError(
            operation: 'PARSE',
            table: 'profesores',
            error: e,
            additionalInfo: 'Error procesando profesor  [1m${i + 1} [0m',
          );
        }
      }
      debugPrint('[REPO] Profesores recibidos de Supabase:  [1m${profesores.length} [0m');
      for (final p in profesores) {
        debugPrint('   - ${p.nombreCompleto} (${p.codigoProfesor})');
      }
    
      final total = response.count;

      return (profesores: profesores, total: total);
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'profesores',
        error: e,
        additionalInfo: 'Filtros aplicados: $filtros',
      );
      rethrow;
    }
  }

  /// Contar total de profesores con filtros aplicados
  Future<int> contarProfesores() async {
    final response = await supabase
        .from('profesores')
        .count();
    return response;
  }

  /// Obtener un profesor por ID
  Future<ProfesorAdmin?> obtenerProfesorPorId(String id) async {
    final response = await supabase
        .from('profesores')
        .select('*, usuarios!inner(*), facultades!inner(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return ProfesorAdmin.fromJson(response);
  }

  /// Crear un nuevo profesor
  Future<ProfesorAdmin> crearProfesor(Map<String, dynamic> datos) async {
    try {
      final datosUsuario = {
      'codigo_usuario': datos['codigo_profesor'],
      'nombre_completo': datos['nombre_completo'],
      'correo_electronico': datos['correo_electronico'],
      'rol': 'profesor',
        'activo': datos['activo'] ?? true,
        'contrasena_hash': 'password_temporal',
      };

      final userResponse = await supabase.from('usuarios').insert(datosUsuario).select('id').single();

      ApiLogger.logPost(
        table: 'usuarios',
        statusCode: 201,
        response: userResponse,
        requestBody: datosUsuario,
      );

    final usuarioId = userResponse['id'];

      final datosProfesor = {
      'usuario_id': usuarioId,
      'especialidad': datos['especialidad'],
      'grado_academico': datos['grado_academico'],
      'facultad_id': datos['facultad_id'],
      };

      final result = await supabase.from('profesores').insert(datosProfesor).select('*, usuarios!inner(*), facultades!inner(*)').single();

      ApiLogger.logPost(
        table: 'profesores',
        statusCode: 201,
        response: result,
        requestBody: datosProfesor,
      );

    return ProfesorAdmin.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'POST',
        table: 'profesores',
        error: e,
        additionalInfo: 'Datos: $datos',
      );
      rethrow;
    }
  }

  /// Actualizar un profesor existente
  Future<ProfesorAdmin> actualizarProfesor(
      String id, Map<String, dynamic> datos) async {
    try {
    final perfil =
        await supabase.from('profesores').select('usuario_id').eq('id', id).single();
    final usuarioId = perfil['usuario_id'];

      // Actualizar tabla usuarios
    await supabase.from('usuarios').update({
      'codigo_usuario': datos['codigo_profesor'],
      'nombre_completo': datos['nombre_completo'],
      'correo_electronico': datos['correo_electronico'],
        'activo': datos['activo'] ?? true,
    }).eq('id', usuarioId);

      // Actualizar tabla profesores
    final result = await supabase.from('profesores').update({
      'especialidad': datos['especialidad'],
      'grado_academico': datos['grado_academico'],
      'facultad_id': datos['facultad_id'],
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      }).eq('id', id).select('*, usuarios!inner(*), facultades(*)').single();

      ApiLogger.logUpdate(
        table: 'profesores',
        statusCode: 200,
        response: result,
        requestBody: datos,
      );

    return ProfesorAdmin.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPDATE',
        table: 'profesores',
        error: e,
        additionalInfo: 'ID: $id, Datos: $datos',
      );
      rethrow;
    }
  }

  /// Cambiar el estado de un profesor (activo/inactivo)
  Future<void> cambiarEstadoProfesor(String id, {required bool activo}) async {
    try {
      // 1. Obtener el profesor actual para conocer su usuario_id
      final perfil = await supabase
          .from('profesores')
          .select('usuario_id')
          .eq('id', id)
          .single();
      final usuarioId = perfil['usuario_id'];

      // 2. Actualizar la tabla usuarios
      final usuarioUpdate = await supabase
          .from('usuarios')
          .update({'activo': activo})
          .eq('id', usuarioId)
          .select()
          .single();

      ApiLogger.logUpdate(
        table: 'usuarios',
        statusCode: 200,
        response: usuarioUpdate,
        requestBody: {'activo': activo},
      );

      // 3. Actualizar la tabla profesores (campo estado)
      final estado = activo ? 'activo' : 'inactivo';
      final profesorUpdate = await supabase
          .from('profesores')
          .update({'estado': estado})
          .eq('id', id)
          .select()
          .single();

      ApiLogger.logUpdate(
        table: 'profesores',
        statusCode: 200,
        response: profesorUpdate,
        requestBody: {'estado': estado},
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPDATE_ESTADO',
        table: 'profesores',
        error: e,
        additionalInfo: 'ID: $id, Activo: $activo',
      );
      rethrow;
    }
  }

  /// Eliminar un profesor
  Future<void> eliminarProfesor(String id) async {
    try {
    final perfil = await supabase
        .from('profesores')
        .select('usuario_id')
        .eq('id', id)
        .maybeSingle();
    if (perfil == null) {
      return;
    }
    final usuarioId = perfil['usuario_id'];

      // Eliminar profesor primero (por la FK)
    await supabase.from('profesores').delete().eq('id', id);
      
      // Luego eliminar usuario
    await supabase.from('usuarios').delete().eq('id', usuarioId);

      ApiLogger.logDelete(
        table: 'profesores',
        statusCode: 200,
        response: {'deleted_id': id},
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'DELETE',
        table: 'profesores',
        error: e,
        additionalInfo: 'ID: $id',
      );
      rethrow;
    }
  }

  /// Obtener todas las facultades
  Future<List<FacultadAdmin>> obtenerFacultades() async {
    try {
      final result = await supabase
          .from('facultades')
          .select('id, codigo, nombre')
          .order('nombre');

      return (result as List<dynamic>).map((facultad) => FacultadAdmin(
        id: facultad['id'],
        codigo: facultad['codigo'],
        nombre: facultad['nombre'],
      )).toList();
    } catch (e) {
      throw Exception('Error al obtener facultades: $e');
    }
  }

  /// Obtener cursos de un profesor
  Future<List<CursoProfesor>> obtenerCursosProfesor(String profesorId) async {
    try {
      final filtros = {'profesor_id': profesorId};
      
      final result = await supabase
          .from('cursos')
          .select('''
            id,
            codigo_curso,
            nombre,
            creditos,
            carreras (
              nombre
            )
          ''')
          .eq('profesor_id', profesorId)
          .order('nombre');

      ApiLogger.logGet(
        table: 'cursos',
        statusCode: 200,
        response: {'length': result.length, 'data': result},
        filters: filtros,
      );

      if (result.isEmpty) {
        return [];
      }

      final cursos = <CursoProfesor>[];
      
             for (int i = 0; i < result.length; i++) {
         try {
           final curso = result[i];

           // Obtener conteo de estudiantes matriculados por separado
           int estudiantesMatriculados = 0;
           try {
             final matriculasResponse = await supabase
                 .from('matriculas')
                 .select('id, grupos_clase!inner(curso_id)')
                 .eq('grupos_clase.curso_id', curso['id'])
                 .eq('estado', 'matriculado')
                 .count(CountOption.exact);
             
             estudiantesMatriculados = matriculasResponse.count;
           } catch (e) {
            ApiLogger.logError(
              operation: 'COUNT',
              table: 'matriculas',
              error: e,
              additionalInfo: 'Error contando estudiantes para curso ${curso['id']}',
            );
           }

           final cursoProfesor = CursoProfesor(
             cursoId: curso['id'],
             codigoCurso: curso['codigo_curso'],
             nombreCurso: curso['nombre'],
             creditos: curso['creditos'],
             carreraNombre: curso['carreras']?['nombre'],
             estudiantesMatriculados: estudiantesMatriculados,
           );
           
           cursos.add(cursoProfesor);
           
         } catch (e) {
          ApiLogger.logError(
            operation: 'PARSE',
            table: 'cursos',
            error: e,
            additionalInfo: 'Error procesando curso ${i + 1}',
          );
         }
       }

      return cursos;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'cursos',
        error: e,
        additionalInfo: 'profesor_id: $profesorId',
      );
      rethrow;
    }
  }

  /// Obtener estadísticas generales de profesores
  Future<Map<String, int>> obtenerEstadisticasProfesores() async {
    try {
      final profesoresResponse = await supabase
          .from('profesores')
          .select('id, estado, cursos(id)');

      final profesores = profesoresResponse as List<dynamic>;
      final activos = profesores.where((p) => p['estado'] == 'activo').length;
      final totalCursos = profesores.fold(0, (sum, p) => sum + (p['cursos'] as List).length);
      
      return {
        'totalProfesores': profesores.length,
        'profesoresActivos': activos,
        'totalCursos': totalCursos,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Verificar si un código de profesor ya existe
  Future<bool> verificarCodigoExiste(String codigo, {String? excludeId}) async {
    try {
      // Verificar directamente en la tabla usuarios (donde están los códigos)
      final usuarioResult = await supabase
          .from('usuarios')
          .select('id')
          .eq('codigo_usuario', codigo)
          .eq('rol', 'profesor')
          .maybeSingle();
      
      return usuarioResult != null;
    } catch (e) {
      throw Exception('Error al verificar código: $e');
    }
  }

  /// Verificar si un email ya existe
  Future<bool> verificarEmailExiste(String email, {String? excludeId}) async {
    try {
      // Verificar directamente en la tabla usuarios (donde están los emails)
      final usuarioResult = await supabase
          .from('usuarios')
          .select('id')
          .eq('correo_electronico', email)
          .maybeSingle();
      
      return usuarioResult != null;
    } catch (e) {
      throw Exception('Error al verificar email: $e');
    }
  }

  Future<List<ModeloCurso>> getCursos(String profesorId) async {
    try {
      final filtros = {'profesor_id': profesorId};

      final response = await supabase
          .from('cursos')
          .select()
          .eq('profesor_id', profesorId);

      ApiLogger.logGet(
        table: 'cursos',
        statusCode: 200,
        response: response,
        filters: filtros,
      );

      if (response.isEmpty) {
        return [];
      }
      
      return response.map<ModeloCurso>(ModeloCurso.fromJson).toList();
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'cursos',
        error: e,
        additionalInfo: 'profesor_id: $profesorId',
      );
      rethrow;
    }
  }
}

final profesorRepositoryProvider = Provider((ref) => ProfesorRepository());
