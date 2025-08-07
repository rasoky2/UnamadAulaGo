import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/providers/admin/estudiantes.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Pantalla principal que retorna directamente el contenido
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
    final state = ref.watch(estudiantesAdminProvider);

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
    final breakpoints = ResponsiveBreakpoints.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
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
      child: _construirHeaderResponsive(breakpoints, screenWidth),
    );
  }

  Widget _construirHeaderResponsive(ResponsiveBreakpointsData breakpoints, double screenWidth) {
    if (breakpoints.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Estudiantes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoEstudiante(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Estudiante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => ref.read(estudiantesAdminProvider.notifier).cargarEstudiantes(refrescar: true),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
              ),
            ],
          ),
        ],
      );
    } else if (breakpoints.isTablet || screenWidth < 1000) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gestión de Estudiantes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ref.read(estudiantesAdminProvider.notifier).cargarEstudiantes(refrescar: true),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarDialogoEstudiante(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Estudiante'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          // Título
          const Text(
            'Gestión de Estudiantes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // Botón refrescar
          IconButton(
            onPressed: () => ref.read(estudiantesAdminProvider.notifier).cargarEstudiantes(refrescar: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          
          const SizedBox(width: 8),
          
          // Botón nuevo estudiante
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoEstudiante(context),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Estudiante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
  }

  Widget _construirFiltros() {
    final state = ref.watch(estudiantesAdminProvider);
    final breakpoints = ResponsiveBreakpoints.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

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
          
          if (breakpoints.isMobile) ...[
            // Vista móvil - filtros apilados
            Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar estudiantes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref.read(estudiantesAdminProvider.notifier).aplicarFiltroTexto(value);
                  },
                ),
                
                const SizedBox(height: 12),
                
                DropdownButtonFormField<FiltroEstadoEstudiante>(
                  initialValue: state.filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: FiltroEstadoEstudiante.values.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(_obtenerTextoEstado(estado)),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      ref.read(estudiantesAdminProvider.notifier).aplicarFiltroEstado(valor);
                    }
                  },
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(estudiantesAdminProvider.notifier).limpiarFiltros();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ] else if (breakpoints.isTablet || screenWidth < 1000) ...[
            // Vista tablet - filtros en 2 columnas
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar estudiantes...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          ref.read(estudiantesAdminProvider.notifier).aplicarFiltroTexto(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<FiltroEstadoEstudiante>(
                        initialValue: state.filtroEstado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: FiltroEstadoEstudiante.values.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(_obtenerTextoEstado(estado)),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            ref.read(estudiantesAdminProvider.notifier).aplicarFiltroEstado(valor);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(estudiantesAdminProvider.notifier).limpiarFiltros();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Vista desktop - filtros en línea
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
                      labelText: 'Buscar estudiantes...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(estudiantesAdminProvider.notifier).aplicarFiltroTexto(value);
                    },
                  ),
                ),
                
                // Filtro por estado
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<FiltroEstadoEstudiante>(
                    initialValue: state.filtroEstado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: FiltroEstadoEstudiante.values.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(_obtenerTextoEstado(estado)),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      if (valor != null) {
                        ref.read(estudiantesAdminProvider.notifier).aplicarFiltroEstado(valor);
                      }
                    },
                  ),
                ),
                
                // Botón limpiar filtros
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(estudiantesAdminProvider.notifier).limpiarFiltros();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirContenido(EstudiantesAdminData state) {
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
              onPressed: () => ref.read(estudiantesAdminProvider.notifier).cargarEstudiantes(refrescar: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.estudiantes.isEmpty) {
      return _construirEstadoVacio();
    }

    return _construirListaEstudiantes(state.estudiantes);
  }

  Widget _construirEstadoVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppConstants.textTertiary),
          SizedBox(height: 16),
          Text(
            'No se encontraron estudiantes',
            style: TextStyle(
              fontSize: 18,
              color: AppConstants.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajusta los filtros o crea el primer estudiante',
            style: TextStyle(
              color: AppConstants.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaEstudiantes(List<EstudianteAdmin> estudiantes) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(estudiantesAdminProvider.notifier).cargarEstudiantes(refrescar: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: estudiantes.length,
        itemBuilder: (context, index) {
          final estudiante = estudiantes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _construirCardEstudiante(estudiante),
          );
        },
      ),
    );
  }

  Widget _construirCardEstudiante(EstudianteAdmin estudiante) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de estado
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: estudiante.activo 
                        ? AppConstants.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: estudiante.activo 
                        ? AppConstants.primaryColor 
                        : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estudiante.activo 
                        ? Colors.green 
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estudiante.activo ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    estudiante.codigoEstudiante,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (estudiante.carreraNombre != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      estudiante.carreraNombre!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          estudiante.correoElectronico ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (estudiante.telefono != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estudiante.telefono!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Botones de acción
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: AppConstants.primaryColor,
                  ),
                  tooltip: 'Ver detalles',
                  onPressed: () => _mostrarDetallesEstudiante(context, estudiante),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  tooltip: 'Editar',
                  onPressed: () => _mostrarDialogoEstudiante(context, estudiante),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: Icon(
                    estudiante.activo ? Icons.toggle_on : Icons.toggle_off,
                    color: estudiante.activo ? Colors.green : Colors.red,
                  ),
                  tooltip: estudiante.activo ? 'Desactivar' : 'Activar',
                  onPressed: () => _confirmarCambioEstado(context, estudiante),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  tooltip: 'Eliminar',
                  onPressed: () => _confirmarEliminar(context, estudiante),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }





  String _obtenerTextoEstado(FiltroEstadoEstudiante estado) {
    switch (estado) {
      case FiltroEstadoEstudiante.todos:
        return 'Todos';
      case FiltroEstadoEstudiante.activos:
        return 'Activos';
      case FiltroEstadoEstudiante.inactivos:
        return 'Inactivos';
    }
  }

  void _mostrarDialogoEstudiante(BuildContext context, [EstudianteAdmin? estudiante]) {
    showDialog(
      context: context,
      builder: (context) => _DialogoEstudiante(estudiante: estudiante),
    );
  }

  void _mostrarDetallesEstudiante(BuildContext context, EstudianteAdmin estudiante) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${estudiante.nombreCompleto}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetalleItem(
                icon: Icons.badge,
                label: 'Código',
                value: estudiante.codigoEstudiante,
              ),
              const SizedBox(height: 12),
              _DetalleItem(
                icon: Icons.person,
                label: 'Nombre',
                value: estudiante.nombreCompleto,
              ),
              if (estudiante.carreraNombre != null) ...[
                const SizedBox(height: 12),
                _DetalleItem(
                  icon: Icons.school,
                  label: 'Carrera',
                  value: estudiante.carreraNombre!,
                ),
              ],
              const SizedBox(height: 12),
              _DetalleItem(
                icon: Icons.email,
                label: 'Email',
                value: estudiante.correoElectronico ?? 'N/A',
              ),
              if (estudiante.telefono != null) ...[
                const SizedBox(height: 12),
                _DetalleItem(
                  icon: Icons.phone,
                  label: 'Teléfono',
                  value: estudiante.telefono!,
                ),
              ],
              const SizedBox(height: 12),
              _DetalleItem(
                icon: Icons.circle,
                label: 'Estado',
                value: estudiante.activo ? 'Activo' : 'Inactivo',
                color: estudiante.activo ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCambioEstado(BuildContext context, EstudianteAdmin estudiante) {
    final nuevoEstado = !estudiante.activo;
    final accion = nuevoEstado ? 'activar' : 'desactivar';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirmar $accion'),
        content: Text(
          '¿Estás seguro de que deseas $accion al estudiante '
          '${estudiante.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(estudiantesAdminProvider.notifier)
                  .cambiarEstadoEstudiante(estudiante.id, activo: nuevoEstado);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Estudiante ${nuevoEstado ? 'activado' : 'desactivado'} exitosamente'
                          : 'Error al cambiar estado del estudiante',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
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

  void _confirmarEliminar(BuildContext context, EstudianteAdmin estudiante) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar al estudiante '
          '${estudiante.nombreCompleto}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref
                  .read(estudiantesAdminProvider.notifier)
                  .eliminarEstudiante(estudiante.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Estudiante eliminado exitosamente'
                          : 'Error al eliminar estudiante',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
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

// Diálogo para crear/editar estudiante
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
  late final TextEditingController _nombresController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _codigoController;
  late final TextEditingController _semestreController;
  
  String? _carreraSeleccionada;
  
  @override
  void initState() {
    super.initState();
    
    // Separar nombre completo en nombres y apellidos si existe el estudiante
    String nombres = '';
    String apellidos = '';
    
    if (widget.estudiante != null) {
      final nombresSeparados = widget.estudiante!.nombreCompleto.split(' ');
      if (nombresSeparados.isNotEmpty) {
        nombres = nombresSeparados.first;
        if (nombresSeparados.length > 1) {
          apellidos = nombresSeparados.skip(1).join(' ');
        }
      }
      _carreraSeleccionada = widget.estudiante!.carreraId;
    }
    
    _nombresController = TextEditingController(text: nombres);
    _apellidosController = TextEditingController(text: apellidos);
    _emailController = TextEditingController(text: widget.estudiante?.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: widget.estudiante?.telefono ?? '');
    _codigoController = TextEditingController(text: widget.estudiante?.codigoEstudiante ?? '');
    _semestreController = TextEditingController(text: widget.estudiante?.semestreActual?.toString() ?? '1');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _codigoController.dispose();
    _semestreController.dispose();
    super.dispose();
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
                TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de Estudiante *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombresController,
                decoration: const InputDecoration(
                  labelText: 'Nombres *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Campo requerido';
                  }
                  return null;
                },
                ),
                const SizedBox(height: 16),
                TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Campo requerido';
                  }
                  return null;
                },
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
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Dropdown para seleccionar carrera
              Consumer(
                builder: (context, ref, child) {
                  final carreras = ref.watch(carrerasDisponiblesProvider);
                  
                  return carreras.when(
                    data: (listaCarreras) => DropdownButtonFormField<String>(
                      initialValue: _carreraSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Carrera *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          child: Text('Seleccionar carrera'),
                        ),
                        ...listaCarreras.map((carrera) => DropdownMenuItem<String>(
                          value: carrera.id,
                          child: Text(carrera.nombre),
                        )),
                      ],
                      onChanged: (valor) {
                        setState(() {
                          _carreraSeleccionada = valor;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Debe seleccionar una carrera';
                        }
                        return null;
                      },
                    ),
                    loading: () => DropdownButtonFormField<String>(
                      items: const [],
                      onChanged: null,
                      decoration: const InputDecoration(
                        labelText: 'Cargando carreras...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    error: (error, stack) => DropdownButtonFormField<String>(
                      items: const [],
                      onChanged: null,
                      decoration: const InputDecoration(
                        labelText: 'Error al cargar carreras',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Campo para semestre actual
              TextFormField(
                controller: _semestreController,
                decoration: const InputDecoration(
                  labelText: 'Semestre Actual *',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Campo requerido';
                  }
                  final semestre = int.tryParse(value!);
                  if (semestre == null || semestre < 1 || semestre > 20) {
                    return 'Debe ser entre 1 y 20';
                  }
                  return null;
                },
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

    final formulario = FormularioEstudiante(
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
      codigoEstudiante: _codigoController.text.trim(),
      carreraId: _carreraSeleccionada,
      semestreActual: _semestreController.text.trim(),
    );

    final notifier = ref.read(estudiantesAdminProvider.notifier);
    final success = widget.estudiante != null
        ? await notifier.actualizarEstudiante(widget.estudiante!.id, formulario)
        : await notifier.crearEstudiante(formulario);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${widget.estudiante != null ? 'Estudiante actualizado' : 'Estudiante creado'} exitosamente'
                : 'Error al ${widget.estudiante != null ? 'actualizar' : 'crear'} estudiante',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}



// Widget para mostrar detalles en el diálogo
class _DetalleItem extends StatelessWidget {

  const _DetalleItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? AppConstants.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icon', icon))
    ..add(StringProperty('label', label))
    ..add(StringProperty('value', value))
    ..add(ColorProperty('color', color));
  }
}