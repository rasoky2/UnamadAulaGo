import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/admin/cursos.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla principal que retorna directamente el contenido
class PantallaCursosAdmin extends ConsumerStatefulWidget {
  const PantallaCursosAdmin({super.key});

  @override
  ConsumerState<PantallaCursosAdmin> createState() => _PantallaCursosAdminState();
}

class _PantallaCursosAdminState extends ConsumerState<PantallaCursosAdmin> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cursosAdminProvider);

    return Column(
              children: [
        // Header y controles
        _construirHeader(),
        
                const SizedBox(height: AppConstants.defaultPadding),
        
        // Filtros
        _construirFiltros(state),
        
                const SizedBox(height: AppConstants.defaultPadding),
        
        // Contenido principal
                Expanded(
          child: _construirContenido(state),
        ),
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
          // Título
          const Text(
            'Gestión de Cursos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // Botón refrescar
          IconButton(
            onPressed: () => ref.read(cursosAdminProvider.notifier).refrescar(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
        ),
          
          const SizedBox(width: 8),
          
          // Botón nuevo curso
        ElevatedButton.icon(
            onPressed: () => _mostrarDialogoCurso(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Curso'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      ),
    );
  }

  Widget _construirFiltros(CursosAdminState state) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
              ),
            ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          Wrap(
            spacing: 16,
            runSpacing: 12,
              children: [
              // Búsqueda
              SizedBox(
                width: 300,
                  child: TextField(
                  controller: _searchController,
                    decoration: const InputDecoration(
                    labelText: 'Buscar cursos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(cursosAdminProvider.notifier).cambiarBusqueda(value);
                    },
                  ),
                ),
              
              // Filtro por carrera
              SizedBox(
                width: 250,
                child: state.carreras.when(
                    data: (carreras) => DropdownButtonFormField<String>(
                    initialValue: state.filtros.filtroCarreraId,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        border: OutlineInputBorder(),
                      isDense: true,
                      ),
                      items: [
                      const DropdownMenuItem<String>(
                        child: Text('Todas las carreras'),
                      ),
                        ...carreras.map((carrera) => DropdownMenuItem(
                          value: carrera.id,
                        child: Text(carrera.nombre),
                        )),
                      ],
                    onChanged: (valor) {
                      ref.read(cursosAdminProvider.notifier).aplicarFiltroCarrera(valor);
                      },
                    ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                  ),
                ),
              
              // Filtro por profesor
              SizedBox(
                width: 250,
                child: state.profesores.when(
                    data: (profesores) => DropdownButtonFormField<String>(
                    initialValue: state.filtros.filtroProfesorId,
                      decoration: const InputDecoration(
                        labelText: 'Profesor',
                        border: OutlineInputBorder(),
                      isDense: true,
                      ),
                      items: [
                      const DropdownMenuItem<String>(
                        child: Text('Todos los profesores'),
                      ),
                        ...profesores.map((profesor) => DropdownMenuItem(
                          value: profesor.id,
                        child: Text(profesor.nombreCompleto),
                        )),
                      ],
                    onChanged: (valor) {
                      ref.read(cursosAdminProvider.notifier).aplicarFiltroProfesor(valor);
                      },
                    ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                  ),
                ),
              
              // Botón limpiar filtros
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(cursosAdminProvider.notifier).cambiarBusqueda('');
                  ref.read(cursosAdminProvider.notifier).aplicarFiltroCarrera(null);
                  ref.read(cursosAdminProvider.notifier).aplicarFiltroProfesor(null);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(CursosAdminState state) {
    return state.cursos.when(
      data: (cursos) {
        if (cursos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: AppConstants.textTertiary),
                SizedBox(height: 16),
                Text(
                  'No se encontraron cursos',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppConstants.textSecondary,
                  ),
                    ),
                SizedBox(height: 8),
                Text(
                  'Ajusta los filtros o crea el primer curso',
                  style: TextStyle(
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: _construirTablaCursos(cursos, state),
            ),
          ),
        );
      },
                  loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: AppConstants.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: AppConstants.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(cursosAdminProvider.notifier).refrescar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTablaCursos(List<ModeloCurso> cursos, CursosAdminState state) {
    return DataTable(
          columns: const [
            DataColumn(label: Text('Código')),
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Carrera')),
        DataColumn(label: Text('Profesor')),
            DataColumn(label: Text('Créditos')),
            DataColumn(label: Text('Acciones')),
          ],
      rows: cursos.map((curso) {
        // Buscar carrera
        final carrera = state.carreras.asData?.value.where((c) => c.id == curso.carreraId).firstOrNull;
        
        // Buscar profesor  
        final profesor = state.profesores.asData?.value.where((p) => p.id == curso.profesorId).firstOrNull;

    return DataRow(
      cells: [
        DataCell(Text(curso.codigoCurso)),
        DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          Text(
              curso.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (curso.descripcion != null)
                    Text(
                      curso.descripcion!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                      maxLines: 2,
              overflow: TextOverflow.ellipsis,
                    ),
                ],
          ),
        ),
            DataCell(Text(carrera?.nombre ?? 'No asignada')),
            DataCell(Text(profesor?.nombreCompleto ?? 'No asignado')),
        DataCell(Text(curso.creditos.toString())),
        DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () => _mostrarDialogoCurso(context, curso),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Editar',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    ),
                ),
                  const SizedBox(width: 4),
                IconButton(
                    onPressed: () => _confirmarEliminarCurso(context, curso),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Eliminar',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                    ),
                ),
              ],
          ),
        ),
      ],
    );
      }).toList(),
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
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el curso "${curso.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(cursosAdminProvider.notifier).eliminarCurso(curso.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Curso eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar curso: $e'),
                      backgroundColor: Colors.red,
                    ),
                );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Provider para el notifier de cursos
