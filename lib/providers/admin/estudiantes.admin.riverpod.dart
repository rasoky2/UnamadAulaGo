import 'dart:async';

import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio
final estudianteRepositoryProvider = Provider<EstudianteRepository>((ref) {
  return EstudianteRepository();
});

// Provider principal para gestión de estudiantes
final estudiantesAdminProvider = StateNotifierProvider<EstudiantesAdminNotifier, EstudiantesAdminData>((ref) {
  return EstudiantesAdminNotifier(ref.read(estudianteRepositoryProvider));
});

class EstudiantesAdminNotifier extends StateNotifier<EstudiantesAdminData> {

  EstudiantesAdminNotifier(this._repository) : super(const EstudiantesAdminData()) {
    // Cargar estudiantes después de un microtask para evitar problemas de renderizado
    Future.microtask(cargarEstudiantes);
  }
  final EstudianteRepository _repository;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static const int _estudiantesPorPagina = 20;

  Future<void> cargarEstudiantes({bool refrescar = false}) async {
    debugPrint('🔍 [EstudiantesAdminNotifier] Cargando estudiantes... refrescar=$refrescar');
    
    if (refrescar || state.estudiantes.isEmpty) {
      debugPrint('⏳ [EstudiantesAdminNotifier] Estableciendo estado de carga...');
      state = state.copyWith(cargando: true);
    }

    try {
      debugPrint('📊 [EstudiantesAdminNotifier] Filtros actuales: texto=${state.filtroTexto}, estado=${state.filtroEstado}, carrera=${state.filtroCarrera}');
      debugPrint('📄 [EstudiantesAdminNotifier] Paginación: página=${state.pagina}, límite=$_estudiantesPorPagina');
      
      final resultado = await _repository.obtenerEstudiantes(
        filtroTexto: state.filtroTexto,
        filtroEstado: state.filtroEstado,
        filtroCarrera: state.filtroCarrera,
        limite: _estudiantesPorPagina,
        offset: (state.pagina - 1) * _estudiantesPorPagina,
      );

      final totalPaginas = (resultado.total / _estudiantesPorPagina).ceil();
      debugPrint('✅ [EstudiantesAdminNotifier] Estudiantes obtenidos: ${resultado.estudiantes.length} de ${resultado.total}');
      debugPrint('📄 [EstudiantesAdminNotifier] Total de páginas: $totalPaginas');

      state = state.copyWith(
        estudiantes: resultado.estudiantes,
        cargando: false,
        totalEstudiantes: resultado.total,
        totalPaginas: totalPaginas > 0 ? totalPaginas : 1,
      );
    } catch (e) {
      debugPrint('❌ [EstudiantesAdminNotifier] Error al cargar estudiantes: $e');
      
      ApiLogger.logError(
        operation: 'cargarEstudiantes',
        table: 'estudiantes',
        error: e,
        additionalInfo: 'Provider level error',
      );
      
      state = state.copyWith(
        cargando: false,
        error: 'Error al cargar estudiantes: ${e.toString()}',
      );
    }
  }

  void cambiarPagina(int nuevaPagina) {
    if (nuevaPagina >= 1 && nuevaPagina <= state.totalPaginas && nuevaPagina != state.pagina) {
      state = state.copyWith(pagina: nuevaPagina);
      cargarEstudiantes();
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
      _debounceTimer = Timer(const Duration(milliseconds: 500), cargarEstudiantes);
    }
  }

  void aplicarFiltroEstado(FiltroEstadoEstudiante filtro) {
    if (state.filtroEstado != filtro) {
      state = state.copyWith(filtroEstado: filtro, pagina: 1);
      cargarEstudiantes();
    }
  }

  void aplicarFiltroCarrera(String? carreraId) {
    if (state.filtroCarrera != carreraId) {
      state = state.copyWith(
        filtroCarrera: carreraId?.isEmpty == true ? null : carreraId, 
        pagina: 1
      );
      cargarEstudiantes();
    }
  }

  void limpiarFiltros() {
    state = state.limpiarEstado();
    cargarEstudiantes();
  }

