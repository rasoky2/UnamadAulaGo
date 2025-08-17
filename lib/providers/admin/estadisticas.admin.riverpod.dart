import 'package:aulago/models/anuncio.model.dart';
import 'package:aulago/models/estadisticas_admin.model.dart';
import 'package:aulago/repositories/anuncio.repository.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/repositories/fecha_importante.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
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
  final _profesorRepo = ProfesorRepository();
  final _tareaRepo = TareaRepository();
  final _examenRepo = ExamenRepository();
  final _anuncioRepo = AnuncioRepository();
  final _fechaImportanteRepo = FechaImportanteRepository();

  Future<void> cargarEstadisticas() async {
    state = state.copyWith(cargando: true);
    
    try {
      // Cargar datos en paralelo para mejor rendimiento
      final futures = await Future.wait([
        _estudianteRepo.obtenerTodos(),
        _profesorRepo.obtenerProfesores(),
        _cursoRepo.obtenerCursos(),
        _tareaRepo.obtenerTareas(),
        _examenRepo.obtenerExamenes(),
        _anuncioRepo.obtenerAnuncios(),
        _fechaImportanteRepo.obtenerFechasImportantes(),
        _matriculaRepo.obtenerTodos(),
      ]);

      final estudiantes = futures[0] as List;
      final profesores = futures[1] as List;
      final cursos = futures[2] as List;
      final tareas = futures[3] as List;
      final examenes = futures[4] as List;
      final anuncios = futures[5] as List<ModeloAnuncio>;
      final fechasImportantes = futures[6] as List;
      final matriculas = futures[7] as List;

      // Calcular estadísticas básicas
      final totalEstudiantes = estudiantes.length;
      final totalProfesores = profesores.length;
      final totalCursos = cursos.length;
      final totalTareas = tareas.length;
      final totalExamenes = examenes.length;
      final totalAnuncios = anuncios.length;
      final totalFechasImportantes = fechasImportantes.length;
      
      // Calcular usuarios activos (simulado basado en actividad reciente)
      final hoy = DateTime.now();
      // Para estudiantes y profesores, asumimos que están activos si tienen datos
      final estudiantesActivos = estudiantes.length; // Todos los estudiantes registrados se consideran activos
      final profesoresActivos = profesores.length; // Todos los profesores registrados se consideran activos
      // Para cursos, asumimos que están activos si tienen profesor asignado
      final cursosActivos = cursos.where((c) => c.profesorId != null && c.profesorId != 0).length;
      
      // Calcular porcentaje de actividad basado en matrículas recientes
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

      // Generar alertas del sistema basadas en datos
      final alertasSistema = _generarAlertasSistema(
        totalEstudiantes, totalProfesores, totalCursos, 
        anuncios, fechasImportantes
      );

      // Generar actividades recientes simuladas
      final actividadesRecientes = _generarActividadesRecientes(
        estudiantes, profesores, cursos, tareas, examenes
      );

      state = EstadisticasAdmin(
        totalEstudiantes: totalEstudiantes,
        totalProfesores: totalProfesores,
        totalCursos: totalCursos,
        totalTareas: totalTareas,
        totalExamenes: totalExamenes,
        totalAnuncios: totalAnuncios,
        totalFechasImportantes: totalFechasImportantes,
        estudiantesActivos: estudiantesActivos,
        profesoresActivos: profesoresActivos,
        cursosActivos: cursosActivos,
        porcentajeActivosHoy: porcentajeActivosHoy,
        ultimaActividad: DateTime.now(),
        alertasSistema: alertasSistema,
        actividadesRecientes: actividadesRecientes,
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

  // Método auxiliar para generar alertas del sistema
  List<AlertaSistema> _generarAlertasSistema(
    int totalEstudiantes, 
    int totalProfesores, 
    int totalCursos,
    List<ModeloAnuncio> anuncios,
    List fechasImportantes,
  ) {
    final alertas = <AlertaSistema>[];
    
    // Alerta si no hay estudiantes
    if (totalEstudiantes == 0) {
      alertas.add(AlertaSistema(
        id: 'no_estudiantes',
        titulo: 'Sin estudiantes registrados',
        descripcion: 'No hay estudiantes en el sistema',
        tipo: TipoAlerta.warning,
        fechaCreacion: DateTime.now(),
      ));
    }
    
    // Alerta si no hay profesores
    if (totalProfesores == 0) {
      alertas.add(AlertaSistema(
        id: 'no_profesores',
        titulo: 'Sin profesores registrados',
        descripcion: 'No hay profesores en el sistema',
        tipo: TipoAlerta.warning,
        fechaCreacion: DateTime.now(),
      ));
    }
    
    // Alerta si no hay cursos
    if (totalCursos == 0) {
      alertas.add(AlertaSistema(
        id: 'no_cursos',
        titulo: 'Sin cursos registrados',
        descripcion: 'No hay cursos en el sistema',
        tipo: TipoAlerta.warning,
        fechaCreacion: DateTime.now(),
      ));
    }
    
    // Alerta si no hay anuncios recientes
    if (anuncios.isEmpty) {
      alertas.add(AlertaSistema(
        id: 'no_anuncios',
        titulo: 'Sin anuncios del sistema',
        descripcion: 'No hay anuncios para los usuarios',
        tipo: TipoAlerta.info,
        fechaCreacion: DateTime.now(),
      ));
    }
    
    return alertas;
  }

  // Método auxiliar para generar actividades recientes simuladas
  List<ActividadReciente> _generarActividadesRecientes(
    List estudiantes,
    List profesores,
    List cursos,
    List tareas,
    List examenes,
  ) {
    final actividades = <ActividadReciente>[];
    final ahora = DateTime.now();
    
    // Actividad de estudiantes
    if (estudiantes.isNotEmpty) {
      actividades.add(ActividadReciente(
        id: 'estudiantes_activos',
        accion: 'Estudiantes activos',
        usuario: 'Sistema',
        fecha: ahora.subtract(const Duration(hours: 2)),
        detalles: '${estudiantes.length} estudiantes registrados',
      ));
    }
    
    // Actividad de profesores
    if (profesores.isNotEmpty) {
      actividades.add(ActividadReciente(
        id: 'profesores_activos',
        accion: 'Profesores activos',
        usuario: 'Sistema',
        fecha: ahora.subtract(const Duration(hours: 1)),
        detalles: '${profesores.length} profesores registrados',
      ));
    }
    
    // Actividad de cursos
    if (cursos.isNotEmpty) {
      actividades.add(ActividadReciente(
        id: 'cursos_activos',
        accion: 'Cursos disponibles',
        usuario: 'Sistema',
        fecha: ahora.subtract(const Duration(minutes: 30)),
        detalles: '${cursos.length} cursos disponibles',
      ));
    }
    
    // Actividad de tareas
    if (tareas.isNotEmpty) {
      actividades.add(ActividadReciente(
        id: 'tareas_activas',
        accion: 'Tareas activas',
        usuario: 'Sistema',
        fecha: ahora.subtract(const Duration(minutes: 15)),
        detalles: '${tareas.length} tareas activas',
      ));
    }
    
    // Actividad de exámenes
    if (examenes.isNotEmpty) {
      actividades.add(ActividadReciente(
        id: 'examenes_activos',
        accion: 'Exámenes disponibles',
        usuario: 'Sistema',
        fecha: ahora,
        detalles: '${examenes.length} exámenes disponibles',
      ));
    }
    
    return actividades;
  }
}
