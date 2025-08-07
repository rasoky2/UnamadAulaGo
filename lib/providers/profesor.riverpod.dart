import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/providers/examen.riverpod.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Clase contenedora para todos los datos necesarios en la pestaña de calificaciones.
class EvaluacionData {
  const EvaluacionData({required this.id, required this.titulo, required this.tipo, required this.puntosMaximos});
  final String id;
  final String titulo;
  final String tipo; // 'Tarea' o 'Examen'
  final double puntosMaximos;
}

class CalificacionesData {

  CalificacionesData({
    required this.estudiantes,
    required this.evaluaciones,
    required this.entregas,
  });
  final List<EstudianteAdmin> estudiantes;
  final List<EvaluacionData> evaluaciones;
  final List<ModeloEntrega> entregas;
}

// Clase contenedora para la pantalla de calificación de UNA tarea.
class CalificacionTareaData {

  CalificacionTareaData({
    required this.tarea,
    required this.estudiantes,
    required this.entregas,
  });
  final ModeloTarea tarea;
  final List<EstudianteAdmin> estudiantes;
  final List<ModeloEntrega> entregas;
}

final calificacionesDataProvider =
    FutureProvider.family<CalificacionesData, String>((ref, cursoId) async {
  final estudianteRepository = ref.read(estudianteRepositoryProvider);
  final tareaRepository = ref.read(tareaRepositoryProvider);
  // Importar el repositorio de exámenes
  final examenRepository = ref.read(examenRepositoryProvider);

  try {
    // 1. Obtener estudiantes del curso usando el repositorio
    final estudiantes = await estudianteRepository.obtenerEstudiantesPorCurso(cursoId);

    // 2. Obtener tareas del curso usando el repositorio
    final tareas = await tareaRepository.obtenerTareas(cursoId: cursoId);
    // 3. Obtener exámenes del curso (asumiendo que hay un método por cursoId, si no, adaptar)
    final examenes = await examenRepository.obtenerExamenesPorCurso(cursoId);

    // Unificar evaluaciones
    final evaluaciones = <EvaluacionData>[
      ...tareas.map((t) => EvaluacionData(id: t.id, titulo: t.titulo, tipo: 'Tarea', puntosMaximos: t.puntosMaximos)),
      ...examenes.map((e) => EvaluacionData(id: e.id, titulo: e.titulo, tipo: 'Examen', puntosMaximos: e.calificacion ?? 20)),
    ];

    // Obtener entregas de tareas
    final List<ModeloEntrega> todasLasEntregas = [];
    for (final tarea in tareas) {
      final entregas = await tareaRepository.obtenerEntregasPorTarea(tarea.id);
      todasLasEntregas.addAll(entregas);
    }
    // Obtener entregas de exámenes (asumiendo que se usan ModeloEntrega)
    for (final examen in examenes) {
      final entregasExamen = await examenRepository.obtenerEntregasPorExamen(examen.id);
      todasLasEntregas.addAll(entregasExamen);
    }

    return CalificacionesData(
      estudiantes: estudiantes,
      evaluaciones: evaluaciones,
      entregas: todasLasEntregas,
    );
  } catch (e) {
    // En caso de error, devolver datos vacíos
    return CalificacionesData(estudiantes: [], evaluaciones: [], entregas: []);
  }
});

final calificacionTareaProvider = 
  FutureProvider.family<CalificacionTareaData, String>((ref, tareaId) async {
    final estudianteRepository = ref.read(estudianteRepositoryProvider);
    final tareaRepository = ref.read(tareaRepositoryProvider);

    try {
      // 1. Obtener los detalles de la tarea usando el repositorio
      final tarea = await tareaRepository.obtenerTareaPorId(tareaId);
      
      if (tarea == null) {
        return CalificacionTareaData(
          tarea: ModeloTarea(
            id: '',
            titulo: 'Tarea no encontrada',
            fechaAsignacion: DateTime.now(),
            fechaEntrega: DateTime.now(),
            puntosMaximos: 0,
            estado: 'inexistente',
            cursoId: '',
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
          ),
          estudiantes: [],
          entregas: [],
        );
      }

      // 2. Obtener estudiantes del curso usando el repositorio
      final estudiantes = await estudianteRepository.obtenerEstudiantesPorCurso(tarea.cursoId);
    
      // 3. Obtener las entregas para esta tarea específica usando el repositorio
      final entregas = await tareaRepository.obtenerEntregasPorTarea(tareaId);

    return CalificacionTareaData(
      tarea: tarea,
      estudiantes: estudiantes,
      entregas: entregas,
    );
    } catch (e) {
      // En caso de error, devolver datos por defecto
      return CalificacionTareaData(
        tarea: ModeloTarea(
          id: '',
          titulo: 'Error al cargar tarea',
          fechaAsignacion: DateTime.now(),
          fechaEntrega: DateTime.now(),
          puntosMaximos: 0,
          estado: 'inexistente',
          cursoId: '',
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
        ),
        estudiantes: [],
        entregas: [],
      );
    }
}); 