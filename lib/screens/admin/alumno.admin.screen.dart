import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final estudiantesProvider = StateNotifierProvider<_EstudiantesNotifier, List<EstudianteAdmin>>((ref) {
  return _EstudiantesNotifier();
});

class _EstudiantesNotifier extends StateNotifier<List<EstudianteAdmin>> {
  _EstudiantesNotifier() : super([]) {
    cargarEstudiantes();
  }
  final _repo = EstudianteRepository();
  Future<void> cargarEstudiantes() async {
    final lista = await _repo.obtenerEstudiantes();
    state = lista;
  }
  Future<bool> crearEstudiante(EstudianteAdmin estudiante) async {
    try {
      await _repo.crearEstudiante(estudiante);
      await cargarEstudiantes();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> actualizarEstudiante(int id, EstudianteAdmin estudiante) async {
    try {
      await _repo.actualizarEstudiante(id, estudiante);
      await cargarEstudiantes();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> eliminarEstudiante(int id) async {
    try {
      await _repo.eliminarEstudiante(id);
      await cargarEstudiantes();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaEstudiantesAdmin extends ConsumerStatefulWidget {
  const PantallaEstudiantesAdmin({super.key});
  @override
  ConsumerState<PantallaEstudiantesAdmin> createState() => _PantallaEstudiantesAdminState();
}

class _PantallaEstudiantesAdminState extends ConsumerState<PantallaEstudiantesAdmin> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final estudiantes = ref.watch(estudiantesProvider);
    final filtro = _searchController.text.trim().toLowerCase();
    final listaFiltrada = filtro.isEmpty
        ? estudiantes
        : estudiantes.where((e) => e.nombreCompleto.toLowerCase().contains(filtro) || e.codigoEstudiante.toLowerCase().contains(filtro)).toList();
    return Column(
      children: [
        _construirHeader(),
        const SizedBox(height: AppConstants.defaultPadding),
        _construirBarraBusqueda(),
        const SizedBox(height: AppConstants.defaultPadding),
        Expanded(child: _construirContenido(listaFiltrada)),
      ],
    );
  }
  Widget _construirHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          const Text('Gestión de Estudiantes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(estudiantesProvider.notifier).cargarEstudiantes(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoEstudiante(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Estudiante'),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
  Widget _construirBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Buscar estudiantes...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
  Widget _construirContenido(List<EstudianteAdmin> estudiantes) {
    if (estudiantes.isEmpty) {
      return const Center(child: Text('No se encontraron estudiantes'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: estudiantes.length,
      itemBuilder: (context, index) {
        final estudiante = estudiantes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: AvatarWidget(
              fotoUrl: estudiante.fotoPerfilUrl,
              nombreCompleto: estudiante.nombreCompleto,
              tipoUsuario: 'estudiante',
              radio: 18,
              mostrarBordeOnline: estudiante.activo,
            ),
            title: Text(estudiante.nombreCompleto),
            subtitle: Text(estudiante.codigoEstudiante),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarDialogoEstudiante(context, estudiante),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminar(context, estudiante),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _mostrarDialogoEstudiante(BuildContext context, [EstudianteAdmin? estudiante]) {
    showDialog(
      context: context,
      builder: (context) => _DialogoEstudiante(estudiante: estudiante),
    );
  }
  void _confirmarEliminar(BuildContext context, EstudianteAdmin estudiante) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar a ${estudiante.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(estudiantesProvider.notifier).eliminarEstudiante(estudiante.id);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Estudiante eliminado exitosamente' : 'Error al eliminar estudiante'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DialogoEstudiante extends ConsumerStatefulWidget {
  const _DialogoEstudiante({this.estudiante});
  final EstudianteAdmin? estudiante;
  @override
  ConsumerState<_DialogoEstudiante> createState() => _DialogoEstudianteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EstudianteAdmin?>('estudiante', estudiante));
  }
}
class _DialogoEstudianteState extends ConsumerState<_DialogoEstudiante> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _semestreController;
  late final TextEditingController _direccionController;
  DateTime? _fechaNacimiento;
  bool _activo = true;
  int? _carreraSeleccionadaId;
  List<ModeloCarrera> _carreras = const [];
  final _carreraRepo = CarreraRepository();
  final _estRepo = EstudianteRepository();
  final TextEditingController _nuevaContrasenaController = TextEditingController();
  final TextEditingController _contrasenaAlCrearController = TextEditingController();
  bool _mostrarContrasena = false;
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.estudiante?.nombreCompleto ?? '');
    _codigoController = TextEditingController(text: widget.estudiante?.codigoEstudiante ?? '');
    _emailController = TextEditingController(text: widget.estudiante?.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: widget.estudiante?.telefono ?? '');
    _semestreController = TextEditingController(text: widget.estudiante?.semestreActual?.toString() ?? '');
    _direccionController = TextEditingController(text: widget.estudiante?.direccion ?? '');
    _fechaNacimiento = widget.estudiante?.fechaNacimiento;
    _activo = widget.estudiante?.activo ?? true;
    _carreraSeleccionadaId = widget.estudiante?.carreraId;
    _cargarCarreras();
  }
  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _semestreController.dispose();
    _direccionController.dispose();
    _nuevaContrasenaController.dispose();
    _contrasenaAlCrearController.dispose();
    super.dispose();
  }

  Future<void> _cargarCarreras() async {
    final lista = await _carreraRepo.obtenerCarreras();
    if (mounted) {
      setState(() => _carreras = lista);
    }
  }
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.estudiante != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Estudiante' : 'Nuevo Estudiante'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (esEdicion) ...[
                Align(
                  alignment: Alignment.center,
                  child: AvatarWidget(
                    fotoUrl: widget.estudiante?.fotoPerfilUrl,
                    nombreCompleto: widget.estudiante?.nombreCompleto ?? 'Estudiante',
                    tipoUsuario: 'estudiante',
                    radio: 36,
                    mostrarBordeOnline: _activo,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código de Estudiante *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              // Contraseña en creación
              if (!esEdicion) ...[
                TextFormField(
                  controller: _contrasenaAlCrearController,
                  decoration: const InputDecoration(labelText: 'Contraseña *', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _carreraSeleccionadaId,
                decoration: const InputDecoration(labelText: 'Carrera *', border: OutlineInputBorder()),
                items: _carreras
                    .map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.nombre),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _carreraSeleccionadaId = v),
                validator: (v) => v == null ? 'Seleccione una carrera' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _semestreController,
                decoration: const InputDecoration(labelText: 'Semestre Actual *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  final semestre = int.tryParse(value);
                  if (semestre == null || semestre < 1 || semestre > 20) {
                    return 'Debe ser entre 1 y 20';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaNacimiento ?? DateTime(now.year - 18, now.month, now.day),
                          firstDate: DateTime(1950),
                          lastDate: DateTime(now.year - 10),
                        );
                        if (picked != null) {
                          setState(() => _fechaNacimiento = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_fechaNacimiento == null
                            ? 'Seleccionar'
                            : _fechaNacimiento!.toIso8601String().substring(0, 10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      value: _activo,
                      title: const Text('Activo'),
                      onChanged: (v) => setState(() => _activo = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Campo de contraseña para edición
              if (esEdicion) ...[
                TextFormField(
                  controller: _nuevaContrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    border: const OutlineInputBorder(),
                    helperText: _nuevaContrasenaController.text.isEmpty 
                        ? 'Dejar vacío para mantener la contraseña actual'
                        : _nuevaContrasenaController.text.length >= 6 
                            ? 'Contraseña válida' 
                            : 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_nuevaContrasenaController.text.isNotEmpty)
                          Icon(
                            _nuevaContrasenaController.text.length >= 6 
                                ? Icons.check_circle 
                                : Icons.error,
                            color: _nuevaContrasenaController.text.length >= 6 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        IconButton(
                          icon: Icon(_mostrarContrasena ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _mostrarContrasena = !_mostrarContrasena;
                            });
                          },
                          tooltip: _mostrarContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña',
                        ),
                      ],
                    ),
                  ),
                  obscureText: !_mostrarContrasena,
                  onChanged: (value) {
                    setState(() {}); // Reconstruir para mostrar el indicador visual
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.trim().length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarEstudiante,
          child: Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
  Future<void> _guardarEstudiante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final estudiante = EstudianteAdmin(
      id: widget.estudiante?.id ?? 0,
      codigoEstudiante: _codigoController.text.trim(),
      nombreCompleto: _nombreController.text.trim(),
      correoElectronico: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      carreraId: _carreraSeleccionadaId,
      semestreActual: int.tryParse(_semestreController.text.trim()),
      fechaIngreso: widget.estudiante?.fechaIngreso ?? DateTime.now(),
      fechaCreacion: widget.estudiante?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      estado: _activo ? 'activo' : 'inactivo',
      usuarioId: widget.estudiante?.usuarioId,
      fotoPerfilUrl: widget.estudiante?.fotoPerfilUrl,
    );
    final notifier = ref.read(estudiantesProvider.notifier);
    final creando = widget.estudiante == null;
    final success = creando
        ? await notifier.crearEstudiante(estudiante)
        : await notifier.actualizarEstudiante(estudiante.id, estudiante);
    if (!mounted) {
      return;
    }
    // Si es creación, setear contraseña inmediatamente por código
    if (creando) {
      final clave = _contrasenaAlCrearController.text.trim();
      if (clave.isNotEmpty) {
        try {
          await _estRepo.actualizarContrasenaPorCodigo(
            codigoEstudiante: _codigoController.text.trim(),
            nuevaContrasena: clave,
          );
        } catch (_) {}
      }
    }
    
    // Si es edición y se proporcionó una nueva contraseña, actualizarla
    if (!creando && _nuevaContrasenaController.text.trim().isNotEmpty) {
      try {
        await _estRepo.actualizarContrasena(
          estudianteId: estudiante.id,
          nuevaContrasena: _nuevaContrasenaController.text.trim(),
          usuarioId: widget.estudiante?.usuarioId,
        );
      } catch (_) {}
    }
    if (success) {
      // Limpiar el campo de contraseña después de guardar exitosamente
      _nuevaContrasenaController.clear();
    }
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Estudiante guardado exitosamente' : 'Error al guardar estudiante'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }


}