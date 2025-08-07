import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final estudiantesRepositoryProvider = Provider((ref) => EstudianteRepository());

final estudiantesDelGrupoProvider =
    FutureProvider.family<List<EstudianteAdmin>, String>((ref, grupoClaseId) {
  final repository = ref.watch(estudiantesRepositoryProvider);
  return repository.obtenerEstudiantesPorGrupo(grupoClaseId);
});

/// Provider para obtener todos los estudiantes de un profesor específico
final estudiantesDelProfesorProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, profesorId) {
  final repository = ref.watch(estudiantesRepositoryProvider);
  return repository.obtenerEstudiantesPorProfesor(profesorId);
});

final estudiantesDelCursoProvider = FutureProvider.family((ref, String cursoId) async {
  final repo = ref.watch(estudianteRepositoryProvider);
  return repo.obtenerEstudiantesPorCurso(cursoId);
});
