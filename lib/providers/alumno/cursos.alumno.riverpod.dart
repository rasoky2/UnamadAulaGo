import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/examen.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/repositories/foro.repository.dart';
import 'package:aulago/repositories/lectura.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/repositories/videoconferencia.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repositories
final cursoRepoProvider = Provider((ref) => CursoRepository());
final tareaRepoProvider = Provider((ref) => TareaRepository());
final examenRepoProvider = Provider((ref) => ExamenRepository());
final foroRepoProvider = Provider((ref) => ForoRepository());
final lecturaRepoProvider = Provider((ref) => LecturaRepository());
final videoconferenciaRepoProvider = Provider((ref) => VideoconferenciaRepository());
final usuarioActualProvider = Provider<ModeloUsuario?>((ref) {
  final authState = ref.watch(proveedorAuthProvider);
  return authState.estaAutenticado ? authState.usuario : null;
});

// State
final cursoAlumnoStateProvider = StateNotifierProvider<CursoAlumnoStateNotifier, CursoAlumnoState>((ref) {
  return CursoAlumnoStateNotifier(ref);
});

class CursoAlumnoStateNotifier extends StateNotifier<CursoAlumnoState> {
  CursoAlumnoStateNotifier(this.ref) : super(const CursoAlumnoState()) {
    _init();
  }
  final Ref ref;

  Future<void> _init() async {
    final cursos = await ref.read(cursosAlumnoProvider.future);
    if (cursos.isNotEmpty && state.cursoSeleccionadoId == null) {
      state = state.copyWith(cursoSeleccionadoId: cursos.first.curso.id, grupoClaseSeleccionadoId: '');
    }
  }

  void seleccionarCurso(String cursoId) {
    state = state.copyWith(cursoSeleccionadoId: cursoId, grupoClaseSeleccionadoId: '');
  }
}

// Providers para la UI
final cursosAlumnoProvider = FutureProvider.autoDispose<List<ModeloCursoDetallado>>((ref) async {
  final cursoRepo = ref.watch(cursoRepoProvider);
  final estudiante = ref.watch(usuarioActualProvider);
  if (estudiante == null) {
    return [];
  }
  return cursoRepo.obtenerCursosEstudiante(estudiante.id);
});

final unidadesProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, cursoId) async {
  return ref.watch(cursoRepoProvider).obtenerUnidadesConTemas(cursoId);
});

final tareasProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(tareaRepoProvider).obtenerTareasConEntregas();
});

final examenesProvider = FutureProvider.family.autoDispose<List<ModeloExamen>, String>((ref, cursoId) async {
  return ref.watch(examenRepoProvider).obtenerExamenesPorCurso(cursoId);
});

final videoconferenciasProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, estudianteId) async {
  return ref.watch(cursoRepoProvider).obtenerVideoconferenciasEstudiante(estudianteId);
});

final forosProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final result = await ref.watch(foroRepoProvider).obtener();
  return result.items.map((foro) => foro.toJson()).toList();
});

final lecturasProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final result = await ref.watch(lecturaRepoProvider).obtener();
  return result.items;
});

final chatGrupalProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, grupoClaseId) async {
  return ref.watch(examenRepoProvider).obtenerMensajesChatGrupal(grupoClaseId);
});

/// Estado para los cursos del alumno
class CursoAlumnoState {

  const CursoAlumnoState({
    this.cursoSeleccionadoId,
    this.grupoClaseSeleccionadoId,
    this.cargando = false,
    this.error,
  });
  final String? cursoSeleccionadoId;
  final String? grupoClaseSeleccionadoId;
  final bool cargando;
  final String? error;

  CursoAlumnoState copyWith({
    String? cursoSeleccionadoId,
    String? grupoClaseSeleccionadoId,
    bool? cargando,
    String? error,
    bool unsetValue = false,
  }) {
    return CursoAlumnoState(
      cursoSeleccionadoId: unsetValue ? null : cursoSeleccionadoId ?? this.cursoSeleccionadoId,
      grupoClaseSeleccionadoId: unsetValue ? null : grupoClaseSeleccionadoId ?? this.grupoClaseSeleccionadoId,
      cargando: cargando ?? this.cargando,
      error: error,
    );
  }
}

/// Provider para obtener un curso específico
final cursoDetalleProvider = FutureProvider.family<ModeloCurso?, String>((ref, cursoId) async {
  final repository = ref.read(cursoRepoProvider);
  return repository.obtenerCursoPorId(cursoId);
});

/// Provider para estadísticas de cursos
final estadisticasCursosProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(cursoRepoProvider);
  return repository.obtenerEstadisticasCursos();
});

/// Provider para obtener el detalle de un curso específico
final cursoDetalleAlumnoProvider = FutureProvider.family<ModeloCursoDetallado?, String>((ref, cursoId) async {
  final repository = ref.watch(cursoRepoProvider);
  return repository.obtenerCursoDetalladoPorId(cursoId);
});

/// Estado para los filtros de cursos
class CursosFiltros {

  const CursosFiltros({
    this.carreraId,
    this.profesorId,
    this.periodoId,
    this.busqueda,
  });
  final String? carreraId;
  final String? profesorId;
  final String? periodoId;
  final String? busqueda;

  CursosFiltros copyWith({
    String? carreraId,
    String? profesorId,
    String? periodoId,
    String? busqueda,
  }) {
    return CursosFiltros(
      carreraId: carreraId ?? this.carreraId,
      profesorId: profesorId ?? this.profesorId,
      periodoId: periodoId ?? this.periodoId,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

/// Provider para los filtros de cursos
final cursosFiltrosProvider = StateProvider<CursosFiltros>((ref) => const CursosFiltros());

/// Provider para obtener la lista de cursos filtrada
final cursosProvider = FutureProvider<List<ModeloCurso>>((ref) async {
  final repository = ref.read(cursoRepoProvider);
  final filtros = ref.watch(cursosFiltrosProvider);
  
  final cursos = await repository.obtenerCursos(
    carreraId: filtros.carreraId,
    profesorId: filtros.profesorId,
    periodoId: filtros.periodoId,
  );

  if (filtros.busqueda != null && filtros.busqueda!.isNotEmpty) {
    return cursos.where((curso) {
      final busqueda = filtros.busqueda!.toLowerCase();
      return curso.nombre.toLowerCase().contains(busqueda) ||
             curso.codigoCurso.toLowerCase().contains(busqueda) ||
             (curso.descripcion?.toLowerCase() ?? '').contains(busqueda);
    }).toList();
  }

  return cursos;
});
