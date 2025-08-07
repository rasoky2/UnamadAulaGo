import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

/// Repositorio para gestión de matrículas
class MatriculaRepository extends BaseRepository<ModeloMatricula> {
  @override
  String get tableName => 'matriculas';
  
  @override
  String get repositoryName => 'MatriculaRepository';
  
  @override
  ModeloMatricula fromJson(Map<String, dynamic> json) {
    return ModeloMatricula.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloMatricula entity) {
    return {
      'id': entity.id,
      'estudiante_id': entity.estudianteId,
      'curso_id': entity.cursoId,
      'periodo_academico_id': entity.periodoAcademicoId,
      'estado': entity.estado,
      'fecha_matricula': entity.fechaMatricula?.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloMatricula entity) {
    return entity.id;
  }

  Future<List<ModeloMatricula>> obtenerMatriculas({
    String? estudianteId,
    String? cursoId,
    String? estado,
    String? filtroTexto,
    int limite = 20,
    int offset = 0,
  }) async {
      final filtros = <String, dynamic>{};
    try {
      if (estudianteId != null) {
        filtros['estudiante_id'] = estudianteId;
      }
      if (cursoId != null) {
        filtros['curso_id'] = cursoId;
      }
      if (estado != null) {
        filtros['estado'] = estado;
      }
      if (filtroTexto != null) {
        filtros['filtro_texto'] = filtroTexto;
      }
      filtros['limite'] = limite;
      filtros['offset'] = offset;
      
      var query = supabase
        .from('matriculas')
        .select('''
          *,
          estudiantes!inner(
            nombre_completo,
            correo_electronico,
            codigo_estudiante
          ),
          cursos(
            nombre,
            codigo_curso,
            profesores(nombre_completo)
          ),
          periodos_academicos!inner(
            nombre
          )
          ''');

      // Aplicar filtros
      if (estudianteId != null) {
        query = query.eq('estudiante_id', estudianteId);
      }
      if (cursoId != null) {
        query = query.eq('curso_id', cursoId);
      }
      if (estado != null) {
        query = query.eq('estado', estado);
      }

      final result = await query.limit(limite).range(offset, offset + limite - 1);
      
      ApiLogger.logGet(
        table: 'matriculas',
        statusCode: 200,
        response: {'count': result.length},
        filters: filtros,
      );
      
      return (result as List)
        .map((json) => ModeloMatricula.fromJson(json))
        .toList();
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'matriculas',
        error: e,
        additionalInfo: 'Filtros: $filtros',
      );
      rethrow;
    }
  }

