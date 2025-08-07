import 'package:aulago/models/curso.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio para gestión de cursos
class CursoRepository extends BaseRepository<ModeloCurso> {
  @override
  String get tableName => 'cursos';
  
  @override
  String get repositoryName => 'CursoRepository';
  
  @override
  ModeloCurso fromJson(Map<String, dynamic> json) {
    return ModeloCurso.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloCurso entity) {
    return {
      'id': entity.id,
      'codigo_curso': entity.codigoCurso,
      'nombre': entity.nombre,
      'descripcion': entity.descripcion,
      'creditos': entity.creditos,
      'horas_teoria': entity.horasTeoria,
      'horas_practica': entity.horasPractica,
      'semestre_recomendado': entity.semestreRecomendado,
      'es_obligatorio': entity.esObligatorio,
      'carrera_id': entity.carreraId,
      'profesor_id': entity.profesorId,
      'fecha_creacion': entity.fechaCreacion?.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloCurso entity) {
    return entity.id;
  }

  /// Convertir ID de usuario a ID de estudiante si es necesario
  Future<String> _obtenerIdEstudianteReal(String estudianteId) async {
    try {
      // Primero verificar si este ID existe en usuarios
      final usuarioResponse = await supabase
          .from('usuarios')
          .select('codigo_usuario, rol')
          .eq('id', estudianteId)
          .maybeSingle();
          
      if (usuarioResponse != null && usuarioResponse['rol'] == 'estudiante') {
        // Si existe en usuarios, buscar el ID correspondiente en estudiantes
        final estudianteResponse = await supabase
            .from('estudiantes')
            .select('id')
            .eq('codigo_estudiante', usuarioResponse['codigo_usuario'])
            .maybeSingle();
            
        if (estudianteResponse != null) {
          debugPrint('[CursoRepository] ID convertido de usuarios a estudiantes: $estudianteId -> ${estudianteResponse['id']}');
          return estudianteResponse['id'];
        }
      }
    } catch (e) {
      debugPrint('[CursoRepository] Error en conversión de ID, usando original: $e');
    }
    
    return estudianteId;
  }

  /// Obtener lista de cursos con filtros opcionales
  Future<List<ModeloCurso>> obtenerCursos({
    String? carreraId,
    String? profesorId,
    String? periodoId,
  }) async {
    try {
      final filtros = <String, dynamic>{};
      if (carreraId != null && carreraId.isNotEmpty) {
        filtros['carrera_id'] = carreraId;
      }
      if (profesorId != null && profesorId.isNotEmpty) {
        filtros['profesor_id'] = profesorId;
      }
      if (periodoId != null && periodoId.isNotEmpty) {
        filtros['periodo_academico_id'] = periodoId;
      }

      final resultado = await obtener(
        filtros: filtros,
        orderBy: 'nombre',
      );
      return resultado.items;
    } catch (e) {
      throw Exception('Error al obtener cursos: $e');
    }
  }

  /// Obtener un curso por su ID
  Future<ModeloCurso?> obtenerCursoPorId(String id) async {
    return obtenerPorId(id);
  }

  /// Crear un nuevo curso
  Future<ModeloCurso> crearCurso(Map<String, dynamic> datos) async {
    try {
      debugPrint('[CursoRepository] Iniciando crearCurso');
      debugPrint('[CursoRepository] Datos recibidos: $datos');
      
      // Convertir horas_totales a horas_teoria y horas_practica si es necesario
      int? horasTeoria;
      int? horasPractica;
      
      if (datos['horas_totales'] != null) {
        final horasTotales = datos['horas_totales'] as int;
        // Dividir las horas totales entre teoría y práctica (por ejemplo 60/40)
        horasTeoria = (horasTotales * 0.6).round();
        horasPractica = horasTotales - horasTeoria;
        debugPrint('[CursoRepository] Convertidas horas_totales ($horasTotales) → teoria: $horasTeoria, practica: $horasPractica');
      } else {
        horasTeoria = datos['horasTeoria'] as int?;
        horasPractica = datos['horasPractica'] as int?;
      }

      final datosParaInsertar = {
        'carrera_id': datos['carrera_id'],
        'codigo_curso': datos['codigo_curso'],
        'nombre': datos['nombre'],
        'descripcion': datos['descripcion'],
        'creditos': datos['creditos'],
        'horas_teoria': horasTeoria,
        'horas_practica': horasPractica,
        'semestre_recomendado': datos['semestre_recomendado'],
        'es_obligatorio': datos['es_obligatorio'] ?? true,
        'profesor_id': datos['profesor_id'],
        'fecha_creacion': DateTime.now().toIso8601String(),
      };
      
      debugPrint('[CursoRepository] Datos para insertar en BD: $datosParaInsertar');

      final curso = await crear(datosParaInsertar);

      debugPrint('[CursoRepository] Curso creado exitosamente');
      return curso;
    } catch (e) {
      debugPrint('[CursoRepository] Error al crear curso: $e');
      debugPrint('[CursoRepository] Datos que causaron error: $datos');
      throw Exception('Error al crear curso: $e');
    }
  }

  /// Actualizar un curso existente
  Future<ModeloCurso> actualizarCurso(String id, Map<String, dynamic> datos) async {
    try {
      debugPrint('[CursoRepository] Iniciando actualizarCurso');
      debugPrint('[CursoRepository] ID del curso: $id');
      debugPrint('[CursoRepository] Datos recibidos: $datos');
      
      // Convertir horas_totales a horas_teoria y horas_practica si es necesario
      int? horasTeoria;
      int? horasPractica;
      
      if (datos['horas_totales'] != null) {
        final horasTotales = datos['horas_totales'] as int;
        // Dividir las horas totales entre teoría y práctica (por ejemplo 60/40)
        horasTeoria = (horasTotales * 0.6).round();
        horasPractica = horasTotales - horasTeoria;
        debugPrint('[CursoRepository] Convertidas horas_totales ($horasTotales) → teoria: $horasTeoria, practica: $horasPractica');
      } else {
        horasTeoria = datos['horasTeoria'] as int?;
        horasPractica = datos['horasPractica'] as int?;
      }

      final datosParaActualizar = {
        'carrera_id': datos['carrera_id'],
        'codigo_curso': datos['codigo_curso'],
        'nombre': datos['nombre'],
        'descripcion': datos['descripcion'],
        'creditos': datos['creditos'],
        'horas_teoria': horasTeoria,
        'horas_practica': horasPractica,
        'semestre_recomendado': datos['semestre_recomendado'],
        'es_obligatorio': datos['es_obligatorio'] ?? true,
        'profesor_id': datos['profesor_id'],
      };
      
      debugPrint('[CursoRepository] Datos para actualizar en BD: $datosParaActualizar');

      final curso = await actualizar(id, datosParaActualizar);

      debugPrint('[CursoRepository] Curso actualizado exitosamente');
      return curso;
    } catch (e) {
      debugPrint('[CursoRepository] Error al actualizar curso: $e');
      debugPrint('[CursoRepository] ID del curso: $id');
      debugPrint('[CursoRepository] Datos que causaron error: $datos');
      throw Exception('Error al actualizar curso: $e');
    }
  }

  /// Eliminar un curso
  Future<void> eliminarCurso(String id) async {
    try {
      await eliminar(id);
    } catch (e) {
      throw Exception('Error al eliminar curso: $e');
    }
  }

  /// Obtener estadísticas de cursos
  Future<Map<String, dynamic>> obtenerEstadisticasCursos() async {
    try {
      final result = await supabase
          .from('cursos')
          .select('''
            id,
            (
              SELECT count(*)
              FROM matriculas
              WHERE curso_id = cursos.id
              AND estado = 'activo'
            ) as estudiantes_matriculados,
            (
              SELECT count(*)
              FROM grupos_clase
              WHERE curso_id = cursos.id
              AND estado = 'activo'
            ) as grupos_activos
          ''');

      final cursos = result as List<dynamic>;
      final totalCursos = cursos.length;
      final cursosActivos = cursos.where((c) => c['estado'] == 'activo').length;
      final totalEstudiantes = cursos.fold<int>(0, (sum, c) => sum + (c['estudiantes_matriculados'] as int? ?? 0));
      final totalGrupos = cursos.fold<int>(0, (sum, c) => sum + (c['grupos_activos'] as int? ?? 0));
      
      return {
        'totalCursos': totalCursos,
        'cursosActivos': cursosActivos,
        'totalEstudiantes': totalEstudiantes,
        'totalGrupos': totalGrupos,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de cursos: $e');
    }
  }

  /// Verificar si un código de curso ya existe
  Future<bool> verificarCodigoExiste(String codigo, {String? excludeId}) async {
    try {
      final query = supabase
          .from('cursos')
          .select('id')
          .eq('codigo_curso', codigo);

      if (excludeId != null) {
        query.neq('id', excludeId);
      }

      final result = await query.maybeSingle();
      return result != null;
    } catch (e) {
      throw Exception('Error al verificar código: $e');
    }
  }

  /// Obtener cursos de un estudiante
  Future<List<ModeloCursoDetallado>> obtenerCursosEstudiante(String estudianteId) async {
    try {
      debugPrint('🔍 [CursoRepository] Iniciando obtenerCursosEstudiante para ID: $estudianteId');
      // Convertir ID de usuario a ID de estudiante si es necesario
      final estudianteIdReal = await _obtenerIdEstudianteReal(estudianteId);
      final response = await supabase
          .from('matriculas')
          .select('''
            *,
            cursos!inner(
                id,
                codigo_curso,
                nombre,
                descripcion,
                creditos,
                horas_teoria,
                horas_practica,
                semestre_recomendado,
                es_obligatorio,
                fecha_creacion,
                carrera_id,
                carreras!inner(
                  id,
                  nombre,
                  codigo
              ),
                profesores!inner(
                  id,
                  nombre_completo,
                  correo_electronico
                )
            )
          ''')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado');

      debugPrint('📊 [CursoRepository] Respuesta cruda de Supabase:');
      debugPrint('📊 Tipo:  [1m${response.runtimeType} [0m');
      debugPrint('📊 Longitud: ${(response as List).length}');
      debugPrint('📊 Datos: $response');

      if ((response as List).isEmpty) {
        debugPrint('⚠️ [CursoRepository] No se encontraron matrículas para el estudiante');
        return [];
      }

      final List<ModeloCursoDetallado> cursos = [];
      for (final json in response) {
        try {
          final curso = json['cursos'];
          if (curso == null) {
            continue;
          }
          final cursoDetallado = ModeloCursoDetallado.fromJson({
            ...curso,
            'matricula_id': json['id'],
            'estado_matricula': json['estado'],
            'fecha_matricula': json['fecha_matricula'],
            'carrera': curso['carreras'],
            'profesor': curso['profesores'],
          });
          cursos.add(cursoDetallado);
        } catch (e, stackTrace) {
          debugPrint('❌ [CursoRepository] Error procesando matrícula: $e');
          debugPrint('❌ StackTrace: $stackTrace');
          debugPrint('❌ JSON problemático: $json');
        }
      }

      debugPrint('🎉 [CursoRepository] Total de cursos procesados: ${cursos.length}');
      return cursos;
    } catch (e, stackTrace) {
      debugPrint('💥 [CursoRepository] Error general en obtenerCursosEstudiante: $e');
      debugPrint('💥 StackTrace: $stackTrace');
      throw Exception('Error al obtener cursos del estudiante: $e');
    }
  }

  /// Obtener detalle completo de un curso por su ID
  Future<ModeloCursoDetallado?> obtenerCursoDetalladoPorId(String id) async {
    try {
      final response = await supabase
          .from('cursos')
          .select('''
            *,
            carreras!inner(*),
            profesores!inner(nombre_completo, correo_electronico),
            grupos_clase!inner(*),
            (
              SELECT count(*)
              FROM matriculas
              WHERE curso_id = cursos.id
              AND estado = 'activo'
            ) as estudiantes_matriculados,
            tareas(*)
          ''')
          .eq('id', id)
          .single();

      return ModeloCursoDetallado.fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null;
      }
      throw Exception('Error al obtener detalle del curso: $e');
    }
  }

  /// Eliminar métodos y lógica de grupos_clase y ModeloGrupoClase
  /// Eliminar método obtenerGrupoClaseActivo y referencias a grupos_clase en selects y joins

  Future<List<Map<String, dynamic>>> obtenerUnidadesConTemas(String cursoId) async {
    try {
      ApiLogger.logRpc(
        functionName: 'obtener_unidades_con_temas',
        statusCode: 200,
        response: 'Llamando función RPC',
        params: {'p_curso_id': cursoId},
      );
      final result = await supabase.rpc(
        'obtener_unidades_con_temas',
        params: {'p_curso_id': cursoId},
      );

      if (result == null) {
        debugPrint('⚠️ [CursoRepository] No se encontraron unidades para el curso $cursoId');
        return [];
      }
      final data = List<Map<String, dynamic>>.from(result as List);
      debugPrint('✅ [CursoRepository] Unidades base obtenidas: ${data.length}');

      // Enriquecer los temas con detalles según su tipo
      for (final unidad in data) {
        final temas = unidad['temas'] as List<dynamic>?;
        if (temas == null) {
          continue;
        }
        for (final tema in temas) {
          final tipo = tema['tipo'] as String?;
          final temaId = tema['id'] as String?;
          if (tipo == null || temaId == null) {
            continue;
          }

          Map<String, dynamic>? detalles;
          switch (tipo.toLowerCase()) {
            case 'examen':
              final examen = await supabase
                  .from('examenes')
                  .select()
                  .eq('id', temaId)
                  .maybeSingle();
              ApiLogger.logGet(table: 'examenes', statusCode: 200, response: examen, filters: {'id': temaId});
              if (examen != null) {
                detalles = examen;
              }
              break;
            case 'lectura':
              final lectura = await supabase
                  .from('lecturas')
                  .select()
                  .eq('id', temaId)
                  .maybeSingle();
              ApiLogger.logGet(table: 'lecturas', statusCode: 200, response: lectura, filters: {'id': temaId});
              if (lectura != null) {
                detalles = lectura;
              }
              break;
            case 'tarea':
              final tarea = await supabase
                  .from('tareas')
                  .select()
                  .eq('id', temaId)
                  .maybeSingle();
              ApiLogger.logGet(table: 'tareas', statusCode: 200, response: tarea, filters: {'id': temaId});
              if (tarea != null) {
                detalles = tarea;
              }
              break;
            case 'foro':
              final foro = await supabase
                  .from('foros')
                  .select()
                  .eq('id', temaId)
                  .maybeSingle();
              ApiLogger.logGet(table: 'foros', statusCode: 200, response: foro, filters: {'id': temaId});
              if (foro != null) {
                detalles = foro;
              }
              break;
            default:
              break;
          }
          if (detalles != null) {
            tema['detalles'] = detalles;
            debugPrint('ℹ️ [CursoRepository] Tema enriquecido: ${tema['titulo']} (${tema['tipo']})');
          }
        }
      }
      debugPrint('🎉 [CursoRepository] Unidades enriquecidas listas para la UI');
      return data;
    } catch (e) {
      ApiLogger.logError(operation: 'obtenerUnidadesConTemas', table: 'unidades/temas', error: e);
      throw Exception('Error al cargar las unidades del curso: $e');
    }
  }

  // ============================================================================
  // FUNCIONES PARA DATOS ESPECÍFICOS DE LAS PANTALLAS
  // ============================================================================

  /// Obtener información completa del estudiante para home.alumno.screen.dart
  Future<Map<String, dynamic>?> obtenerInformacionEstudiante(String codigoEstudiante) async {
    try {
      final response = await supabase
          .from('estudiantes')
          .select('''
            id,
            codigo_estudiante,
            nombre_completo,
            correo_electronico,
            semestre_actual,
            telefono,
            carreras!inner(
              nombre,
              codigo
            )
          ''')
          .eq('codigo_estudiante', codigoEstudiante)
          .single();

      // Obtener estadísticas adicionales
      final matriculasCount = await supabase
          .from('matriculas')
          .select('id')
          .eq('estudiante_id', response['id'])
          .eq('estado', 'matriculado')
          .count();

      // Obtener total de créditos
      final creditosResult = await supabase
          .from('matriculas')
          .select('''
            grupos_clase!inner(
              cursos!inner(creditos)
            )
          ''')
          .eq('estudiante_id', response['id'])
          .eq('estado', 'matriculado');

      int totalCreditos = 0;
      for (final matricula in creditosResult) {
        final creditos = matricula['grupos_clase']['cursos']['creditos'] as int? ?? 0;
        totalCreditos += creditos;
      }

      return {
        ...response,
        'total_cursos_matriculados': matriculasCount,
        'total_creditos': totalCreditos,
      };
    } catch (e) {
      throw Exception('Error al obtener información del estudiante: $e');
    }
  }

  /// Obtener anuncios generales para home.alumno.screen.dart
  Future<List<Map<String, dynamic>>> obtenerAnunciosGenerales({int limite = 5}) async {
    try {
      final response = await supabase
          .from('anuncios_generales')
          .select()
          .order('fecha_publicacion', ascending: false)
          .limit(limite);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener anuncios generales: $e');
    }
  }

  /// Obtener estadísticas del panel para home.alumno.screen.dart
  Future<Map<String, dynamic>> obtenerEstadisticasPanel(String estudianteId) async {
    try {
      // Convertir ID de usuario a ID de estudiante si es necesario
      final estudianteIdReal = await _obtenerIdEstudianteReal(estudianteId);
      
      // Obtener número de cursos matriculados
      final cursosMatriculados = await supabase
          .from('matriculas')
          .select('id')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado')
          .count();

      // Obtener grupos de clase donde el estudiante está matriculado
      final matriculasResponse = await supabase
          .from('matriculas')
          .select('grupo_clase_id')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado');

      final gruposIds = matriculasResponse
          .map((m) => m['grupo_clase_id'] as String)
          .toList();

      int tareasPendientes = 0;
      int examenesPendientes = 0;

      if (gruposIds.isNotEmpty) {
        // Contar tareas pendientes (no entregadas y no vencidas)
        final tareasResult = await supabase
            .from('tareas')
            .select('id')
            .inFilter('grupo_clase_id', gruposIds)
            .eq('estado', 'activa')
            .gte('fecha_entrega', DateTime.now().toIso8601String());

        final tareas = List<Map<String, dynamic>>.from(tareasResult);
        
        for (final tarea in tareas) {
          final entregaExiste = await supabase
              .from('entregas_tareas')
              .select('id')
              .eq('tarea_id', tarea['id'])
              .eq('estudiante_id', estudianteId)
              .maybeSingle();
          
          if (entregaExiste == null) {
            tareasPendientes++;
          }
        }

        // Contar exámenes pendientes
        final examenesResult = await supabase
            .from('examenes')
            .select('id')
            .inFilter('grupo_clase_id', gruposIds)
            .eq('estado', 'publicado')
            .gte('fecha_limite', DateTime.now().toIso8601String());

        final examenes = List<Map<String, dynamic>>.from(examenesResult);
        
        for (final examen in examenes) {
          final intentoExiste = await supabase
              .from('intentos_examenes')
              .select('id')
              .eq('examen_id', examen['id'])
              .eq('estudiante_id', estudianteId)
              .eq('estado', 'finalizado')
              .maybeSingle();
          
          if (intentoExiste == null) {
            examenesPendientes++;
          }
        }
      }

      return {
        'cursosMatriculados': cursosMatriculados,
        'tareasPendientes': tareasPendientes,
        'examenesPendientes': examenesPendientes,
        'notificacionesNuevas': 0, // Por implementar si existe tabla de notificaciones
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas del panel: $e');
    }
  }

  /// Obtener tareas del estudiante para tareas.alumno.screen.dart
  Future<List<Map<String, dynamic>>> obtenerTareasEstudiante(String estudianteId) async {
    try {
      final estudianteIdReal = await _obtenerIdEstudianteReal(estudianteId);
      // Obtener los cursos donde el estudiante está matriculado
      final matriculasResponse = await supabase
          .from('matriculas')
          .select('curso_id')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado');
      final cursosIds = matriculasResponse.map((m) => m['curso_id'] as String).toList();
      if (cursosIds.isEmpty) {
        return [];
      }
      final tareasResponse = await supabase
          .from('tareas')
          .select()
          .inFilter('curso_id', cursosIds)
          .order('fecha_entrega', ascending: false);
      return List<Map<String, dynamic>>.from(tareasResponse);
    } catch (e) {
      throw Exception('Error al obtener tareas del estudiante: $e');
    }
  }

  /// Obtener videoconferencias del estudiante
  Future<List<Map<String, dynamic>>> obtenerVideoconferenciasEstudiante(String estudianteId) async {
    try {
      final estudianteIdReal = await _obtenerIdEstudianteReal(estudianteId);
      final matriculasResponse = await supabase
          .from('matriculas')
          .select('curso_id')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado');
      final cursosIds = matriculasResponse.map((m) => m['curso_id'] as String).toList();
      if (cursosIds.isEmpty) {
        return [];
      }
      final response = await supabase
          .from('videoconferencias')
          .select()
          .inFilter('curso_id', cursosIds)
          .order('fecha_inicio', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener videoconferencias del estudiante: $e');
    }
  }

  /// Obtener exámenes del estudiante
  Future<List<Map<String, dynamic>>> obtenerExamenesEstudiante(String estudianteId) async {
    try {
      final estudianteIdReal = await _obtenerIdEstudianteReal(estudianteId);
      final matriculasResponse = await supabase
          .from('matriculas')
          .select('curso_id')
          .eq('estudiante_id', estudianteIdReal)
          .eq('estado', 'matriculado');
      final cursosIds = matriculasResponse.map((m) => m['curso_id'] as String).toList();
      if (cursosIds.isEmpty) {
        return [];
      }
      final response = await supabase
          .from('examenes')
          .select()
          .inFilter('curso_id', cursosIds)
          .order('fecha_limite', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener exámenes del estudiante: $e');
    }
  }
} 