import 'dart:math';

import 'package:aulago/models/profesor_admin.model.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Clase de Estado
class ProfesoresAdminState {

  const ProfesoresAdminState({
    this.profesores = const [],
    this.totalProfesores = 0,
    this.cargando = false,
    this.error,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.filtroTexto = '',
    this.filtroActivo,
    this.filtroFacultad,
  });
  final List<ProfesorAdmin> profesores;
  final int totalProfesores;
  final bool cargando;
  final String? error;
  final int pagina;
  final int totalPaginas;

  // Filtros
  final String filtroTexto;
  final bool? filtroActivo;
  final String? filtroFacultad;

  ProfesoresAdminState copyWith({
    List<ProfesorAdmin>? profesores,
    int? totalProfesores,
    bool? cargando,
    String? error,
    int? pagina,
    int? totalPaginas,
    String? filtroTexto,
    bool? filtroActivo,
    String? filtroFacultad,
  }) {
    return ProfesoresAdminState(
      profesores: profesores ?? this.profesores,
      totalProfesores: totalProfesores ?? this.totalProfesores,
      cargando: cargando ?? this.cargando,
      error: error,
      pagina: pagina ?? this.pagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      filtroTexto: filtroTexto ?? this.filtroTexto,
      filtroActivo: filtroActivo,
      filtroFacultad: filtroFacultad,
    );
  }
}

// 2. StateNotifier
class ProfesoresAdminNotifier extends StateNotifier<ProfesoresAdminState> {

  ProfesoresAdminNotifier(this._repository) : super(const ProfesoresAdminState()) {
    cargarProfesores();
  }
  final ProfesorRepository _repository;
  static const int _elementosPorPagina = 10;

  Future<void> cargarProfesores() async {
    state = state.copyWith(cargando: true);
    try {
      final response = await _repository.obtenerProfesores(
        filtroTexto: state.filtroTexto,
        filtroActivo: state.filtroActivo,
        filtroFacultad: state.filtroFacultad,
        offset: (state.pagina - 1) * _elementosPorPagina,
      );
      debugPrint('[PROFESORES] Total recibidos:  [1m${response.profesores.length} [0m');
      for (final p in response.profesores) {
        debugPrint(' - ${p.nombreCompleto} (${p.codigoProfesor})');
      }
      state = state.copyWith(
        profesores: response.profesores,
        totalProfesores: response.total,
        totalPaginas: (response.total / _elementosPorPagina).ceil(),
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), cargando: false);
    }
  }

  void cambiarPagina(int nuevaPagina) {
    state = state.copyWith(pagina: max(1, nuevaPagina));
    cargarProfesores();
  }
  
  void aplicarFiltroTexto(String texto) {
    state = state.copyWith(filtroTexto: texto, pagina: 1);
    cargarProfesores();
  }
  void aplicarFiltroActivo({bool? activo}) {
    state = state.copyWith(filtroActivo: activo, pagina: 1);
    cargarProfesores();
  }

  void aplicarFiltroFacultad(String? facultadId) {
    state = state.copyWith(filtroFacultad: facultadId, pagina: 1);
    cargarProfesores();
  }

  Future<void> crearProfesor(Map<String, dynamic> datos) async {
    await _repository.crearProfesor(datos);
    cargarProfesores();
  }

  Future<void> editarProfesor(String id, Map<String, dynamic> datos) async {
    await _repository.actualizarProfesor(id, datos);
    cargarProfesores();
  }

  Future<void> cambiarEstadoProfesor(String id, {required bool activo}) async {
    await _repository.cambiarEstadoProfesor(id, activo: activo);
    cargarProfesores();
  }

  Future<void> eliminarProfesor(String id) async {
    await _repository.eliminarProfesor(id);
    cargarProfesores();
  }
}

// 3. Provider
final profesorRepositoryProvider = Provider<ProfesorRepository>((ref) {
  return ProfesorRepository();
});

final profesoresAdminProvider = StateNotifierProvider<ProfesoresAdminNotifier, ProfesoresAdminState>((ref) {
  final repository = ref.watch(profesorRepositoryProvider);
  return ProfesoresAdminNotifier(repository);
});

final facultadesProvider = FutureProvider<List<FacultadAdmin>>((ref) async {
  final repository = ref.watch(profesorRepositoryProvider);
  return repository.obtenerFacultades();
});

final gradosAcademicosProvider = Provider<List<String>>((ref) {
  return [
    'Licenciado',
    'Magister',
    'Doctor',
    'PhD',
  ];
});

final cursosProfesorProvider = FutureProvider.family<List<CursoProfesor>, String>((ref, profesorId) async {
  final repository = ref.watch(profesorRepositoryProvider);
  return repository.obtenerCursosProfesor(profesorId);
}); 