final cursosAdminProvider = StateNotifierProvider<CursosAdminNotifier, CursosAdminState>((ref) {
  return CursosAdminNotifier(
    ref.watch(cursoRepositoryProvider),
    ref.watch(carreraRepositoryProvider),
    ref.watch(profesorRepositoryProvider),
    ref.watch(periodoAcademicoRepositoryProvider),
  );
});

// Diálogo para crear/editar curso
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
  String? _carreraSeleccionada;
  String? _profesorSeleccionado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.curso?.nombre ?? '');
    _codigoController = TextEditingController(text: widget.curso?.codigoCurso ?? '');
    _descripcionController = TextEditingController(text: widget.curso?.descripcion ?? '');
    _creditosController = TextEditingController(text: widget.curso?.creditos.toString() ?? '');
    _carreraSeleccionada = widget.curso?.carreraId;
    _profesorSeleccionado = widget.curso?.profesorId;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _creditosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.curso != null;
    final state = ref.watch(cursosAdminProvider);

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
                  decoration: const InputDecoration(
                    labelText: 'Código del Curso *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
              ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Curso *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditosController,
                  decoration: const InputDecoration(
                    labelText: 'Créditos *',
                    border: OutlineInputBorder(),
                  ),
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
                state.carreras.when(
                  data: (carreras) => DropdownButtonFormField<String>(
                    initialValue: _carreraSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Carrera *',
                      border: OutlineInputBorder(),
                    ),
                    items: carreras.map((carrera) => DropdownMenuItem(
                      value: carrera.id,
                      child: Text(carrera.nombre),
                    )).toList(),
                    onChanged: (valor) => setState(() => _carreraSeleccionada = valor),
                    validator: (value) => value == null ? 'Selecciona una carrera' : null,
                ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error al cargar carreras'),
                ),
                const SizedBox(height: 16),
                state.profesores.when(
                  data: (profesores) => DropdownButtonFormField<String>(
                    initialValue: _profesorSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Profesor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('Sin asignar'),
                      ),
                      ...profesores.map((profesor) => DropdownMenuItem(
                        value: profesor.id,
                        child: Text(profesor.nombreCompleto),
                      )),
                    ],
                    onChanged: (valor) => setState(() => _profesorSeleccionado = valor),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error al cargar profesores'),
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

    final datos = {
      'codigo_curso': _codigoController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      'creditos': int.parse(_creditosController.text.trim()),
      'carrera_id': _carreraSeleccionada,
      'profesor_id': _profesorSeleccionado,
    };

    try {
      final notifier = ref.read(cursosAdminProvider.notifier);
      if (widget.curso != null) {
        await notifier.actualizarCurso(widget.curso!.id, datos);
      } else {
        await notifier.crearCurso(datos);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.curso != null ? 'Curso actualizado' : 'Curso creado'} exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 