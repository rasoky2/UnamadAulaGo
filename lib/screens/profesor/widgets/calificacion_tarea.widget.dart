import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/providers/profesor/calificacion_tarea.riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalificacionTareaScreen extends ConsumerWidget {
  const CalificacionTareaScreen({super.key, required this.tareaId});
  final String tareaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareaDataAsync = ref.watch(calificacionTareaProvider(tareaId));

    return Scaffold(
      appBar: AppBar(
        title: tareaDataAsync.when(
          data: (data) => Text('Calificar: ${data.tarea.titulo}'),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: tareaDataAsync.when(
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
            return const Center(
                child: Text('No hay estudiantes para calificar en esta tarea.'));
          }
          
          final mapaEntregas = { for (final e in data.entregas) e.estudianteId : e };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.assignment_late),
                  label: const Text('Calificar con 0 a los que no entregaron'),
                  onPressed: () async {
                    final noEntregaron = data.estudiantes.where((est) => !mapaEntregas.containsKey(est.id)).toList();
                    if (noEntregaron.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todos los estudiantes ya entregaron o han sido calificados.')),
                      );
                      return;
                    }
                    final tareaNotifier = ref.read(calificacionTareaProvider(tareaId).notifier);
                    for (final est in noEntregaron) {
                      await tareaNotifier.calificar(
                        estudianteId: est.id,
                        calificacion: 0.0,
                        comentario: 'No entregó la tarea',
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Se calificó con 0 a ${noEntregaron.length} estudiante(s) que no entregaron.')),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: data.estudiantes.length,
                  itemBuilder: (context, index) {
                    final estudiante = data.estudiantes[index];
                    final entrega = mapaEntregas[estudiante.id];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(estudiante.iniciales),
                        ),
                        title: Text(estudiante.nombreCompleto),
                        subtitle: Text(_estadoEntrega(entrega)),
                        trailing: Chip(
                          label: Text(entrega?.calificacion?.toString() ?? '- / ${data.tarea.puntosMaximos}'),
                          backgroundColor: entrega?.calificacion != null ? Colors.green.shade100 : Colors.grey.shade200,
                        ),
                        onTap: () {
                          // TODO: Mostrar dialogo para ingresar/modificar nota
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calificando a ${estudiante.nombreCompleto}...'))
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _estadoEntrega(ModeloEntrega? entrega) {
    if (entrega == null) {
      return 'No entregado';
    }
    if (entrega.calificacion != null) {
      return 'Calificado';
    }
    return 'Entregado - Pendiente de calificar';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('tareaId', tareaId));
  }
} 