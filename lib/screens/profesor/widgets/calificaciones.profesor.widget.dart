import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/providers/profesor.riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalificacionesTab extends ConsumerWidget {
  const CalificacionesTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calificacionesAsync = ref.watch(calificacionesDataProvider(cursoId));
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;

    return calificacionesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${err.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.estudiantes.isEmpty) {
          return const Center(child: Text('No hay estudiantes matriculados en este curso.'));
        }
        if (data.evaluaciones.isEmpty) {
          return const Center(child: Text('Aún no se han creado tareas o exámenes para este curso.'));
        }

        final mapaEntregas = <String, ModeloEntrega>{};
        for (final entrega in data.entregas) {
          mapaEntregas['${entrega.estudianteId}-${entrega.tareaId}'] = entrega;
        }

        if (esMovil) {
          // Vista responsiva para móvil: lista de tarjetas expandibles
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: data.estudiantes.length,
            itemBuilder: (context, index) {
              final estudiante = data.estudiantes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ExpansionTile(
                  leading: const Icon(Icons.person),
                  title: Text(estudiante.nombreCompleto),
                  subtitle: Text(estudiante.correoElectronico ?? 'Sin correo'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.evaluaciones.map((eval) {
                          final entrega = mapaEntregas['${estudiante.id}-${eval.id}'];
                          Widget cellContent;
                          Color? cellColor;
                          String tooltip = '';
                          if (entrega == null) {
                            cellContent = const Text('No entregado', style: TextStyle(color: Colors.red));
                            cellColor = Colors.red.shade50;
                            tooltip = 'No entregó la tarea/examen';
                          } else if (entrega.estado == EstadoEntrega.noEntregado) {
                            cellContent = const Text('No entregado', style: TextStyle(color: Colors.red));
                            cellColor = Colors.red.shade50;
                            tooltip = entrega.comentarioProfesor ?? 'No entregó la tarea/examen';
                          } else if (entrega.estado == EstadoEntrega.tarde) {
                            cellContent = Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Text('${entrega.calificacion ?? '-'}', style: const TextStyle(color: Colors.orange)),
                              ],
                            );
                            cellColor = Colors.orange.shade50;
                            tooltip = 'Entregado tarde. ${entrega.comentarioProfesor ?? ''}';
                          } else if (entrega.estado == EstadoEntrega.calificado) {
                            cellContent = Text('${entrega.calificacion ?? '-'}', style: const TextStyle(color: Colors.green));
                            cellColor = Colors.green.shade50;
                            tooltip = entrega.comentarioProfesor ?? 'Calificado';
                          } else if (entrega.estado == EstadoEntrega.entregado) {
                            cellContent = const Text('Pendiente', style: TextStyle(color: Colors.blue));
                            cellColor = Colors.blue.shade50;
                            tooltip = 'Entregado, pendiente de calificar';
                          } else {
                            cellContent = const Text('-');
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${eval.titulo} (${eval.tipo})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: tooltip,
                                  child: cellContent,
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
            },
          );
        }

        // Vista de escritorio/tablet: DataTable tradicional
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Estudiante', style: TextStyle(fontWeight: FontWeight.bold))),
                ...data.evaluaciones.map((eval) => DataColumn(
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
              ],
              rows: data.estudiantes.map((estudiante) {
                return DataRow(
                  cells: [
                    DataCell(Text(estudiante.nombreCompleto)),
                    ...data.evaluaciones.map((eval) {
                      final entrega = mapaEntregas['${estudiante.id}-${eval.id}'];
                      Widget cellContent;
                      Color? cellColor;
                      String tooltip = '';
                      if (entrega == null) {
                        cellContent = const Text('No entregado', style: TextStyle(color: Colors.red));
                        cellColor = Colors.red.shade50;
                        tooltip = 'No entregó la tarea/examen';
                      } else if (entrega.estado == EstadoEntrega.noEntregado) {
                        cellContent = const Text('No entregado', style: TextStyle(color: Colors.red));
                        cellColor = Colors.red.shade50;
                        tooltip = entrega.comentarioProfesor ?? 'No entregó la tarea/examen';
                      } else if (entrega.estado == EstadoEntrega.tarde) {
                        cellContent = Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text('${entrega.calificacion ?? '-'}', style: const TextStyle(color: Colors.orange)),
                          ],
                        );
                        cellColor = Colors.orange.shade50;
                        tooltip = 'Entregado tarde. ${entrega.comentarioProfesor ?? ''}';
                      } else if (entrega.estado == EstadoEntrega.calificado) {
                        cellContent = Text('${entrega.calificacion ?? '-'}', style: const TextStyle(color: Colors.green));
                        cellColor = Colors.green.shade50;
                        tooltip = entrega.comentarioProfesor ?? 'Calificado';
                      } else if (entrega.estado == EstadoEntrega.entregado) {
                        cellContent = const Text('Pendiente', style: TextStyle(color: Colors.blue));
                        cellColor = Colors.blue.shade50;
                        tooltip = 'Entregado, pendiente de calificar';
                      } else {
                        cellContent = const Text('-');
                      }
                      return DataCell(
                        Tooltip(
                          message: tooltip,
                          child: Container(
                            color: cellColor,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: cellContent,
                          ),
                        ),
                        onTap: () {
                          if (entrega != null && entrega.comentarioProfesor != null && entrega.comentarioProfesor!.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Comentario: ${entrega.comentarioProfesor}')),
                          );
                          }
                        },
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
} 