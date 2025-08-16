import 'package:aulago/models/calificacion.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/calificacion.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Providers para datos de calificaciones
final estudiantesMatriculadosProvider = FutureProvider.family<List<EstudianteAdmin>, int>((ref, cursoId) async {
  final matriculaRepo = MatriculaRepository();
  final estudianteRepo = EstudianteRepository();
  
  // Obtener matriculas del curso
  final matriculas = await matriculaRepo.obtenerMatriculas();
  final matriculasDelCurso = matriculas.where((m) => m.cursoId == cursoId).toList();
  
  // Obtener datos completos de estudiantes
  final estudiantes = <EstudianteAdmin>[];
  for (final matricula in matriculasDelCurso) {
    try {
      final estudiante = await estudianteRepo.obtenerEstudiantePorId(matricula.estudianteId);
      if (estudiante != null) {
        estudiantes.add(estudiante);
      }
    } catch (e) {
      debugPrint('Error obteniendo estudiante ${matricula.estudianteId}: $e');
    }
  }
  
  return estudiantes..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
});

final evaluacionesCursoProvider = FutureProvider.family<List<EvaluacionData>, int>((ref, cursoId) async {
  final tareaRepo = TareaRepository();
  final examenRepo = ExamenRepository();
  
  final evaluaciones = <EvaluacionData>[];
  
  // Obtener tareas del curso
  final tareas = await tareaRepo.obtenerTareas();
  final tareasDelCurso = tareas.where((t) => t.cursoId == cursoId).toList();
  
  for (final tarea in tareasDelCurso) {
    evaluaciones.add(EvaluacionData(
      id: tarea.id.toString(),
      titulo: tarea.titulo,
      tipo: 'Tarea',
      puntosMaximos: tarea.puntosMaximos,
      fechaEntrega: tarea.fechaEntrega,
    ));
  }
  
  // Obtener exámenes del curso
  final examenes = await examenRepo.obtenerExamenesPorCurso(cursoId);
  
  for (final examen in examenes) {
    evaluaciones.add(EvaluacionData(
      id: examen.id.toString(),
      titulo: examen.titulo,
      tipo: 'Examen',
      puntosMaximos: examen.puntosMaximos,
      fechaEntrega: examen.fechaLimite,
    ));
  }
  
  // Ordenar por fecha de entrega
  evaluaciones.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
  
  return evaluaciones;
});

final calificacionesCursoProvider = FutureProvider.family<List<CalificacionUnificada>, int>((ref, cursoId) async {
  final repo = CalificacionRepository();
  
  // Primero sincronizar para asegurar que todas las calificaciones estén en la tabla
  await repo.sincronizarCalificaciones(cursoId);
  
  // Luego obtener las calificaciones unificadas
  return repo.obtenerCalificacionesUnificadasPorCurso(cursoId);
});

class CalificacionesTab extends ConsumerStatefulWidget {
  const CalificacionesTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  ConsumerState<CalificacionesTab> createState() => _CalificacionesTabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _CalificacionesTabState extends ConsumerState<CalificacionesTab> {
  String _filtroTexto = '';
  String _filtroEstado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    final cursoIdInt = int.tryParse(widget.cursoId) ?? 0;

    final estudiantesAsync = ref.watch(estudiantesMatriculadosProvider(cursoIdInt));
    final evaluacionesAsync = ref.watch(evaluacionesCursoProvider(cursoIdInt));
    final calificacionesAsync = ref.watch(calificacionesCursoProvider(cursoIdInt));

    return estudiantesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error al cargar datos: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(estudiantesMatriculadosProvider(cursoIdInt)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (estudiantes) {
        if (estudiantes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay estudiantes matriculados en este curso'),
              ],
            ),
          );
        }

