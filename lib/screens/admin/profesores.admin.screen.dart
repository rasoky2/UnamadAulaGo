import 'package:aulago/models/profesor_admin.model.dart';
import 'package:aulago/providers/admin/profesores.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla principal que retorna directamente el contenido
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
    final state = ref.watch(profesoresAdminProvider);

    return Column(
      children: [
        // Header y controles
        _construirHeader(),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Filtros
        _construirFiltros(),
        
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
            'Gestión de Profesores',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // Botón refrescar
          IconButton(
            onPressed: () => ref.read(profesoresAdminProvider.notifier).cargarProfesores(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          
          const SizedBox(width: 8),
          
          // Botón nuevo profesor
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoProfesor(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Profesor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    final state = ref.watch(profesoresAdminProvider);
    
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
                    labelText: 'Buscar profesores...',
                    prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    isDense: true,
                    ),
                    onChanged: (value) {
                    ref.read(profesoresAdminProvider.notifier).aplicarFiltroTexto(value);
                    },
                  ),
                ),
              
              // Filtro por estado
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<bool?>(
                  initialValue: state.filtroActivo,
                      decoration: const InputDecoration(
                    labelText: 'Estado',
                        border: OutlineInputBorder(),
                    isDense: true,
                      ),
                  items: const [
                    DropdownMenuItem<bool?>(
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Activos'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Inactivos'),
                    ),
                      ],
                  onChanged: (valor) {
                    ref.read(profesoresAdminProvider.notifier).aplicarFiltroActivo(activo: valor);
                  },
                ),
              ),
              
              // Botón limpiar filtros
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(profesoresAdminProvider.notifier).aplicarFiltroTexto('');
                  ref.read(profesoresAdminProvider.notifier).aplicarFiltroActivo();
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

  Widget _construirContenido(ProfesoresAdminState state) {
    if (state.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: AppConstants.errorColor),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: AppConstants.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(profesoresAdminProvider.notifier).cargarProfesores(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.profesores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: AppConstants.textTertiary),
            SizedBox(height: 16),
            Text(
              'No se encontraron profesores',
              style: TextStyle(
                fontSize: 18,
                color: AppConstants.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajusta los filtros o crea el primer profesor',
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
      child: Column(
        children: [
          // Tabla de profesores
          Expanded(
            child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _construirTablaProfesores(state.profesores),
              ),
            ),
          ),
          
          // Paginación
          if (state.totalPaginas > 1) _construirPaginacion(state),
        ],
      ),
    );
  }

  Widget _construirTablaProfesores(List<ProfesorAdmin> profesores) {
    final activos = profesores.where((p) => p.visibleActivo).toList();
    final inactivos = profesores.where((p) => !p.visibleActivo).toList();
    final List<DataRow> rows = [];
    if (activos.isNotEmpty) {
      rows.add(
        DataRow(
          cells: [
            const DataCell(
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Profesores Activos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              ),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
          ],
        ),
      );
      rows.addAll(activos.map(_dataRowProfesor));
    }
    if (inactivos.isNotEmpty) {
      rows.add(
        DataRow(
          cells: [
            const DataCell(
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Profesores Inactivos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              ),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
            DataCell(Container()),
          ],
        ),
      );
      rows.addAll(inactivos.map(_dataRowProfesor));
    }
    return DataTable(
      columns: const [
        DataColumn(label: Text('Código')),
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Teléfono')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: rows,
    );
  }

  DataRow _dataRowProfesor(ProfesorAdmin profesor) {
    return DataRow(
      cells: [
        DataCell(Text(profesor.codigoProfesor)),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profesor.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (profesor.especialidad != null)
                Text(
                  profesor.especialidad!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text(profesor.correoElectronico ?? 'N/A')),
        const DataCell(Text('N/A')),
        DataCell(_construirChipEstado(profesor.visibleActivo)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _mostrarDialogoProfesor(context, profesor),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Editar',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmarCambioEstado(context, profesor),
                icon: Icon(
                  profesor.visibleActivo ? Icons.toggle_on : Icons.toggle_off,
                  size: 20,
                  color: profesor.visibleActivo ? Colors.green : Colors.red,
                ),
                tooltip: profesor.visibleActivo ? 'Desactivar' : 'Activar',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _confirmarEliminar(context, profesor),
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
  }

  Widget _construirChipEstado(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        activo ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          color: activo ? Colors.green[800] : Colors.red[800],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _construirPaginacion(ProfesoresAdminState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.borderRadius),
          bottomRight: Radius.circular(AppConstants.borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${state.profesores.length} de ${state.totalProfesores} profesores',
            style: const TextStyle(color: AppConstants.textSecondary),
          ),
          Row(
      children: [
        IconButton(
                onPressed: state.pagina > 1
                    ? () => ref.read(profesoresAdminProvider.notifier).cambiarPagina(state.pagina - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
              Text('${state.pagina} de ${state.totalPaginas}'),
        IconButton(
                onPressed: state.pagina < state.totalPaginas
                    ? () => ref.read(profesoresAdminProvider.notifier).cambiarPagina(state.pagina + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
          ),
        ],
      ),
    );
  }


  void _mostrarDialogoProfesor(BuildContext context, [ProfesorAdmin? profesor]) {
    showDialog(
      context: context,
      builder: (context) => _DialogoProfesor(profesor: profesor),
    );
  }

  void _confirmarCambioEstado(BuildContext context, ProfesorAdmin profesor) {
    final nuevoEstado = !profesor.visibleActivo;
    final accion = nuevoEstado ? 'activar' : 'desactivar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar $accion'),
        content: Text(
          '¿Estás seguro de que deseas $accion al profesor ${profesor.nombreCompleto}?',
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
                await ref.read(profesoresAdminProvider.notifier).cambiarEstadoProfesor(profesor.id, activo: nuevoEstado);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profesor ${nuevoEstado ? 'activado' : 'desactivado'} exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cambiar estado del profesor: $e'),
                      backgroundColor: Colors.red,
                    ),
                );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado ? Colors.green : Colors.red,
            ),
            child: Text(accion.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, ProfesorAdmin profesor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al profesor ${profesor.nombreCompleto}?\n\n'
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
                await ref.read(profesoresAdminProvider.notifier).eliminarProfesor(profesor.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profesor eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar profesor: $e'),
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

// Diálogo para crear/editar profesor
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
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _codigoController;
  late final TextEditingController _especialidadController;
  late final TextEditingController _passwordController;
  late bool _esActivo;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.profesor?.usuario.nombreCompleto ?? '');
    _apellidosController = TextEditingController(text: ''); // Campo no disponible en el modelo
    _emailController = TextEditingController(text: widget.profesor?.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: ''); // Campo no disponible en el modelo
    _codigoController = TextEditingController(text: widget.profesor?.codigoProfesor ?? '');
    _especialidadController = TextEditingController(text: widget.profesor?.especialidad ?? '');
    _passwordController = TextEditingController(text: ''); // Contraseña siempre vacía para seguridad
    _esActivo = (widget.profesor?.estado ?? 'activo') == 'activo';
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _codigoController.dispose();
    _especialidadController.dispose();
    _passwordController.dispose();
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
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Profesor *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              // Campo de contraseña - solo requerido para crear nuevos profesores
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.profesor != null ? 'Contraseña (dejar vacío para no cambiar)' : 'Contraseña *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_passwordController.text.isEmpty ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        // Aquí podrías implementar la lógica para mostrar/ocultar contraseña
                      });
                    },
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  // Solo requerido para crear nuevos profesores
                  if (widget.profesor == null && (value?.isEmpty == true)) {
                    return 'Campo requerido';
                  }
                  // Para edición, si se ingresa contraseña debe tener al menos 6 caracteres
                  if (widget.profesor != null && value != null && value.isNotEmpty && value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
              ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _especialidadController,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    border: OutlineInputBorder(),
                  ),
              ),
              const SizedBox(height: 16),
              // Switch de estado activo/inactivo
              Row(
                children: [
                  const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Switch(
                    value: _esActivo,
                    onChanged: (valor) {
                      setState(() {
                        _esActivo = valor;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(_esActivo ? 'Activo' : 'Inactivo', style: TextStyle(color: _esActivo ? Colors.green : Colors.red)),
                ],
              ),
              const SizedBox(height: 16),
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

    final datos = {
      'nombre_completo': _nombresController.text.trim(),
      'correo_electronico': _emailController.text.trim(),
      'codigo_profesor': _codigoController.text.trim(),
      'especialidad': _especialidadController.text.trim().isEmpty ? null : _especialidadController.text.trim(),
      'estado': _esActivo ? 'activo' : 'inactivo',
    };

    // Agregar contraseña solo si no está vacía
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) {
      datos['contrasena_hash'] = password; // En un proyecto real aquí harías hash de la contraseña
    }

    try {
      final notifier = ref.read(profesoresAdminProvider.notifier);
      if (widget.profesor != null) {
        await notifier.editarProfesor(widget.profesor!.id, datos);
      } else {
        await notifier.crearProfesor(datos);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.profesor != null ? 'Profesor actualizado' : 'Profesor creado'} exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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