import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/providers/profesor/calificacion_tarea.riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(calificacionTareaProvider(tareaId).notifier).refrescar(),
          )
        ],
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
                child: Text('No hay estudiantes matriculados en esta tarea.'));
          }
          
          final mapaEntregas = { for (final e in data.entregas) e.estudianteId : e };

          return ListView.builder(
            itemCount: data.estudiantes.length,
            itemBuilder: (context, index) {
              final estudiante = data.estudiantes[index];
              final entrega = mapaEntregas[estudiante.id];
              final puntosMaximos = data.tarea.puntosMaximos;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(estudiante.iniciales),
                  ),
                  title: Text(estudiante.nombreCompleto),
                  subtitle: Text(_estadoEntrega(entrega)),
                  trailing: Chip(
                    label: Text('${entrega?.calificacion?.toString() ?? '-'} / $puntosMaximos'),
                    backgroundColor: entrega?.calificacion != null ? Colors.green.shade100 : Colors.grey.shade200,
                  ),
                  onTap: () => _mostrarDialogoCalificacion(context, ref, estudiante, entrega, puntosMaximos),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogoCalificacion(BuildContext context, WidgetRef ref, EstudianteAdmin estudiante, ModeloEntrega? entrega, double puntosMaximos) {
    showDialog(
      context: context,
      builder: (_) => _DialogoCalificacionForm(
        tareaId: tareaId,
        estudiante: estudiante,
        entrega: entrega,
        puntosMaximos: puntosMaximos,
      ),
    );
  }

  String _estadoEntrega(ModeloEntrega? entrega) {
    if (entrega == null) {
      return 'No entregado';
    }
    if (entrega.calificacion != null) {
      final fechaFormateada = DateFormat.yMd('es').add_jm().format(entrega.fechaEntrega);
      return 'Calificado el $fechaFormateada';
    }
    return 'Entregado - Pendiente de calificar';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('tareaId', tareaId));
  }
}

class _DialogoCalificacionForm extends ConsumerStatefulWidget {

  const _DialogoCalificacionForm({
    required this.tareaId,
    required this.estudiante,
    this.entrega,
    required this.puntosMaximos,
  });
  final String tareaId;
  final EstudianteAdmin estudiante;
  final ModeloEntrega? entrega;
  final double puntosMaximos;

  @override
  ConsumerState<_DialogoCalificacionForm> createState() => __DialogoCalificacionFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('tareaId', tareaId))
      ..add(DiagnosticsProperty<EstudianteAdmin>('estudiante', estudiante))
      ..add(DiagnosticsProperty<ModeloEntrega?>('entrega', entrega))
      ..add(DoubleProperty('puntosMaximos', puntosMaximos));
  }
}

class __DialogoCalificacionFormState extends ConsumerState<_DialogoCalificacionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notaController;
  late final TextEditingController _comentarioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notaController = TextEditingController(text: widget.entrega?.calificacion?.toString() ?? '');
    _comentarioController = TextEditingController(text: widget.entrega?.comentarioProfesor ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(calificacionTareaProvider(widget.tareaId).notifier);
      await notifier.calificar(
        estudianteId: widget.estudiante.id,
        calificacion: double.parse(_notaController.text),
        comentario: _comentarioController.text,
        estado: double.parse(_notaController.text) == 0.0 ? EstadoEntrega.noEntregado : EstadoEntrega.calificado,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calificar a ${widget.estudiante.nombreCompleto}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _notaController,
                decoration: InputDecoration(
                  labelText: 'Nota (Máx: ${widget.puntosMaximos})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La nota es requerida.';
                  }
                  final nota = double.tryParse(value);
                  if (nota == null) {
                    return 'Ingrese un número válido.';
                  }
                  if (nota < 0 || nota > widget.puntosMaximos) {
                    return 'La nota debe estar entre 0 y ${widget.puntosMaximos}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar Calificación'),
        ),
      ],
    );
  }
} 