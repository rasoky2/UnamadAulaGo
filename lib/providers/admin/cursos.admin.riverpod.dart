import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/profesor_admin.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/periodo_academico.repository.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Modelo para el estado de los filtros
class CursosAdminFiltros {

  const CursosAdminFiltros({
    this.busqueda = '',
    this.filtroCarreraId,
    this.filtroProfesorId,
    this.filtroPeriodoId,
  });
  final String busqueda;
  final String? filtroCarreraId;
  final String? filtroProfesorId;
  final String? filtroPeriodoId;

  CursosAdminFiltros copyWith({
    String? busqueda,
    String? filtroCarreraId,
    String? filtroProfesorId,
    String? filtroPeriodoId,
  }) {
    return CursosAdminFiltros(
      busqueda: busqueda ?? this.busqueda,
      filtroCarreraId: filtroCarreraId,
      filtroProfesorId: filtroProfesorId,
      filtroPeriodoId: filtroPeriodoId,
    );
  }
}

// 2. Modelo para el estado del Notifier
class CursosAdminState {

  const CursosAdminState({
    this.cursos = const AsyncLoading(),
    this.filtros = const CursosAdminFiltros(),
    this.carreras = const AsyncLoading(),
    this.profesores = const AsyncLoading(),
    this.periodosAcademicos = const AsyncLoading(),
  });
  final AsyncValue<List<ModeloCurso>> cursos;
  final CursosAdminFiltros filtros;
  final AsyncValue<List<ModeloCarrera>> carreras;
  final AsyncValue<List<ProfesorAdmin>> profesores;
  final AsyncValue<List<Map<String, dynamic>>> periodosAcademicos;

  CursosAdminState copyWith({
    AsyncValue<List<ModeloCurso>>? cursos,
    CursosAdminFiltros? filtros,
    AsyncValue<List<ModeloCarrera>>? carreras,
    AsyncValue<List<ProfesorAdmin>>? profesores,
    AsyncValue<List<Map<String, dynamic>>>? periodosAcademicos,
  }) {
    return CursosAdminState(
      cursos: cursos ?? this.cursos,
      filtros: filtros ?? this.filtros,
      carreras: carreras ?? this.carreras,
      profesores: profesores ?? this.profesores,
      periodosAcademicos: periodosAcademicos ?? this.periodosAcademicos,
    );
  }
}

// 3. El StateNotifier
class CursosAdminNotifier extends StateNotifier<CursosAdminState> {

  CursosAdminNotifier(this._cursoRepository, this._carreraRepository, this._profesorRepository, this._periodoAcademicoRepository) : super(const CursosAdminState()) {
    _cargarInicial();
  }
  final CursoRepository _cursoRepository;
  final CarreraRepository _carreraRepository;
  final ProfesorRepository _profesorRepository;
  final PeriodoAcademicoRepository _periodoAcademicoRepository;
  List<ModeloCurso> _cursosOriginales = [];

  Future<void> _cargarInicial() async {
    state = state.copyWith(
      cursos: const AsyncLoading(),
      carreras: const AsyncLoading(),
      profesores: const AsyncLoading(),
      periodosAcademicos: const AsyncLoading(),
    );
    try {
      final cursos = await _cursoRepository.obtenerCursos();
      final carreras = await _carreraRepository.obtenerCarrerasDropdown();
      final profesores = await _profesorRepository.obtenerProfesores(limite: 1000).then((value) => value.profesores);
      final periodosAcademicos = await _periodoAcademicoRepository.obtenerPeriodosAcademicos();
      
      _cursosOriginales = cursos;
      state = state.copyWith(
        cursos: AsyncData(cursos),
        carreras: AsyncData(carreras),
        profesores: AsyncData(profesores),
        periodosAcademicos: AsyncData(periodosAcademicos),
      );
      _filtrarCursos();
    } catch (e, s) {
      state = state.copyWith(
        cursos: AsyncError(e, s),
        carreras: AsyncError(e, s),
        profesores: AsyncError(e, s),
        periodosAcademicos: AsyncError(e, s),
      );
    }
  }

  void _filtrarCursos() {
    final busqueda = state.filtros.busqueda.toLowerCase();
    final filtroCarreraId = state.filtros.filtroCarreraId;
    final filtroProfesorId = state.filtros.filtroProfesorId;

    final cursosFiltrados = _cursosOriginales.where((curso) {
      final coincideBusqueda = curso.nombre.toLowerCase().contains(busqueda) ||
                               curso.codigoCurso.toLowerCase().contains(busqueda);
      
      final coincideCarrera = filtroCarreraId == null ||
                              curso.carreraId == filtroCarreraId;
      
      final coincideProfesor = filtroProfesorId == null ||
                               curso.profesorId == filtroProfesorId; // Asegúrate de que ModeloCurso tenga profesorId
      // Eliminado coincidePeriodo porque ModeloCurso ya no tiene periodoAcademicoId
      return coincideBusqueda && coincideCarrera && coincideProfesor;
    }).toList();
    state = state.copyWith(cursos: AsyncData(cursosFiltrados));
  }

  void cambiarBusqueda(String busqueda) {
    state = state.copyWith(filtros: state.filtros.copyWith(busqueda: busqueda));
    _filtrarCursos();
  }

  void aplicarFiltroCarrera(String? carreraId) {
    state = state.copyWith(filtros: state.filtros.copyWith(filtroCarreraId: carreraId));
    _filtrarCursos();
  }

  void aplicarFiltroProfesor(String? profesorId) {
    state = state.copyWith(filtros: state.filtros.copyWith(filtroProfesorId: profesorId));
    _filtrarCursos();
  }

  void aplicarFiltroPeriodo(String? periodoId) {
    state = state.copyWith(filtros: state.filtros.copyWith(filtroPeriodoId: periodoId));
    _filtrarCursos();
  }

  void refrescar() {
    _cargarInicial();
  }
  
  Future<void> crearCurso(Map<String, dynamic> datos) async {
    try {
      await _cursoRepository.crearCurso(datos);
      refrescar();
    } catch (e) {
      throw Exception('Error al crear el curso: $e');
    }
  }

  Future<void> actualizarCurso(String id, Map<String, dynamic> datos) async {
    try {
      await _cursoRepository.actualizarCurso(id, datos);
      refrescar();
    } catch (e) {
      throw Exception('Error al actualizar el curso: $e');
    }
  }

  Future<void> eliminarCurso(String id) async {
    try {
      await _cursoRepository.eliminarCurso(id);
      refrescar();
    } catch (e) {
      throw Exception('Error al eliminar el curso: $e');
    }
  }
}

// 4. El Provider
final cursoRepositoryProvider = Provider((ref) => CursoRepository());

final carreraRepositoryProvider = Provider((ref) => CarreraRepository());

final profesorRepositoryProvider = Provider((ref) => ProfesorRepository());

final periodoAcademicoRepositoryProvider = Provider((ref) => PeriodoAcademicoRepository());

final cursosAdminProvider = StateNotifierProvider<CursosAdminNotifier, CursosAdminState>((ref) {
  final cursoRepository = ref.watch(cursoRepositoryProvider);
  final carreraRepository = ref.watch(carreraRepositoryProvider);
  final profesorRepository = ref.watch(profesorRepositoryProvider);
  final periodoAcademicoRepository = ref.watch(periodoAcademicoRepositoryProvider);
  return CursosAdminNotifier(cursoRepository, carreraRepository, profesorRepository, periodoAcademicoRepository);
});
