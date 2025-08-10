import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/repositories/base.repository.dart';

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
    return entity.toJson();
  }
  
  @override
  String getId(ModeloMatricula entity) {
    return entity.id.toString();
  }

  // CRUD básico compatible con BaseRepository
  Future<List<ModeloMatricula>> obtenerTodos() async {
    // Mantener método básico por compatibilidad (sin joins)
    final result = await obtener(filtros: null, limite: 1000, offset: 0);
    return result.items;
  }

  Future<List<ModeloMatricula>> obtenerMatriculas() async {
    return obtenerTodos();
  }

  /// Obtiene matrículas con joins para mostrar nombres en la UI
  Future<List<ModeloMatricula>> obtenerMatriculasDetallado() async {
    final response = await supabase
        .from(tableName)
        .select('''
          *,
          estudiantes(id, nombre_completo, codigo_estudiante, foto_perfil_url),
          cursos(id, nombre, codigo_curso, carrera_id, profesores(nombre_completo)),
          periodos_academicos(id, nombre)
        ''')
        .order('id');

    return List<Map<String, dynamic>>.from(response)
        .map(ModeloMatricula.fromJson)
        .toList();
  }

  Future<ModeloMatricula?> obtenerMatriculaPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloMatricula> crearMatricula(ModeloMatricula matricula) async {
    return crear(matricula.toJson());
  }

  Future<ModeloMatricula> actualizarMatricula(int id, ModeloMatricula matricula) async {
    return actualizar(id.toString(), matricula.toJson());
  }

  Future<bool> eliminarMatricula(int id) async {
    await eliminar(id.toString());
    return true;
  }

  /// Verifica si ya existe una matrícula para estudiante-curso-periodo
  Future<bool> existeMatricula({
    required int estudianteId,
    required int cursoId,
    required int periodoId,
  }) async {
    final resp = await supabase
        .from(tableName)
        .select('id')
        .eq('estudiante_id', estudianteId)
        .eq('curso_id', cursoId)
        .eq('periodo_academico_id', periodoId)
        .limit(1);
    // Si la lista trae al menos un elemento, existe.
    return (resp as List).isNotEmpty;
  }

  /// Devuelve cursos matriculados por código de estudiante
  Future<List<ModeloCursoDetallado>> obtenerCursosMatriculadosPorCodigo(String codigoEstudiante) async {
    final response = await supabase
        .from(tableName)
        .select('''
          cursos:curso_id(
            *,
            profesor:profesores!profesor_id(
              id,
              nombre_completo
            )
          ),
          estudiantes!inner(codigo_estudiante)
        ''')
        .eq('estudiantes.codigo_estudiante', codigoEstudiante);

    final List<ModeloCursoDetallado> cursos = [];
    for (final item in (response as List)) {
      final data = Map<String, dynamic>.from(item);
      final cursoData = data['cursos'];
      if (cursoData == null) continue;
      final cursoJson = Map<String, dynamic>.from(cursoData as Map);
      final profesorData = cursoJson.remove('profesor');

      final curso = ModeloCurso.fromJson(cursoJson);
      cursos.add(
        ModeloCursoDetallado(
          curso: curso,
          profesor: profesorData != null ? ModeloUsuario.fromProfesorJson(Map<String, dynamic>.from(profesorData as Map)) : null,
        ),
      );
    }

    // Evitar duplicados por si existen múltiples matrículas del mismo curso en distintos periodos
    final Map<int, ModeloCursoDetallado> porId = { for (final c in cursos) c.curso.id: c };
    return porId.values.toList();
  }
}