  Future<bool> crearEstudiante(FormularioEstudiante formulario) async {
    debugPrint('🎓 [EstudiantesAdminNotifier] Iniciando creación de estudiante...');
    debugPrint('📝 [EstudiantesAdminNotifier] Formulario: ${formulario.toJson()}');
    
    try {
      await _repository.crearEstudiante(formulario.toJson());
      debugPrint('✅ [EstudiantesAdminNotifier] Estudiante creado exitosamente en repositorio');
      
      await cargarEstudiantes(refrescar: true);
      debugPrint('🔄 [EstudiantesAdminNotifier] Lista de estudiantes actualizada');
      
      return true;
    } catch (e) {
      debugPrint('❌ [EstudiantesAdminNotifier] Error al crear estudiante: $e');
      
      ApiLogger.logError(
        operation: 'crearEstudiante',
        table: 'estudiantes',
        error: e,
        additionalInfo: 'Provider level error',
      );
      
      state = state.copyWith(
        error: 'Error al crear estudiante: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> actualizarEstudiante(String id, FormularioEstudiante formulario) async {
    try {
      await _repository.actualizarEstudiante(id, formulario.toJson());
      await cargarEstudiantes(refrescar: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al actualizar estudiante: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> eliminarEstudiante(String id) async {
    try {
      await _repository.eliminarEstudiante(id);
      await cargarEstudiantes(refrescar: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al eliminar estudiante: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> cambiarEstadoEstudiante(String id, {required bool activo}) async {
    try {
      await _repository.cambiarEstadoEstudiante(id, activo: activo);
      await cargarEstudiantes(refrescar: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cambiar estado del estudiante: ${e.toString()}',
      );
      return false;
    }
  }

  void limpiarError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }
}

// Provider para el formulario de estudiantes
final formularioEstudianteProvider = StateNotifierProvider<FormularioEstudianteNotifier, FormularioEstudiante>((ref) {
  return FormularioEstudianteNotifier();
});

class FormularioEstudianteNotifier extends StateNotifier<FormularioEstudiante> {
  FormularioEstudianteNotifier() : super(
    const FormularioEstudiante(
      nombres: '',
      apellidos: '',
      email: '',
      telefono: '',
      codigoEstudiante: '',
    ),
  );

  void actualizarNombres(String nombres) {
    state = state.copyWith(nombres: nombres);
  }

  void actualizarApellidos(String apellidos) {
    state = state.copyWith(apellidos: apellidos);
  }

  void actualizarEmail(String email) {
    state = state.copyWith(email: email);
  }

  void actualizarTelefono(String telefono) {
    state = state.copyWith(telefono: telefono);
  }

  void actualizarCodigoEstudiante(String codigo) {
    state = state.copyWith(codigoEstudiante: codigo);
  }

  void actualizarCarrera(String? carreraId) {
    state = state.copyWith(carreraId: carreraId);
  }

  void actualizarSemestre(String? semestre) {
    state = state.copyWith(semestreActual: semestre);
  }

  void actualizarActivo({required bool activo}) {
    state = state.copyWith(activo: activo);
  }

  void actualizarFechaNacimiento(DateTime? fecha) {
    state = state.copyWith(fechaNacimiento: fecha);
  }

  void actualizarDireccion(String? direccion) {
    state = state.copyWith(direccion: direccion);
  }

  void cargarEstudiante(EstudianteAdmin estudiante) {
    state = FormularioEstudiante.fromEstudiante(estudiante);
  }

  void limpiarFormulario() {
    state = const FormularioEstudiante(
      nombres: '',
      apellidos: '',
      email: '',
      telefono: '',
      codigoEstudiante: '',
    );
  }

  bool validarFormulario() {
    return state.nombres.isNotEmpty &&
           state.apellidos.isNotEmpty &&
           state.email.isNotEmpty &&
           state.codigoEstudiante.isNotEmpty &&
           _validarEmail(state.email);
  }

  bool _validarEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String? validarCampo(String campo, String valor) {
    switch (campo) {
      case 'nombres':
        if (valor.isEmpty) {
          return 'Los nombres son obligatorios';
        }
        if (valor.length < 2) {
          return 'Los nombres deben tener al menos 2 caracteres';
        }
        break;
      case 'apellidos':
        if (valor.isEmpty) {
          return 'Los apellidos son obligatorios';
        }
        if (valor.length < 2) {
          return 'Los apellidos deben tener al menos 2 caracteres';
        }
        break;
      case 'email':
        if (valor.isEmpty) {
          return 'El email es obligatorio';
        }
        if (!_validarEmail(valor)) {
          return 'Ingrese un email válido';
        }
        break;
      case 'codigoEstudiante':
        if (valor.isEmpty) {
          return 'El código de estudiante es obligatorio';
        }
        if (valor.length < 6) {
          return 'El código debe tener al menos 6 caracteres';
        }
        break;
    }
    return null;
  }
}

// Provider para carreras disponibles
final carrerasDisponiblesProvider = FutureProvider<List<ModeloCarrera>>((ref) async {
  final repository = ref.read(estudianteRepositoryProvider);
  return repository.obtenerCarreras();
});

// Provider para estadísticas de estudiantes
final estadisticasEstudiantesProvider = FutureProvider<EstadisticasEstudiantes>((ref) async {
  final repository = ref.read(estudianteRepositoryProvider);
  return repository.obtenerEstadisticasEstudiantes();
}); 