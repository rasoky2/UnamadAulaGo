import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final carrerasProvider = StateNotifierProvider<_CarrerasNotifier, List<ModeloCarrera>>((ref) {
  return _CarrerasNotifier();
});

class _CarrerasNotifier extends StateNotifier<List<ModeloCarrera>> {
  _CarrerasNotifier() : super([]) {
    cargarCarreras();
  }
  final _repo = CarreraRepository();
  Future<void> cargarCarreras() async {
    final lista = await _repo.obtenerCarreras();
    state = lista;
  }
  Future<bool> crearCarrera(ModeloCarrera carrera) async {
    try {
      await _repo.crearCarrera(carrera);
      await cargarCarreras();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> actualizarCarrera(int id, ModeloCarrera carrera) async {
    try {
      await _repo.actualizarCarrera(id, carrera);
      await cargarCarreras();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> eliminarCarrera(int id) async {
    try {
      await _repo.eliminarCarrera(id);
      await cargarCarreras();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaCarrerasAdmin extends ConsumerWidget {
  const PantallaCarrerasAdmin({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carreras = ref.watch(carrerasProvider);
    return Column(
      children: [
        _BarraControles(),
        const SizedBox(height: AppConstants.defaultPadding),
        Expanded(
          child: carreras.isEmpty
              ? const _VistaVacia()
              : _ListaCarreras(carreras: carreras),
        ),
      ],
    );
  }
}

class _BarraControles extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Gestión de Carreras',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(carrerasProvider.notifier).cargarCarreras(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          const SizedBox(width: AppConstants.smallPadding),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoCarrera(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Carrera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaCarreras extends StatelessWidget {
  const _ListaCarreras({required this.carreras});
  final List<ModeloCarrera> carreras;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: ListView.builder(
        itemCount: carreras.length,
        itemBuilder: (context, index) {
          final carrera = carreras[index];
          return _TarjetaCarrera(carrera: carrera);
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<ModeloCarrera>('carreras', carreras));
  }
}

class _TarjetaCarrera extends ConsumerWidget {
  const _TarjetaCarrera({required this.carrera});
  final ModeloCarrera carrera;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Icon(Icons.school, color: Colors.blue.shade600, size: 28),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          carrera.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          carrera.codigo,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (carrera.descripcion != null && carrera.descripcion!.isNotEmpty)
                    Text(
                      carrera.descripcion!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${carrera.duracionSemestres} semestres',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      if (carrera.directorNombre != null && carrera.directorNombre!.isNotEmpty) ...[
                        Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            carrera.directorNombre!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Column(
              children: [
                IconButton(
                  onPressed: () => _mostrarDialogoCarrera(context, ref, carrera: carrera),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar carrera',
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _confirmarEliminar(context, ref, carrera),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar carrera',
                ),
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
    properties.add(DiagnosticsProperty<ModeloCarrera>('carrera', carrera));
  }
}

class _VistaVacia extends ConsumerWidget {
  const _VistaVacia();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.largePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.school_outlined, size: 64, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay carreras registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza agregando la primera carrera de tu institución',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoCarrera(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primera Carrera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.defaultPadding,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarDialogoCarrera(BuildContext context, WidgetRef ref, {ModeloCarrera? carrera}) {
  showDialog(
    context: context,
    builder: (context) => _DialogoCarrera(carrera: carrera),
  );
}

class _DialogoCarrera extends ConsumerStatefulWidget {
  const _DialogoCarrera({this.carrera});
  final ModeloCarrera? carrera;
  @override
  ConsumerState<_DialogoCarrera> createState() => _DialogoCarreraState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCarrera?>('carrera', carrera));
  }
}
class _DialogoCarreraState extends ConsumerState<_DialogoCarrera> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _duracionController = TextEditingController();
  final _directorNombreController = TextEditingController();
  final _directorEmailController = TextEditingController();
  bool _guardando = false;
  
  // Variables para facultades
  List<Map<String, dynamic>> _facultades = [];
  int? _facultadSeleccionada;
  @override
  void initState() {
    super.initState();
    if (widget.carrera != null) {
      _nombreController.text = widget.carrera!.nombre;
      _codigoController.text = widget.carrera!.codigo;
      _descripcionController.text = widget.carrera!.descripcion ?? '';
      _duracionController.text = widget.carrera!.duracionSemestres.toString();
      _directorNombreController.text = widget.carrera!.directorNombre ?? '';
      _directorEmailController.text = widget.carrera!.directorEmail ?? '';
      // Solo asignar facultad si no es 0 (valor por defecto cuando no hay facultad)
      if (widget.carrera!.facultadId != 0) {
        _facultadSeleccionada = widget.carrera!.facultadId;
      }
    } else {
      _duracionController.text = '10';
    }
    _cargarFacultades();
  }
  
  /// Carga las facultades desde la base de datos
  Future<void> _cargarFacultades() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('facultades')
          .select('id, nombre, codigo')
          .order('nombre');
      
      setState(() {
        _facultades = List<Map<String, dynamic>>.from(response);
        // Si no hay facultad seleccionada, seleccionar la primera por defecto
        if (_facultadSeleccionada == null && _facultades.isNotEmpty) {
          _facultadSeleccionada = _facultades.first['id'] as int;
        }
      });
    } catch (e) {
      debugPrint('Error al cargar facultades: $e');
    }
  }
  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _duracionController.dispose();
    _directorNombreController.dispose();
          _directorEmailController.dispose();
      super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.carrera != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppConstants.largePadding),
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
                    esEdicion ? 'Editar Carrera' : 'Nueva Carrera',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largePadding),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre de la carrera *', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codigoController,
                              decoration: const InputDecoration(labelText: 'Código *', border: OutlineInputBorder(), hintText: 'Ej: ISI'),
                              inputFormatters: const [],
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) => value == null || value.trim().isEmpty ? 'El código es obligatorio' : null,
                            ),
                          ),
                          const SizedBox(width: AppConstants.defaultPadding),
                          Expanded(
                            child: TextFormField(
                              controller: _duracionController,
                              decoration: const InputDecoration(labelText: 'Duración (semestres) *', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La duración es obligatoria';
                                }
                                final duracion = int.tryParse(value);
                                if (duracion == null || duracion < 1 || duracion > 20) {
                                  return 'Debe ser entre 1 y 20 semestres';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      DropdownButtonFormField<int>(
                        initialValue: _facultades.isNotEmpty ? (_facultadSeleccionada ?? _facultades.first['id'] as int) : null,
                        decoration: const InputDecoration(
                          labelText: 'Facultad *',
                          border: OutlineInputBorder(),
                        ),
                        items: _facultades.map((facultad) {
                          return DropdownMenuItem<int>(
                            value: facultad['id'] as int,
                            child: Text(facultad['nombre'] as String),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          setState(() {
                            _facultadSeleccionada = value;
                          });
                        },
                        validator: (value) => value == null ? 'Selecciona una facultad' : null,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      TextFormField(
                        controller: _directorNombreController,
                        decoration: const InputDecoration(labelText: 'Nombre del director', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      TextFormField(
                        controller: _directorEmailController,
                        decoration: const InputDecoration(labelText: 'Email del director', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Email inválido';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardarCarrera,
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
  Future<void> _guardarCarrera() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _guardando = true; });
    final carrera = ModeloCarrera(
      id: widget.carrera?.id ?? 0,
      nombre: _nombreController.text.trim(),
      codigo: _codigoController.text.trim().toUpperCase(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      facultadId: _facultadSeleccionada ?? 1,
      duracionSemestres: int.tryParse(_duracionController.text.trim()) ?? 10,
      directorNombre: _directorNombreController.text.trim().isEmpty ? null : _directorNombreController.text.trim(),
      directorEmail: _directorEmailController.text.trim().isEmpty ? null : _directorEmailController.text.trim(),
      fechaCreacion: widget.carrera?.fechaCreacion ?? DateTime.now(),
    );
    final notifier = ref.read(carrerasProvider.notifier);
    final success = widget.carrera != null
        ? await notifier.actualizarCarrera(carrera.id, carrera)
        : await notifier.crearCarrera(carrera);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Carrera guardada exitosamente' : 'Error al guardar carrera'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    setState(() { _guardando = false; });
  }
}

void _confirmarEliminar(BuildContext context, WidgetRef ref, ModeloCarrera carrera) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Estás seguro de que deseas eliminar la carrera "${carrera.nombre}"?'),
          const SizedBox(height: 8),
          Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final success = await ref.read(carrerasProvider.notifier).eliminarCarrera(carrera.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Carrera eliminada exitosamente' : 'Error al eliminar'),
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
