import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para el repositorio de cursos
final cursoRepositoryProvider = Provider((ref) => CursoRepository());

// Provider para el repositorio de tareas
final tareaRepositoryProvider = Provider((ref) => TareaRepository());

// Provider para obtener los cursos del profesor autenticado
final cursosProfesorProvider = FutureProvider<List<ModeloCurso>>((ref) async {
  final authState = ref.watch(proveedorAuthProvider);
  final usuario = authState.usuario;
  if (usuario == null || !usuario.esProfesor) {
    throw Exception('Acceso denegado. Se requiere ser profesor.');
  }
  final repository = ref.watch(cursoRepositoryProvider);
  // Buscar el ID de la tabla profesores usando usuario.id
  final supabase = Supabase.instance.client;
  final profesorRow = await supabase
      .from('profesores')
      .select('id')
      .eq('usuario_id', usuario.id)
      .maybeSingle();
  if (profesorRow == null) {
    throw Exception('No se encontró el registro de profesor para el usuario actual.');
  }
  final profesorId = profesorRow['id'] as String;
  return repository.obtenerCursos(profesorId: profesorId);
});

// Provider para obtener las tareas de un curso
final tareasPorCursoProvider = FutureProvider.family<List<ModeloTarea>, String>((ref, cursoId) async {
  final repository = ref.watch(tareaRepositoryProvider);
  return repository.obtenerTareas(cursoId: cursoId);
});
