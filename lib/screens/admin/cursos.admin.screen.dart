import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/profesor.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cursosProvider = StateNotifierProvider<_CursosNotifier, List<ModeloCurso>>((ref) {
  return _CursosNotifier();
});

class _CursosNotifier extends StateNotifier<List<ModeloCurso>> {
  _CursosNotifier() : super([]) {
    cargarCursos();
  }
  final _repo = CursoRepository();
  Future<void> cargarCursos() async {
    final lista = await _repo.obtenerTodos();
    state = lista;
  }
  Future<bool> crearCurso(ModeloCurso curso) async {
    try {
      await _repo.crearCurso(curso);
      await cargarCursos();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> actualizarCurso(int id, ModeloCurso curso) async {
    try {
      await _repo.actualizarCurso(id, curso);
      await cargarCursos();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> eliminarCurso(int id) async {
    try {
      await _repo.eliminarCurso(id);
      await cargarCursos();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaCursosAdmin extends ConsumerStatefulWidget {
  const PantallaCursosAdmin({super.key});
  @override
  ConsumerState<PantallaCursosAdmin> createState() => _PantallaCursosAdminState();
}

class _PantallaCursosAdminState extends ConsumerState<PantallaCursosAdmin> {
  final TextEditingController _searchController = TextEditingController();
  final CarreraRepository _carreraRepo = CarreraRepository();
  final ProfesorRepository _profesorRepo = ProfesorRepository();

  Map<int, String> _carreraIdToNombre = {};
  Map<int, String> _profesorIdToNombre = {};

  @override
  void initState() {
    super.initState();
    _cargarAuxiliares();
  }

  Future<void> _cargarAuxiliares() async {
    try {
      final carreras = await _carreraRepo.obtenerCarreras();
      final profesores = await _profesorRepo.obtenerProfesores();
      if (!mounted) {
        return;
      }
      setState(() {
        _carreraIdToNombre = {
          for (final c in carreras) c.id: c.nombre,
        };
        _profesorIdToNombre = {
          for (final p in profesores)
            int.tryParse(p.id) ?? -1: p.nombreCompleto,
        }..removeWhere((key, value) => key == -1);
      });
    } catch (_) {
      // silencioso; la UI seguirá funcionando y mostrará IDs si no cargan
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final cursos = ref.watch(cursosProvider);
    final filtro = _searchController.text.trim().toLowerCase();
    final listaFiltrada = filtro.isEmpty
        ? cursos
        : cursos.where((e) => e.nombre.toLowerCase().contains(filtro) || e.codigoCurso.toLowerCase().contains(filtro)).toList();
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('Gestión de Cursos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(cursosProvider.notifier).cargarCursos(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoCurso(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Curso'),
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
          labelText: 'Buscar cursos...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
  Widget _construirContenido(List<ModeloCurso> cursos) {
    if (cursos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: AppConstants.textTertiary),
            SizedBox(height: 16),
            Text('No se encontraron cursos', style: TextStyle(fontSize: 18, color: AppConstants.textSecondary)),
            SizedBox(height: 8),
            Text('Ajusta la búsqueda o crea el primer curso', style: TextStyle(color: AppConstants.textTertiary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cursos.length,
      itemBuilder: (context, index) {
        final curso = cursos[index];
        final carreraNombre = _carreraIdToNombre[curso.carreraId] ?? '—';
        final profesorNombre = curso.profesorId != null
            ? (_profesorIdToNombre[curso.profesorId!] ?? '—')
            : '—';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.book, color: AppConstants.primaryColor),
            title: Text(curso.nombre),
            subtitle: Text('${curso.codigoCurso} • $carreraNombre • Prof: $profesorNombre'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _mostrarDialogoCurso(context, curso),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminarCurso(context, curso),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _mostrarDialogoCurso(BuildContext context, [ModeloCurso? curso]) {
    showDialog(
      context: context,
      builder: (context) => _DialogoCurso(curso: curso),
    );
  }
  void _confirmarEliminarCurso(BuildContext context, ModeloCurso curso) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el curso "${curso.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(cursosProvider.notifier).eliminarCurso(curso.id);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Curso eliminado exitosamente' : 'Error al eliminar curso'),
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

class _DialogoCurso extends ConsumerStatefulWidget {
  const _DialogoCurso({this.curso});
  final ModeloCurso? curso;
  @override
  ConsumerState<_DialogoCurso> createState() => _DialogoCursoState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCurso?>('curso', curso));
  }
}
class _DialogoCursoState extends ConsumerState<_DialogoCurso> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _creditosController;
  final CarreraRepository _carreraRepo = CarreraRepository();
  final ProfesorRepository _profesorRepo = ProfesorRepository();
  List<ModeloCarrera> _carreras = const [];
  List<ProfesorAdmin> _profesores = const [];
  int? _carreraSeleccionadaId;
  int? _profesorSeleccionadoId;
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.curso?.nombre ?? '');
    _codigoController = TextEditingController(text: widget.curso?.codigoCurso ?? '');
    _descripcionController = TextEditingController(text: widget.curso?.descripcion ?? '');
    _creditosController = TextEditingController(text: widget.curso?.creditos.toString() ?? '');
    _carreraSeleccionadaId = widget.curso?.carreraId;
    _profesorSeleccionadoId = widget.curso?.profesorId;
    _cargarOpciones();
  }
  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _creditosController.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final carreras = await _carreraRepo.obtenerCarreras();
      final profesores = await _profesorRepo.obtenerProfesores();
      if (!mounted) {
        return;
      }
      setState(() {
        _carreras = carreras;
        _profesores = profesores;
      });
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.curso != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Curso' : 'Nuevo Curso'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(labelText: 'Código del Curso *', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del Curso *', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditosController,
                  decoration: const InputDecoration(labelText: 'Créditos *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value?.isEmpty == true) {
                  return 'Campo requerido';
                }
                    final creditos = int.tryParse(value!);
                    if (creditos == null || creditos <= 0) {
                  return 'Debe ser un número mayor a 0';
                }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _profesorSeleccionadoId,
                  decoration: const InputDecoration(labelText: 'Profesor', border: OutlineInputBorder()),
                  items: _profesores
                      .map((p) => DropdownMenuItem<int>(
                            value: int.tryParse(p.id) ?? -1,
                            child: Text(p.nombreCompleto),
                          ))
                      .where((e) => e.value != -1)
                      .toList(),
                  onChanged: (v) => setState(() => _profesorSeleccionadoId = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarCurso,
          child: Text(esEdicion ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
  Future<void> _guardarCurso() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final curso = ModeloCurso(
      id: widget.curso?.id ?? 0,
      codigoCurso: _codigoController.text.trim(),
      nombre: _nombreController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      creditos: int.tryParse(_creditosController.text.trim()) ?? 0,
      carreraId: _carreraSeleccionadaId ?? 0,
      profesorId: _profesorSeleccionadoId,
      fechaCreacion: widget.curso?.fechaCreacion ?? DateTime.now(),
    );
    final notifier = ref.read(cursosProvider.notifier);
    final success = widget.curso != null
        ? await notifier.actualizarCurso(curso.id, curso)
        : await notifier.crearCurso(curso);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Curso guardado exitosamente' : 'Error al guardar curso'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
} 