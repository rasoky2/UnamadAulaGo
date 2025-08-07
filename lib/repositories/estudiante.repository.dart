import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
/// Provider para inyectar una instancia del EstudianteRepository
final estudianteRepositoryProvider = Provider<EstudianteRepository>((ref) {
  return EstudianteRepository();
});

/// Repositorio para gestión de estudiantes
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
    return {
      'id': entity.id,
      'codigo_estudiante': entity.codigoEstudiante,
      'nombre_completo': entity.nombreCompleto,
      'correo_electronico': entity.correoElectronico,
      'telefono': entity.telefono,
      'carrera_id': entity.carreraId,
      'carrera_nombre': entity.carreraNombre,
      'semestre_actual': entity.semestreActual,
      'estado': entity.estado,
      'fecha_nacimiento': entity.fechaNacimiento,
      'direccion': entity.direccion,
      'fecha_ingreso': entity.fechaIngreso,
      'fecha_actualizacion': entity.fechaActualizacion,
    };
  }
  
  @override
  String getId(EstudianteAdmin entity) {
    return entity.id;
  }

  Future<({List<EstudianteAdmin> estudiantes, int total})> obtenerEstudiantes({
    String? filtroTexto,
    FiltroEstadoEstudiante filtroEstado = FiltroEstadoEstudiante.todos,
    String? filtroCarrera,
    int limite = 10,
    int offset = 0,
  }) async {
    debugPrint('🔍 [EstudianteRepository] Obteniendo estudiantes...');
    debugPrint('📊 [EstudianteRepository] Filtros: texto=$filtroTexto, estado=$filtroEstado, carrera=$filtroCarrera');
    debugPrint('📄 [EstudianteRepository] Paginación: limite=$limite, offset=$offset');
    
    var query = supabase
        .from('estudiantes')
        .select('*, carreras(nombre)');

    if (filtroTexto != null && filtroTexto.isNotEmpty) {
       query = query.or(
          '''nombre_completo.ilike.%$filtroTexto%,
             codigo_estudiante.ilike.%$filtroTexto%,
             correo_electronico.ilike.%$filtroTexto%'''
        );
    }

    if (filtroEstado != FiltroEstadoEstudiante.todos) {
      final estadoFiltro = filtroEstado == FiltroEstadoEstudiante.activos ? 'activo' : 'inactivo';
      query = query.eq('estado', estadoFiltro);
    }
    
    if (filtroCarrera != null && filtroCarrera.isNotEmpty) {
      query = query.eq('carrera_id', filtroCarrera);
    }
    
    final response = await query
        .range(offset, offset + limite - 1)
        .order('nombre_completo')
        .count(CountOption.exact);
        
    final estudiantes = (response.data)
        .map((json) {
          // Ajustar el formato para que coincida con el modelo
          if (json['carreras'] != null) {
            json['carrera_nombre'] = json['carreras']['nombre'];
          }
          return EstudianteAdmin.fromJson(json);
        })
        .toList();
    
    final total = response.count;

    ApiLogger.logGet(
      table: 'estudiantes',
      statusCode: 200,
      response: {
        'estudiantes_count': estudiantes.length,
        'total': total,
        'filtros_aplicados': {
          'texto': filtroTexto,
          'estado': filtroEstado.toString(),
          'carrera': filtroCarrera,
        },
      },
      filters: {
        'filtroTexto': filtroTexto,
        'filtroEstado': filtroEstado.toString(),
        'filtroCarrera': filtroCarrera,
        'limite': limite,
        'offset': offset,
      },
    );

    debugPrint('✅ [EstudianteRepository] Estudiantes obtenidos: ${estudiantes.length} de $total');
    return (estudiantes: estudiantes, total: total);
  }

  Future<EstudianteAdmin?> obtenerEstudiantePorId(String id) async {
    final respuesta = await supabase
        .from('estudiantes')
        .select('*, carreras(nombre)')
        .eq('id', id)
        .single();
    
    // Ajustar el formato para que coincida con el modelo
    if (respuesta['carreras'] != null) {
      respuesta['carrera_nombre'] = respuesta['carreras']['nombre'];
    }
    
    return EstudianteAdmin.fromJson(respuesta);
  }

  Future<List<ModeloMatricula>> obtenerMatriculasEstudiante(String estudianteId) async {
    final respuesta = await supabase
        .from('matriculas')
        .select('''
          *,
          cursos!inner(*),
          grupos_clase!inner(*)
        ''')
        .eq('estudiante_id', estudianteId)
        .order('fecha_matricula', ascending: false);

    return (respuesta as List)
        .map((json) => ModeloMatricula.fromJson(json))
        .toList();
  }

  Future<EstudianteAdmin> crearEstudiante(Map<String, dynamic> datos) async {
    debugPrint('🎓 [EstudianteRepository] Iniciando creación de estudiante...');
    debugPrint('📝 [EstudianteRepository] Datos recibidos: $datos');
    
    // 1. PRIMERO: Crear el usuario en la tabla usuarios
    debugPrint('👤 [EstudianteRepository] Creando usuario en tabla usuarios...');
    final usuarioResult = await supabase
        .from('usuarios')
        .insert({
          'codigo_usuario': datos['codigo_estudiante'],
          'contrasena_hash': 'password_temporal',
          'nombre_completo': datos['nombre_completo'],
          'correo_electronico': datos['correo_electronico'],
          'rol': 'estudiante',
          'activo': true,
        })
        .select()
        .single();
    
    ApiLogger.logPost(
      table: 'usuarios',
      statusCode: 201,
      response: usuarioResult,
      requestBody: {
        'codigo_usuario': datos['codigo_estudiante'],
        'nombre_completo': datos['nombre_completo'],
        'correo_electronico': datos['correo_electronico'],
        'rol': 'estudiante',
        'activo': true,
      },
    );
    
    debugPrint('✅ [EstudianteRepository] Usuario creado exitosamente: ${usuarioResult['id']}');

    try {
      // 2. SEGUNDO: Crear el estudiante con referencia al usuario
      debugPrint('🎓 [EstudianteRepository] Creando estudiante en tabla estudiantes...');
      debugPrint('🔗 [EstudianteRepository] Usuario ID: ${usuarioResult['id']}');
      debugPrint('📚 [EstudianteRepository] Carrera ID: ${datos['carrera_id']}');
      debugPrint('📅 [EstudianteRepository] Semestre: ${datos['semestre_actual']}');
      
      final estudianteResult = await supabase
          .from('estudiantes')
          .insert({
            'codigo_estudiante': datos['codigo_estudiante'],
            'contrasena_hash': 'password_temporal',
          'nombre_completo': datos['nombre_completo'],
          'correo_electronico': datos['correo_electronico'],
          'telefono': datos['telefono'],
          'carrera_id': datos['carrera_id'],
            'semestre_actual': datos['semestre_actual'] ?? 1,
          'estado': datos['estado'] ?? 'activo',
          'rol': 'estudiante',
          'fecha_nacimiento': datos['fecha_nacimiento'],
          'direccion': datos['direccion'],
          'fecha_ingreso': DateTime.now().toIso8601String(),
            'usuario_id': usuarioResult['id'], // ← CLAVE: Establecer la relación
        })
        .select('*, carreras(nombre)')
        .single();
      
      ApiLogger.logPost(
        table: 'estudiantes',
        statusCode: 201,
        response: estudianteResult,
        requestBody: {
          'codigo_estudiante': datos['codigo_estudiante'],
          'nombre_completo': datos['nombre_completo'],
          'correo_electronico': datos['correo_electronico'],
          'telefono': datos['telefono'],
          'carrera_id': datos['carrera_id'],
          'semestre_actual': datos['semestre_actual'] ?? 1,
          'estado': datos['estado'] ?? 'activo',
          'rol': 'estudiante',
          'usuario_id': usuarioResult['id'],
        },
      );
      
      debugPrint('✅ [EstudianteRepository] Estudiante creado exitosamente: ${estudianteResult['id']}');

    // Ajustar el formato para que coincida con el modelo
      if (estudianteResult['carreras'] != null) {
        estudianteResult['carrera_nombre'] = estudianteResult['carreras']['nombre'];
    }

      // Ajustar el formato para que coincida con el modelo
      if (estudianteResult['carreras'] != null) {
        estudianteResult['carrera_nombre'] = estudianteResult['carreras']['nombre'];
    }

      debugPrint('🎉 [EstudianteRepository] Estudiante creado completamente exitoso');
      return EstudianteAdmin.fromJson(estudianteResult);
    } catch (e) {
      // Si falla la creación del estudiante, eliminar el usuario creado
      debugPrint('❌ [EstudianteRepository] Error al crear estudiante: $e');
      debugPrint('🗑️ [EstudianteRepository] Eliminando usuario creado: ${usuarioResult['id']}');
      
      ApiLogger.logError(
        operation: 'crearEstudiante',
        table: 'estudiantes',
        error: e,
        additionalInfo: 'Eliminando usuario creado: ${usuarioResult['id']}',
      );
      
      await supabase
          .from('usuarios')
          .delete()
          .eq('id', usuarioResult['id']);
      rethrow;
    }
  }

  Future<EstudianteAdmin> actualizarEstudiante(String id, Map<String, dynamic> datos) async {
    debugPrint('✏️ [EstudianteRepository] Actualizando estudiante ID: $id');
    debugPrint('📝 [EstudianteRepository] Datos a actualizar: $datos');
    
    // 1. PRIMERO: Obtener el estudiante actual para conocer su usuario_id
    debugPrint('🔍 [EstudianteRepository] Obteniendo estudiante actual...');
    final estudianteActual = await supabase
        .from('estudiantes')
        .select('usuario_id')
        .eq('id', id)
        .single();

    // 2. SEGUNDO: Actualizar la tabla usuarios si tiene usuario_id
    if (estudianteActual['usuario_id'] != null) {
      debugPrint('👤 [EstudianteRepository] Actualizando usuario ID: ${estudianteActual['usuario_id']}');
      await supabase
          .from('usuarios')
          .update({
            'codigo_usuario': datos['codigo_estudiante'],
            'nombre_completo': datos['nombre_completo'],
            'correo_electronico': datos['correo_electronico'],
          })
          .eq('id', estudianteActual['usuario_id']);
      
      ApiLogger.logUpdate(
        table: 'usuarios',
        statusCode: 200,
        response: {'updated': true},
        requestBody: {
          'codigo_usuario': datos['codigo_estudiante'],
          'nombre_completo': datos['nombre_completo'],
          'correo_electronico': datos['correo_electronico'],
        },
      );
    }

    // 3. TERCERO: Actualizar la tabla estudiantes
    debugPrint('🎓 [EstudianteRepository] Actualizando estudiante en tabla estudiantes...');
    final result = await supabase
        .from('estudiantes')
        .update({
          'codigo_estudiante': datos['codigo_estudiante'],
          'nombre_completo': datos['nombre_completo'],
          'correo_electronico': datos['correo_electronico'],
          'telefono': datos['telefono'],
          'carrera_id': datos['carrera_id'],
          'semestre_actual': datos['semestre_actual'],
          'estado': datos['estado'] ?? 'activo',
          'fecha_nacimiento': datos['fecha_nacimiento'],
          'direccion': datos['direccion'],
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select('*, carreras(nombre)')
        .single();
    
    ApiLogger.logUpdate(
      table: 'estudiantes',
      statusCode: 200,
      response: result,
      requestBody: {
        'codigo_estudiante': datos['codigo_estudiante'],
        'nombre_completo': datos['nombre_completo'],
        'correo_electronico': datos['correo_electronico'],
        'telefono': datos['telefono'],
        'carrera_id': datos['carrera_id'],
        'semestre_actual': datos['semestre_actual'],
        'estado': datos['estado'] ?? 'activo',
      },
    );
    
    debugPrint('✅ [EstudianteRepository] Estudiante actualizado exitosamente');

    // Ajustar el formato para que coincida con el modelo
    if (result['carreras'] != null) {
      result['carrera_nombre'] = result['carreras']['nombre'];
    }

    return EstudianteAdmin.fromJson(result);
  }

  Future<void> cambiarEstadoEstudiante(String id, {required bool activo}) async {
    // 1. Obtener el estudiante actual para conocer su usuario_id
    final estudianteActual = await supabase
        .from('estudiantes')
        .select('usuario_id')
        .eq('id', id)
        .single();

    // 2. Actualizar la tabla usuarios si tiene usuario_id
    if (estudianteActual['usuario_id'] != null) {
      await supabase
          .from('usuarios')
          .update({'activo': activo})
          .eq('id', estudianteActual['usuario_id']);
    }

    // 3. Actualizar la tabla estudiantes
    await supabase
        .from('estudiantes')
        .update({
          'estado': activo ? 'activo' : 'inactivo',
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<bool> verificarCodigoExiste(String codigo, {String? excludeId}) async {
    // Verificar en ambas tablas: estudiantes y usuarios
    final estudianteResult = await supabase
        .from('estudiantes')
        .select('id')
        .eq('codigo_estudiante', codigo)
        .neq('id', excludeId ?? '')
        .maybeSingle();
    
    final usuarioResult = await supabase
        .from('usuarios')
        .select('id')
        .eq('codigo_usuario', codigo)
        .maybeSingle();
    
    return estudianteResult != null || usuarioResult != null;
  }

  Future<bool> verificarEmailExiste(String email, {String? excludeId}) async {
    // Verificar en ambas tablas: estudiantes y usuarios
    final estudianteResult = await supabase
        .from('estudiantes')
        .select('id')
        .eq('correo_electronico', email)
        .neq('id', excludeId ?? '')
        .maybeSingle();
    
    final usuarioResult = await supabase
        .from('usuarios')
        .select('id')
        .eq('correo_electronico', email)
        .maybeSingle();
    
    return estudianteResult != null || usuarioResult != null;
  }

  /// Obtiene lista de carreras disponibles
  Future<List<ModeloCarrera>> obtenerCarreras() async {
    debugPrint('📚 [EstudianteRepository] Obteniendo carreras disponibles...');
    
    final response = await supabase
        .from('carreras')
        .select()
        .order('nombre');
    
    ApiLogger.logGet(
      table: 'carreras',
      statusCode: 200,
      response: {
        'carreras_count': response.length,
        'carreras': response,
      },
    );
    
    debugPrint('✅ [EstudianteRepository] Carreras obtenidas: ${response.length}');
    return (response as List).map((json) => ModeloCarrera.fromJson(json)).toList();
  }

  /// Obtiene la lista de estudiantes matriculados en un grupo de clase específico.
  Future<List<EstudianteAdmin>> obtenerEstudiantesPorGrupo(String grupoClaseId) async {
    final matriculasResponse = await supabase
      .from('matriculas')
      .select('estudiante_id')
      .eq('grupo_clase_id', grupoClaseId);
      
    final List<String> estudianteIds = matriculasResponse
      .map((matricula) => matricula['estudiante_id'] as String)
      .toList();

    if (estudianteIds.isEmpty) {
      return [];
    }

    final estudiantesResponse = await supabase
      .from('estudiantes')
      .select('*, carreras(nombre)')
      .filter('id', 'in', '(${estudianteIds.join(',')})')
      .order('nombre_completo');

    return (estudiantesResponse as List).map((json) {
      // Ajustar el formato para que coincida con el modelo
      if (json['carreras'] != null) {
        json['carrera_nombre'] = json['carreras']['nombre'];
      }
      return EstudianteAdmin.fromJson(json);
    }).toList();
  }

  /// Obtiene todos los estudiantes matriculados en los cursos de un profesor
  Future<List<Map<String, dynamic>>> obtenerEstudiantesPorProfesor(String profesorId) async {
    // Primero obtenemos todos los cursos del profesor
    final cursosResponse = await supabase
        .from('cursos')
        .select('id, nombre, codigo_curso')
        .eq('profesor_id', profesorId);

    if (cursosResponse.isEmpty) {
      return [];
    }

    final List<String> cursoIds = cursosResponse
        .map((curso) => curso['id'] as String)
        .toList();

    // Obtener matrículas directas (por curso)
    final matriculasDirectas = await supabase
        .from('matriculas')
        .select('''
          estudiante_id,
          curso_id,
          estudiantes!inner(
            id,
            nombre_completo,
            codigo_estudiante,
            correo_electronico,
            carrera_id,
            semestre_actual,
            estado,
            carreras(nombre)
          ),
          cursos!inner(
            id,
            nombre,
            codigo_curso
          )
        ''')
        .filter('curso_id', 'in', '(${cursoIds.join(',')})')
        .not('curso_id', 'is', null);

    // Procesar y estructurar los datos
    final Map<String, Map<String, dynamic>> estudiantesMap = {};

    // Procesar matrículas directas
    for (final matricula in matriculasDirectas) {
      final estudiante = matricula['estudiantes'];
      final curso = matricula['cursos'];
      final estudianteId = estudiante['id'];

      // Ajustar formato del estudiante
      if (estudiante['carreras'] != null) {
        estudiante['carrera_nombre'] = estudiante['carreras']['nombre'];
      }

      if (!estudiantesMap.containsKey(estudianteId)) {
        estudiantesMap[estudianteId] = {
          'estudiante': EstudianteAdmin.fromJson(estudiante),
          'cursos': <Map<String, dynamic>>[],
        };
      }

      // Agregar información del curso
      estudiantesMap[estudianteId]!['cursos'].add({
        'curso': curso,
        'grupo': null,
        'tipo_matricula': 'directa',
      });
    }

    return estudiantesMap.values.toList();
  }

  /// Obtiene la lista de estudiantes matriculados en un curso específico (por curso_id directo)
  Future<List<EstudianteAdmin>> obtenerEstudiantesPorCurso(String cursoId) async {
    final matriculasResponse = await supabase
      .from('matriculas')
      .select('estudiante_id')
      .eq('curso_id', cursoId);
    
    final List<String> estudianteIds = matriculasResponse
      .map((matricula) => matricula['estudiante_id'] as String)
      .toList();

    if (estudianteIds.isEmpty) {
      return [];
    }

    final estudiantesResponse = await supabase
      .from('estudiantes')
      .select('*, carreras(nombre)')
      .filter('id', 'in', '(${estudianteIds.join(',')})')
      .order('nombre_completo');

    return (estudiantesResponse as List).map((json) {
      if (json['carreras'] != null) {
        json['carrera_nombre'] = json['carreras']['nombre'];
      }
      return EstudianteAdmin.fromJson(json);
    }).toList();
  }

  /// Obtiene estadísticas de estudiantes
  Future<EstadisticasEstudiantes> obtenerEstadisticasEstudiantes() async {
    final response = await supabase
        .from('estudiantes')
        .select('''
          id,
          estado,
          fecha_creacion
        ''');

    final estudiantes = response as List;
    final activos = estudiantes.where((e) => e['estado'] == 'activo').length;
    final inactivos = estudiantes.where((e) => e['estado'] == 'inactivo').length;
    final nuevosEsteMes = estudiantes.where((e) => 
      DateTime.parse(e['fecha_creacion']).isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;

    return EstadisticasEstudiantes(
      totalEstudiantes: estudiantes.length,
      estudiantesActivos: activos,
      estudiantesInactivos: inactivos,
      nuevosEsteMes: nuevosEsteMes,
    );
  }

  Future<void> eliminarEstudiante(String id) async {
    debugPrint('🗑️ [EstudianteRepository] Eliminando estudiante ID: $id');
    
    // 1. Obtener el estudiante actual para conocer su usuario_id
    debugPrint('🔍 [EstudianteRepository] Obteniendo información del estudiante...');
    final estudianteActual = await supabase
        .from('estudiantes')
        .select('usuario_id')
        .eq('id', id)
        .single();

    // 2. Eliminar el estudiante
    debugPrint('🎓 [EstudianteRepository] Eliminando estudiante de tabla estudiantes...');
    await supabase
        .from('estudiantes')
        .delete()
        .eq('id', id);
    
    ApiLogger.logDelete(
      table: 'estudiantes',
      statusCode: 200,
      response: {'deleted': true},
      id: id,
    );

    // 3. Eliminar el usuario si existe (el FK debería eliminar automáticamente, pero por seguridad)
    if (estudianteActual['usuario_id'] != null) {
      debugPrint('👤 [EstudianteRepository] Eliminando usuario ID: ${estudianteActual['usuario_id']}');
      await supabase
          .from('usuarios')
          .delete()
          .eq('id', estudianteActual['usuario_id']);
      
      ApiLogger.logDelete(
        table: 'usuarios',
        statusCode: 200,
        response: {'deleted': true},
        id: estudianteActual['usuario_id'],
      );
    }
    
    debugPrint('✅ [EstudianteRepository] Estudiante eliminado exitosamente');
  }

  /// Obtiene las estadísticas para el panel de un alumno específico.
  Future<Map<String, int>> obtenerEstadisticasPanel(String estudianteId) async {
    try {
      // Obtener cursos matriculados desde la tabla matriculas
    final cursosMatriculados = await supabase
        .from('matriculas')
          .select('id')
          .eq('estudiante_id', estudianteId);

      // Simulamos datos para tareas y exámenes mientras se crean las tablas reales
      await Future.delayed(const Duration(milliseconds: 200));

    return {
        'cursos_matriculados': cursosMatriculados.length,
        'tareas_completadas': 5, // Datos de prueba
        'examenes_rendidos': 3,  // Datos de prueba
      };
    } catch (e) {
      // ignore: avoid_print
      print('Error al obtener estadísticas del panel: $e');
      // Devolver datos por defecto en caso de error
      return {
        'cursos_matriculados': 0,
        'tareas_completadas': 0,
        'examenes_rendidos': 0,
    };
    }
  }

  /// Actualiza el perfil del estudiante actual (para uso del alumno)
  Future<bool> actualizarPerfilEstudiante(String usuarioId, Map<String, dynamic> datos) async {
    try {
      // 1. Obtener el estudiante por usuario_id
      final estudianteActual = await supabase
          .from('estudiantes')
          .select('id, usuario_id')
          .eq('usuario_id', usuarioId)
          .single();

      // 2. Actualizar la tabla usuarios
      await supabase
          .from('usuarios')
          .update({
            'nombre_completo': datos['nombre_completo'],
            'correo_electronico': datos['correo_electronico'],
          })
          .eq('id', usuarioId);

      // 3. Actualizar la tabla estudiantes (solo campos permitidos para el alumno)
      await supabase
          .from('estudiantes')
          .update({
            'nombre_completo': datos['nombre_completo'],
            'correo_electronico': datos['correo_electronico'],
            'telefono': datos['telefono'],
            'fecha_nacimiento': datos['fecha_nacimiento'],
            'direccion': datos['direccion'],
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('id', estudianteActual['id']);

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error al actualizar perfil del estudiante: $e');
      return false;
    }
  }
}

/// Modelo para estadísticas de estudiantes
class EstadisticasEstudiantes {

  const EstadisticasEstudiantes({
    required this.totalEstudiantes,
    required this.estudiantesActivos,
    required this.estudiantesInactivos,
    required this.nuevosEsteMes,
  });
  final int totalEstudiantes;
  final int estudiantesActivos;
  final int estudiantesInactivos;
  final int nuevosEsteMes;
}

// Datos simulados basados en estructura real de Supabase

