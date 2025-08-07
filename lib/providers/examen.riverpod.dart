import 'package:aulago/models/examen.model.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que inyecta una instancia del ExamenRepository
final examenRepositoryProvider = Provider<ExamenRepository>((ref) {
  return ExamenRepository();
});

/// Provider que expone los exámenes de un grupo de clase
final examenesProvider = FutureProvider.family<List<ModeloExamen>, String>((ref, cursoId) async {
  final repository = ref.watch(examenRepositoryProvider);
  return repository.obtenerExamenesPorCurso(cursoId);
}); 