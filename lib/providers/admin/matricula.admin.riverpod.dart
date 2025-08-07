import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del repositorio de matrículas
final matriculaRepositoryProvider = Provider<MatriculaRepository>((ref) {
  return MatriculaRepository();
});

// Provider principal para gestión de matrículas
final matriculasAdminProvider = StateNotifierProvider<MatriculasAdminNotifier, MatriculasAdminData>((ref) {
  final repository = ref.watch(matriculaRepositoryProvider);
  return MatriculasAdminNotifier(repository);
});

class MatriculasAdminNotifier extends StateNotifier<MatriculasAdminData> {

  MatriculasAdminNotifier(this._repository) : super(const MatriculasAdminData()) {
    cargarMatriculas();
  }
  final MatriculaRepository _repository;
  static const int _elementosPorPagina = 20;

  /// Carga las matrículas con filtros y paginación
  Future<void> cargarMatriculas({bool refrescar = false}) async {
    if (refrescar) {
      state = state.copyWith(cargando: true);
    }

    try {
      final offset = (state.pagina - 1) * _elementosPorPagina;
      
      // Aplicar filtros según el estado seleccionado
      String? estadoFiltro;
      switch (state.filtroEstado) {
        case FiltroEstadoMatricula.matriculado:
          estadoFiltro = 'matriculado';
          break;
        case FiltroEstadoMatricula.retirado:
          estadoFiltro = 'retirado';
          break;
        case FiltroEstadoMatricula.transferido:
          estadoFiltro = 'transferido';
          break;
        case FiltroEstadoMatricula.todos:
          estadoFiltro = null;
          break;
      }

      // Obtener matrículas
      final matriculas = await _repository.obtenerMatriculas(
        estado: estadoFiltro,
        filtroTexto: state.filtroTexto.isEmpty ? null : state.filtroTexto,
        offset: offset,
      );

      // Contar total para paginación
      final totalMatriculas = await _repository.contarMatriculas(
        estado: estadoFiltro,
        filtroTexto: state.filtroTexto.isEmpty ? null : state.filtroTexto,
      );

      final totalPaginas = (totalMatriculas / _elementosPorPagina).ceil();

      state = state.copyWith(
        matriculas: matriculas,
        totalMatriculas: totalMatriculas,
        totalPaginas: totalPaginas > 0 ? totalPaginas : 1,
        cargando: false,
      );

      debugPrint('📚 Matrículas: Cargadas ${matriculas.length} de $totalMatriculas matrículas');
    } catch (e) {
      state = state.copyWith(
        cargando: false,
        error: 'Error al cargar matrículas: ${e.toString()}',
      );
      debugPrint('❌ Matrículas: Error al cargar: $e');
    }
  }

  /// Crear nueva matrícula
  Future<bool> crearMatricula(FormularioMatricula formulario) async {
    try {
      debugPrint('📝 Matrículas: Creando nueva matrícula...');

      // Verificar si la matrícula ya existe
      final existe = await _repository.verificarMatriculaExiste(
        estudianteId: formulario.estudianteId,
        cursoId: formulario.cursoId,
      );

      if (existe) {
        state = state.copyWith(
          error: 'El estudiante ya está matriculado en este curso',
        );
        return false;
      }

      // Crear la matrícula usando el método apropiado del repositorio
        await _repository.crearMatriculaDirecta(
          estudianteId: formulario.estudianteId,
          cursoId: formulario.cursoId!,
          periodoAcademicoId: formulario.periodoAcademicoId,
        );

      // Recargar la lista
      await cargarMatriculas(refrescar: true);

      debugPrint('✅ Matrículas: Matrícula directa creada exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al crear matrícula: ${e.toString()}',
      );
      debugPrint('❌ Matrículas: Error al crear: $e');
      return false;
    }
  }

  /// Cambiar estado de matrícula (activar/desactivar/retirar)
  Future<bool> cambiarEstadoMatricula(String matriculaId, String nuevoEstado) async {
    try {
      debugPrint('🔄 Matrículas: Cambiando estado de matrícula $matriculaId a $nuevoEstado');

      await _repository.actualizarMatricula(matriculaId, {'estado': nuevoEstado});

      // Recargar la lista
      await cargarMatriculas(refrescar: true);

      debugPrint('✅ Matrículas: Estado cambiado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cambiar estado: ${e.toString()}',
      );
      debugPrint('❌ Matrículas: Error al cambiar estado: $e');
      return false;
    }
  }

  /// Eliminar matrícula
  Future<bool> eliminarMatricula(String matriculaId) async {
    try {
      debugPrint('🗑️ Matrículas: Eliminando matrícula $matriculaId');

      await _repository.eliminarMatricula(matriculaId);

      // Recargar la lista
      await cargarMatriculas(refrescar: true);

      debugPrint('✅ Matrículas: Matrícula eliminada exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al eliminar matrícula: ${e.toString()}',
      );
      debugPrint('❌ Matrículas: Error al eliminar: $e');
      return false;
    }
  }