        return evaluacionesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error al cargar evaluaciones: $error')),
          data: (evaluaciones) {
            if (evaluaciones.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileText, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aún no se han creado tareas o exámenes para este curso'),
                  ],
                ),
              );
            }

            return calificacionesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar calificaciones: $error')),
              data: (calificaciones) => _construirInterfazCompleta(
                context,
                estudiantes,
                evaluaciones,
                calificaciones,
                esMovil,
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirInterfazCompleta(
    BuildContext context,
    List<EstudianteAdmin> estudiantes,
    List<EvaluacionData> evaluaciones,
    List<CalificacionUnificada> calificaciones,
    bool esMovil,
  ) {
    // --- Crear mapa de calificaciones ---
    final mapaCalificaciones = <String, CalificacionUnificada>{};
    for (final calificacion in calificaciones) {
      final key = calificacion.tareaId != null 
          ? '${calificacion.estudianteId}-${calificacion.tareaId}'
          : '${calificacion.estudianteId}-${calificacion.examenId}';
      mapaCalificaciones[key] = calificacion;
    }

    // --- Dashboard resumen ---
    int totalAprobados = 0;
    int totalReprobados = 0;
    int totalPendientes = 0;
    double sumaNotas = 0;
    int totalNotas = 0;
    
    for (final estudiante in estudiantes) {
      double sumaCalificaciones = 0;
      int cantidadCalificaciones = 0;
      
      for (final evaluacion in evaluaciones) {
        final key = '${estudiante.id}-${evaluacion.id}';
        final calificacion = mapaCalificaciones[key];
        
        if (calificacion != null) {
          // Convertir puntos a nota sobre 20
          final notaSobre20 = (calificacion.puntosObtenidos / calificacion.puntosTotales) * 20;
          sumaCalificaciones += notaSobre20;
          cantidadCalificaciones++;
        }
      }
      
      if (cantidadCalificaciones > 0) {
        final promedio = sumaCalificaciones / cantidadCalificaciones;
        sumaNotas += promedio;
        totalNotas++;
        
        if (promedio >= 11) {
          totalAprobados++;
        } else {
          totalReprobados++;
        }
      } else {
        totalPendientes++;
      }
    }
    
    final promedioGeneral = totalNotas > 0 ? (sumaNotas / totalNotas) : 0.0;

    // --- Filtros y búsqueda ---
    final estudiantesFiltrados = estudiantes.where((estudiante) {
      final coincideTexto = _filtroTexto.isEmpty || 
          estudiante.nombreCompleto.toLowerCase().contains(_filtroTexto.toLowerCase()) || 
          (estudiante.correoElectronico?.toLowerCase().contains(_filtroTexto.toLowerCase()) ?? false);
      
      final promedio = _calcularPromedioEstudiante(estudiante, evaluaciones, mapaCalificaciones);
      final estado = promedio == null
          ? 'Pendiente'
          : promedio >= 11
              ? 'Aprobado'
              : 'Reprobado';
      
      final coincideEstado = _filtroEstado == 'Todos' || estado == _filtroEstado;
      return coincideTexto && coincideEstado;
    }).toList();

    return Column(
      children: [
        // --- Dashboard resumen ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              // Botón de sincronización
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final cursoIdInt = int.tryParse(widget.cursoId) ?? 0;
                      final repo = CalificacionRepository();
                      await repo.sincronizarCalificaciones(cursoIdInt);
                      
                      // Refrescar todos los providers
                      ref.invalidate(calificacionesCursoProvider(cursoIdInt));
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calificaciones sincronizadas correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al sincronizar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar Calificaciones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dashboard existente
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoBox(
                    icon: LucideIcons.graduationCap,
                    label: 'Promedio general',
                    value: promedioGeneral.toStringAsFixed(2),
                    color: Colors.blue,
                  ),
                  _InfoBox(
                    icon: LucideIcons.check,
                    label: 'Aprobados',
                    value: '$totalAprobados',
                    color: Colors.green,
                  ),
                  _InfoBox(
                    icon: LucideIcons.x,
                    label: 'Reprobados',
                    value: '$totalReprobados',
                    color: Colors.red,
                  ),
                  _InfoBox(
                    icon: LucideIcons.clock,
                    label: 'Pendientes',
                    value: '$totalPendientes',
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
            // --- Filtros y búsqueda ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar estudiante',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _filtroTexto = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filtroEstado,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Aprobado', child: Text('Aprobados')),
                      DropdownMenuItem(value: 'Reprobado', child: Text('Reprobados')),
                      DropdownMenuItem(value: 'Pendiente', child: Text('Pendientes')),
                    ],
                    onChanged: (v) => setState(() => _filtroEstado = v ?? 'Todos'),
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 8),
        // --- Tabla responsiva ---
        Expanded(
          child: esMovil
              ? ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: estudiantesFiltrados.length,
                  itemBuilder: (context, index) {
                    final estudiante = estudiantesFiltrados[index];
                    return _EstudianteCard(
                      estudiante: estudiante,
                      evaluaciones: evaluaciones,
                      mapaCalificaciones: mapaCalificaciones,
                      onEditarNota: (evalId, calificacion, eval) => _mostrarDialogoNota(context, estudiante, evalId, calificacion, eval),
                    );
                  },
                )
               : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Estudiante', style: TextStyle(fontWeight: FontWeight.bold))),
              ...evaluaciones.map((eval) => DataColumn(
                label: Tooltip(
                  message: '${eval.titulo} (${eval.tipo})',
                  child: Row(
                    children: [
                      Text(
                        eval.titulo.length > 15 ? '${eval.titulo.substring(0, 12)}...' : eval.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: eval.tipo == 'Examen' ? Colors.purple.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(eval.tipo, style: TextStyle(fontSize: 10, color: eval.tipo == 'Examen' ? Colors.purple : Colors.blue)),
                      ),
                    ],
                  ),
                ),
              )),
              const DataColumn(label: Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: estudiantesFiltrados.map((estudiante) {
              final promedio = _calcularPromedioEstudiante(estudiante, evaluaciones, mapaCalificaciones);
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        AvatarWidget(
                          fotoUrl: estudiante.fotoPerfilUrl,
                          nombreCompleto: estudiante.nombreCompleto,
                          radio: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(estudiante.nombreCompleto)),
                      ],
                    ),
                  ),
                  ...evaluaciones.map((eval) {
                    final key = '${estudiante.id}-${eval.id}';
                    final calificacion = mapaCalificaciones[key];
                    return DataCell(
                      GestureDetector(
                        onTap: () => _mostrarDialogoNota(context, estudiante, eval.id, calificacion, eval),
                        child: _NotaCell(calificacion: calificacion, puntosMaximos: eval.puntosMaximos),
                      ),
                    );
                  }),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: promedio == null
                          ? Colors.orange.shade50
                          : promedio >= 11
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      promedio == null ? '-' : promedio.toStringAsFixed(2),
                      style: TextStyle(
                        color: promedio == null
                            ? Colors.orange
                            : promedio >= 11
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
        ),
      ],
    );
  }

  double? _calcularPromedioEstudiante(
    EstudianteAdmin estudiante, 
    List<EvaluacionData> evaluaciones, 
    Map<String, CalificacionUnificada> mapaCalificaciones
  ) {
    double suma = 0;
    int cuenta = 0;
    
    for (final evaluacion in evaluaciones) {
      final key = '${estudiante.id}-${evaluacion.id}';
      final calificacion = mapaCalificaciones[key];
      
      if (calificacion != null) {
        // Convertir puntos a nota sobre 20
        final notaSobre20 = (calificacion.puntosObtenidos / calificacion.puntosTotales) * 20;
        suma += notaSobre20;
        cuenta++;
      }
    }
    
    if (cuenta == 0) {
      return null;
    }
    return suma / cuenta;
  }

  Future<void> _mostrarDialogoNota(
    BuildContext context, 
    EstudianteAdmin estudiante, 
    String evalId, 
    CalificacionUnificada? calificacionExistente, 
    EvaluacionData evaluacion
  ) async {
    final puntosController = TextEditingController(
      text: calificacionExistente?.puntosObtenidos.toString() ?? ''
    );
    final comentarioController = TextEditingController(
      text: '' // Podríamos añadir comentarios en el futuro
    );
    
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Calificar: ${evaluacion.titulo}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  AvatarWidget(
                    fotoUrl: estudiante.fotoPerfilUrl,
                    nombreCompleto: estudiante.nombreCompleto,
                    radio: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estudiante.nombreCompleto,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: puntosController,
                decoration: InputDecoration(
                  labelText: 'Puntos obtenidos',
                  hintText: 'Máximo: ${evaluacion.puntosMaximos}',
                  suffixText: '/ ${evaluacion.puntosMaximos}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: evaluacion.tipo == 'Examen' ? Colors.purple.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      evaluacion.tipo == 'Examen' ? LucideIcons.fileText : LucideIcons.clipboard,
                      color: evaluacion.tipo == 'Examen' ? Colors.purple : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evaluacion.tipo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: evaluacion.tipo == 'Examen' ? Colors.purple : Colors.blue,
                            ),
                          ),
                          Text(
                            'Fecha límite: ${evaluacion.fechaEntrega.day}/${evaluacion.fechaEntrega.month}/${evaluacion.fechaEntrega.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            if (calificacionExistente != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop({'eliminar': true}),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ElevatedButton(
              onPressed: () {
                final puntos = double.tryParse(puntosController.text);
                if (puntos != null && puntos >= 0 && puntos <= evaluacion.puntosMaximos) {
                  Navigator.of(context).pop({
                    'puntos': puntos,
                    'comentario': comentarioController.text,
                  });
                }
              },
              child: Text(calificacionExistente != null ? 'Actualizar' : 'Guardar'),
            ),
          ],
        );
      },
    );
    
    if (resultado != null && mounted) {
      if (resultado['eliminar'] == true) {
        await _eliminarCalificacion(calificacionExistente!);
      } else if (resultado['puntos'] != null) {
        await _guardarCalificacion(
          estudiante,
          evaluacion,
          resultado['puntos'] as double,
          calificacionExistente,
        );
      }
    }
  }

  Future<void> _guardarCalificacion(
    EstudianteAdmin estudiante,
    EvaluacionData evaluacion,
    double puntosObtenidos,
    CalificacionUnificada? calificacionExistente,
  ) async {
    try {
      final repo = CalificacionRepository();
      final cursoIdInt = int.tryParse(widget.cursoId) ?? 0;
      
      if (calificacionExistente != null) {
        // Actualizar calificación existente
        final calificacion = Calificacion(
          id: calificacionExistente.id,
          estudianteId: estudiante.id,
          tareaId: evaluacion.tipo == 'Tarea' ? int.tryParse(evaluacion.id) : null,
          examenId: evaluacion.tipo == 'Examen' ? int.tryParse(evaluacion.id) : null,
          cursoId: cursoIdInt,
          puntosObtenidos: puntosObtenidos,
          puntosTotales: evaluacion.puntosMaximos,
          fechaCalificacion: calificacionExistente.fechaCalificacion, // Mantener fecha original
        );
        await repo.actualizarCalificacion(calificacionExistente.id, calificacion);
      } else {
        // Crear nueva calificación
        final calificacion = Calificacion.crear(
          estudianteId: estudiante.id,
          tareaId: evaluacion.tipo == 'Tarea' ? int.tryParse(evaluacion.id) : null,
          examenId: evaluacion.tipo == 'Examen' ? int.tryParse(evaluacion.id) : null,
          cursoId: cursoIdInt,
          puntosObtenidos: puntosObtenidos,
          puntosTotales: evaluacion.puntosMaximos,
          fechaCalificacion: DateTime.now(),
        );
        await repo.crearCalificacion(calificacion);
      }
      
      // Refrescar datos
      // ignore: unused_result
      ref.refresh(calificacionesCursoProvider(cursoIdInt));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota ${calificacionExistente != null ? 'actualizada' : 'guardada'} correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la nota: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCalificacion(CalificacionUnificada calificacion) async {
    try {
      final repo = CalificacionRepository();
      
      // Si la calificación viene de una entrega, no la eliminamos de la tabla
      // Solo si viene de la tabla de calificaciones
      if (calificacion.fuente == 'tabla_calificaciones') {
        await repo.eliminarCalificacion(calificacion.id);
      }
      
      // Refrescar datos
      final cursoIdInt = int.tryParse(widget.cursoId) ?? 0;
      // ignore: unused_result
      ref.refresh(calificacionesCursoProvider(cursoIdInt));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación eliminada correctamente'), 
            backgroundColor: Colors.orange
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la calificación: $e'), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icon', icon))
    ..add(StringProperty('label', label))
    ..add(StringProperty('value', value))
    ..add(ColorProperty('color', color));
  }
}

