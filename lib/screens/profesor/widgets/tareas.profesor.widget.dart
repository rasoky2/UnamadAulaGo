import 'package:aulago/models/entrega.model.dart';

import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/entrega.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/screens/profesor/widgets/calificacion_tarea.widget.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// ==================== PROVIDERS OPTIMIZADOS ====================

/// Provider para obtener tareas de un curso específico con caching
final tareasCursoProvider = FutureProvider.family<List<ModeloTarea>, String>((ref, cursoId) async {
  try {
    final repo = TareaRepository();
    final todasTareas = await repo.obtenerTareas();
    return todasTareas.where((t) => t.cursoId.toString() == cursoId).toList();
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo tareas del curso $cursoId: $e');
    }
    return [];
  }
});

/// Provider para obtener entregas de una tarea específica con caching
final entregasTareaProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, tareaId) async {
  try {
    final repo = EntregaRepository();
    return await repo.obtenerEntregasConEstudiante(tareaId);
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo entregas de tarea $tareaId: $e');
    }
    return [];
  }
});

class TareasTab extends ConsumerStatefulWidget {
  const TareasTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  ConsumerState<TareasTab> createState() => _TareasTabState();
}

class _TareasTabState extends ConsumerState<TareasTab> {
  @override
  Widget build(BuildContext context) {
    // Usar el provider optimizado en lugar de FutureBuilder
    final tareasAsync = ref.watch(tareasCursoProvider(widget.cursoId));
    
    return tareasAsync.when(
      data: (tareas) => _buildTareasContent(tareas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorContent(error),
    );
  }

  Widget _buildTareasContent(List<ModeloTarea> tareas) {
    if (tareas.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        // Header con botón de crear
        _buildHeader(),
        // Lista de tareas
        Expanded(
          child: _buildTareasList(tareas),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Text(
            'Tareas del Curso',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoTarea(context),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Crear Nueva Tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareasList(List<ModeloTarea> tareas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final tarea = tareas[index];
        return _TareaCard(
          tarea: tarea,
          onEdit: () => _mostrarDialogoTarea(context, tareaExistente: tarea),
          onGrade: () => _navegarACalificacion(tarea),
          onDelete: () => _refrescarTareas(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aún no has creado ninguna tarea.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera tarea para comenzar',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoTarea(context),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Crear Tarea'),
          )
        ],
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refrescarTareas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoTarea(BuildContext context, {ModeloTarea? tareaExistente}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tareaExistente == null ? 'Crear Nueva Tarea' : 'Editar Tarea'),
          content: _TareaForm(
            cursoId: widget.cursoId,
            tarea: tareaExistente,
            onSuccess: _refrescarTareas,
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

  void _navegarACalificacion(ModeloTarea tarea) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalificacionTareaScreen(tareaId: tarea.id.toString()),
      ),
    );
  }

  void _refrescarTareas() {
    // Invalidar el provider para refrescar los datos
    ref.invalidate(tareasCursoProvider(widget.cursoId));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', widget.cursoId));
  }
}

class _TareaCard extends StatefulWidget {
  const _TareaCard({
    required this.tarea, 
    required this.onEdit, 
    required this.onGrade,
    required this.onDelete,
  });
  final ModeloTarea tarea;
  final VoidCallback onEdit;
  final VoidCallback onGrade;
  final VoidCallback onDelete;

  @override
  State<_TareaCard> createState() => _TareaCardState();
}

class _TareaCardState extends State<_TareaCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool estaVencida = DateTime.now().isAfter(widget.tarea.fechaEntrega);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tarea.titulo, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              widget.tarea.descripcion ?? 'Sin descripción.',
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
                  'Entrega: ${DateFormat.yMMMEd('es').add_jm().format(widget.tarea.fechaEntrega)}',
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
                  onPressed: widget.onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _mostrarEntregasModal(context, widget.tarea),
                  icon: const Icon(LucideIcons.graduationCap, size: 16),
                  label: const Text('Ver Entregas'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmarEliminarTarea(context, widget.tarea),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                  tooltip: 'Eliminar tarea',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarTarea(BuildContext context, ModeloTarea tarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar la tarea "${tarea.titulo}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final repo = TareaRepository();
                await repo.eliminarTarea(tarea.id);
                
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarea eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refrescar la lista de tareas
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Cerrar el modal de entregas si está abierto
                  }
                  // Llamar al callback para refrescar la lista
                  widget.onDelete();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar la tarea: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

void mostrarDialogoTarea(BuildContext context, WidgetRef ref, String cursoId, {ModeloTarea? tareaExistente, VoidCallback? onSuccess}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(tareaExistente == null ? 'Crear Nueva Tarea' : 'Editar Tarea'),
        content: _TareaForm(
          cursoId: cursoId,
          tarea: tareaExistente,
          onSuccess: onSuccess ?? () => Navigator.of(context).pop(),
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

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _puntosController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final repo = TareaRepository();
        final cursoIdInt = int.tryParse(widget.cursoId) ?? 0;
        
        if (widget.tarea == null) {
          // Crear nueva tarea
          final nuevaTarea = ModeloTarea(
            id: 0,
            titulo: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
            fechaAsignacion: DateTime.now(),
            fechaEntrega: _fechaEntrega,
            puntosMaximos: double.tryParse(_puntosController.text) ?? 20.0,
            estado: 'activa',
            cursoId: cursoIdInt,
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
          );
          
          await repo.crearTarea(nuevaTarea);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tarea creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Cerrar el diálogo
            widget.onSuccess(); // Llamar al callback de éxito
          }
        } else {
          // Actualizar tarea existente
          final tareaActualizada = widget.tarea!.copyWith(
            titulo: _tituloController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
            fechaEntrega: _fechaEntrega,
            puntosMaximos: double.tryParse(_puntosController.text) ?? widget.tarea!.puntosMaximos,
            fechaActualizacion: DateTime.now(),
          );
          
          await repo.actualizarTarea(widget.tarea!.id, tareaActualizada);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tarea actualizada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Cerrar el diálogo
            widget.onSuccess(); // Llamar al callback de éxito
          }
        }
      } catch (e) {
        debugPrint('Error al guardar tarea: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la tarea: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Descripción opcional de la tarea',
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _puntosController,
              decoration: const InputDecoration(
                labelText: 'Puntos Máximos *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
                helperText: 'Puntos que vale la tarea',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Los puntos son requeridos';
                }
                final puntos = double.tryParse(value);
                if (puntos == null || puntos <= 0) {
                  return 'Ingrese un número válido mayor a 0';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha de Entrega *'),
              subtitle: Text(
                DateFormat.yMMMEd('es').add_jm().format(_fechaEntrega),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                  _fechaEntrega = DateTime(
                    date.year, 
                    date.month, 
                    date.day, 
                    time.hour, 
                    time.minute
                  );
                });
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(widget.tarea == null ? Icons.add : Icons.save),
                  label: Text(widget.tarea == null ? 'Crear Tarea' : 'Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== MODAL DE ENTREGAS ====================

/// Muestra el modal bottom sheet con las entregas de una tarea
void _mostrarEntregasModal(BuildContext context, ModeloTarea tarea) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header del modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de arrastre
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Título de la tarea
                  Text(
                    tarea.titulo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Información de la tarea
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Entrega: ${DateFormat.yMMMEd('es').add_jm().format(tarea.fechaEntrega)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text('${tarea.puntosMaximos.toInt()} pts'),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lista de entregas
            Expanded(
              child: _EntregasListWidget(
                tarea: tarea,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Widget que muestra la lista de entregas
class _EntregasListWidget extends ConsumerStatefulWidget {
  const _EntregasListWidget({
    required this.tarea,
    required this.scrollController,
  });

  final ModeloTarea tarea;
  final ScrollController scrollController;

  @override
  ConsumerState<_EntregasListWidget> createState() => _EntregasListWidgetState();
}

class _EntregasListWidgetState extends ConsumerState<_EntregasListWidget> {
  void _refrescarEntregas() {
    // Invalidar el provider para refrescar los datos
    ref.invalidate(entregasTareaProvider(widget.tarea.id));
  }

  @override
  Widget build(BuildContext context) {
    // Usar el provider optimizado en lugar de FutureBuilder
    final entregasAsync = ref.watch(entregasTareaProvider(widget.tarea.id));
    
    return entregasAsync.when(
      data: (entregas) => _buildEntregasContent(entregas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorContent(error),
    );
  }

  Widget _buildEntregasContent(List<Map<String, dynamic>> entregas) {
    if (entregas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileX, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Sin entregas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay estudiantes que hayan entregado esta tarea.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refrescarEntregas(),
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: entregas.length,
        itemBuilder: (context, index) {
          final entregaData = entregas[index];
          final entrega = ModeloEntrega.fromJson(entregaData);
          final estudiante = entregaData['estudiantes'] as Map<String, dynamic>;
          
          return _EntregaCard(
            entrega: entrega,
            estudiante: estudiante,
            tarea: widget.tarea,
            onActualizado: _refrescarEntregas,
          );
        },
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error al cargar entregas',
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refrescarEntregas,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Card individual de una entrega
class _EntregaCard extends StatelessWidget {
  const _EntregaCard({
    required this.entrega,
    required this.estudiante,
    required this.tarea,
    required this.onActualizado,
  });

  final ModeloEntrega entrega;
  final Map<String, dynamic> estudiante;
  final ModeloTarea tarea;
  final VoidCallback onActualizado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorEstado = _obtenerColorEstado(entrega.estado);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estudiante y estado
            Row(
              children: [
                AvatarWidget(
                  fotoUrl: estudiante['foto_perfil_url'] as String?,
                  nombreCompleto: estudiante['nombre_completo'] as String? ?? 'Sin nombre',
                  tipoUsuario: 'estudiante',
                  radio: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante['nombre_completo'] as String? ?? 'Sin nombre',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        estudiante['codigo_estudiante'] as String? ?? 'Sin código',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoEntregaToString(entrega.estado),
                    style: TextStyle(
                      color: colorEstado,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información de entrega
            Row(
              children: [
                Icon(LucideIcons.clock, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Entregado: ${DateFormat.yMMMEd('es').add_jm().format(entrega.fechaEntrega)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                if (entrega.calificacion != null) ...[
                  Icon(LucideIcons.star, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${entrega.calificacion!.toStringAsFixed(1)}/${tarea.puntosMaximos.toInt()}',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            
            // Comentario del estudiante
            if (entrega.comentarioEstudiante != null && entrega.comentarioEstudiante!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentario del estudiante:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.comentarioEstudiante!,
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            ],
            
            // Archivos adjuntos
            if (entrega.archivosAdjuntos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Archivos adjuntos (${entrega.totalArchivos}):',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entrega.archivosAdjuntos.map((archivo) => 
                  _ArchivoChip(archivo: archivo)
                ).toList(),
              ),
            ],
            
            // Comentario del profesor
            if (entrega.comentarioProfesor != null && entrega.comentarioProfesor!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentario del profesor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.comentarioProfesor!,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _mostrarDialogoCalificacion(context, entrega, tarea, onActualizado),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: Text(entrega.calificacion != null ? 'Editar Calificación' : 'Calificar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _obtenerColorEstado(EstadoEntrega estado) {
    switch (estado) {
      case EstadoEntrega.entregado:
        return Colors.green;
      case EstadoEntrega.calificado:
        return Colors.blue;
      case EstadoEntrega.tarde:
        return Colors.orange;
      case EstadoEntrega.noEntregado:
        return Colors.grey;
    }
  }
}

/// Chip para mostrar un archivo adjunto
class _ArchivoChip extends StatelessWidget {
  const _ArchivoChip({required this.archivo});
  
  final ArchivoAdjunto archivo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _descargarArchivo(archivo.urlArchivo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(archivo.icono, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archivo.nombreOriginal,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    archivo.tamanoFormateado,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.download,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descargarArchivo(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('No se pudo abrir la URL: $url');
      }
    } catch (e) {
      debugPrint('Error al descargar archivo: $e');
    }
  }
}

/// Muestra el diálogo para calificar una entrega
void _mostrarDialogoCalificacion(
  BuildContext context,
  ModeloEntrega entrega,
  ModeloTarea tarea,
  VoidCallback onActualizado,
) {
  showDialog(
    context: context,
    builder: (context) => _DialogoCalificacion(
      entrega: entrega,
      tarea: tarea,
      onActualizado: onActualizado,
    ),
  );
}

/// Diálogo para calificar una entrega
class _DialogoCalificacion extends StatefulWidget {
  const _DialogoCalificacion({
    required this.entrega,
    required this.tarea,
    required this.onActualizado,
  });

  final ModeloEntrega entrega;
  final ModeloTarea tarea;
  final VoidCallback onActualizado;

  @override
  State<_DialogoCalificacion> createState() => _DialogoCalificacionState();
}

class _DialogoCalificacionState extends State<_DialogoCalificacion> {
  late TextEditingController _calificacionController;
  late TextEditingController _comentarioController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _calificacionController = TextEditingController(
      text: widget.entrega.calificacion?.toString() ?? '',
    );
    _comentarioController = TextEditingController(
      text: widget.entrega.comentarioProfesor ?? '',
    );
  }

  @override
  void dispose() {
    _calificacionController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardarCalificacion() async {
    final calificacion = double.tryParse(_calificacionController.text);
    if (calificacion == null || calificacion < 0 || calificacion > widget.tarea.puntosMaximos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingrese una calificación válida (0 - ${widget.tarea.puntosMaximos.toInt()})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final repo = EntregaRepository();
      await repo.calificarEntrega(
        entregaId: widget.entrega.id,
        calificacion: calificacion,
        comentarioProfesor: _comentarioController.text.trim().isEmpty 
          ? null 
          : _comentarioController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onActualizado();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar calificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar Entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _calificacionController,
            decoration: InputDecoration(
              labelText: 'Calificación',
              suffixText: '/ ${widget.tarea.puntosMaximos.toInt()}',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _comentarioController,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardarCalificacion,
          child: _guardando 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
        ),
      ],
    );
  }
} 