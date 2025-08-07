import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/periodo_academico.repository.dart';
import 'package:aulago/repositories/plataforma.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositories Providers
final plataformaRepositoryProvider = Provider((ref) => PlataformaRepository());
final periodoAcademicoRepositoryProvider = Provider((ref) => PeriodoAcademicoRepository());
final cursoRepositoryProvider = Provider((ref) => CursoRepository());
final estudianteRepositoryProvider = Provider((ref) => EstudianteRepository());


final supabaseProvider = Provider((ref) => Supabase.instance.client);

final anunciosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return [];
});

final fechasImportantesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return [];
});

final periodosAcademicosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return [];
});

final periodoSeleccionadoProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final usuarioActualProvider = Provider<ModeloUsuario?>((ref) {
  final authState = ref.watch(proveedorAuthProvider);
  if (authState.estaAutenticado && authState.usuario != null && authState.usuario!.esEstudiante) {
    return authState.usuario;
  }
  return null;
});

final cursosEstudianteActualProvider = FutureProvider.autoDispose<List<ModeloCursoDetallado>>((ref) async {
  final cursoRepo = ref.watch(cursoRepositoryProvider);
  final estudiante = ref.watch(usuarioActualProvider);

  if (estudiante == null) {
    throw Exception('No hay un estudiante autenticado');
  }
  
  return cursoRepo.obtenerCursosEstudiante(estudiante.id);
});

final estadisticasEstudianteActualProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final estudianteRepo = ref.watch(estudianteRepositoryProvider);
  final estudiante = ref.watch(usuarioActualProvider);

  if (estudiante == null) {
    throw Exception('No hay un estudiante autenticado');
  }

  return estudianteRepo.obtenerEstadisticasPanel(estudiante.id);
}); 