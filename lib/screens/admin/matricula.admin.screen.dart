import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/providers/admin/matricula.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla principal que retorna directamente el contenido
class PantallaMatriculasAdmin extends ConsumerStatefulWidget {
  const PantallaMatriculasAdmin({super.key});

  @override
  ConsumerState<PantallaMatriculasAdmin> createState() => _PantallaMatriculasAdminState();
}

class _PantallaMatriculasAdminState extends ConsumerState<PantallaMatriculasAdmin> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matriculasAdminProvider);

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
            'Gestión de Matrículas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // Botón refrescar
          IconButton(
            onPressed: () => ref.read(matriculasAdminProvider.notifier).cargarMatriculas(refrescar: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
          ),
          
          const SizedBox(width: 8),
          
          // Botón nueva matrícula
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoMatricula(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Matrícula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón matricular estudiante (nuevo enfoque)
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoMatricularEstudiante(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Matricular Estudiante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    final state = ref.watch(matriculasAdminProvider);

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
                    labelText: 'Buscar por estudiante o curso...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref.read(matriculasAdminProvider.notifier).aplicarFiltroTexto(value);
                  },
                ),
              ),
              
              // Filtro por estado
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<FiltroEstadoMatricula>(
                  initialValue: state.filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: FiltroEstadoMatricula.values.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(_obtenerTextoEstado(estado)),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      ref.read(matriculasAdminProvider.notifier).aplicarFiltroEstado(valor);
                    }
                  },
                ),
              ),
              
              // Botón limpiar filtros
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(matriculasAdminProvider.notifier).limpiarFiltros();
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

  Widget _construirContenido(MatriculasAdminData state) {
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
              onPressed: () => ref.read(matriculasAdminProvider.notifier).cargarMatriculas(refrescar: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.matriculas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, size: 64, color: AppConstants.textTertiary),
            SizedBox(height: 16),
            Text(
              'No se encontraron matrículas',
              style: TextStyle(
                fontSize: 18,
              color: AppConstants.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajusta los filtros o crea la primera matrícula',
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
          // Tabla de matrículas
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _construirTablaMatriculas(state.matriculas),
              ),
            ),
          ),
          
          // Paginación
          if (state.totalPaginas > 1) _construirPaginacion(state),
        ],
      ),
    );
  }

  Widget _construirTablaMatriculas(List<ModeloMatricula> matriculas) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Estudiante')),
        DataColumn(label: Text('Curso')),
        DataColumn(label: Text('Grupo')),
        DataColumn(label: Text('Profesor')),
        DataColumn(label: Text('Período')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Fecha')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: matriculas.map((matricula) {
        return DataRow(
          cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    matricula.estudianteNombre ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (matricula.estudianteCodigo != null)
                    Text(
                      matricula.estudianteCodigo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    matricula.cursoNombre ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (matricula.cursoCodigo != null)
                    Text(
                      matricula.cursoCodigo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            DataCell(Text(matricula.cursoNombre ?? 'N/A')),
            DataCell(Text(matricula.profesorNombre ?? 'N/A')),
            DataCell(Text(matricula.periodoNombre ?? 'N/A')),
            DataCell(_construirChipEstado(matricula.estado)),
            DataCell(Text(
              matricula.fechaMatricula != null 
                ? '${matricula.fechaMatricula!.day}/${matricula.fechaMatricula!.month}/${matricula.fechaMatricula!.year}'
                : 'N/A'
            )),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón cambiar estado
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Cambiar estado',
                    onSelected: (estado) => _cambiarEstado(matricula, estado),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'matriculado',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text('Matriculado'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'retirado',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Text('Retirado'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'transferido',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Text('Transferido'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Botón eliminar
                  IconButton(
                    onPressed: () => _confirmarEliminar(context, matricula),
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

  Widget _construirChipEstado(String estado) {
    Color color;
    switch (estado.toLowerCase()) {
      case 'matriculado':
        color = Colors.green;
        break;
      case 'retirado':
        color = Colors.orange;
        break;
      case 'transferido':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

         return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: color.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: color.withValues(alpha: 0.3)),
       ),
       child: Text(
         estado.toUpperCase(),
         style: TextStyle(
           color: color,
           fontSize: 12,
           fontWeight: FontWeight.w500,
         ),
       ),
     );
  }

  Widget _construirPaginacion(MatriculasAdminData state) {
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
            'Mostrando ${state.matriculas.length} de ${state.totalMatriculas} matrículas',
            style: const TextStyle(color: AppConstants.textSecondary),
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.pagina > 1
                    ? () => ref.read(matriculasAdminProvider.notifier).cambiarPagina(state.pagina - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${state.pagina} de ${state.totalPaginas}'),
              IconButton(
                onPressed: state.pagina < state.totalPaginas
                    ? () => ref.read(matriculasAdminProvider.notifier).cambiarPagina(state.pagina + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _obtenerTextoEstado(FiltroEstadoMatricula estado) {
    switch (estado) {
      case FiltroEstadoMatricula.todos:
        return 'Todos';
      case FiltroEstadoMatricula.matriculado:
        return 'Matriculados';
      case FiltroEstadoMatricula.retirado:
        return 'Retirados';
      case FiltroEstadoMatricula.transferido:
        return 'Transferidos';
    }
  }

  void _mostrarDialogoMatricula(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _DialogoMatricula(),
    );
  }

  void _mostrarDialogoMatricularEstudiante(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _DialogoMatricularEstudiante(),
    );
  }

  Future<void> _cambiarEstado(ModeloMatricula matricula, String nuevoEstado) async {
    final success = await ref
        .read(matriculasAdminProvider.notifier)
        .cambiarEstadoMatricula(matricula.id, nuevoEstado);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Estado cambiado a $nuevoEstado exitosamente'
                : 'Error al cambiar estado',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmarEliminar(BuildContext context, ModeloMatricula matricula) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la matrícula de '
          '${matricula.estudianteNombre} en ${matricula.cursoNombre}?\n\n'
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
              final success = await ref
                  .read(matriculasAdminProvider.notifier)
                  .eliminarMatricula(matricula.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Matrícula eliminada exitosamente'
                          : 'Error al eliminar matrícula',
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

// Diálogo para crear nueva matrícula
class _DialogoMatricula extends ConsumerStatefulWidget {
  const _DialogoMatricula();

  @override
  ConsumerState<_DialogoMatricula> createState() => _DialogoMatriculaState();


}

class _DialogoMatriculaState extends ConsumerState<_DialogoMatricula> {
  final _formKey = GlobalKey<FormState>();
  String? _estudianteSeleccionado;
  String? _cursoSeleccionado;
  String? _periodoSeleccionado;

  @override
  Widget build(BuildContext context) {
    final estudiantes = ref.watch(estudiantesDisponiblesProvider);
    final cursos = ref.watch(cursosParaMatriculacionProvider(const MatriculaFiltros()));
    final periodos = ref.watch(periodosAcademicosProvider);

    return AlertDialog(
      title: const Text('Nueva Matrícula'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de estudiante
              estudiantes.when(
                data: (data) => DropdownButtonFormField<String>(
                  initialValue: _estudianteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estudiante *',
                    border: OutlineInputBorder(),
                  ),
                                     items: data.map<DropdownMenuItem<String>>((estudiante) {
                     return DropdownMenuItem<String>(
                       value: estudiante['id'],
                       child: Text('${estudiante['nombre_completo']} (${estudiante['codigo_estudiante']})'),
                     );
                   }).toList(),
                  onChanged: (value) => setState(() => _estudianteSeleccionado = value),
                  validator: (value) => value == null ? 'Selecciona un estudiante' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar estudiantes'),
              ),
              
              const SizedBox(height: 16),
              
              // Selector de curso
              cursos.when(
                data: (data) => DropdownButtonFormField<String>(
                  initialValue: _cursoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Curso *',
                    border: OutlineInputBorder(),
                  ),
                                     items: data.map<DropdownMenuItem<String>>((curso) {
                     return DropdownMenuItem<String>(
                       value: curso.id,
                       child: Text('${curso.nombre} - ${curso.codigoCurso}'),
                     );
                   }).toList(),
                  onChanged: (value) => setState(() => _cursoSeleccionado = value),
                    validator: (value) => value == null ? 'Selecciona un curso' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar cursos'),
              ),
              
              const SizedBox(height: 16),
              
              // Selector de período académico
              periodos.when(
                data: (data) => DropdownButtonFormField<String>(
                  initialValue: _periodoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Período Académico *',
                    border: OutlineInputBorder(),
                  ),
                                     items: data.map<DropdownMenuItem<String>>((periodo) {
                     return DropdownMenuItem<String>(
                       value: periodo['id'],
                       child: Text(periodo['nombre']),
                     );
                   }).toList(),
                  onChanged: (value) => setState(() => _periodoSeleccionado = value),
                  validator: (value) => value == null ? 'Selecciona un período académico' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar períodos académicos'),
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
          onPressed: _crearMatricula,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _crearMatricula() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formulario = FormularioMatricula(
      estudianteId: _estudianteSeleccionado!,
      cursoId: _cursoSeleccionado!,
      periodoAcademicoId: _periodoSeleccionado!,
    );

    final notifier = ref.read(matriculasAdminProvider.notifier);
    final success = await notifier.crearMatricula(formulario);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Matrícula creada exitosamente'
                : 'Error al crear matrícula',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

// Diálogo para matricular estudiante (nuevo enfoque)
class _DialogoMatricularEstudiante extends ConsumerStatefulWidget {
  const _DialogoMatricularEstudiante();

  @override
  ConsumerState<_DialogoMatricularEstudiante> createState() => _DialogoMatricularEstudianteState();
}

class _DialogoMatricularEstudianteState extends ConsumerState<_DialogoMatricularEstudiante> {
  final _formKey = GlobalKey<FormState>();
  String? _estudianteSeleccionado;
  String? _periodoSeleccionado;
  final Set<String> _cursosSeleccionados = {};
  final Map<String, String> _gruposSeleccionados = {}; // cursoId -> grupoId

  @override
  Widget build(BuildContext context) {
    final estudiantes = ref.watch(estudiantesDisponiblesProvider);
    final periodos = ref.watch(periodosAcademicosProvider);
    
    // Solo cargar cursos si hay estudiante y período seleccionado
    final cursosDisponibles = (_estudianteSeleccionado != null && _periodoSeleccionado != null)
        ? ref.watch(cursosDisponiblesEstudianteProvider(CursosEstudianteFiltros(
            estudianteId: _estudianteSeleccionado,
            periodoAcademicoId: _periodoSeleccionado,
          )))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);

    return AlertDialog(
      title: const Text('Matricular Estudiante'),
      content: SizedBox(
        width: 700,
        height: 600,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de estudiante
              estudiantes.when(
                data: (data) => DropdownButtonFormField<String>(
                  initialValue: _estudianteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Estudiante *',
                    border: OutlineInputBorder(),
                  ),
                  items: data.map<DropdownMenuItem<String>>((estudiante) {
                    return DropdownMenuItem<String>(
                      value: estudiante['id'],
                      child: Text('${estudiante['nombre_completo']} (${estudiante['codigo_estudiante']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _estudianteSeleccionado = value;
                      _cursosSeleccionados.clear();
                      _gruposSeleccionados.clear();
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona un estudiante' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar estudiantes'),
              ),
              
              const SizedBox(height: 16),
              
              // Selector de período académico
              periodos.when(
                data: (data) => DropdownButtonFormField<String>(
                  initialValue: _periodoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Período Académico *',
                    border: OutlineInputBorder(),
                  ),
                  items: data.map<DropdownMenuItem<String>>((periodo) {
                    return DropdownMenuItem<String>(
                      value: periodo['id'],
                      child: Text(periodo['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _periodoSeleccionado = value;
                      _cursosSeleccionados.clear();
                      _gruposSeleccionados.clear();
                    });
                  },
                  validator: (value) => value == null ? 'Selecciona un período académico' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error al cargar períodos académicos'),
              ),
              
              const SizedBox(height: 20),
              
              // Lista de cursos disponibles
              if (_estudianteSeleccionado != null && _periodoSeleccionado != null) ...[
                const Text(
                  'Cursos Disponibles:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: cursosDisponibles.when(
                    data: _construirListaCursos,
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      'Selecciona un estudiante y período académico\npara ver los cursos disponibles',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
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
          onPressed: _cursosSeleccionados.isNotEmpty ? _matricularEstudiante : null,
          child: Text('Matricular ${_cursosSeleccionados.length} curso(s)'),
        ),
      ],
    );
  }

  Widget _construirListaCursos(List<Map<String, dynamic>> cursos) {
    if (cursos.isEmpty) {
      return const Center(
        child: Text(
          'No hay cursos disponibles para este estudiante en el período seleccionado',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: cursos.length,
      itemBuilder: (context, index) {
        final curso = cursos[index];
        final cursoId = curso['id'] as String;
        // Solo muestra la información de cursos disponibles para matricular.
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _cursosSeleccionados.contains(cursoId),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _cursosSeleccionados.add(cursoId);
                            _gruposSeleccionados.remove(cursoId);
                          } else {
                            _cursosSeleccionados.remove(cursoId);
                            _gruposSeleccionados.remove(cursoId);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${curso['codigo_curso']} - ${curso['nombre']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${curso['creditos']} créditos • Semestre ${curso['semestre_recomendado'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          if (curso['descripcion'] != null)
                            Text(
                              curso['descripcion'],
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Indicador de tipo de matrícula (ahora siempre directa)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                '📘 Matrícula Directa',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Elimina cualquier widget o condicional relacionado con grupos
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _matricularEstudiante() async {
    if (!_formKey.currentState!.validate() || _cursosSeleccionados.isEmpty) {
      return;
    }

    // Crear matrículas para cada curso seleccionado
    final matriculas = _cursosSeleccionados.map((cursoId) {
// Puede ser null para matrículas directas
      
      return FormularioMatricula(
        estudianteId: _estudianteSeleccionado!,
        cursoId: cursoId,
        periodoAcademicoId: _periodoSeleccionado!,
      );
    }).toList();

    final notifier = ref.read(matriculasAdminProvider.notifier);
    int exitosos = 0;
    int fallidos = 0;
    final List<String> errores = [];

    for (final formulario in matriculas) {
      try {
        final success = await notifier.crearMatricula(formulario);
        if (success) {
          exitosos++;
        } else {
          fallidos++;
          errores.add('Error en matrícula ${formulario.cursoId}');
        }
      } catch (e) {
        fallidos++;
        errores.add('Error: $e');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      
      // Mostrar resultado detallado
      final mensaje = exitosos > 0 
        ? '✅ $exitosos matrícula(s) exitosa(s)${fallidos > 0 ? '\n❌ $fallidos fallida(s)' : ''}'
        : '❌ Todas las matrículas fallaron';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              if (errores.isNotEmpty && errores.length <= 3) 
                ...errores.map((error) => Text('• $error', style: const TextStyle(fontSize: 12))),
            ],
          ),
          backgroundColor: exitosos > 0 ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