  /// Aplicar filtro de texto
  void aplicarFiltroTexto(String texto) {
    state = state.copyWith(
      filtroTexto: texto,
      pagina: 1, // Resetear a primera página
    );
    cargarMatriculas();
  }

  /// Aplicar filtro de estado
  void aplicarFiltroEstado(FiltroEstadoMatricula filtro) {
    state = state.copyWith(
      filtroEstado: filtro,
      pagina: 1, // Resetear a primera página
    );
    cargarMatriculas();
  }

  /// Limpiar todos los filtros
  void limpiarFiltros() {
    state = state.copyWith(
      filtroTexto: '',
      filtroEstado: FiltroEstadoMatricula.todos,
      pagina: 1,
    );
    cargarMatriculas();
  }

  /// Cambiar página
  void cambiarPagina(int nuevaPagina) {
    if (nuevaPagina >= 1 && nuevaPagina <= state.totalPaginas) {
      state = state.copyWith(pagina: nuevaPagina);
      cargarMatriculas();
    }
  }

  /// Crear múltiples matrículas de una vez
  Future<Map<String, dynamic>> crearMatriculasMultiples(FormularioMatriculaMultiple formulario) async {
    try {
      debugPrint('📝 Matrículas: Creando ${formulario.cursosSeleccionados.length} matrículas múltiples...');

      final matriculasJson = formulario.toMatriculasJson();
      final resultado = await _repository.crearMatriculasMultiples(matriculasJson);

      // Recargar la lista después de crear
      await cargarMatriculas(refrescar: true);

      debugPrint('✅ Matrículas: Procesadas ${resultado['total_procesadas']} - Exitosas: ${resultado['total_exitosas']}, Fallidas: ${resultado['total_fallidas']}');
      
      return resultado;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al crear matrículas múltiples: ${e.toString()}',
      );
      debugPrint('❌ Matrículas: Error en matriculación múltiple: $e');
      return {
        'exitosas': [],
        'fallidas': [],
        'total_procesadas': 0,
        'total_exitosas': 0,
        'total_fallidas': 0,
        'error': e.toString(),
      };
    }
  }

  /// Verificar elegibilidad de un estudiante para un curso específico
  Future<Map<String, dynamic>> verificarElegibilidadCurso(String estudianteId, String cursoId) async {
    try {
      return await _repository.verificarElegibilidadCurso(estudianteId, cursoId);
    } catch (e) {
      debugPrint('❌ Matrículas: Error verificando elegibilidad: $e');
      return {
        'elegible': false,
        'razon': 'Error en verificación',
        'detalle': e.toString()
      };
    }
  }
}

// Providers para datos de formularios
final estudiantesDisponiblesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(matriculaRepositoryProvider);
  return repository.obtenerEstudiantesDisponibles();
});

final periodosAcademicosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(matriculaRepositoryProvider);
  return repository.obtenerPeriodosAcademicos();
});

// Providers para datos de formularios extendidos

/// Provider para obtener cursos disponibles para un estudiante específico
final cursosDisponiblesEstudianteProvider = FutureProvider.family<List<Map<String, dynamic>>, CursosEstudianteFiltros>((ref, filtros) async {
  final repository = ref.watch(matriculaRepositoryProvider);
  
  if (filtros.estudianteId == null) {
    return []; // Si no hay estudiante seleccionado, retornar lista vacía
  }
  
  return repository.obtenerCursosDisponiblesParaEstudiante(
    filtros.estudianteId!,
    periodoAcademicoId: filtros.periodoAcademicoId,
  );
});

final cursosParaMatriculacionProvider = FutureProvider.family<List<CursoMatriculacion>, MatriculaFiltros>((ref, filtros) async {
  final repository = ref.watch(matriculaRepositoryProvider);
  final cursosData = await repository.obtenerCursosParaMatriculacion(
    carreraId: filtros.carreraId,
    periodoAcademicoId: filtros.periodoAcademicoId,
  );
  
  return cursosData.map(CursoMatriculacion.fromJson).toList();
});

final carrerasParaMatriculacionProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(matriculaRepositoryProvider);
  return repository.obtenerCarrerasParaMatriculacion();
});

/// Clase para pasar filtros a los providers
class MatriculaFiltros {

  const MatriculaFiltros({
    this.carreraId,
    this.periodoAcademicoId,
  });
  final String? carreraId;
  final String? periodoAcademicoId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MatriculaFiltros &&
        other.carreraId == carreraId &&
        other.periodoAcademicoId == periodoAcademicoId;
  }

  @override
  int get hashCode => carreraId.hashCode ^ periodoAcademicoId.hashCode;
}

/// Clase para pasar filtros específicos de estudiante
class CursosEstudianteFiltros {

  const CursosEstudianteFiltros({
    this.estudianteId,
    this.periodoAcademicoId,
  });
  final String? estudianteId;
  final String? periodoAcademicoId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CursosEstudianteFiltros &&
        other.estudianteId == estudianteId &&
        other.periodoAcademicoId == periodoAcademicoId;
  }

  @override
  int get hashCode => estudianteId.hashCode ^ periodoAcademicoId.hashCode;
}
