import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

/// Repositorio para gestión de carreras
class CarreraRepository extends BaseRepository<ModeloCarrera> {
  @override
  String get tableName => 'carreras';
  
  @override
  String get repositoryName => 'CarreraRepository';
  
  @override
  ModeloCarrera fromJson(Map<String, dynamic> json) {
    return ModeloCarrera.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloCarrera entity) {
    return {
      'id': entity.id,
      'codigo': entity.codigo,
      'nombre': entity.nombre,
      'descripcion': entity.descripcion,
      'duracion_semestres': entity.duracionSemestres,
      'director_nombre': entity.directorNombre,
      'director_email': entity.directorEmail,
      'facultad_id': entity.facultadId,
      'fecha_creacion': entity.fechaCreacion.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloCarrera entity) {
    return entity.id;
  }

  // Obtener todas las carreras con filtros y paginación
  Future<Map<String, dynamic>> obtenerCarreras({
    String? filtroTexto,
    String? filtroFacultad,
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      var query = supabase
          .from('carreras')
          .select('''
            *,
            facultades!inner(
              id,
              nombre,
              codigo
            )
          ''');

      // Aplicar filtros
      if (filtroTexto != null && filtroTexto.isNotEmpty) {
        query = query.or('nombre.ilike.%$filtroTexto%,codigo.ilike.%$filtroTexto%,director_nombre.ilike.%$filtroTexto%');
      }

      if (filtroFacultad != null && filtroFacultad.isNotEmpty) {
        query = query.eq('facultad_id', filtroFacultad);
      }

      // Obtener total para paginación - query separado
      final countQuery = supabase.from('carreras').select('id');
      
      if (filtroTexto != null && filtroTexto.isNotEmpty) {
        countQuery.or('nombre.ilike.%$filtroTexto%,codigo.ilike.%$filtroTexto%,director_nombre.ilike.%$filtroTexto%');
      }

      if (filtroFacultad != null && filtroFacultad.isNotEmpty) {
        countQuery.eq('facultad_id', filtroFacultad);
      }

      final totalResponse = await countQuery;
      final total = totalResponse.length;

      // Aplicar paginación - corregir tipos
      final offset = (pagina - 1) * limite;
      final finalQuery = query.range(offset, offset + limite - 1).order('nombre');

      final response = await finalQuery;
      
      ApiLogger.logGet(
        table: 'carreras',
        statusCode: 200,
        response: response,
        filters: {
          'filtroTexto': filtroTexto,
          'filtroFacultad': filtroFacultad,
          'pagina': pagina,
          'limite': limite,
        },
      );
      
      final carreras = (response as List)
          .map((json) => ModeloCarrera.fromJson(json))
          .toList();

      return {
        'carreras': carreras,
        'total': total,
        'totalPaginas': (total / limite).ceil(),
        'paginaActual': pagina,
      };
    } catch (e) {
      ApiLogger.logError(
        operation: 'obtenerCarreras',
        table: 'carreras',
        error: e,
        additionalInfo: 'Filtros aplicados: texto=$filtroTexto, facultad=$filtroFacultad',
      );
      throw Exception('Error al obtener carreras: $e');
    }
  }

  // Obtener carrera por ID usando BaseRepository
  Future<ModeloCarrera?> obtenerCarreraPorId(String id) async {
    return obtenerPorId(id);
  }

  // Crear nueva carrera usando BaseRepository
  Future<ModeloCarrera> crearCarrera(CrearEditarCarreraData datos) async {
    try {
      // Verificar que el código no exista
      final existente = await supabase
          .from('carreras')
          .select('id')
          .eq('codigo', datos.codigo)
          .maybeSingle();

      if (existente != null) {
        throw Exception('Ya existe una carrera con el código ${datos.codigo}');
      }

      return await crear(datos.toJson());
    } catch (e) {
      if (e.toString().contains('Ya existe una carrera')) {
        rethrow;
      }
      throw Exception('Error al crear carrera: $e');
    }
  }

  // Actualizar carrera existente usando BaseRepository
  Future<ModeloCarrera> actualizarCarrera(String id, CrearEditarCarreraData datos) async {
    try {
      // Verificar que el código no exista en otra carrera
      final existente = await supabase
          .from('carreras')
          .select('id')
          .eq('codigo', datos.codigo)
          .neq('id', id)
          .maybeSingle();

      if (existente != null) {
        throw Exception('Ya existe otra carrera con el código ${datos.codigo}');
      }

      return await actualizar(id, datos.toJson());
    } catch (e) {
      if (e.toString().contains('Ya existe otra carrera')) {
        rethrow;
      }
      throw Exception('Error al actualizar carrera: $e');
    }
  }

  // Eliminar carrera usando BaseRepository
  Future<bool> eliminarCarrera(String id) async {
    try {
      // Verificar si hay estudiantes matriculados en esta carrera
      final estudiantesResponse = await supabase
          .from('estudiantes')
          .select('id')
          .eq('carrera_id', id);

      if (estudiantesResponse.isNotEmpty) {
        throw Exception('No se puede eliminar la carrera porque tiene estudiantes matriculados');
      }

      // Verificar si hay cursos asociados a esta carrera
      final cursosResponse = await supabase
          .from('cursos')
          .select('id')
          .eq('carrera_id', id);

      if (cursosResponse.isNotEmpty) {
        throw Exception('No se puede eliminar la carrera porque tiene cursos asociados');
      }

      await eliminar(id);
      return true;
    } catch (e) {
      if (e.toString().contains('No se puede eliminar')) {
        rethrow;
      }
      throw Exception('Error al eliminar carrera: $e');
    }
  }

  // Obtener carreras para dropdown (sin paginación)
  Future<List<ModeloCarrera>> obtenerCarrerasDropdown() async {
    try {
      final resultado = await obtener(orderBy: 'nombre');
      return resultado.items;
    } catch (e) {
      throw Exception('Error al obtener carreras para dropdown: $e');
    }
  }

  // Buscar carreras por texto
  Future<List<ModeloCarrera>> buscarCarreras(String termino) async {
    try {
      final resultado = await obtener(
        filtroTexto: termino,
        orderBy: 'nombre',
        limite: 10,
      );
      return resultado.items;
    } catch (e) {
      throw Exception('Error al buscar carreras: $e');
    }
  }

  // Validar código único
  Future<bool> esCodigoUnico(String codigo, [String? excluirId]) async {
    try {
      var query = supabase
          .from('carreras')
          .select('id')
          .eq('codigo', codigo);

      if (excluirId != null) {
        query = query.neq('id', excluirId);
      }

      final response = await query.maybeSingle();
      return response == null;
    } catch (e) {
      throw Exception('Error al validar código: $e');
    }
  }

  // Obtener estadísticas de carreras
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      // Total de carreras
      final totalCarrerasResponse = await supabase
          .from('carreras')
          .select('id');

      // Carreras por facultad
      final carrerasPorFacultad = await supabase
          .from('carreras')
          .select('''
            facultad_id,
            facultades!inner(nombre)
          ''');

      // Contar estudiantes por carrera
      final estudiantesPorCarrera = await supabase
          .from('estudiantes')
          .select('''
            carrera_id,
            carreras!inner(nombre)
          ''');

      return {
        'totalCarreras': totalCarrerasResponse.length,
        'carrerasPorFacultad': carrerasPorFacultad,
        'estudiantesPorCarrera': estudiantesPorCarrera,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
