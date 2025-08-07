import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/providers/profesor/tareas.profesor.riverpod.dart';
import 'package:aulago/screens/profesor/widgets/calificacion_tarea.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TareasTab extends ConsumerWidget {
  const TareasTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tareasAsync = ref.watch(tareasProfesorProvider(cursoId));
    return tareasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error:   [31m${err.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
      data: (tareas) {
        if (tareas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Aún no has creado ninguna tarea.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => mostrarDialogoTarea(context, ref, cursoId),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Crear Tarea'),
                )
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tareas.length + 1, // +1 para el botón
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => mostrarDialogoTarea(context, ref, cursoId),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Crear Nueva Tarea'),
                  ),
                ),
              );
            }
            final tarea = tareas[index - 1];
            return _TareaCard(
              tarea: tarea,
              onEdit: () => mostrarDialogoTarea(context, ref, cursoId, tareaExistente: tarea),
              onGrade: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalificacionTareaScreen(tareaId: tarea.id),
                  ),
                );
              },
            );
          },
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

class _TareaCard extends StatelessWidget {

  const _TareaCard({required this.tarea, required this.onEdit, required this.onGrade});
  final ModeloTarea tarea;
  final VoidCallback onEdit;
  final VoidCallback onGrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool estaVencida = DateTime.now().isAfter(tarea.fechaEntrega);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tarea.titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              tarea.descripcion ?? 'Sin descripción.',
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 16, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(
                  'Entrega: ${DateFormat.yMMMEd('es').add_jm().format(tarea.fechaEntrega)}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                if (estaVencida)
                  Chip(
                    label: const Text('Vencida'),
                    backgroundColor: theme.colorScheme.errorContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                    padding: EdgeInsets.zero,
                  )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onGrade,
                  icon: const Icon(LucideIcons.graduationCap, size: 16),
                  label: const Text('Calificar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloTarea>('tarea', tarea))
    ..add(ObjectFlagProperty<VoidCallback>.has('onEdit', onEdit))
    ..add(ObjectFlagProperty<VoidCallback>.has('onGrade', onGrade));
  }
}

void mostrarDialogoTarea(BuildContext context, WidgetRef ref, String cursoId, {ModeloTarea? tareaExistente}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tareaExistente == null ? 'Crear Nueva Tarea' : 'Editar Tarea'),
        content: _TareaForm(
          cursoId: cursoId,
          tarea: tareaExistente,
          onSuccess: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );
}

class _TareaForm extends ConsumerStatefulWidget {

  const _TareaForm({required this.cursoId, this.tarea, required this.onSuccess});
  final String cursoId;
  final ModeloTarea? tarea;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_TareaForm> createState() => _TareaFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('cursoId', cursoId))
    ..add(DiagnosticsProperty<ModeloTarea?>('tarea', tarea))
    ..add(ObjectFlagProperty<VoidCallback>.has('onSuccess', onSuccess));
  }
}

class _TareaFormState extends ConsumerState<_TareaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late DateTime _fechaEntrega;
  late TextEditingController _puntosController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final tarea = widget.tarea;
    _tituloController = TextEditingController(text: tarea?.titulo ?? '');
    _descripcionController = TextEditingController(text: tarea?.descripcion ?? '');
    _fechaEntrega = tarea?.fechaEntrega ?? DateTime.now().add(const Duration(days: 7));
    _puntosController = TextEditingController(text: tarea?.puntosMaximos.toString() ?? '20');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final datosTarea = {
        'curso_id': widget.cursoId,
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'fecha_entrega': _fechaEntrega.toIso8601String(),
        'puntos_maximos': double.tryParse(_puntosController.text) ?? 20.0,
      };

      try {
        final notifier = ref.read(tareasProfesorProvider(widget.cursoId).notifier);
        if (widget.tarea == null) {
          await notifier.crearTarea(datosTarea);
        } else {
          await notifier.actualizarTarea(widget.tarea!.id, datosTarea);
        }
        if (mounted) {
          widget.onSuccess();
        }
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la tarea: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value!.isEmpty ? 'El título es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
               maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _puntosController,
              decoration: const InputDecoration(labelText: 'Puntos Máximos'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Campo requerido';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
             ListTile(
              title: const Text('Fecha de Entrega'),
              subtitle: Text(DateFormat.yMMMEd('es').add_jm().format(_fechaEntrega)),
              trailing: const Icon(LucideIcons.calendar),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaEntrega,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) {
                  return;
                }
                
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_fechaEntrega),
                );
                if (time == null) {
                  return;
                }

                setState(() {
                  _fechaEntrega = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator() else ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(widget.tarea == null ? 'Crear' : 'Guardar Cambios'),
                  ),
          ],
        ),
      ),
    );
  }
} 