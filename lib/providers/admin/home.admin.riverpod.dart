import 'package:aulago/models/estadisticas_admin.model.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/plataforma.repository.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositories Providers
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);
final adminEstudianteRepoProvider = Provider((ref) => EstudianteRepository());
final adminProfesorRepoProvider = Provider((ref) => ProfesorRepository());
final adminCursoRepoProvider = Provider((ref) => CursoRepository());

// 1. Provider para el repositorio de la plataforma
final plataformaRepositoryProvider = Provider((ref) => PlataformaRepository());

// 2. El StateNotifier para las estadísticas
class EstadisticasAdminNotifier extends StateNotifier<EstadisticasAdmin> {

  EstadisticasAdminNotifier(this._plataformaRepository) : super(const EstadisticasAdmin()) {
    _cargarEstadisticas();
  }
  final PlataformaRepository _plataformaRepository;

  Future<void> _cargarEstadisticas() async {
    state = state.copyWith(cargando: true);
    try {
      final statsMap = await _plataformaRepository.obtenerEstadisticasGenerales();
      state = state.copyWith(
        totalEstudiantes: statsMap['totalEstudiantes'],
        totalProfesores: statsMap['totalProfesores'],
        totalCursos: statsMap['totalCursos'],
        cargando: false,
      );
    } catch (e) {
      // En caso de error, dejamos las estadísticas en 0 y quitamos el loading.
      state = state.copyWith(cargando: false);
    }
  }

  void refrescarEstadisticas() {
    _cargarEstadisticas();
  }
}

// 3. El StateNotifierProvider principal
final estadisticasAdminProvider = StateNotifierProvider<EstadisticasAdminNotifier, EstadisticasAdmin>((ref) {
  final repo = ref.watch(plataformaRepositoryProvider);
  return EstadisticasAdminNotifier(repo);
});

// Placeholder Providers
final alertasSistemaProvider = FutureProvider<List<String>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return ['Sistema funcionando normalmente.'];
});

final actividadRecienteProvider = FutureProvider<List<String>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return ['Nuevo estudiante registrado: Juan Perez.'];
});

final configuracionSistemaProvider = Provider<Map<String, dynamic>>((ref) {
  return {'Mantenimiento': false, 'Version': '1.2.0'};
});
