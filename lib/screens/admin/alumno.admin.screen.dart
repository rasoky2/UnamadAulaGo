import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:aulago/widgets/foto_perfil_upload.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<bool> crearEstudiante(EstudianteAdmin estudiante, {required String contrasena}) async {
    try {
      await _repo.crearEstudiante(estudiante, contrasena: contrasena);
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
            onPressed: () => _mostrarSheetCrearEstudiante(context),
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
                  onPressed: () => _mostrarSheetEditarEstudiante(context, estudiante),
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
  // Eliminado el diálogo clásico; ahora usamos bottom sheets para crear/editar

  void _mostrarSheetCrearEstudiante(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _SheetCrearEstudiante(),
    );
  }

  void _mostrarSheetEditarEstudiante(BuildContext context, EstudianteAdmin estudiante) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SheetEditarEstudiante(estudiante: estudiante),
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

// Diálogo clásico removido: ahora solo bottom sheets para crear/editar estudiantes

class _SheetCrearEstudiante extends ConsumerStatefulWidget {
  const _SheetCrearEstudiante();
  @override
  ConsumerState<_SheetCrearEstudiante> createState() => _SheetCrearEstudianteState();
}

class _SheetCrearEstudianteState extends ConsumerState<_SheetCrearEstudiante> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _usuarioEmailController;
  late final TextEditingController _emailFullController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _semestreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _contrasenaController;
  DateTime? _fechaNacimiento;
  bool _activo = true;
  int? _carreraSeleccionadaId;
  List<ModeloCarrera> _carreras = const [];
  final _carreraRepo = CarreraRepository();
  bool _bloquearDominioEmail = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _codigoController = TextEditingController();
    _usuarioEmailController = TextEditingController();
    _emailFullController = TextEditingController();
    _telefonoController = TextEditingController();
    _semestreController = TextEditingController();
    _direccionController = TextEditingController();
    _contrasenaController = TextEditingController();
    _cargarCarreras();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _usuarioEmailController.dispose();
    _emailFullController.dispose();
    _telefonoController.dispose();
    _semestreController.dispose();
    _direccionController.dispose();
    _contrasenaController.dispose();
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
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
          bottom: viewInsets + AppConstants.defaultPadding,
        ),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nuevo Estudiante',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    )
                  ],
                ),
                const SizedBox(height: 12),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
                const SizedBox(height: 12),

              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código de Estudiante *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (value.trim().length > 10) {
                      return 'Máximo 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email institucional bloqueando dominio
                Row(
                  children: [
                    Expanded(
                      child: _bloquearDominioEmail
                          ? TextFormField(
                              controller: _usuarioEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Usuario del correo *',
                                hintText: 'usuario',
                                border: OutlineInputBorder(),
                                suffixText: '@unamad.edu.pe',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                if (value.contains('@')) {
                                  return 'Solo ingrese el usuario, sin @';
                                }
                                return null;
                              },
                            )
                          : TextFormField(
                              controller: _emailFullController,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                hintText: 'usuario@unamad.edu.pe',
                                border: OutlineInputBorder(),
                              ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                                final email = value.trim();
                                if (!email.endsWith('@unamad.edu.pe')) {
                                  return 'Debe ser dominio @unamad.edu.pe';
                                }
                                final local = email.split('@').first;
                                if (local.isEmpty) {
                                  return 'Ingrese el usuario antes de @unamad.edu.pe';
                  }
                  return null;
                },
              ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _bloquearDominioEmail = !_bloquearDominioEmail),
                      icon: Icon(_bloquearDominioEmail ? Icons.lock : Icons.lock_open),
                      tooltip: _bloquearDominioEmail ? 'Desbloquear dominio' : 'Bloquear dominio',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono (9 dígitos)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length != 9) {
                        return 'Debe tener exactamente 9 dígitos';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                  initialValue: _carreraSeleccionadaId,
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
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
              ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

                TextFormField(
                  controller: _contrasenaController,
                  decoration: const InputDecoration(labelText: 'Contraseña *', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (value.trim().length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarEstudiante,
                        child: const Text('Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarEstudiante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Construir email según estado del bloqueo
    final String email = _bloquearDominioEmail
        ? '${_usuarioEmailController.text.trim()}@unamad.edu.pe'
        : _emailFullController.text.trim();

    final estudiante = EstudianteAdmin(
      id: 0,
      codigoEstudiante: _codigoController.text.trim(),
      nombreCompleto: _nombreController.text.trim(),
      correoElectronico: email,
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      carreraId: _carreraSeleccionadaId,
      semestreActual: int.tryParse(_semestreController.text.trim()),
      fechaIngreso: DateTime.now(),
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      estado: _activo ? 'activo' : 'inactivo',
    );

    final success = await ref.read(estudiantesProvider.notifier).crearEstudiante(
          estudiante,
          contrasena: _contrasenaController.text.trim(),
        );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Estudiante creado exitosamente' : 'Error al crear estudiante'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _SheetEditarEstudiante extends ConsumerStatefulWidget {
  const _SheetEditarEstudiante({required this.estudiante});
  final EstudianteAdmin estudiante;
  @override
  ConsumerState<_SheetEditarEstudiante> createState() => _SheetEditarEstudianteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EstudianteAdmin>('estudiante', estudiante));
  }
}

class _SheetEditarEstudianteState extends ConsumerState<_SheetEditarEstudiante> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _semestreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _nuevaContrasenaController;
  DateTime? _fechaNacimiento;
  bool _activo = true;
  int? _carreraSeleccionadaId;
  List<ModeloCarrera> _carreras = const [];
  final _carreraRepo = CarreraRepository();
  bool _mostrarContrasena = false;
  String? _fotoTemporalUrl;

  @override
  void initState() {
    super.initState();
    final e = widget.estudiante;
    _nombreController = TextEditingController(text: e.nombreCompleto);
    _codigoController = TextEditingController(text: e.codigoEstudiante);
    _emailController = TextEditingController(text: e.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: e.telefono ?? '');
    _semestreController = TextEditingController(text: e.semestreActual?.toString() ?? '');
    _direccionController = TextEditingController(text: e.direccion ?? '');
    _nuevaContrasenaController = TextEditingController();
    _fechaNacimiento = e.fechaNacimiento;
    _activo = e.activo;
    _carreraSeleccionadaId = e.carreraId;
    _fotoTemporalUrl = e.fotoPerfilUrl;
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
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
          bottom: viewInsets + AppConstants.defaultPadding,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Editar Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Foto con uploader
                Center(
                  child: FotoPerfilUploadWidget(
                    usuarioId: (widget.estudiante.usuarioId ?? widget.estudiante.id).toString(),
                    nombreCompleto: widget.estudiante.nombreCompleto,
                    tipoUsuario: 'estudiante',
                    fotoActualUrl: _fotoTemporalUrl,
                    radio: 36,
                    onFotoSubida: (nuevaUrl) {
                      setState(() => _fotoTemporalUrl = nuevaUrl);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(labelText: 'Código de Estudiante *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (value.trim().length > 10) {
                      return 'Máximo 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email *', hintText: 'usuario@unamad.edu.pe', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    final email = value.trim();
                    if (!email.endsWith('@unamad.edu.pe')) {
                      return 'Debe ser dominio @unamad.edu.pe';
                    }
                    final local = email.split('@').first;
                    if (local.isEmpty) {
                      return 'Ingrese el usuario antes de @unamad.edu.pe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono (9 dígitos)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length != 9) {
                        return 'Debe tener exactamente 9 dígitos';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  initialValue: _carreraSeleccionadaId,
                  decoration: const InputDecoration(labelText: 'Carrera *', border: OutlineInputBorder()),
                  items: _carreras
                      .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _carreraSeleccionadaId = v),
                  validator: (v) => v == null ? 'Seleccione una carrera' : null,
                ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

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
                          decoration: const InputDecoration(labelText: 'Fecha de nacimiento', border: OutlineInputBorder()),
                          child: Text(_fechaNacimiento == null ? 'Seleccionar' : _fechaNacimiento!.toIso8601String().substring(0, 10)),
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
                const SizedBox(height: 12),

                TextFormField(
            controller: _nuevaContrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña (opcional)',
                    border: const OutlineInputBorder(),
                    helperText: _nuevaContrasenaController.text.isEmpty
                        ? 'Dejar vacío para mantener la contraseña actual'
                        : _nuevaContrasenaController.text.length >= 6 ? 'Contraseña válida' : 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_mostrarContrasena ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
                    ),
                  ),
                  obscureText: !_mostrarContrasena,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.trim().length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardar,
                        child: const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
                return;
              }
    final estudiante = EstudianteAdmin(
      id: widget.estudiante.id,
      codigoEstudiante: _codigoController.text.trim(),
      nombreCompleto: _nombreController.text.trim(),
      correoElectronico: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      carreraId: _carreraSeleccionadaId,
      semestreActual: int.tryParse(_semestreController.text.trim()),
      fechaIngreso: widget.estudiante.fechaIngreso ?? DateTime.now(),
      fechaCreacion: widget.estudiante.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      estado: _activo ? 'activo' : 'inactivo',
      usuarioId: widget.estudiante.usuarioId,
      fotoPerfilUrl: _fotoTemporalUrl,
    );

    final success = await ref.read(estudiantesProvider.notifier).actualizarEstudiante(estudiante.id, estudiante);
    if (!mounted) {
                return;
              }
    // Si se ingresó nueva contraseña, actualizarla
    if (_nuevaContrasenaController.text.trim().isNotEmpty) {
      try {
        await EstudianteRepository().actualizarContrasena(
          estudianteId: estudiante.id,
          nuevaContrasena: _nuevaContrasenaController.text.trim(),
          usuarioId: estudiante.usuarioId,
        );
      } catch (_) {}
    }
    Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Estudiante actualizado' : 'Error al actualizar estudiante'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}