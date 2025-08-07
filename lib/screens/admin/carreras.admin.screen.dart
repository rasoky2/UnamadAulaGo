import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/providers/admin/carreras.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla principal que retorna directamente el contenido
class PantallaCarrerasAdmin extends ConsumerWidget {
  const PantallaCarrerasAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(carrerasAdminProvider);

    return Column(
      children: [
        // Barra de controles superior
        _BarraControles(),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Contenido principal
        Expanded(
          child: datos.cargando && datos.carreras.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : datos.error != null && datos.carreras.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar carreras',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            datos.error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(carrerasAdminProvider.notifier).refrescar(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : datos.carreras.isEmpty
                      ? const _VistaVacia()
                      : _ListaCarreras(carreras: datos.carreras),
        ),
        
        // Paginación
        if (datos.totalPaginas > 1)
          _BarraPaginacion(
            paginaActual: datos.pagina,
            totalPaginas: datos.totalPaginas,
            onCambioPagina: (pagina) => ref.read(carrerasAdminProvider.notifier).cambiarPagina(pagina),
          ),
      ],
    );
  }
}

// Barra de controles con filtros y acciones
class _BarraControles extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(carrerasAdminProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: Column(
        children: [
          // Filtros principales en una fila responsive
          Row(
            children: [
              // Buscador
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, código o director...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (valor) => ref.read(carrerasAdminProvider.notifier).aplicarFiltroTexto(valor),
                ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Filtro por facultad
              SizedBox(
                width: 200,
                child: Consumer(
                  builder: (context, ref, child) {
                    final facultades = ref.watch(facultadesDisponiblesProvider);
                    
                    return facultades.when(
                      data: (listaFacultades) {
                        // Verificar si el valor actual está en la lista de facultades disponibles
                        final valorActual = datos.filtroFacultad;
                        final esValorValido = valorActual == null || 
                            listaFacultades.any((facultad) => facultad['id'] == valorActual);
                        
                        return DropdownButtonFormField<String>(
                          initialValue: esValorValido ? valorActual : null,
                          decoration: const InputDecoration(
                            labelText: 'Facultad',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              child: Text('Todas las facultades'),
                            ),
                            ...listaFacultades.map((facultad) => DropdownMenuItem<String>(
                              value: facultad['id'],
                              child: Text(facultad['nombre']),
                            )),
                          ],
                          onChanged: (valor) => ref.read(carrerasAdminProvider.notifier).aplicarFiltroFacultad(valor),
                        );
                      },
                      loading: () => DropdownButtonFormField<String>(
                        items: const [],
                        onChanged: null,
                        decoration: const InputDecoration(
                          labelText: 'Cargando facultades...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      error: (error, stack) => DropdownButtonFormField<String>(
                        items: const [],
                        onChanged: null,
                        decoration: const InputDecoration(
                          labelText: 'Error al cargar facultades',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Botón limpiar filtros
              OutlinedButton.icon(
                onPressed: () => ref.read(carrerasAdminProvider.notifier).limpiarFiltros(),
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Acciones y estadísticas
          Row(
            children: [
              // Estadísticas
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${datos.totalCarreras} carrera${datos.totalCarreras != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (datos.filtroTexto != null || datos.filtroFacultad != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Filtrado',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Botón refrescar
              IconButton(
                onPressed: datos.cargando 
                    ? null 
                    : () => ref.read(carrerasAdminProvider.notifier).refrescar(),
                icon: datos.cargando 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refrescar',
              ),
              
              const SizedBox(width: AppConstants.smallPadding),
              
              // Botón agregar carrera
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
        ],
      ),
    );
  }
}

// Lista de carreras
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

// Tarjeta individual de carrera
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
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Row(
          children: [
            // Icono de carrera
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Icon(
                Icons.school,
                color: Colors.blue.shade600,
                size: 28,
              ),
            ),
            
            const SizedBox(width: AppConstants.defaultPadding),
            
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y código
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          carrera.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Descripción
                  if (carrera.descripcion != null && carrera.descripcion!.isNotEmpty)
                    Text(
                      carrera.descripcion!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Información adicional
                  Row(
                    children: [
                      // Duración
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${carrera.duracionSemestres} semestres',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Director
                      if (carrera.directorNombre != null && carrera.directorNombre!.isNotEmpty) ...[
                        Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            carrera.directorNombre!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
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
            
            // Acciones
            Column(
              children: [
                IconButton(
                  onPressed: () => _mostrarDialogoCarrera(context, ref, carrera: carrera),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar carrera',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                IconButton(
                  onPressed: () => _confirmarEliminar(context, ref, carrera),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar carrera',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                  ),
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

// Vista cuando no hay carreras
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
              child: Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay carreras registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza agregando la primera carrera de tu institución',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
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

// Barra de paginación
class _BarraPaginacion extends StatelessWidget {

  const _BarraPaginacion({
    required this.paginaActual,
    required this.totalPaginas,
    required this.onCambioPagina,
  });
  final int paginaActual;
  final int totalPaginas;
  final Function(int) onCambioPagina;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.largePadding,
        vertical: AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Información de página
          Text(
            'Página $paginaActual de $totalPaginas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          
          // Controles de navegación
          Row(
            children: [
              IconButton(
                onPressed: paginaActual > 1 ? () => onCambioPagina(paginaActual - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
              ),
              
              const SizedBox(width: AppConstants.smallPadding),
              
              IconButton(
                onPressed: paginaActual < totalPaginas ? () => onCambioPagina(paginaActual + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Página siguiente',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IntProperty('paginaActual', paginaActual))
    ..add(IntProperty('totalPaginas', totalPaginas))
    ..add(ObjectFlagProperty<Function(int p1)>.has('onCambioPagina', onCambioPagina));
  }


}

// Función para mostrar diálogo de crear/editar carrera
void _mostrarDialogoCarrera(BuildContext context, WidgetRef ref, {ModeloCarrera? carrera}) {
  showDialog(
    context: context,
    builder: (context) => _DialogoCarrera(carrera: carrera),
  );
}

// Diálogo para crear/editar carrera
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
  
  String? _facultadSeleccionada;
  bool _guardando = false;

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
      _facultadSeleccionada = widget.carrera!.facultadId;
    } else {
      _duracionController.text = '10';
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
    final facultades = ref.watch(facultadesDisponiblesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  widget.carrera == null ? Icons.add : Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.carrera == null ? 'Nueva Carrera' : 'Editar Carrera',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Formulario
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la carrera *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Código y Duración
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _codigoController,
                              decoration: const InputDecoration(
                                labelText: 'Código *',
                                border: OutlineInputBorder(),
                                hintText: 'Ej: ISI',
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                                LengthLimitingTextInputFormatter(10),
                              ],
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El código es obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                          
                          const SizedBox(width: AppConstants.defaultPadding),
                          
                          Expanded(
                            child: TextFormField(
                              controller: _duracionController,
                              decoration: const InputDecoration(
                                labelText: 'Duración (semestres) *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
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
                      
                      // Facultad
                      facultades.when(
                        data: (listaFacultades) => DropdownButtonFormField<String>(
                          initialValue: _facultadSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Facultad *',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: listaFacultades.map((facultad) => DropdownMenuItem<String>(
                            value: facultad['id'],
                            child: Text(facultad['nombre']),
                          )).toList(),
                          onChanged: (valor) {
                            setState(() {
                              _facultadSeleccionada = valor;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Debe seleccionar una facultad';
                            }
                            return null;
                          },
                        ),
                        loading: () => DropdownButtonFormField<String>(
                          items: const [],
                          onChanged: null,
                          decoration: const InputDecoration(
                            labelText: 'Cargando facultades...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        error: (error, stack) => DropdownButtonFormField<String>(
                          items: const [],
                          onChanged: null,
                          decoration: const InputDecoration(
                            labelText: 'Error al cargar facultades',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Director
                      TextFormField(
                        controller: _directorNombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del director',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Email del director
                      TextFormField(
                        controller: _directorEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email del director',
                          border: OutlineInputBorder(),
                        ),
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
            
            // Botones
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(widget.carrera == null ? 'Crear' : 'Guardar'),
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

    setState(() {
      _guardando = true;
    });

    try {
      final datos = CrearEditarCarreraData(
        id: widget.carrera?.id,
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().toUpperCase(),
        descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        facultadId: _facultadSeleccionada!,
        duracionSemestres: int.parse(_duracionController.text),
        directorNombre: _directorNombreController.text.trim().isEmpty ? null : _directorNombreController.text.trim(),
        directorEmail: _directorEmailController.text.trim().isEmpty ? null : _directorEmailController.text.trim(),
      );

      bool exito;
      if (widget.carrera == null) {
        exito = await ref.read(carrerasAdminProvider.notifier).crearCarrera(datos);
      } else {
        exito = await ref.read(carrerasAdminProvider.notifier).editarCarrera(widget.carrera!.id, datos);
      }

      if (exito && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.carrera == null ? 'Carrera creada exitosamente' : 'Carrera actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(carrerasAdminProvider).error;
        if (mounted && error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }
}

// Función para confirmar eliminación
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
          Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            
            final exito = await ref.read(carrerasAdminProvider.notifier).eliminarCarrera(carrera.id);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(exito ? 'Carrera eliminada exitosamente' : ref.read(carrerasAdminProvider).error ?? 'Error al eliminar'),
                  backgroundColor: exito ? Colors.green : Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
