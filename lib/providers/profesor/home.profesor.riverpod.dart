import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final cursosProfesorProvider = FutureProvider<List<ModeloCurso>>((ref) async {
  final authState = ref.watch(proveedorAuthProvider);
  final usuario = authState.usuario;

  if (!authState.estaAutenticado || usuario == null || !usuario.esProfesor) {
    throw Exception('Usuario no autenticado o no es un profesor.');
  }

  final profesorRepository = ref.watch(profesorRepositoryProvider);
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
  return profesorRepository.getCursos(profesorId);
});