class _NotaCell extends StatelessWidget {
  const _NotaCell({required this.calificacion, required this.puntosMaximos});
  final CalificacionUnificada? calificacion;
  final double puntosMaximos;

  @override
  Widget build(BuildContext context) {
    if (calificacion == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Sin calificar',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    final notaSobre20 = (calificacion!.puntosObtenidos / calificacion!.puntosTotales) * 20;
    final color = notaSobre20 >= 11 ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${calificacion!.puntosObtenidos.toStringAsFixed(1)} / ${calificacion!.puntosTotales.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            '${notaSobre20.toStringAsFixed(1)}/20',
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<CalificacionUnificada?>('calificacion', calificacion))
    ..add(DoubleProperty('puntosMaximos', puntosMaximos));
  }
}

class _EstudianteCard extends StatelessWidget {
  const _EstudianteCard({
    required this.estudiante,
    required this.evaluaciones,
    required this.mapaCalificaciones,
    required this.onEditarNota,
  });
  
  final EstudianteAdmin estudiante;
  final List<EvaluacionData> evaluaciones;
  final Map<String, CalificacionUnificada> mapaCalificaciones;
  final void Function(String evalId, CalificacionUnificada? calificacion, EvaluacionData eval) onEditarNota;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: AvatarWidget(
          fotoUrl: estudiante.fotoPerfilUrl,
          nombreCompleto: estudiante.nombreCompleto,
        ),
        title: Text(
          estudiante.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estudiante.correoElectronico?.isNotEmpty == true)
              Text(
                estudiante.correoElectronico!,
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              'Código: ${estudiante.codigoEstudiante}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: evaluaciones.map((eval) {
                final key = '${estudiante.id}-${eval.id}';
                final calificacion = mapaCalificaciones[key];
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCellColor(calificacion),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getBorderColor(calificacion),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  eval.tipo == 'Examen' ? LucideIcons.fileText : LucideIcons.clipboard,
                                  size: 16,
                                  color: eval.tipo == 'Examen' ? Colors.purple : Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    eval.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: eval.tipo == 'Examen' ? Colors.purple.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    eval.tipo,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: eval.tipo == 'Examen' ? Colors.purple : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Max: ${eval.puntosMaximos}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onEditarNota(eval.id, calificacion, eval),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _NotaCell(calificacion: calificacion, puntosMaximos: eval.puntosMaximos),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCellColor(CalificacionUnificada? calificacion) {
    if (calificacion == null) {
      return Colors.grey.shade50;
    }
    
    final notaSobre20 = (calificacion.puntosObtenidos / calificacion.puntosTotales) * 20;
    if (notaSobre20 >= 11) {
      return Colors.green.shade50;
    } else {
      return Colors.red.shade50;
    }
  }

  Color _getBorderColor(CalificacionUnificada? calificacion) {
    if (calificacion == null) {
      return Colors.grey.shade200;
    }
    
    final notaSobre20 = (calificacion.puntosObtenidos / calificacion.puntosTotales) * 20;
    if (notaSobre20 >= 11) {
      return Colors.green.shade200;
    } else {
      return Colors.red.shade200;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('estudiante', estudiante))
    ..add(IterableProperty<EvaluacionData>('evaluaciones', evaluaciones))
    ..add(DiagnosticsProperty<Map<String, CalificacionUnificada>>('mapaCalificaciones', mapaCalificaciones))
    ..add(ObjectFlagProperty<void Function(String evalId, CalificacionUnificada? calificacion, EvaluacionData eval)>.has('onEditarNota', onEditarNota));
  }
} 

class EvaluacionData {
  EvaluacionData({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.puntosMaximos,
    required this.fechaEntrega,
  });
  
  final String id;
  final String titulo;
  final String tipo;
  final double puntosMaximos;
  final DateTime fechaEntrega;
} 