  Future<ModeloMatricula?> obtenerMatriculaPorId(String id) async {
    try {
    final respuesta = await supabase
        .from('matriculas')
        .select('''
          *,
          estudiantes!inner(nombre_completo, correo_electronico),
          cursos(
            nombre,
            codigo_curso
          )
        ''')
        .eq('id', id)
        .single();
      
      ApiLogger.logGet(
        table: 'matriculas',
        statusCode: 200,
        response: respuesta,
        filters: {'id': id},
      );

    return ModeloMatricula.fromJson(respuesta);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'matriculas',
        error: e,
        additionalInfo: 'ID solicitado: $id',
      );
      return null;
    }
  }

  Future<ModeloMatricula> crearMatricula(Map<String, dynamic> datos) async {
    try {
      final datosRequest = <String, dynamic>{
          'estudiante_id': datos['estudianteId'],
          'periodo_academico_id': datos['periodoAcademicoId'],
          'estado': datos['estado'] ?? 'matriculado',
          'fecha_matricula': DateTime.now().toIso8601String(),
      };

      // Agregar curso_id si se especifica
      if (datos['cursoId'] != null) {
        datosRequest['curso_id'] = datos['cursoId'];
      }

      final result = await supabase
        .from('matriculas')
        .insert(datosRequest)
        .select('''
          *,
          estudiantes!inner(nombre_completo, correo_electronico),
            cursos(
              nombre,
            codigo_curso,
            profesores(nombre_completo)
          ),
          periodos_academicos!inner(nombre)
        ''')
        .single();

      ApiLogger.logPost(
        table: 'matriculas',
        statusCode: 201,
        response: result,
        requestBody: datosRequest,
      );

    return ModeloMatricula.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'POST',
        table: 'matriculas',
        error: e,
        additionalInfo: 'Datos enviados: $datos',
      );
      rethrow;
    }
  }

  Future<ModeloMatricula> actualizarMatricula(String id, Map<String, dynamic> datos) async {
    try {
      final datosRequest = {
        'estado': datos['estado'],
      };
      
    final result = await supabase
        .from('matriculas')
        .update(datosRequest)
        .eq('id', id)
        .select('''
          *,
          estudiantes!inner(nombre_completo, correo_electronico),
          cursos(
            nombre,
            codigo_curso
          )
        ''')
        .single();

      ApiLogger.logUpdate(
        table: 'matriculas',
        statusCode: 200,
        response: result,
        requestBody: datosRequest,
      );

    return ModeloMatricula.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'UPDATE',
        table: 'matriculas',
        error: e,
        additionalInfo: 'ID: $id, Datos: $datos',
      );
      rethrow;
    }
  }

  Future<void> eliminarMatricula(String id) async {
    try {
      final result = await supabase
        .from('matriculas')
        .delete()
        .eq('id', id);

      ApiLogger.logDelete(
        table: 'matriculas',
        statusCode: 204,
        response: result,
        id: id,
      );
    } catch (e) {
      ApiLogger.logError(
        operation: 'DELETE',
        table: 'matriculas',
        error: e,
        additionalInfo: 'ID: $id',
      );
      rethrow;
    }
  }

  Future<bool> verificarMatriculaExiste({
    required String estudianteId,
    String? cursoId,
  }) async {
    try {
      final filtros = <String, dynamic>{
        'estudiante_id': estudianteId,
        'estado': 'matriculado',
      };

      var query = supabase
        .from('matriculas')
        .select('id')
        .eq('estudiante_id', estudianteId)
        .eq('estado', 'matriculado');

      // Verificar matrícula por curso específico
      if (cursoId != null) {
        query = query.eq('curso_id', cursoId);
        filtros['curso_id'] = cursoId;
      }

      final result = await query.maybeSingle();
    
      final existe = result != null;
      
      ApiLogger.logGet(
        table: 'matriculas',
        statusCode: 200,
        response: {'existe': existe, 'data': result},
        filters: filtros,
      );

      return existe;
    } catch (e) {
      ApiLogger.logError(
        operation: 'VERIFICAR',
        table: 'matriculas',
        error: e,
        additionalInfo: 'Estudiante: $estudianteId, Curso: $cursoId',
      );
      return false;
    }
  }

  Future<int> contarMatriculas({
    String? estudianteId,
    String? cursoId,
    String? estado,
    String? filtroTexto,
    int limite = 20,
    int offset = 0,
  }) async {
    final filtros = <String, dynamic>{};
    try {
      var query = supabase
        .from('matriculas')
        .select('id');
      if (estudianteId != null) {
        query = query.eq('estudiante_id', estudianteId);
        filtros['estudiante_id'] = estudianteId;
      }
      if (cursoId != null) {
        query = query.eq('curso_id', cursoId);
        filtros['curso_id'] = cursoId;
      }
      if (estado != null) {
        query = query.eq('estado', estado);
        filtros['estado'] = estado;
      }
      final result = await query;
      return (result as List).length;
    } catch (e) {
      ApiLogger.logError(
        operation: 'COUNT',
        table: 'matriculas',
        error: e,
        additionalInfo: 'Filtros: $filtros',
      );
      rethrow;
    }
  }

  /// Obtiene los estudiantes disponibles para matricular
  Future<List<Map<String, dynamic>>> obtenerEstudiantesDisponibles() async {
    try {
      final result = await supabase
        .from('estudiantes')
        .select('id, nombre_completo, codigo_estudiante, correo_electronico')
        .eq('estado', 'activo')
        .order('nombre_completo');

      ApiLogger.logGet(
        table: 'estudiantes',
        statusCode: 200,
        response: {'count': result.length},
        filters: {'disponibles_matricula': true},
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'estudiantes',
        error: e,
        additionalInfo: 'Obteniendo estudiantes disponibles',
      );
      rethrow;
    }
  }

  /// Obtiene los cursos disponibles para matricular
  Future<List<Map<String, dynamic>>> obtenerCursosDisponibles() async {
    try {
      final result = await supabase
        .from('cursos')
        .select('''
          id,
          codigo_curso,
          nombre,
          descripcion,
          creditos,
          semestre_recomendado,
          es_obligatorio
        ''')
        .order('semestre_recomendado')
        .order('codigo_curso');

      ApiLogger.logGet(
        table: 'cursos',
        statusCode: 200,
        response: {'count': result.length},
        filters: {'disponibles_matricula': true},
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'cursos',
        error: e,
        additionalInfo: 'Obteniendo cursos disponibles',
      );
      rethrow;
    }
  }

  /// Obtiene los períodos académicos activos
  Future<List<Map<String, dynamic>>> obtenerPeriodosAcademicos() async {
    try {
      final result = await supabase
        .from('periodos_academicos')
        .select('id, nombre, anio, semestre, estado')
        .order('anio', ascending: false)
        .order('semestre', ascending: false);

      ApiLogger.logGet(
        table: 'periodos_academicos',
        statusCode: 200,
        response: {'count': result.length},
        filters: {'para_matriculas': true},
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'periodos_academicos',
        error: e,
        additionalInfo: 'Obteniendo períodos académicos',
      );
      rethrow;
    }
  }

  /// Obtiene los cursos disponibles para matriculación agrupados por carrera
  Future<List<Map<String, dynamic>>> obtenerCursosParaMatriculacion({
    String? carreraId,
    String? periodoAcademicoId,
  }) async {
    try {
      // Query base para obtener cursos con sus grupos de clase
      var query = supabase
        .from('cursos')
        .select('''
          id,
          codigo_curso,
          nombre,
          descripcion,
          creditos,
          semestre_recomendado,
          es_obligatorio,
          carreras!inner(
            id,
            nombre,
            codigo
          ),
          periodos_academicos!inner(
            id,
            nombre
          )
        ''');

      // Aplicar filtros si se especifican
      if (carreraId != null) {
        query = query.eq('carrera_id', carreraId);
      }

      if (periodoAcademicoId != null) {
        query = query.eq('periodo_academico_id', periodoAcademicoId);
      }

      // Solo grupos activos con cupos disponibles
      final result = await query
        .eq('estado', 'activo')
        .order('codigo_curso');

      ApiLogger.logGet(
        table: 'cursos_matriculacion',
        statusCode: 200,
        response: {'count': result.length},
        filters: {
          'carrera_id': carreraId,
          'periodo_academico_id': periodoAcademicoId,
        },
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'cursos_matriculacion',
        error: e,
        additionalInfo: 'Obteniendo cursos para matriculación',
      );
      rethrow;
    }
  }

  /// Obtiene las carreras disponibles para filtrar
  Future<List<Map<String, dynamic>>> obtenerCarrerasParaMatriculacion() async {
    try {
      final result = await supabase
        .from('carreras')
        .select('''
          id,
          nombre,
          codigo,
          facultades!inner(nombre)
        ''')
        .order('facultades.nombre')
        .order('nombre');

      ApiLogger.logGet(
        table: 'carreras',
        statusCode: 200,
        response: {'count': result.length},
        filters: {'para_matriculacion': true},
      );

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'carreras',
        error: e,
        additionalInfo: 'Obteniendo carreras para matriculación',
      );
      rethrow;
    }
  }

  /// Verifica si un estudiante puede matricularse en un curso
  Future<Map<String, dynamic>> verificarElegibilidadCurso(
    String estudianteId, 
    String cursoId
  ) async {
    try {
      // Verificar si ya está matriculado en algún grupo de este curso
      final matriculaExistente = await supabase
        .from('matriculas')
        .select('''
          id,
          estado,
          curso_id
        ''')
        .eq('estudiante_id', estudianteId)
                 .eq('curso_id', cursoId)
         .inFilter('estado', ['matriculado', 'activo'])
         .maybeSingle();

      if (matriculaExistente != null) {
        return {
          'elegible': false,
          'razon': 'Ya está matriculado en este curso',
          'detalle': 'Estado: ${matriculaExistente['estado']}'
        };
      }

      return {
        'elegible': true,
        'razon': 'Puede matricularse',
        'detalle': 'Cumple todos los requisitos'
      };

    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'elegibilidad_curso',
        error: e,
        additionalInfo: 'Verificando elegibilidad para curso $cursoId',
      );
      return {
        'elegible': false,
        'razon': 'Error en verificación',
        'detalle': e.toString()
      };
    }
  }

  /// Crear múltiples matrículas de una vez (ahora soporta matrículas directas)
  Future<Map<String, dynamic>> crearMatriculasMultiples(
    List<Map<String, dynamic>> matriculas
  ) async {
    try {
      ApiLogger.logPost(
        table: 'matriculas_multiples',
        statusCode: 200,
        response: {'cantidad': matriculas.length},
      );

      final resultados = <Map<String, dynamic>>[];
      final errores = <Map<String, dynamic>>[];

      for (final matricula in matriculas) {
        try {
          final estudianteId = matricula['estudiante_id'] as String;
          final cursoId = matricula['curso_id'] as String?;

          // Verificar que al menos uno esté presente
          if (cursoId == null) {
            errores.add({
              'matricula': matricula,
              'error': 'Debe especificar curso_id'
            });
            continue;
          }

          // Verificar elegibilidad
            final elegibilidad = await verificarElegibilidadCurso(estudianteId, cursoId);
            if (!elegibilidad['elegible']) {
              errores.add({
                'matricula': matricula,
                'error': elegibilidad['razon']
              });
              continue;
            }

            // Verificar si ya está matriculado en el curso
            final yaMatriculado = await verificarMatriculaExiste(
              estudianteId: estudianteId,
              cursoId: cursoId,
            );

            if (yaMatriculado) {
              errores.add({
                'matricula': matricula,
                'error': 'Ya está matriculado en este curso'
              });
              continue;
          }

          // Crear la matrícula
          final datosMatricula = <String, dynamic>{
            'estudiante_id': estudianteId,
            'periodo_academico_id': matricula['periodo_academico_id'],
            'estado': 'matriculado',
            'fecha_matricula': DateTime.now().toIso8601String(),
          };

            datosMatricula['curso_id'] = cursoId;

          final nuevaMatricula = await supabase
            .from('matriculas')
            .insert(datosMatricula)
            .select()
            .single();

          resultados.add(nuevaMatricula);

        } catch (e) {
          errores.add({
            'matricula': matricula,
            'error': e.toString()
          });
        }
      }

      ApiLogger.logPost(
        table: 'matriculas_multiples',
        statusCode: resultados.isNotEmpty ? 201 : 400,
        response: {
          'exitosas': resultados.length,
          'fallidas': errores.length,
        },
      );

      return {
        'exitosas': resultados,
        'fallidas': errores,
        'total_procesadas': matriculas.length,
        'total_exitosas': resultados.length,
        'total_fallidas': errores.length,
      };

    } catch (e) {
      ApiLogger.logError(
        operation: 'POST',
        table: 'matriculas_multiples',
        error: e,
        additionalInfo: 'Creando matrículas múltiples',
      );
      rethrow;
    }
  }

  /// Crear matrícula directa a un curso
  Future<ModeloMatricula> crearMatriculaDirecta({
    required String estudianteId,
    required String cursoId,
    required String periodoAcademicoId,
  }) async {
    try {
      // Verificar elegibilidad
      final elegibilidad = await verificarElegibilidadCurso(estudianteId, cursoId);
      if (!elegibilidad['elegible']) {
        throw Exception('Estudiante no elegible: ${elegibilidad['razon']}');
      }

      // Verificar si ya está matriculado
      final yaMatriculado = await verificarMatriculaExiste(
        estudianteId: estudianteId,
        cursoId: cursoId,
      );

      if (yaMatriculado) {
        throw Exception('El estudiante ya está matriculado en este curso');
      }

      // Crear la matrícula directa
      final datosRequest = {
        'estudiante_id': estudianteId,
        'curso_id': cursoId,
        'periodo_academico_id': periodoAcademicoId,
        'estado': 'matriculado',
        'fecha_matricula': DateTime.now().toIso8601String(),
      };

      final result = await supabase
        .from('matriculas')
        .insert(datosRequest)
        .select('''
          *,
          estudiantes!inner(nombre_completo, correo_electronico),
          cursos!inner(nombre, codigo_curso)
        ''')
        .single();

      ApiLogger.logPost(
        table: 'matricula_directa',
        statusCode: 201,
        response: result,
        requestBody: datosRequest,
      );

      return ModeloMatricula.fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'POST',
        table: 'matricula_directa',
        error: e,
        additionalInfo: 'Estudiante: $estudianteId, Curso: $cursoId',
      );
      rethrow;
    }
  }

  /// Obtiene los cursos disponibles específicamente para un estudiante
  Future<List<Map<String, dynamic>>> obtenerCursosDisponiblesParaEstudiante(
    String estudianteId, {
    String? periodoAcademicoId,
  }) async {
    try {
      // Primero obtener información del estudiante (carrera, semestre)
      final estudianteResponse = await supabase
        .from('estudiantes')
        .select('''
          carrera_id,
          semestre_actual,
          carreras!inner(
            id,
            nombre
          )
        ''')
        .eq('id', estudianteId)
        .maybeSingle();

      if (estudianteResponse == null) {
        throw Exception('Estudiante no encontrado');
      }

      final estudiante = estudianteResponse;
      final carreraId = estudiante['carrera_id'] as String;
      final semestreActual = estudiante['semestre_actual'] as int? ?? 1;

      // DEBUG: Log información del estudiante
      ApiLogger.logGet(
        table: 'debug_estudiante_info',
        statusCode: 200,
        response: {
          'estudiante_id': estudianteId,
          'carrera_id': carreraId,
          'carrera_nombre': estudiante['carreras']['nombre'],
          'semestre_actual': semestreActual,
        },
      );

      // Obtener TODOS los cursos de la carrera del estudiante
      final cursosQuery = await supabase
        .from('cursos')
        .select('''
          id,
          codigo_curso,
          nombre,
          descripcion,
          creditos,
          semestre_recomendado,
          es_obligatorio
        ''')
        .eq('carrera_id', carreraId)
        .order('semestre_recomendado')
        .order('codigo_curso');

      // DEBUG: Log cursos encontrados en la consulta inicial
      ApiLogger.logGet(
        table: 'debug_cursos_query',
        statusCode: 200,
        response: {
          'total_cursos_encontrados': cursosQuery.length,
          'carrera_id': carreraId,
          'periodo_academico_id': periodoAcademicoId,
          'cursos_encontrados': cursosQuery.map((c) => {
            'id': c['id'],
            'codigo_curso': c['codigo_curso'],
            'nombre': c['nombre'],
          }).toList(),
        },
      );

      // Obtener cursos ya matriculados por el estudiante (tanto directos como por grupo)
      final matriculasEstudiante = await supabase
        .from('matriculas')
        .select('''
          estado,
          nota_final,
          curso_id
        ''')
        .eq('estudiante_id', estudianteId);

      final cursosMatriculados = <String>{};
      final cursosCompletados = <String>{};

      for (final matricula in matriculasEstudiante) {
        // Obtener curso_id ya sea directo o del grupo
        final String? cursoId = matricula['curso_id'] as String?;

        if (cursoId != null) {
          final estado = matricula['estado'] as String;
          final notaFinal = matricula['nota_final'] as double?;

          if (estado == 'matriculado' || estado == 'activo') {
            cursosMatriculados.add(cursoId);
          } else if (estado == 'completado' && (notaFinal ?? 0) >= 60) {
            cursosCompletados.add(cursoId);
          }
        }
      }

      // DEBUG: Log matrículas del estudiante
      ApiLogger.logGet(
        table: 'debug_matriculas_estudiante',
        statusCode: 200,
        response: {
          'total_matriculas': matriculasEstudiante.length,
          'cursos_matriculados': cursosMatriculados.toList(),
          'cursos_completados': cursosCompletados.toList(),
          'matriculas_detalle': matriculasEstudiante.map((m) => {
            'curso_id': m['curso_id'],
            'estado': m['estado'],
            'nota_final': m['nota_final'],
          }).toList(),
        },
      );

      // Al final, elimina cualquier uso de gruposPorCurso, grupos_disponibles, etc.
      // Filtrar cursos disponibles
      final cursosDisponibles = <Map<String, dynamic>>[];
      final cursosDescartados = <Map<String, String>>[];

      for (final curso in cursosQuery) {
        final cursoId = curso['id'] as String;
        final cursoNombre = curso['nombre'] as String;
        
        // Saltar si ya está matriculado
        if (cursosMatriculados.contains(cursoId)) {
          cursosDescartados.add({
            'curso_id': cursoId,
            'nombre': cursoNombre,
            'razon': 'Ya matriculado'
          });
          continue;
        }

        // Saltar si ya completó el curso
        if (cursosCompletados.contains(cursoId)) {
          cursosDescartados.add({
            'curso_id': cursoId,
            'nombre': cursoNombre,
            'razon': 'Ya completado'
          });
          continue;
        }

        // Verificar prerequisitos
        final prerequisitos = curso['prerequisitos'] as List<dynamic>?;
        bool cumplePrerequisitos = true;
        String razonPrerequisitos = '';

        if (prerequisitos != null && prerequisitos.isNotEmpty) {
          for (final prerequisitoId in prerequisitos) {
            if (!cursosCompletados.contains(prerequisitoId)) {
              cumplePrerequisitos = false;
              razonPrerequisitos = 'Falta prerequisito: $prerequisitoId';
              break;
            }
          }
        }

        if (!cumplePrerequisitos) {
          cursosDescartados.add({
            'curso_id': cursoId,
            'nombre': cursoNombre,
            'razon': razonPrerequisitos
          });
          continue;
        }

        // Agregar información del curso
        final cursoConInfo = Map<String, dynamic>.from(curso);
        
        // Agregar información de elegibilidad
        cursoConInfo['elegibilidad'] = {
          'puede_matricular': true,
          'razon': 'Disponible',
          'semestre_recomendado': curso['semestre_recomendado'],
          'semestre_estudiante': semestreActual,
          'tiene_grupos': false, // No hay grupos de clase en esta lógica
          'matricula_directa_posible': true, // Siempre permitir matrícula directa
        };

        cursosDisponibles.add(cursoConInfo);
      }

      // DEBUG: Log resultado final
      ApiLogger.logGet(
        table: 'debug_resultado_final',
        statusCode: 200,
        response: {
          'cursos_disponibles': cursosDisponibles.length,
          'cursos_descartados': cursosDescartados.length,
          'detalle_descartados': cursosDescartados,
          'detalle_disponibles': cursosDisponibles.map((c) => {
            'id': c['id'],
            'nombre': c['nombre'],
            'grupos_disponibles': 0, // No hay grupos de clase
            'matricula_directa': c['elegibilidad']['matricula_directa_posible'],
          }).toList(),
        },
      );

      ApiLogger.logGet(
        table: 'cursos_estudiante',
        statusCode: 200,
        response: {
          'estudiante_id': estudianteId,
          'carrera': estudiante['carreras']['nombre'],
          'semestre_actual': semestreActual,
          'cursos_disponibles': cursosDisponibles.length,
        },
        filters: {
          'periodo_academico_id': periodoAcademicoId,
        },
      );

      return cursosDisponibles;

    } catch (e) {
      ApiLogger.logError(
        operation: 'GET',
        table: 'cursos_estudiante',
        error: e,
        additionalInfo: 'Obteniendo cursos disponibles para estudiante $estudianteId',
      );
      rethrow;
    }
  }
} 