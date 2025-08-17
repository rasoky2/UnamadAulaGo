import 'package:aulago/models/anuncio.model.dart';
import 'package:aulago/models/fecha_importante.model.dart';
import 'package:aulago/repositories/anuncio.repository.dart';
import 'package:aulago/repositories/fecha_importante.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers para Riverpod
final anunciosProvider = StateNotifierProvider<_AnunciosNotifier, List<ModeloAnuncio>>((ref) {
  return _AnunciosNotifier();
});

final fechasImportantesProvider = StateNotifierProvider<_FechasImportantesNotifier, List<ModeloFechaImportante>>((ref) {
  return _FechasImportantesNotifier();
});

class _AnunciosNotifier extends StateNotifier<List<ModeloAnuncio>> {
  _AnunciosNotifier() : super([]) {
    cargarAnuncios();
  }
  
  final _repo = AnuncioRepository();
  
  Future<void> cargarAnuncios() async {
    final lista = await _repo.obtenerAnuncios();
    state = lista;
  }
  
  Future<bool> crearAnuncio(ModeloAnuncio anuncio) async {
    try {
      await _repo.crearAnuncio(anuncio);
      await cargarAnuncios();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<bool> actualizarAnuncio(int id, ModeloAnuncio anuncio) async {
    try {
      await _repo.actualizarAnuncio(id, anuncio);
      await cargarAnuncios();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<bool> eliminarAnuncio(int id) async {
    try {
      await _repo.eliminarAnuncio(id);
      await cargarAnuncios();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _FechasImportantesNotifier extends StateNotifier<List<ModeloFechaImportante>> {
  _FechasImportantesNotifier() : super([]) {
    cargarFechasImportantes();
  }
  
  final _repo = FechaImportanteRepository();
  
  Future<void> cargarFechasImportantes() async {
    final lista = await _repo.obtenerFechasImportantes();
    state = lista;
  }
  
  Future<bool> crearFechaImportante(ModeloFechaImportante fecha) async {
    try {
      await _repo.crearFechaImportante(fecha);
      await cargarFechasImportantes();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<bool> actualizarFechaImportante(int id, ModeloFechaImportante fecha) async {
    try {
      await _repo.actualizarFechaImportante(id, fecha);
      await cargarFechasImportantes();
      return true;
    } catch (_) {
      return false;
    }
  }
  
  Future<bool> eliminarFechaImportante(int id) async {
    try {
      await _repo.eliminarFechaImportante(id);
      await cargarFechasImportantes();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaExtrasAdmin extends ConsumerWidget {
  const PantallaExtrasAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anuncios = ref.watch(anunciosProvider);
    final fechasImportantes = ref.watch(fechasImportantesProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeccionAnuncios(ref: ref, anuncios: anuncios),
          const SizedBox(height: 24),
          _SeccionFechasImportantes(ref: ref, fechasImportantes: fechasImportantes),
        ],
      ),
    );
  }
}

// Sección de Anuncios
class _SeccionAnuncios extends ConsumerWidget {
  const _SeccionAnuncios({required this.ref, required this.anuncios});
  
  final WidgetRef ref;
  final List<ModeloAnuncio> anuncios;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Gestión de Anuncios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(anunciosProvider.notifier).cargarAnuncios(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
            ),
            const SizedBox(width: AppConstants.smallPadding),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAnuncio(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Anuncio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (anuncios.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No hay anuncios registrados'),
              ),
            ),
          )
        else
          ...anuncios.map((anuncio) => _TarjetaAnuncio(anuncio: anuncio, ref: ref)),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IterableProperty<ModeloAnuncio>('anuncios', anuncios))
    ..add(DiagnosticsProperty<WidgetRef>('ref', ref));
  }
}

// Tarjeta de Anuncio
class _TarjetaAnuncio extends ConsumerWidget {
  const _TarjetaAnuncio({required this.anuncio, required this.ref});
  
  final ModeloAnuncio anuncio;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    anuncio.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => _mostrarDialogoAnuncio(context, ref, anuncio: anuncio),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar anuncio',
                ),
                IconButton(
                  onPressed: () => _confirmarEliminarAnuncio(context, ref, anuncio),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar anuncio',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              anuncio.contenido,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Creado: ${_formatearFecha(anuncio.fechaCreacion)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<WidgetRef>('ref', ref))
    ..add(DiagnosticsProperty<ModeloAnuncio>('anuncio', anuncio));
  }
}

// Sección de Fechas Importantes
class _SeccionFechasImportantes extends ConsumerWidget {
  const _SeccionFechasImportantes({required this.ref, required this.fechasImportantes});
  
  final WidgetRef ref;
  final List<ModeloFechaImportante> fechasImportantes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Gestión de Fechas Importantes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => ref.read(fechasImportantesProvider.notifier).cargarFechasImportantes(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
            ),
            const SizedBox(width: AppConstants.smallPadding),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoFechaImportante(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Fecha'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (fechasImportantes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No hay fechas importantes registradas'),
              ),
            ),
          )
        else
          ...fechasImportantes.map((fecha) => _TarjetaFechaImportante(fecha: fecha, ref: ref)),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IterableProperty<ModeloFechaImportante>('fechasImportantes', fechasImportantes))
    ..add(DiagnosticsProperty<WidgetRef>('ref', ref));
  }
}

