import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/entrega.repository.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TareasWidget extends StatefulWidget {
  const TareasWidget({super.key, this.onRegresar});
  final VoidCallback? onRegresar;

  @override
  State<TareasWidget> createState() => _TareasWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onRegresar', onRegresar));
  }
}

class _TareasWidgetState extends State<TareasWidget> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  /// Refresca la lista de tareas
  Future<void> _refrescarTareas() async {
    setState(() {
      // Forzar rebuild del FutureBuilder
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[TareasWidget] Solicitando tareas (cliente)');
    final repo = TareaRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.clipboardCheck,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tareas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              if (widget.onRegresar != null)
                ElevatedButton(
                  onPressed: widget.onRegresar!,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Regresar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tabla de tareas
          RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refrescarTareas,
            child: FutureBuilder<List<ModeloTarea>>(
              future: repo.obtenerTareas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Datos no cargados'));
                }
                final tareas = snapshot.data ?? [];
                if (tareas.isEmpty) {
                  return const Center(child: Text('Datos no encontrados'));
                }
                return _construirTablaTareas(tareas);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTablaTareas(List<ModeloTarea> tareas) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header de la tabla
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Título',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Fecha Límite',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Calificación',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Acciones',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // Filas de tareas
            ...List.generate(tareas.length, (index) {
              final tarea = tareas[index];
              return _construirFilaTarea(context, tarea, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _construirFilaTarea(BuildContext context, ModeloTarea tarea, int index) {
    final esParImpar = index % 2 == 0;
    final String estado = tarea.estado.isNotEmpty ? tarea.estado : 'pendiente';
    final Color colorEstado = _obtenerColorEstado(estado);
    final String fechaLimiteStr = DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaEntrega);
    final bool esVencida = tarea.fechaEntrega.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esParImpar ? Colors.grey.shade50 : Colors.white,
        border: estado == 'Pendiente' && esVencida 
          ? const Border(left: BorderSide(color: Colors.red, width: 4))
          : null,
      ),
      child: Column(
        children: [
          // Fila principal
          Row(
            children: [
              // Título de la tarea
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fecha Límite
              Expanded(
                flex: 2,
                child: Text(
                  fechaLimiteStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
              // Calificación
              const Expanded(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Acciones
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _mostrarDetalleTarea(context, tarea),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF072D3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Ver', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _mostrarDialogoEntregaTarea(context, tarea),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Entregar', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'entregado':
        return Colors.green;
      case 'calificado':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Muestra el detalle completo de la tarea en un modal
  void _mostrarDetalleTarea(BuildContext context, ModeloTarea tarea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _DetalleTareaWidget(
            tarea: tarea,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo para entregar una tarea
  void _mostrarDialogoEntregaTarea(BuildContext context, ModeloTarea tarea) {
    showDialog(
      context: context,
      builder: (context) => _DialogoEntregaTarea(
        tarea: tarea,
        onEntregaExitosa: _refrescarTareas,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty.has('onRegresar', widget.onRegresar));
  }
}

// ==================== WIDGET DE DETALLE DE TAREA ====================

class _DetalleTareaWidget extends StatefulWidget {
  const _DetalleTareaWidget({
    required this.tarea,
    required this.scrollController,
  });

  final ModeloTarea tarea;
  final ScrollController scrollController;

  @override
  State<_DetalleTareaWidget> createState() => _DetalleTareaWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloTarea>('tarea', tarea))
    ..add(DiagnosticsProperty<ScrollController>('scrollController', scrollController));
  }
}

class _DetalleTareaWidgetState extends State<_DetalleTareaWidget> {
  ModeloEntrega? _entregaAlumno;
  bool _cargandoEntrega = true;
  final EntregaRepository _entregaRepo = EntregaRepository();

  @override
  void initState() {
    super.initState();
    _cargarEntregaAlumno();
  }

  Future<void> _cargarEntregaAlumno() async {
    try {
      // Obtener el ID del estudiante actual desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('userId');
      final userId = int.tryParse(userIdStr ?? '');
      
      if (userId == null) {
        if (mounted) {
          setState(() {
            _cargandoEntrega = false;
          });
        }
        return;
      }
      
      // Obtener el ID de la tabla estudiantes usando el usuario_id
      final supabase = Supabase.instance.client;
      final estudianteResponse = await supabase
          .from('estudiantes')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();
      
      if (estudianteResponse == null) {
        if (mounted) {
          setState(() {
            _cargandoEntrega = false;
          });
        }
        return;
      }
      
      final estudianteId = estudianteResponse['id'] as int;
      debugPrint('[DEBUG] _cargarEntregaAlumno - ID del estudiante: $estudianteId');
      
      final entrega = await _entregaRepo.obtenerEntregaPorTareaYEstudiante(
        widget.tarea.id,
        estudianteId,
      );
      
      if (mounted) {
        setState(() {
          _entregaAlumno = entrega;
          _cargandoEntrega = false;
        });
      }
    } catch (e) {
      debugPrint('[ERROR] _cargarEntregaAlumno: $e');
      if (mounted) {
        setState(() {
          _cargandoEntrega = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaCierre = widget.tarea.fechaEntrega;
    final esUrgente = fechaCierre.isBefore(DateTime.now().add(const Duration(days: 2)));

    return Column(
      children: [
        // Header del modal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withAlpha(26),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tarea.titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        if (widget.tarea.nombreCurso != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.tarea.nombreCurso!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icono: Icons.calendar_today,
                    texto: DateFormat('dd/MM/yyyy HH:mm').format(fechaCierre),
                    color: esUrgente ? Colors.red : AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.tarea.estado.isNotEmpty ? widget.tarea.estado : 'Pendiente',
                      style: const TextStyle(fontSize: 12, color: AppConstants.textTertiary),
                    ),
                  ),
                  if (esUrgente) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Contenido de la tarea
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descripción de la tarea',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.tarea.descripcion ?? 'Esta tarea no tiene descripción detallada.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Información adicional',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  titulo: 'Fecha de entrega',
                  valor: DateFormat.yMMMMEEEEd('es').add_jm().format(fechaCierre),
                  icono: Icons.schedule,
                  color: esUrgente ? Colors.red : AppConstants.primaryColor,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  titulo: 'Estado',
                  valor: widget.tarea.estado.isNotEmpty ? widget.tarea.estado : 'Pendiente de entrega',
                  icono: Icons.pending_actions,
                  color: Colors.orange,
                ),
                if (widget.tarea.nombreCurso != null) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    titulo: 'Curso',
                    valor: widget.tarea.nombreCurso!,
                    icono: Icons.school,
                    color: AppConstants.primaryColor,
                  ),
                ],
                
                // Sección de entrega del alumno
                const SizedBox(height: 24),
                _buildSeccionEntregaAlumno(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionEntregaAlumno() {
    if (_cargandoEntrega) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_entregaAlumno == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Tarea no entregada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no has entregado esta tarea. Haz clic en "Entregar" en la lista de tareas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mi entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de la entrega
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Entregado el ${DateFormat('dd/MM/yyyy HH:mm').format(_entregaAlumno!.fechaEntrega)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoEntregaToString(_entregaAlumno!.estado),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Comentario del estudiante
              if (_entregaAlumno!.comentarioEstudiante != null && 
                  _entregaAlumno!.comentarioEstudiante!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi comentario:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_entregaAlumno!.comentarioEstudiante!),
                    ],
                  ),
                ),
              ],
              
              // Archivos adjuntos
              if (_entregaAlumno!.archivosAdjuntos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Archivos entregados (${_entregaAlumno!.archivosAdjuntos.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _entregaAlumno!.archivosAdjuntos.map((archivo) => 
                    _ArchivoChipAlumno(archivo: archivo)
                  ).toList(),
                ),
              ],
              
              // Calificación (si existe)
              if (_entregaAlumno!.calificacion != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Calificación: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        '${_entregaAlumno!.calificacion!.toStringAsFixed(1)}/${widget.tarea.puntosMaximos.toInt()} puntos',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Comentario del profesor (si existe)
              if (_entregaAlumno!.comentarioProfesor != null && 
                  _entregaAlumno!.comentarioProfesor!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comentario del profesor:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_entregaAlumno!.comentarioProfesor!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== DIALOGO DE ENTREGA DE TAREA ====================

class _DialogoEntregaTarea extends StatefulWidget {
  const _DialogoEntregaTarea({
    required this.tarea,
    required this.onEntregaExitosa,
  });
  
  final ModeloTarea tarea;
  final VoidCallback onEntregaExitosa;

  @override
  State<_DialogoEntregaTarea> createState() => _DialogoEntregaTareaState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloTarea>('tarea', tarea))
    ..add(ObjectFlagProperty<VoidCallback>.has('onEntregaExitosa', onEntregaExitosa));
  }
}

class _DialogoEntregaTareaState extends State<_DialogoEntregaTarea> {
  final _formKey = GlobalKey<FormState>();
  final _comentariosController = TextEditingController();
  String? _archivoSeleccionado;
  Uint8List? _archivoBytes;
  bool _isSubiendo = false;
  final EntregaRepository _entregaRepo = EntregaRepository();

  @override
  void dispose() {
    _comentariosController.dispose();
    super.dispose();
  }

  /// Muestra un mensaje usando Navigator.overlay
  void _mostrarMensaje(String mensaje, bool esError) {
    final overlay = Navigator.of(context).overlay;
    if (overlay != null) {
      final entry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: esError ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      
      overlay.insert(entry);
      
      // Remover el mensaje después de 3 segundos
      Future.delayed(const Duration(seconds: 3), entry.remove);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.upload_file, color: AppConstants.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Entregar: ${widget.tarea.titulo}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la tarea
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha límite: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.tarea.fechaEntrega)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puntos: ${widget.tarea.puntosMaximos.toInt()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Selección de archivo
            const Text(
              'Archivo de la tarea *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(
                    _archivoSeleccionado != null ? Icons.file_present : Icons.file_upload_outlined,
                    size: 32,
                    color: _archivoSeleccionado != null ? Colors.green : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _archivoSeleccionado != null ? 'Archivo seleccionado' : 'Selecciona un archivo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _archivoSeleccionado != null ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                  if (_archivoSeleccionado != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _archivoSeleccionado!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _seleccionarArchivo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.attach_file),
                    label: Text(_archivoSeleccionado != null ? 'Cambiar archivo' : 'Seleccionar archivo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Comentarios
            const Text(
              'Comentarios adicionales (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _comentariosController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agrega comentarios sobre tu entrega...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubiendo ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _archivoBytes != null && !_isSubiendo ? _entregarTarea : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSubiendo 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Entregar Tarea'),
        ),
      ],
    );
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip', 'rar', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true, // IMPORTANTE: Captura los bytes del archivo
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _archivoSeleccionado = file.name;
          _archivoBytes = file.bytes;
        });
        
        // Debug: verificar que las variables se establecieron correctamente
        debugPrint('[DEBUG] Archivo seleccionado: $_archivoSeleccionado');
        debugPrint('[DEBUG] Archivo bytes: ${_archivoBytes != null ? "SÍ" : "NO"}');
        debugPrint('[DEBUG] Tamaño del archivo: ${_archivoBytes?.length ?? 0} bytes');
        debugPrint('[DEBUG] FilePicker result: ${result.files.first.toString()}');
        
        if (mounted) {
          // Mostrar mensaje usando Navigator.overlay
          _mostrarMensaje('Archivo seleccionado: ${file.name}', false);
        }
      }
    } catch (e) {
              if (mounted) {
          // Mostrar mensaje usando Navigator.overlay
          _mostrarMensaje('Error al seleccionar archivo: $e', true);
        }
    }
  }

  Future<void> _entregarTarea() async {
    // Debug: verificar estado de las variables antes de procesar
    debugPrint('[DEBUG] _entregarTarea - _archivoSeleccionado: $_archivoSeleccionado');
    debugPrint('[DEBUG] _entregarTarea - _archivoBytes: ${_archivoBytes != null ? "SÍ" : "NO"}');
    
    if (_formKey.currentState!.validate()) {
      if (_archivoBytes == null) {
        // Mostrar mensaje usando Navigator.overlay
        _mostrarMensaje('Por favor selecciona un archivo para entregar', true);
        return;
      }

      setState(() {
        _isSubiendo = true;
      });

      try {


        // Obtener el ID del usuario desde SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userIdStr = prefs.getString('userId');
        final userId = int.tryParse(userIdStr ?? '');
        
        if (userId == null) {
          _mostrarMensaje('Error: No se pudo obtener el ID del usuario', true);
          return;
        }
        
        debugPrint('[DEBUG] _entregarTarea - ID del usuario obtenido: $userId');
        
        // Obtener el ID de la tabla estudiantes usando el usuario_id
        final supabase = Supabase.instance.client;
        final estudianteResponse = await supabase
            .from('estudiantes')
            .select('id')
            .eq('usuario_id', userId)
            .maybeSingle();
        
        if (estudianteResponse == null) {
          _mostrarMensaje('Error: No se encontró el perfil del estudiante', true);
          return;
        }
        
        final estudianteId = estudianteResponse['id'] as int;
        debugPrint('[DEBUG] _entregarTarea - ID del estudiante en tabla estudiantes: $estudianteId');
        
        // 3. Crear la entrega en la base de datos
        await _entregaRepo.crearEntregaConArchivos(
          tareaId: widget.tarea.id,
          estudianteId: estudianteId, // ID de la tabla estudiantes
          comentarioEstudiante: _comentariosController.text.trim().isEmpty 
            ? null 
            : _comentariosController.text.trim(),
          archivos: [
            {
              'file': _archivoBytes!,
              'name': _archivoSeleccionado!,
            }
          ],
        );
        
        if (mounted) {
          Navigator.pop(context);
          // Mostrar mensaje usando Navigator.overlay
          _mostrarMensaje('¡Tarea entregada exitosamente!', false);
          // Llamar al callback para actualizar la lista de tareas
          widget.onEntregaExitosa();
        }
      } catch (e) {
        if (mounted) {
          // Mostrar mensaje usando Navigator.overlay
          _mostrarMensaje('Error al entregar tarea: $e', true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubiendo = false;
          });
        }
      }
    }
  }
}

// ==================== WIDGETS AUXILIARES ====================

/// Chip para mostrar un archivo adjunto del alumno
class _ArchivoChipAlumno extends StatelessWidget {
  const _ArchivoChipAlumno({required this.archivo});
  
  final ArchivoAdjunto archivo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _abrirArchivo(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(archivo.icono, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archivo.nombreOriginal,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    archivo.tamanoFormateado,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 12,
              color: Colors.blue.shade600,
            ),
          ],
        ),
      ),
    );
  }

  /// Abre el archivo en el navegador o aplicación correspondiente
  Future<void> _abrirArchivo(BuildContext context) async {
    try {
      final url = Uri.parse(archivo.urlArchivo);
      final canLaunch = await canLaunchUrl(url);
      
      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Si no se puede abrir, mostrar mensaje de error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ArchivoAdjunto>('archivo', archivo));
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(StringProperty('texto', texto))
    ..add(ColorProperty('color', color));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('titulo', titulo))
    ..add(StringProperty('valor', valor))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(ColorProperty('color', color));
  }
}