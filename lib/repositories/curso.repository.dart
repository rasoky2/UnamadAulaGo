import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

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
    return entity.toJson();
  }
  
  @override
  String getId(ModeloCurso entity) {
    return entity.id.toString();
  }

  // CRUD básico compatible con BaseRepository
  Future<List<ModeloCurso>> obtenerTodos() async {
    final result = await obtener();
    return result.items;
  }

  Future<List<ModeloCurso>> obtenerCursos() async {
    return obtenerTodos();
  }

  Future<ModeloCurso?> obtenerCursoPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloCurso> crearCurso(ModeloCurso curso) async {
    return crear(curso.toJson());
  }

  Future<ModeloCurso> actualizarCurso(int id, ModeloCurso curso) async {
    return actualizar(id.toString(), curso.toJson());
  }

  Future<bool> eliminarCurso(int id) async {
    await eliminar(id.toString());
    return true;
  }

  /// Obtiene cursos con información completa del profesor
  Future<List<ModeloCursoDetallado>> obtenerCursosConProfesor() async {
    try {
      final response = await supabase
          .from(tableName)
          .select('''
            *,
            profesor:profesores!profesor_id(
              id,
              nombre_completo
            )
          ''');

      final List<ModeloCursoDetallado> cursosDetallados = [];
      
      for (final item in response) {
        final cursoJson = Map<String, dynamic>.from(item);
        final profesorData = cursoJson.remove('profesor');
        
        // Crear el curso base
        final curso = ModeloCurso.fromJson(cursoJson);
        
        // Crear el curso detallado con información del profesor
        final cursoDetallado = ModeloCursoDetallado(
          curso: curso,
          profesor: profesorData != null 
              ? ModeloUsuario.fromProfesorJson(profesorData)
              : null,
        );
        
        cursosDetallados.add(cursoDetallado);
      }
      
      return cursosDetallados;
    } catch (e) {
      debugPrint('Error al obtener cursos con profesor: $e');
      // Fallback: devolver cursos básicos convertidos a detallados
      final cursosBasicos = await obtenerCursos();
      return cursosBasicos.map((curso) => ModeloCursoDetallado(curso: curso)).toList();
    }
  }
} 