// Tarjeta de Fecha Importante
class _TarjetaFechaImportante extends ConsumerWidget {
  const _TarjetaFechaImportante({required this.fecha, required this.ref});
  
  final ModeloFechaImportante fecha;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fecha.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => _mostrarDialogoFechaImportante(context, ref, fecha: fecha),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar fecha importante',
                ),
                IconButton(
                  onPressed: () => _confirmarEliminarFechaImportante(context, ref, fecha),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar fecha importante',
                ),
              ],
            ),
            if (fecha.descripcion != null && fecha.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                fecha.descripcion!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatearFecha(fecha.fechaEvento),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                if (fecha.categoria != null && fecha.categoria!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fecha.categoria!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloFechaImportante>('fecha', fecha))
    ..add(DiagnosticsProperty<WidgetRef>('ref', ref));
  }
}

// Funciones auxiliares
String _formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

void _mostrarDialogoAnuncio(BuildContext context, WidgetRef ref, {ModeloAnuncio? anuncio}) {
  showDialog(
    context: context,
    builder: (context) => _DialogoAnuncio(anuncio: anuncio),
  );
}

void _mostrarDialogoFechaImportante(BuildContext context, WidgetRef ref, {ModeloFechaImportante? fecha}) {
  showDialog(
    context: context,
    builder: (context) => _DialogoFechaImportante(fecha: fecha),
  );
}

void _confirmarEliminarAnuncio(BuildContext context, WidgetRef ref, ModeloAnuncio anuncio) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Estás seguro de que deseas eliminar el anuncio "${anuncio.titulo}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await ref.read(anunciosProvider.notifier).eliminarAnuncio(anuncio.id!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Anuncio eliminado exitosamente' : 'Error al eliminar'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}

void _confirmarEliminarFechaImportante(BuildContext context, WidgetRef ref, ModeloFechaImportante fecha) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Estás seguro de que deseas eliminar la fecha importante "${fecha.titulo}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await ref.read(fechasImportantesProvider.notifier).eliminarFechaImportante(fecha.id!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Fecha importante eliminada exitosamente' : 'Error al eliminar'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}

// Diálogo para crear/editar anuncios
class _DialogoAnuncio extends ConsumerStatefulWidget {
  const _DialogoAnuncio({this.anuncio});
  
  final ModeloAnuncio? anuncio;
  
