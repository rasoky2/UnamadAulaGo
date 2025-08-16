// import 'package:aulago/models/entrega.model.dart';
// import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/models/calificacion.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/calificacion.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';

class CalificacionTareaScreen extends ConsumerWidget {
  const CalificacionTareaScreen({super.key, required this.tareaId});
  final String tareaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar tarea #$tareaId'),
      ),
      body: FutureBuilder(
        future: TareaRepository().obtenerTareaPorId(int.tryParse(tareaId) ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tarea = snapshot.data;
          if (tarea == null) {
            return const Center(child: Text('Tarea no encontrada'));
          }
          // Placeholder simple: solo muestra botón para asignar 0 a todos (sin listar estudiantes/entregas)
          return Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.assignment_late),
              label: const Text('Registrar 0 manualmente'),
              onPressed: () async {
                final repo = CalificacionRepository();
                await repo.crearCalificacion(Calificacion.crear(
                  estudianteId: 0,
                  tareaId: tarea.id,
                  puntosObtenidos: 0,
                  puntosTotales: tarea.puntosMaximos,
                  fechaCalificacion: DateTime.now(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calificación registrada')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Placeholder reducido, sin diálogo de calificación conectado

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
    required this.puntosMaximos,
  });
  final String tareaId;
  final EstudianteAdmin estudiante;
  // final ModeloEntrega? entrega;
  final double puntosMaximos;

  @override
  ConsumerState<_DialogoCalificacionForm> createState() => __DialogoCalificacionFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('tareaId', tareaId))
      ..add(DiagnosticsProperty<EstudianteAdmin>('estudiante', estudiante))
      // ..add(DiagnosticsProperty<ModeloEntrega?>('entrega', entrega))
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
    _notaController = TextEditingController(text: '');
    _comentarioController = TextEditingController(text: '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // Placeholder: sin provider; aquí iría la lógica para guardar usando repositorios CRUD
      await Future<void>.delayed(const Duration(milliseconds: 10));
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