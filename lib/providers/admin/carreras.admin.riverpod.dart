import 'dart:async';

import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/facultad.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio
final carreraRepositoryProvider = Provider<CarreraRepository>((ref) {
  return CarreraRepository();
});

final facultadRepositoryProvider = Provider<FacultadRepository>((ref) {
  return FacultadRepository();
});

// Provider principal para gestión de carreras
final carrerasAdminProvider = StateNotifierProvider<CarrerasAdminNotifier, CarrerasAdminData>((ref) {
  return CarrerasAdminNotifier(
    ref.read(carreraRepositoryProvider),
  );
});

// Provider para facultades disponibles
final facultadesDisponiblesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.read(facultadRepositoryProvider);
  return repository.obtenerFacultadesDropdown();
});

// Provider para carreras dropdown
final carrerasDropdownProvider = FutureProvider<List<ModeloCarrera>>((ref) async {
  final repository = ref.read(carreraRepositoryProvider);
  return repository.obtenerCarrerasDropdown();
});

// Notifier principal
class CarrerasAdminNotifier extends StateNotifier<CarrerasAdminData> {

  CarrerasAdminNotifier(this._repository) : super(const CarrerasAdminData()) {
    // Cargar carreras después de un microtask para evitar problemas de renderizado
    Future.microtask(cargarCarreras);
  }
  final CarreraRepository _repository;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> cargarCarreras({bool refrescar = false}) async {
    if (refrescar || state.carreras.isEmpty) {
      state = state.copyWith(cargando: true);
    }

    try {
      final resultado = await _repository.obtenerCarreras(
        filtroTexto: state.filtroTexto,
        filtroFacultad: state.filtroFacultad,
        pagina: state.pagina,
      );

      state = state.copyWith(
        carreras: resultado['carreras'] as List<ModeloCarrera>,
        totalCarreras: resultado['total'] as int,
        totalPaginas: resultado['totalPaginas'] as int,
        cargando: false,
      );
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: e.toString(),
      );
    }
  }

  void aplicarFiltroTexto(String? texto) {
    final textoLimpio = texto?.isEmpty == true ? null : texto?.trim();
    
    if (state.filtroTexto != textoLimpio) {
      // Cancelar el timer anterior si existe
      _debounceTimer?.cancel();
      
      // Actualizar el estado inmediatamente para mostrar el texto en el campo
      state = state.copyWith(filtroTexto: textoLimpio, pagina: 1);
      
      // Programar la búsqueda con debounce de 500ms
      _debounceTimer = Timer(const Duration(milliseconds: 500), cargarCarreras);
    }
  }

  void aplicarFiltroFacultad(String? facultadId) {
    if (state.filtroFacultad != facultadId) {
      state = state.copyWith(
        filtroFacultad: facultadId?.isEmpty == true ? null : facultadId, 
        pagina: 1
      );
      cargarCarreras();
    }
  }

  void limpiarFiltros() {
    state = state.limpiarEstado();
    cargarCarreras();
  }

  void cambiarPagina(int nuevaPagina) {
    if (nuevaPagina != state.pagina && nuevaPagina > 0 && nuevaPagina <= state.totalPaginas) {
      state = state.copyWith(pagina: nuevaPagina);
      cargarCarreras();
    }
  }

  Future<void> refrescar() async {
    await cargarCarreras(refrescar: true);
  }

  // Crear carrera
  Future<bool> crearCarrera(CrearEditarCarreraData datos) async {
    try {
      state = state.copyWith(cargando: true);
      
      await _repository.crearCarrera(datos);
      
      // Refrescar lista
      await cargarCarreras();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Editar carrera
  Future<bool> editarCarrera(String id, CrearEditarCarreraData datos) async {
    try {
      state = state.copyWith(cargando: true);
      
      await _repository.actualizarCarrera(id, datos);
      
      // Refrescar lista
      await cargarCarreras();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Eliminar carrera
  Future<bool> eliminarCarrera(String id) async {
    try {
      state = state.copyWith(cargando: true);
      
      await _repository.eliminarCarrera(id);
      
      // Refrescar lista
      await cargarCarreras();
      
      return true;
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Obtener carrera por ID
  Future<ModeloCarrera?> obtenerCarreraPorId(String id) async {
    try {
      return await _repository.obtenerCarreraPorId(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Validar código único
  Future<bool> validarCodigoUnico(String codigo, [String? excluirId]) async {
    try {
      return await _repository.esCodigoUnico(codigo, excluirId);
    } catch (e) {
      return false;
    }
  }

  // Buscar carreras
  Future<List<ModeloCarrera>> buscarCarreras(String termino) async {
    try {
      return await _repository.buscarCarreras(termino);
    } catch (e) {
      return [];
    }
  }
}

// Provider para formulario de crear/editar carrera
final formularioCarreraProvider = StateNotifierProvider.autoDispose<FormularioCarreraNotifier, CrearEditarCarreraData?>((ref) {
  return FormularioCarreraNotifier();
});

class FormularioCarreraNotifier extends StateNotifier<CrearEditarCarreraData?> {
  FormularioCarreraNotifier() : super(null);

  void inicializar({
    ModeloCarrera? carrera,
    String? facultadIdPorDefecto,
  }) {
    if (carrera != null) {
      // Modo edición
      state = CrearEditarCarreraData(
        id: carrera.id,
        nombre: carrera.nombre,
        codigo: carrera.codigo,
        descripcion: carrera.descripcion,
        facultadId: carrera.facultadId,
        duracionSemestres: carrera.duracionSemestres,
        directorNombre: carrera.directorNombre,
        directorEmail: carrera.directorEmail,
      );
    } else {
      // Modo creación
      state = CrearEditarCarreraData(
        nombre: '',
        codigo: '',
        descripcion: '',
        facultadId: facultadIdPorDefecto ?? '',
        duracionSemestres: 10,
        directorNombre: '',
        directorEmail: '',
      );
    }
  }

  void actualizarNombre(String nombre) {
    if (state != null) {
      state = state!.copyWith(nombre: nombre);
    }
  }

  void actualizarCodigo(String codigo) {
    if (state != null) {
      state = state!.copyWith(codigo: codigo.toUpperCase());
    }
  }

  void actualizarDescripcion(String descripcion) {
    if (state != null) {
      state = state!.copyWith(descripcion: descripcion);
    }
  }

  void actualizarFacultad(String facultadId) {
    if (state != null) {
      state = state!.copyWith(facultadId: facultadId);
    }
  }

  void actualizarDuracion(int duracion) {
    if (state != null) {
      state = state!.copyWith(duracionSemestres: duracion);
    }
  }

  void actualizarDirectorNombre(String nombre) {
    if (state != null) {
      state = state!.copyWith(directorNombre: nombre);
    }
  }

  void actualizarDirectorEmail(String email) {
    if (state != null) {
      state = state!.copyWith(directorEmail: email);
    }
  }

  void limpiar() {
    state = null;
  }
}