  @override
  ConsumerState<_DialogoAnuncio> createState() => _DialogoAnuncioState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloAnuncio?>('anuncio', anuncio));
  }
}

class _DialogoAnuncioState extends ConsumerState<_DialogoAnuncio> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  bool _guardando = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.anuncio != null) {
      _tituloController.text = widget.anuncio!.titulo;
      _contenidoController.text = widget.anuncio!.contenido;
    }
  }
  
  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.anuncio != null;
    
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(esEdicion ? Icons.edit : Icons.add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    esEdicion ? 'Editar Anuncio' : 'Nuevo Anuncio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'El título es obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contenidoController,
                    decoration: const InputDecoration(
                      labelText: 'Contenido *',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 4,
                    maxLines: 8,
                    validator: (value) => value == null || value.trim().isEmpty ? 'El contenido es obligatorio' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardarAnuncio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _guardando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(esEdicion ? 'Guardar' : 'Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _guardarAnuncio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() { _guardando = true; });
    
    final anuncio = ModeloAnuncio(
      id: widget.anuncio?.id,
      titulo: _tituloController.text.trim(),
      contenido: _contenidoController.text.trim(),
      fechaCreacion: widget.anuncio?.fechaCreacion ?? DateTime.now(),
    );
    
    final notifier = ref.read(anunciosProvider.notifier);
    final success = widget.anuncio != null
        ? await notifier.actualizarAnuncio(anuncio.id!, anuncio)
        : await notifier.crearAnuncio(anuncio);
    
    if (!mounted) {
      return;
    }
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Anuncio guardado exitosamente' : 'Error al guardar anuncio'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    
    setState(() { _guardando = false; });
  }
}

// Diálogo para crear/editar fechas importantes
class _DialogoFechaImportante extends ConsumerStatefulWidget {
  const _DialogoFechaImportante({this.fecha});
  
  final ModeloFechaImportante? fecha;
  
  @override
  ConsumerState<_DialogoFechaImportante> createState() => _DialogoFechaImportanteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloFechaImportante?>('fecha', fecha));
  }
}

class _DialogoFechaImportanteState extends ConsumerState<_DialogoFechaImportante> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();
  DateTime? _fechaEvento;
  bool _guardando = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.fecha != null) {
      _tituloController.text = widget.fecha!.titulo;
      _descripcionController.text = widget.fecha!.descripcion ?? '';
      _categoriaController.text = widget.fecha!.categoria ?? '';
      _fechaEvento = widget.fecha!.fechaEvento;
    } else {
      _fechaEvento = DateTime.now();
    }
  }
  
  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.fecha != null;
    
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(esEdicion ? Icons.edit : Icons.add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    esEdicion ? 'Editar Fecha Importante' : 'Nueva Fecha Importante',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'El título es obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoriaController,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Académico, Evento, Examen',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha del evento *',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _fechaEvento == null ? 'Seleccionar' : _formatearFecha(_fechaEvento!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaEvento ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() => _fechaEvento = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: const Text('Elegir fecha'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardarFechaImportante,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _guardando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(esEdicion ? 'Guardar' : 'Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _guardarFechaImportante() async {
    if (!_formKey.currentState!.validate() || _fechaEvento == null) {
      return;
    }
    
    setState(() { _guardando = true; });
    
    final fecha = ModeloFechaImportante(
      id: widget.fecha?.id ?? 0,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      fechaEvento: _fechaEvento!,
      categoria: _categoriaController.text.trim().isEmpty ? null : _categoriaController.text.trim(),
    );
    
    final notifier = ref.read(fechasImportantesProvider.notifier);
    final success = widget.fecha != null
        ? await notifier.actualizarFechaImportante(fecha.id!, fecha)
        : await notifier.crearFechaImportante(fecha);
    
    if (!mounted) {
      return;
    }
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Fecha importante guardada exitosamente' : 'Error al guardar fecha importante'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    
    setState(() { _guardando = false; });
  }
}


