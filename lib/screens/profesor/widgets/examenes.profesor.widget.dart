import 'package:aulago/models/examen.model.dart';
import 'package:aulago/providers/examen.riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamenesTab extends ConsumerStatefulWidget {
  const ExamenesTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  ConsumerState<ExamenesTab> createState() => _ExamenesTabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _ExamenesTabState extends ConsumerState<ExamenesTab> {
  late Future<List<ModeloExamen>> _futureExamenes;

  @override
  void initState() {
    super.initState();
    _cargarExamenes();
  }

  void _cargarExamenes() {
    final examenRepo = ref.read(examenRepositoryProvider);
    setState(() {
      _futureExamenes = examenRepo.obtenerExamenesPorCurso(widget.cursoId);
    });
  }

  Future<void> _mostrarDialogoCrearExamen() async {
    final creado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoCrearExamen(cursoId: widget.cursoId),
    );
    if (creado == true) {
      _cargarExamenes();
    }
  }

  Future<void> _mostrarDialogoEditarExamen(ModeloExamen examen) async {
    final editado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoCrearExamen(
        cursoId: widget.cursoId,
        examen: examen,
      ),
    );
    if (editado == true) {
      _cargarExamenes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Exámenes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Examen'),
                onPressed: _mostrarDialogoCrearExamen,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ModeloExamen>>(
            future: _futureExamenes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final examenes = snapshot.data ?? [];
              if (examenes.isEmpty) {
                return const Center(child: Text('No hay exámenes creados para este curso.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: examenes.length,
                itemBuilder: (context, index) {
                  final examen = examenes[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_turned_in),
                      title: Text(examen.titulo),
                      subtitle: Text('Disponible: ${examen.fechaDisponible} - Límite: ${examen.fechaLimite}\nDuración: ${examen.fechaLimite.difference(examen.fechaDisponible).inMinutes} min'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _mostrarDialogoEditarExamen(examen);
                        },
                      ),
                      onTap: () {
                        // TODO: Implementar detalle/calificación de examen
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Cambia el retorno de showDialog a bool para indicar si se creó un examen
class _DialogoCrearExamen extends ConsumerStatefulWidget {
  const _DialogoCrearExamen({required this.cursoId, this.examen});
  final String cursoId;
  final ModeloExamen? examen;

  @override
  ConsumerState<_DialogoCrearExamen> createState() => _DialogoCrearExamenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('cursoId', cursoId))
    ..add(DiagnosticsProperty<ModeloExamen?>('examen', examen));
  }
}

class _DialogoCrearExamenState extends ConsumerState<_DialogoCrearExamen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int? _duracion;
  double? _puntosMaximos;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.examen != null) {
      _tituloController.text = widget.examen!.titulo;
      _descripcionController.text = widget.examen!.descripcion ?? '';
      _fechaInicio = widget.examen!.fechaDisponible;
      _fechaFin = widget.examen!.fechaLimite;
      _puntosMaximos = widget.examen!.calificacion ?? 0.0;
      // No hay campo duracion en ModeloExamen, así que lo dejamos manual
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(examenRepositoryProvider);
      if (widget.examen == null) {
        // Crear
        await repo.crearExamen({
          'titulo': _tituloController.text,
          'descripcion': _descripcionController.text,
          'fecha_disponible': _fechaInicio!.toIso8601String(),
          'fecha_limite': _fechaFin!.toIso8601String(),
          'duracion_minutos': _duracion,
          'puntos_maximos': _puntosMaximos,
          'curso_id': widget.cursoId,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        });
      } else {
        // Editar
        await repo.actualizarExamen(widget.examen!.id, {
          'titulo': _tituloController.text,
          'descripcion': _descripcionController.text,
          'fecha_disponible': _fechaInicio!.toIso8601String(),
          'fecha_limite': _fechaFin!.toIso8601String(),
          'duracion_minutos': _duracion,
          'puntos_maximos': _puntosMaximos,
          'curso_id': widget.cursoId,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar examen: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Examen'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_fechaInicio == null ? 'Inicio: --' : 'Inicio: ${_fechaInicio!.toLocal()}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _fechaInicio = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: const Text('Elegir'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_fechaFin == null ? 'Fin: --' : 'Fin: ${_fechaFin!.toLocal()}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaInicio ?? DateTime.now(),
                        firstDate: _fechaInicio ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _fechaFin = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: const Text('Elegir'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Duración (minutos)'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Requerido' : null,
                onChanged: (v) => _duracion = int.tryParse(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Puntos máximos'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Requerido' : null,
                onChanged: (v) => _puntosMaximos = double.tryParse(v),
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
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear'),
        ),
      ],
    );
  }
}
