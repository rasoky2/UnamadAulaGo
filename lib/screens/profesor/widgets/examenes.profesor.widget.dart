import 'package:aulago/models/examen.model.dart';
import 'package:aulago/models/examen_entrega.model.dart';
import 'package:aulago/models/pregunta_examen.model.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/repositories/examen_entrega.repository.dart';
import 'package:aulago/screens/profesor/widgets/examen_creation_widgets.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExamenesTab extends ConsumerStatefulWidget {
  const ExamenesTab({required this.cursoId, super.key});
  final String cursoId;

  @override
  ConsumerState<ExamenesTab> createState() => _ExamenesTabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _ExamenesTabState extends ConsumerState<ExamenesTab> {
  late Future<List<ModeloExamen>> _futureExamenes;

  @override
  void initState() {
    super.initState();
    _cargarExamenes();
  }

  @override
  void didUpdateWidget(ExamenesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el cursoId, recargar los exámenes
    if (oldWidget.cursoId != widget.cursoId) {
      _cargarExamenes();
    }
  }

  void _cargarExamenes() {
    debugPrint('[ExamenesTab] Cargando exámenes para curso: ${widget.cursoId}');
    
    // Validar que el cursoId sea válido
    final cursoIdInt = int.tryParse(widget.cursoId);
    if (cursoIdInt == null) {
      debugPrint('[ExamenesTab] Error: cursoId inválido: ${widget.cursoId}');
      return;
    }
    
    final examenRepo = ExamenRepository();
    setState(() {
      _futureExamenes = examenRepo.obtenerExamenesPorCurso(cursoIdInt);
    });
  }

  /// Refresca manualmente los exámenes
  Future<void> _refrescarExamenes() async {
    debugPrint('[ExamenesTab] Refrescando exámenes para curso: ${widget.cursoId}');
    _cargarExamenes();
  }

  Future<void> _mostrarDialogoCrearExamen() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => _PantallaCrearExamen(cursoId: widget.cursoId),
        fullscreenDialog: true,
      ),
    );
    if (resultado == true) {
      _cargarExamenes();
    }
  }

  Future<void> _mostrarDialogoEditarExamen(ModeloExamen examen) async {
    final editado = await showDialog<bool>(
      context: context,
      builder: (context) => _PantallaCrearExamen(
        cursoId: widget.cursoId,
        examen: examen,
      ),
    );
    if (editado == true) {
      _cargarExamenes();
    }
  }

  /// Muestra el modal con las entregas del examen
  void _mostrarEntregasModal(BuildContext context, ModeloExamen examen) {
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
          child: _EntregasExamenWidget(
            examen: examen,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  /// Muestra el modal con los puntajes del examen
  void _mostrarPuntajesModal(BuildContext context, ModeloExamen examen) {
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
          child: _PuntajesExamenWidget(
            examen: examen,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Exámenes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Botón de refresh
                  IconButton(
                    onPressed: _refrescarExamenes,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refrescar exámenes',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Examen'),
                    onPressed: _mostrarDialogoCrearExamen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Curso ID: ${widget.cursoId}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Indicador de estado
                  FutureBuilder<List<ModeloExamen>>(
                    future: _futureExamenes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cargando...',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasData) {
                        final examenes = snapshot.data!;
                        return Text(
                          '${examenes.length} examen${examenes.length == 1 ? '' : 'es'}',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ModeloExamen>>(
            future: _futureExamenes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar exámenes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curso ID: ${widget.cursoId}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refrescarExamenes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final examenes = snapshot.data ?? [];
              if (examenes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No hay exámenes para este curso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curso ID: ${widget.cursoId}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoCrearExamen,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primer Examen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                  onRefresh: _refrescarExamenes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: examenes.length,
                    itemBuilder: (context, index) {
                      final examen = examenes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_turned_in, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          examen.titulo,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Disponible: ${examen.fechaDisponible} - Límite: ${examen.fechaLimite}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Duración: ${examen.fechaLimite.difference(examen.fechaDisponible).inMinutes} min',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () {
                                      _mostrarDialogoEditarExamen(examen);
                                    },
                                    tooltip: 'Editar examen',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _mostrarEntregasModal(context, examen),
                                      icon: const Icon(Icons.people, size: 18),
                                      label: const Text('Ver Entregas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _mostrarPuntajesModal(context, examen),
                                      icon: const Icon(Icons.score, size: 18),
                                      label: const Text('Ver Puntajes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
            },
          ),
        ),
      ],
    );
  }
}

// ==================== PANTALLA COMPLETA PARA CREAR EXAMEN ====================

class _PantallaCrearExamen extends ConsumerStatefulWidget {
  const _PantallaCrearExamen({required this.cursoId, this.examen});
  final String cursoId;
  final ModeloExamen? examen;

  @override
  ConsumerState<_PantallaCrearExamen> createState() => _PantallaCrearExamenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('cursoId', cursoId))
    ..add(DiagnosticsProperty<ModeloExamen?>('examen', examen));
  }
}

class _PantallaCrearExamenState extends ConsumerState<_PantallaCrearExamen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controladores para información básica
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _instruccionesController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  int _duracion = 120;
  double _puntosMaximos = 20.0;
  String _tipoExamen = 'parcial';
  bool _aleatorizarPreguntas = false;
  
  // Lista de preguntas
  final List<PreguntaTemporal> _preguntas = [];
  
  // Estado
  int _pasoActual = 0;
  bool _isLoading = false;
  bool _cargandoPreguntas = false;

  @override
  void initState() {
    super.initState();
    if (widget.examen != null) {
      _tituloController.text = widget.examen!.titulo;
      _descripcionController.text = widget.examen!.descripcion ?? '';
      _instruccionesController.text = widget.examen!.instrucciones ?? '';
      _fechaInicio = widget.examen!.fechaDisponible;
      _fechaFin = widget.examen!.fechaLimite;
      _duracion = widget.examen!.duracionMinutos;
      _puntosMaximos = widget.examen!.puntosMaximos;
      _tipoExamen = widget.examen!.tipoExamen;
      _aleatorizarPreguntas = widget.examen!.aleatorizarPreguntas;
      
      // Cargar preguntas existentes del examen de forma asíncrona
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarPreguntasExistentes();
      });
    } else {
      // Agregar una pregunta inicial para nuevo examen
      _agregarPregunta();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _instruccionesController.dispose();
    _pageController.dispose();
    for (final pregunta in _preguntas) {
      pregunta.dispose();
    }
    super.dispose();
  }

  void _agregarPregunta() {
    setState(() {
      _preguntas.add(PreguntaTemporal());
    });
  }

  void _eliminarPregunta(int index) {
    if (_preguntas.length > 1) {
      setState(() {
        _preguntas[index].dispose();
        _preguntas.removeAt(index);
      });
    }
  }

  /// Carga las preguntas existentes del examen que se está editando
  Future<void> _cargarPreguntasExistentes() async {
    if (widget.examen == null) {
      return;
    }
    
    setState(() {
      _cargandoPreguntas = true;
    });
    
    try {
      final repo = ExamenRepository();
      final preguntasExistentes = await repo.obtenerPreguntasExamen(widget.examen!.id!);
      
      setState(() {
        _preguntas.clear();
        for (final pregunta in preguntasExistentes) {
          _preguntas.add(PreguntaTemporal.fromPreguntaExamen(pregunta));
        }
        _cargandoPreguntas = false;
      });
      
      debugPrint('[EditarExamen] Preguntas cargadas: ${_preguntas.length}');
    } catch (e) {
      debugPrint('[EditarExamen] Error al cargar preguntas: $e');
      setState(() {
        _cargandoPreguntas = false;
      });
      // Si falla la carga, agregar una pregunta por defecto
      _agregarPregunta();
    }
  }

  void _siguientePaso() {
    if (_pasoActual == 0) {
      // Validar información básica
      if (!_formKey.currentState!.validate()) {
        return;
      }
      if (_fechaInicio == null || _fechaFin == null) {
        _mostrarError('Por favor selecciona las fechas del examen');
        return;
      }
      if (_fechaFin!.isBefore(_fechaInicio!)) {
        _mostrarError('La fecha de fin debe ser posterior a la fecha de inicio');
        return;
      }
    }

    if (_pasoActual < 2) {
      setState(() => _pasoActual++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pasoAnterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _guardarExamen() async {
    // Validar preguntas
    if (_preguntas.isEmpty) {
      _mostrarError('Debes agregar al menos una pregunta');
      return;
    }

    for (int i = 0; i < _preguntas.length; i++) {
      final pregunta = _preguntas[i];
      if (!pregunta.esValida()) {
        _mostrarError('La pregunta ${i + 1} está incompleta');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ExamenRepository();
      
      if (widget.examen != null) {
        // EDITAR EXAMEN EXISTENTE
        debugPrint('[EditarExamen] Editando examen ID: ${widget.examen!.id}');
        
        // Actualizar datos del examen
        final examenActualizado = ModeloExamen(
          id: widget.examen!.id!,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          instrucciones: _instruccionesController.text,
          fechaDisponible: _fechaInicio!,
          fechaLimite: _fechaFin!,
          duracionMinutos: _duracion,
          puntosMaximos: _puntosMaximos,
          tipoExamen: _tipoExamen,
          aleatorizarPreguntas: _aleatorizarPreguntas,
          estado: widget.examen!.estado, // Mantener estado actual
          fechaCreacion: widget.examen!.fechaCreacion, // Mantener fecha de creación
          cursoId: widget.examen!.cursoId, // Mantener curso ID
          fechaActualizacion: DateTime.now(),
        );

        // Convertir preguntas temporales a preguntas del modelo
        final preguntas = _preguntas.map((p) => p.toPreguntaExamen()).toList();

        // Actualizar examen con preguntas
        await repo.actualizarExamenConPreguntas(
          examen: examenActualizado,
          preguntas: preguntas,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Examen actualizado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // CREAR NUEVO EXAMEN
        debugPrint('[CrearExamen] Creando nuevo examen');
        
        // Crear el examen
        final examen = ModeloExamen(
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          instrucciones: _instruccionesController.text,
          fechaDisponible: _fechaInicio!,
          fechaLimite: _fechaFin!,
          duracionMinutos: _duracion,
          puntosMaximos: _puntosMaximos,
          tipoExamen: _tipoExamen,
          aleatorizarPreguntas: _aleatorizarPreguntas,
          estado: 'publicado',
          fechaCreacion: DateTime.now(),
          cursoId: int.tryParse(widget.cursoId),
          fechaActualizacion: DateTime.now(),
        );

        // Convertir preguntas temporales a preguntas del modelo
        final preguntas = _preguntas.map((p) => p.toPreguntaExamen()).toList();

        // Crear examen con preguntas
        await repo.crearExamenConPreguntas(
          examen: examen,
          preguntas: preguntas,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Examen creado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final accion = widget.examen != null ? 'actualizar' : 'crear';
        _mostrarError('Error al $accion examen: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examen == null ? 'Crear Examen' : 'Editar Examen'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _pasoActual ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          
          // Títulos de pasos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información',
                  style: TextStyle(
                    fontWeight: _pasoActual == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _pasoActual == 0 ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Preguntas',
                  style: TextStyle(
                    fontWeight: _pasoActual == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _pasoActual == 1 ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Revisión',
                  style: TextStyle(
                    fontWeight: _pasoActual == 2 ? FontWeight.bold : FontWeight.normal,
                    color: _pasoActual == 2 ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contenido de los pasos
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _construirPasoInformacion(),
                _construirPasoPreguntas(),
                _construirPasoRevision(),
              ],
            ),
          ),

          // Botones de navegación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_pasoActual > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _pasoAnterior,
                      child: const Text('Anterior'),
                    ),
                  ),
                if (_pasoActual > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_pasoActual == 2 ? _guardarExamen : _siguientePaso),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_pasoActual == 2 
                            ? (widget.examen != null ? 'Actualizar Examen' : 'Crear Examen')
                            : 'Siguiente'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPasoInformacion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Examen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título del examen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.fileText),
              ),
              validator: (v) => v == null || v.isEmpty ? 'El título es requerido' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.alignLeft),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _instruccionesController,
              decoration: const InputDecoration(
                labelText: 'Instrucciones para los estudiantes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.info),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Fechas
            const Text(
              'Fechas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaInicio,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de inicio'),
                          const SizedBox(height: 4),
                          Text(
                            _fechaInicio == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy HH:mm').format(_fechaInicio!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _fechaInicio == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaFin,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha límite'),
                          const SizedBox(height: 4),
                          Text(
                            _fechaFin == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy HH:mm').format(_fechaFin!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _fechaFin == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Configuración
            const Text(
              'Configuración',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _duracion.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Duración (minutos)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.clock),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Requerido' : null,
                    onChanged: (v) => _duracion = int.tryParse(v) ?? 120,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _puntosMaximos.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Puntos máximos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.award),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Requerido' : null,
                    onChanged: (v) => _puntosMaximos = double.tryParse(v) ?? 20.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _tipoExamen,
              decoration: const InputDecoration(
                labelText: 'Tipo de examen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.bookmark),
              ),
              items: const [
                DropdownMenuItem(value: 'parcial', child: Text('Examen Parcial')),
                DropdownMenuItem(value: 'final', child: Text('Examen Final')),
                DropdownMenuItem(value: 'practica', child: Text('Práctica')),
                DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
              ],
              onChanged: (v) => setState(() => _tipoExamen = v!),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Aleatorizar preguntas'),
              subtitle: const Text('Las preguntas aparecerán en orden aleatorio'),
              value: _aleatorizarPreguntas,
              onChanged: (v) => setState(() => _aleatorizarPreguntas = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPasoPreguntas() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Preguntas del Examen',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _agregarPregunta,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Agregar Pregunta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Lista de preguntas
        Expanded(
          child: _cargandoPreguntas
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando preguntas existentes...'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _preguntas.length,
                  itemBuilder: (context, index) {
                    return PreguntaCard(
                      pregunta: _preguntas[index],
                      numero: index + 1,
                      onEliminar: _preguntas.length > 1 ? () => _eliminarPregunta(index) : null,
                    );
                  },
                ),
        ),

        // Resumen
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ResumenItem(
                icono: Icons.help_outline,
                titulo: 'Preguntas',
                valor: '${_preguntas.length}',
              ),
              ResumenItem(
                icono: Icons.star,
                titulo: 'Puntos Totales',
                valor: '${_preguntas.fold<double>(0, (sum, p) => sum + p.puntos)}',
              ),
              ResumenItem(
                icono: Icons.access_time,
                titulo: 'Tiempo',
                valor: '${_duracion}min',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirPasoRevision() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revisión del Examen',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Información básica
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Básica',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ItemRevision(titulo: 'Título', valor: _tituloController.text),
                  ItemRevision(titulo: 'Descripción', valor: _descripcionController.text.isEmpty ? 'Sin descripción' : _descripcionController.text),
                  ItemRevision(titulo: 'Tipo', valor: _tipoExamen),
                  ItemRevision(titulo: 'Duración', valor: '$_duracion minutos'),
                  ItemRevision(titulo: 'Puntos máximos', valor: '$_puntosMaximos'),
                  if (_fechaInicio != null && _fechaFin != null) ...[
                    ItemRevision(titulo: 'Inicio', valor: DateFormat('dd/MM/yyyy HH:mm').format(_fechaInicio!)),
                    ItemRevision(titulo: 'Fin', valor: DateFormat('dd/MM/yyyy HH:mm').format(_fechaFin!)),
                  ],
                  ItemRevision(titulo: 'Aleatorizar', valor: _aleatorizarPreguntas ? 'Sí' : 'No'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preguntas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preguntas (${_preguntas.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < _preguntas.length; i++) ...[
                    PreguntaRevision(
                      numero: i + 1,
                      pregunta: _preguntas[i],
                    ),
                    if (i < _preguntas.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaInicio ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _fechaInicio = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaFin ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _fechaFin = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }
}

// ==================== MODAL DE ENTREGAS DE EXAMEN ====================

class _EntregasExamenWidget extends ConsumerStatefulWidget {
  const _EntregasExamenWidget({
    required this.examen,
    required this.scrollController,
  });

  final ModeloExamen examen;
  final ScrollController scrollController;

  @override
  ConsumerState<_EntregasExamenWidget> createState() => _EntregasExamenWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloExamen>('examen', examen))
    ..add(DiagnosticsProperty<ScrollController>('scrollController', scrollController));
  }
}

class _EntregasExamenWidgetState extends ConsumerState<_EntregasExamenWidget> {
  final ExamenEntregaRepository _entregaRepo = ExamenEntregaRepository();
  late Future<List<Map<String, dynamic>>> _futureEntregas;
  late Future<Map<String, dynamic>> _futureEstadisticas;
  late Future<List<PreguntaExamen>> _futurePreguntas;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    if (widget.examen.id != null) {
      _futureEntregas = _entregaRepo.obtenerEntregasConEstudiante(widget.examen.id!);
      _futureEstadisticas = _entregaRepo.obtenerEstadisticasExamen(widget.examen.id!);
      _futurePreguntas = _entregaRepo.obtenerPreguntasExamen(widget.examen.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header del modal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fileText, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.examen.titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha límite: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.examen.fechaLimite)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                'Puntos máximos: ${widget.examen.puntosMaximos}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Estadísticas del examen
        Container(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _futureEstadisticas,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _EstadisticaCard(
                        titulo: 'Total',
                        valor: '${stats['total_entregas'] ?? 0}',
                        icono: LucideIcons.users,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaCard(
                        titulo: 'Completadas',
                        valor: '${stats['completadas'] ?? 0}',
                        icono: LucideIcons.check,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaCard(
                        titulo: 'Promedio',
                        valor: '${(stats['promedio_calificacion'] ?? 0.0).toStringAsFixed(1)}',
                        icono: LucideIcons.trendingUp,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaCard(
                        titulo: 'Aprobación',
                        valor: '${(stats['porcentaje_aprobacion'] ?? 0.0).toStringAsFixed(0)}%',
                        icono: LucideIcons.award,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox(height: 80);
            },
          ),
        ),

        // Lista de entregas
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureEntregas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar entregas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final entregas = snapshot.data ?? [];

              if (entregas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileX, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No hay entregas para este examen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _cargarDatos(),
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entregas.length,
                  itemBuilder: (context, index) {
                    final entregaData = entregas[index];
                    final entrega = ExamenEntrega.fromJson(entregaData);
                    final estudiante = entregaData['estudiantes'];

                    return _EntregaExamenCard(
                      entrega: entrega,
                      estudiante: estudiante,
                      examen: widget.examen,
                      onVerDetalle: () => _mostrarDetalleEntrega(entrega, estudiante),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Muestra el detalle de una entrega específica
  void _mostrarDetalleEntrega(ExamenEntrega entrega, Map<String, dynamic> estudianteData) {
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
          child: _DetalleEntregaWidget(
            entrega: entrega,
            estudiante: estudianteData,
            examen: widget.examen,
            preguntas: _futurePreguntas,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _EstadisticaCard extends StatelessWidget {
  const _EstadisticaCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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

class _EntregaExamenCard extends StatelessWidget {
  const _EntregaExamenCard({
    required this.entrega,
    required this.estudiante,
    required this.examen,
    required this.onVerDetalle,
  });

  final ExamenEntrega entrega;
  final Map<String, dynamic> estudiante;
  final ModeloExamen examen;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    final duracion = entrega.duracionMinutos;
    final porcentaje = entrega.porcentajeCalificacion(examen.puntosMaximos);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onVerDetalle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(
                    fotoUrl: estudiante['foto_perfil_url'],
                    nombreCompleto: estudiante['nombre_completo'] ?? 'Estudiante',
                    radio: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estudiante['nombre_completo'] ?? 'Estudiante sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          estudiante['codigo_estudiante'] ?? 'Sin código',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entrega.calificacion != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (entrega.calificacion! >= 11) ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entrega.calificacion!.toStringAsFixed(1)}/20',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Duración: ${duracion != null ? '${duracion}min' : 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.check, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Correctas: ${entrega.respuestasCorrectas}/${entrega.respuestas.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              if (porcentaje != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          porcentaje >= 55 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: porcentaje >= 55 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ExamenEntrega>('entrega', entrega))
    ..add(DiagnosticsProperty<Map<String, dynamic>>('estudiante', estudiante))
    ..add(DiagnosticsProperty<ModeloExamen>('examen', examen))
    ..add(ObjectFlagProperty<VoidCallback>.has('onVerDetalle', onVerDetalle));
  }
}

class _DetalleEntregaWidget extends StatelessWidget {
  const _DetalleEntregaWidget({
    required this.entrega,
    required this.estudiante,
    required this.examen,
    required this.preguntas,
    required this.scrollController,
  });

  final ExamenEntrega entrega;
  final Map<String, dynamic> estudiante;
  final ModeloExamen examen;
  final Future<List<PreguntaExamen>> preguntas;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(
                    fotoUrl: estudiante['foto_perfil_url'],
                    nombreCompleto: estudiante['nombre_completo'],
                    radio: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estudiante['nombre_completo'] ?? 'Estudiante sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Código: ${estudiante['codigo_estudiante'] ?? 'Sin código'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icono: LucideIcons.calendar,
                    texto: DateFormat('dd/MM HH:mm').format(entrega.fechaInicio),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icono: LucideIcons.clock,
                    texto: '${entrega.duracionMinutos ?? 0}min',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  if (entrega.calificacion != null)
                    _InfoChip(
                      icono: LucideIcons.award,
                      texto: '${entrega.calificacion!.toStringAsFixed(1)}/20',
                      color: entrega.calificacion! >= 11 ? Colors.green : Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Preguntas y respuestas
        Expanded(
          child: FutureBuilder<List<PreguntaExamen>>(
            future: preguntas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Error al cargar preguntas'));
              }

              final preguntasList = snapshot.data!;

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: preguntasList.length,
                itemBuilder: (context, index) {
                  final pregunta = preguntasList[index];
                  final respuesta = entrega.respuestas.firstWhere(
                    (r) => r.preguntaId == pregunta.id,
                    orElse: () => const RespuestaExamen(
                      preguntaId: -1,
                      respuestaDada: 'Sin respuesta',
                    ),
                  );

                  return _PreguntaRespuestaCard(
                    pregunta: pregunta,
                    respuesta: respuesta,
                    numeroPregunta: index + 1,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ExamenEntrega>('entrega', entrega))
    ..add(DiagnosticsProperty<Map<String, dynamic>>('estudiante', estudiante))
    ..add(DiagnosticsProperty<ModeloExamen>('examen', examen))
    ..add(DiagnosticsProperty<Future<List<PreguntaExamen>>>('preguntas', preguntas))
    ..add(DiagnosticsProperty<ScrollController>('scrollController', scrollController));
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
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

class _PreguntaRespuestaCard extends StatelessWidget {
  const _PreguntaRespuestaCard({
    required this.pregunta,
    required this.respuesta,
    required this.numeroPregunta,
  });

  final PreguntaExamen pregunta;
  final RespuestaExamen respuesta;
  final int numeroPregunta;

  @override
  Widget build(BuildContext context) {
    final esCorrecta = respuesta.esCorrecta ?? false;
    final colorTema = esCorrecta ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la pregunta
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorTema.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorTema.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '$numeroPregunta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorTema,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pregunta.enunciado,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorTema,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esCorrecta ? LucideIcons.check : LucideIcons.x,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${respuesta.puntosObtenidos ?? 0}/${pregunta.puntos}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Opciones
            ...pregunta.opciones.asMap().entries.map((entry) {
              final index = entry.key;
              final opcion = entry.value;
              final letra = String.fromCharCode(65 + index); // A, B, C, D
              
              final esRespuestaCorrecta = opcion == pregunta.respuestaCorrecta;
              final esRespuestaDada = opcion == respuesta.respuestaDada;

              Color? colorFondo;
              Color? colorTexto;
              IconData? icono;

              if (esRespuestaCorrecta && esRespuestaDada) {
                // Respuesta correcta seleccionada
                colorFondo = Colors.green.withValues(alpha: 0.1);
                colorTexto = Colors.green;
                icono = LucideIcons.check;
              } else if (esRespuestaCorrecta) {
                // Respuesta correcta no seleccionada
                colorFondo = Colors.green.withValues(alpha: 0.05);
                colorTexto = Colors.green;
                icono = LucideIcons.check;
              } else if (esRespuestaDada) {
                // Respuesta incorrecta seleccionada
                colorFondo = Colors.red.withValues(alpha: 0.1);
                colorTexto = Colors.red;
                icono = LucideIcons.x;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(8),
                  border: colorTexto != null
                      ? Border.all(color: colorTexto.withValues(alpha: 0.3))
                      : Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorTexto?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorTexto?.withValues(alpha: 0.3) ?? Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letra,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorTexto ?? Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opcion,
                        style: TextStyle(
                          color: colorTexto ?? Colors.grey.shade800,
                          fontWeight: colorTexto != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icono != null) ...[
                      const SizedBox(width: 8),
                      Icon(icono, size: 16, color: colorTexto),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<PreguntaExamen>('pregunta', pregunta))
    ..add(DiagnosticsProperty<RespuestaExamen>('respuesta', respuesta))
    ..add(IntProperty('numeroPregunta', numeroPregunta));
  }
}

// ==================== WIDGET DE PUNTAJES DEL EXAMEN ====================

class _PuntajesExamenWidget extends ConsumerStatefulWidget {
  const _PuntajesExamenWidget({
    required this.examen,
    required this.scrollController,
  });

  final ModeloExamen examen;
  final ScrollController scrollController;

  @override
  ConsumerState<_PuntajesExamenWidget> createState() => _PuntajesExamenWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloExamen>('examen', examen))
    ..add(DiagnosticsProperty<ScrollController>('scrollController', scrollController));
  }
}

class _PuntajesExamenWidgetState extends ConsumerState<_PuntajesExamenWidget> {
  final ExamenEntregaRepository _entregaRepo = ExamenEntregaRepository();
  late Future<List<Map<String, dynamic>>> _futureEntregas;
  late Future<Map<String, dynamic>> _futureEstadisticas;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    if (widget.examen.id != null) {
      _futureEntregas = _entregaRepo.obtenerEntregasConEstudiante(widget.examen.id!);
      _futureEstadisticas = _entregaRepo.obtenerEstadisticasExamen(widget.examen.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header del modal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.score, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puntajes - ${widget.examen.titulo}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Puntos máximos: ${widget.examen.puntosMaximos}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),

        // Estadísticas del examen
        Container(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _futureEstadisticas,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: _EstadisticaPuntajeCard(
                        titulo: 'Total',
                        valor: '${stats['total_entregas'] ?? 0}',
                        icono: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaPuntajeCard(
                        titulo: 'Completadas',
                        valor: '${stats['completadas'] ?? 0}',
                        icono: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaPuntajeCard(
                        titulo: 'Promedio',
                        valor: '${(stats['promedio_calificacion'] ?? 0.0).toStringAsFixed(1)}',
                        icono: Icons.trending_up,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EstadisticaPuntajeCard(
                        titulo: 'Aprobación',
                        valor: '${(stats['porcentaje_aprobacion'] ?? 0.0).toStringAsFixed(0)}%',
                        icono: Icons.school,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox(height: 80);
            },
          ),
        ),

        // Lista de puntajes
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureEntregas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar puntajes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final entregas = snapshot.data ?? [];

              if (entregas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No hay entregas para este examen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los puntajes aparecerán cuando los estudiantes completen el examen',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Ordenar entregas por calificación (de mayor a menor)
              entregas.sort((a, b) {
                final calA = a['calificacion'] ?? 0.0;
                final calB = b['calificacion'] ?? 0.0;
                return calB.compareTo(calA);
              });

              return RefreshIndicator(
                onRefresh: () async => _cargarDatos(),
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entregas.length,
                  itemBuilder: (context, index) {
                    final entregaData = entregas[index];
                    final entrega = ExamenEntrega.fromJson(entregaData);
                    final estudiante = entregaData['estudiantes'];
                    final posicion = index + 1;

                    return _PuntajeAlumnoCard(
                      entrega: entrega,
                      estudiante: estudiante,
                      posicion: posicion,
                      examen: widget.examen,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EstadisticaPuntajeCard extends StatelessWidget {
  const _EstadisticaPuntajeCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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

class _PuntajeAlumnoCard extends StatelessWidget {
  const _PuntajeAlumnoCard({
    required this.entrega,
    required this.estudiante,
    required this.posicion,
    required this.examen,
  });

  final ExamenEntrega entrega;
  final Map<String, dynamic> estudiante;
  final int posicion;
  final ModeloExamen examen;

  @override
  Widget build(BuildContext context) {
    final calificacion = entrega.calificacion ?? 0.0;
    final porcentaje = entrega.porcentajeCalificacion(examen.puntosMaximos);
    final esAprobado = calificacion >= 11;
    final colorCalificacion = esAprobado ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Posición
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColorPosicion(posicion),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$posicion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Información del estudiante
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante['nombre_completo'] ?? 'Estudiante sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    estudiante['codigo_estudiante'] ?? 'Sin código',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (entrega.duracionMinutos != null) ...[
                    const SizedBox(height: 4),
                                         Row(
                       children: [
                         Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                         const SizedBox(width: 4),
                         Text(
                           'Duración: ${entrega.duracionMinutos}min',
                           style: TextStyle(
                             color: Colors.grey.shade600,
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                  ],
                ],
              ),
            ),

            // Calificación
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorCalificacion,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${calificacion.toStringAsFixed(1)}/${examen.puntosMaximos}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (porcentaje != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${porcentaje.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: colorCalificacion,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorCalificacion.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorCalificacion.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    esAprobado ? 'APROBADO' : 'REPROBADO',
                    style: TextStyle(
                      color: colorCalificacion,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorPosicion(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber.shade600; // Oro
      case 2:
        return Colors.grey.shade400; // Plata
      case 3:
        return Colors.orange.shade600; // Bronce
      default:
        return Colors.blue.shade600; // Azul para el resto
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ExamenEntrega>('entrega', entrega))
    ..add(DiagnosticsProperty<Map<String, dynamic>>('estudiante', estudiante))
    ..add(IntProperty('posicion', posicion))
    ..add(DiagnosticsProperty<ModeloExamen>('examen', examen));
  }
}
