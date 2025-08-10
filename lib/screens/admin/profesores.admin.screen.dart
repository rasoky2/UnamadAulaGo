import 'package:aulago/models/profesor.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profesoresProvider = StateNotifierProvider<_ProfesoresNotifier, List<ProfesorAdmin>>((ref) {
  return _ProfesoresNotifier();
});

class _ProfesoresNotifier extends StateNotifier<List<ProfesorAdmin>> {
  _ProfesoresNotifier() : super([]) {
    cargarProfesores();
  }
  final _repo = ProfesorRepository();
  Future<void> cargarProfesores() async {
    final lista = await _repo.obtenerProfesores();
    state = lista;
  }
  Future<bool> crearProfesor(ProfesorAdmin profesor) async {
    try {
      await _repo.crearProfesor(profesor);
      await cargarProfesores();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> actualizarProfesor(String id, ProfesorAdmin profesor) async {
    try {
      await _repo.actualizarProfesor(int.tryParse(id) ?? 0, profesor);
      await cargarProfesores();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> eliminarProfesor(String id) async {
    try {
      await _repo.eliminarProfesor(int.tryParse(id) ?? 0);
      await cargarProfesores();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaProfesoresAdmin extends ConsumerStatefulWidget {
  const PantallaProfesoresAdmin({super.key});
  @override
  ConsumerState<PantallaProfesoresAdmin> createState() => _PantallaProfesoresAdminState();
}

class _PantallaProfesoresAdminState extends ConsumerState<PantallaProfesoresAdmin> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final profesores = ref.watch(profesoresProvider);
    final filtro = _searchController.text.trim().toLowerCase();
    final listaFiltrada = filtro.isEmpty
        ? profesores
        : profesores.where((e) => e.nombreCompleto.toLowerCase().contains(filtro) || e.codigoProfesor.toLowerCase().contains(filtro)).toList();
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('Gestión de Profesores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(profesoresProvider.notifier).cargarProfesores(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoProfesor(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Profesor'),
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
          labelText: 'Buscar profesores...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
  Widget _construirContenido(List<ProfesorAdmin> profesores) {
    if (profesores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: AppConstants.textTertiary),
            SizedBox(height: 16),
            Text('No se encontraron profesores', style: TextStyle(fontSize: 18, color: AppConstants.textSecondary)),
            SizedBox(height: 8),
            Text('Ajusta la búsqueda o crea el primer profesor', style: TextStyle(color: AppConstants.textTertiary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profesores.length,
      itemBuilder: (context, index) {
        final profesor = profesores[index];
          return Card(
          margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: AvatarWidget(
                fotoUrl: profesor.usuario.fotoPerfilUrl,
                nombreCompleto: profesor.nombreCompleto,
                tipoUsuario: 'profesor',
                radio: 18,
                mostrarBordeOnline: profesor.activo,
              ),
              title: Text(profesor.nombreCompleto),
              subtitle: Text('${profesor.codigoProfesor} • ${profesor.correoElectronico ?? '—'}'),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cursos dictados', style: Theme.of(context).textTheme.titleMedium),
                ),
                FutureBuilder<List<CursoProfesor>>(
                  future: ProfesorRepository().obtenerCursosPorProfesor(int.tryParse(profesor.id) ?? 0),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error al cargar cursos: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                      );
                    }
                    final cursos = snapshot.data ?? const [];
                    if (cursos.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No tiene cursos asignados'),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in cursos)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text('${c.codigoCurso} - ${c.nombreCurso}'),
                            subtitle: Text('${c.carreraNombre ?? '—'} • ${c.creditos} créditos'),
                            trailing: Chip(
                              avatar: const Icon(Icons.group, size: 16),
                              label: Text('${c.estudiantesMatriculados}'),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _mostrarDialogoEditarProfesor(context, profesor),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar perfil'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _mostrarDialogoCambiarContrasena(context, profesor),
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Cambiar contraseña'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmarEliminar(context, profesor),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
        );
      },
    );
  }
  void _mostrarDialogoProfesor(BuildContext context, [ProfesorAdmin? profesor]) {
    showDialog(
      context: context,
      builder: (context) => _DialogoProfesor(profesor: profesor),
    );
  }

  void _mostrarDialogoEditarProfesor(BuildContext context, ProfesorAdmin profesor) {
    showDialog(
      context: context,
      builder: (context) => _DialogoProfesor(profesor: profesor),
    );
  }

  void _mostrarDialogoCambiarContrasena(BuildContext context, ProfesorAdmin profesor) {
    showDialog(
      context: context,
      builder: (context) => _DialogoContrasenaProfesor(profesor: profesor),
    );
  }
  void _confirmarEliminar(BuildContext context, ProfesorAdmin profesor) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar al profesor ${profesor.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(profesoresProvider.notifier).eliminarProfesor(profesor.id);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Profesor eliminado exitosamente' : 'Error al eliminar profesor'),
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

class _DialogoProfesor extends ConsumerStatefulWidget {
  const _DialogoProfesor({this.profesor});
  final ProfesorAdmin? profesor;
  @override
  ConsumerState<_DialogoProfesor> createState() => _DialogoProfesorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ProfesorAdmin?>('profesor', profesor));
  }
}
class _DialogoProfesorState extends ConsumerState<_DialogoProfesor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _emailController;
  late final TextEditingController _especialidadController;
  late final TextEditingController _gradoController;
  late bool _activo;
  final TextEditingController _contrasenaController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.profesor?.nombreCompleto ?? '');
    _codigoController = TextEditingController(text: widget.profesor?.codigoProfesor ?? '');
    _emailController = TextEditingController(text: widget.profesor?.correoElectronico ?? '');
    _especialidadController = TextEditingController(text: widget.profesor?.especialidad ?? '');
    _gradoController = TextEditingController(text: widget.profesor?.gradoAcademico ?? '');
    _activo = widget.profesor?.activo ?? true;
  }
  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _emailController.dispose();
    _especialidadController.dispose();
    _gradoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.profesor != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Profesor' : 'Nuevo Profesor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código de Profesor *', border: OutlineInputBorder()),
                validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo *', border: OutlineInputBorder()),
                validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Campo requerido';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value!)) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de contraseña (opcional en edición, requerido en creación)
              TextFormField(
                controller: _contrasenaController,
                decoration: InputDecoration(
                  labelText: widget.profesor == null ? 'Contraseña *' : 'Contraseña (dejar en blanco para no cambiar)',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (widget.profesor == null && (value == null || value.trim().isEmpty)) {
                    return 'Ingrese una contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especialidadController,
                decoration: const InputDecoration(labelText: 'Especialidad', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradoController,
                decoration: const InputDecoration(labelText: 'Grado académico', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text('Activo'),
                contentPadding: EdgeInsets.zero,
              ),
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
          onPressed: _guardarProfesor,
          child: Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
  Future<void> _guardarProfesor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    final usuario = widget.profesor?.usuario ?? ModeloUsuario(
      id: 0,
      codigoUsuario: _codigoController.text.trim(),
      nombreCompleto: _nombreController.text.trim(),
      correoElectronico: _emailController.text.trim(),
      rol: 'profesor',
      activo: _activo,
      fechaCreacion: now,
    );
    final profesor = ProfesorAdmin(
      id: widget.profesor?.id ?? '',
      usuario: usuario.copyWith(
        codigoUsuario: _codigoController.text.trim(),
        nombreCompleto: _nombreController.text.trim(),
        correoElectronico: _emailController.text.trim(),
        activo: _activo,
      ),
      especialidad: _especialidadController.text.trim().isEmpty ? null : _especialidadController.text.trim(),
      gradoAcademico: _gradoController.text.trim().isEmpty ? null : _gradoController.text.trim(),
      fechaCreacion: widget.profesor?.fechaCreacion ?? now,
      fechaActualizacion: now,
    );
    final notifier = ref.read(profesoresProvider.notifier);
    final creando = widget.profesor == null;
    final success = creando
        ? await notifier.crearProfesor(profesor)
        : await notifier.actualizarProfesor(profesor.id, profesor);
    if (!mounted) {
      return;
    }
    // Si es creación o si se envió nueva contraseña, sincronizar en BD usuarios/profesores
    final nuevaClave = _contrasenaController.text.trim();
    if (nuevaClave.isNotEmpty) {
      try {
        await ProfesorRepository().actualizarContrasenaPorCodigo(
          codigoProfesor: _codigoController.text.trim(),
          nuevaContrasena: nuevaClave,
        );
      } catch (_) {}
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profesor guardado exitosamente' : 'Error al guardar profesor'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
} 

class _DialogoContrasenaProfesor extends ConsumerStatefulWidget {
  const _DialogoContrasenaProfesor({required this.profesor});
  final ProfesorAdmin profesor;
  @override
  ConsumerState<_DialogoContrasenaProfesor> createState() => _DialogoContrasenaProfesorState();
}

class _DialogoContrasenaProfesorState extends ConsumerState<_DialogoContrasenaProfesor> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contrasenaController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _contrasenaController,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese una contraseña' : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ProfesorRepository().actualizarContrasena(
        profesorId: int.tryParse(widget.profesor.id) ?? 0,
        nuevaContrasena: _contrasenaController.text.trim(),
        usuarioId: widget.profesor.usuario.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}