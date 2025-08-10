import 'package:aulago/models/estadisticas_admin.model.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para las estadísticas del admin
final estadisticasAdminProvider = StateNotifierProvider<EstadisticasAdminNotifier, EstadisticasAdmin>((ref) {
  return EstadisticasAdminNotifier();
});

class EstadisticasAdminNotifier extends StateNotifier<EstadisticasAdmin> {
  EstadisticasAdminNotifier() : super(const EstadisticasAdmin()) {
    cargarEstadisticas();
  }

  final _estudianteRepo = EstudianteRepository();
  final _cursoRepo = CursoRepository();
  final _matriculaRepo = MatriculaRepository();

  Future<void> cargarEstadisticas() async {
    state = state.copyWith(cargando: true);
    
    try {
      // Cargar datos en paralelo
      final estudiantes = await _estudianteRepo.obtenerTodos();
      final cursos = await _cursoRepo.obtenerTodos();
      final matriculas = await _matriculaRepo.obtenerTodos();

      // Calcular estadísticas básicas
      final totalEstudiantes = estudiantes.length;
      final totalCursos = cursos.length;
      
      // Calcular porcentaje de actividad (simulado basado en matrículas recientes)
      final hoy = DateTime.now();
      final matriculasRecientes = matriculas.where((m) {
        final fechaMatricula = m.fechaMatricula;
        if (fechaMatricula == null) {
          return false;
        }
        return hoy.difference(fechaMatricula).inDays <= 30;
      }).length;
      
      final porcentajeActivosHoy = totalEstudiantes > 0 
          ? (matriculasRecientes / totalEstudiantes) * 100 
          : 0.0;

      state = EstadisticasAdmin(
        totalEstudiantes: totalEstudiantes,
        totalCursos: totalCursos,
        porcentajeActivosHoy: porcentajeActivosHoy,
      );

    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: 'Error al cargar estadísticas: $e',
      );
    }
  }

  void refrescar() {
    cargarEstadisticas();
  }
}
