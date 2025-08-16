import 'dart:async';

import 'package:aulago/models/examen.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleExamenAlumnoScreen extends StatefulWidget {
  const DetalleExamenAlumnoScreen({super.key, required this.examen});
  final ModeloExamen examen;

  @override
  State<DetalleExamenAlumnoScreen> createState() => _DetalleExamenAlumnoScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloExamen>('examen', examen));
  }
}

class _DetalleExamenAlumnoScreenState extends State<DetalleExamenAlumnoScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late DateTime _fechaFinReal;
  Timer? _timer;
  Duration _restante = Duration.zero;
  bool _entregado = false;

  final Map<int, dynamic> _respuestas = {};
  List<Map<String, dynamic>> _preguntas = [];

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    final finPorDuracion = ahora.add(Duration(minutes: widget.examen.duracionMinutos));
    _fechaFinReal = finPorDuracion.isBefore(widget.examen.fechaLimite)
        ? finPorDuracion
        : widget.examen.fechaLimite;
    _restante = _fechaFinReal.difference(ahora);
    _iniciarTimer();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    try {
      final data = await _supabase
          .from('preguntas_examen')
          .select()
          .eq('examen_id', widget.examen.id);
      setState(() {
        _preguntas = (data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando preguntas: $e')),
        );
      }
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final restante = _fechaFinReal.difference(DateTime.now());
      if (!mounted) {
        return;
      }
      if (restante.isNegative || restante.inSeconds <= 0) {
        _timer?.cancel();
        _entregar();
        return;
      }
      setState(() => _restante = restante);
    });
  }

  Future<void> _entregar() async {
    if (_entregado) {
      return;
    }
    setState(() => _entregado = true);
    // Calcular calificación automática en escala de 0 a 20
    double pesoTotal = 0;
    double pesoObtenido = 0;
    for (final q in _preguntas) {
      final String? correcta = q['respuesta_correcta']?.toString();
      final num puntosQ = (q['puntos'] as num?) ?? 1; // peso de la pregunta
      final int id = q['id'] as int;
      pesoTotal += puntosQ.toDouble();
      if (_respuestas[id] != null && correcta != null && _respuestas[id].toString() == correcta) {
        pesoObtenido += puntosQ.toDouble();
      }
    }
    final double calificacion20 = pesoTotal == 0 ? 0 : (pesoObtenido / pesoTotal) * 20.0;

    // Guardar en examenes_entregas (upsert simple por unicidad examen_id,estudiante_id)
    try {
      // Obtener estudiante actual desde sesión (SharedPreferences -> proveedor auth ya guarda userId y role)
      // En demo, intentamos usar el id guardado por el backend
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('userId');
      final userRole = prefs.getString('userRole');
      int? estudianteId;
      if (userRole == 'estudiante' && userIdStr != null) {
        // usuarios.id -> estudiantes.usuario_id
        final est = await _supabase.from('estudiantes').select('id').eq('usuario_id', int.parse(userIdStr)).maybeSingle();
        estudianteId = est?['id'] as int?;
      }

      await _supabase.from('examenes_entregas').upsert({
        'examen_id': widget.examen.id,
        'estudiante_id': estudianteId,
        'fecha_inicio': DateTime.now().toIso8601String(),
        'fecha_fin': DateTime.now().toIso8601String(),
        'calificacion': calificacion20,
        'intento': 1,
        'estado': 'enviado',
        'respuestas': _respuestas.entries
            .map((e) => {'pregunta_id': e.key, 'respuesta': e.value})
            .toList(),
      }, onConflict: 'examen_id,estudiante_id');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar entrega: $e')));
      }
    }

    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoExamenEnviado(
        calificacion: calificacion20,
        onAceptar: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutos = _restante.inMinutes.remainder(60).toString().padLeft(2, '0');
    final horas = (_restante.inHours).toString().padLeft(2, '0');
    final segundos = _restante.inSeconds.remainder(60).toString().padLeft(2, '0');
    final Duration total = Duration(minutes: widget.examen.duracionMinutos);
    final double progreso = total.inSeconds == 0
        ? 0
        : (total.inSeconds - _restante.inSeconds).clamp(0, total.inSeconds) / total.inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examen.titulo),
        actions: [
          Chip(
            label: Text('Tiempo: $horas:$minutos:$segundos', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de progreso de tiempo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso.isNaN ? 0 : progreso,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.examen.descripcion ?? 'Sin descripción'),
            const SizedBox(height: 8),
            Text('Disponible: ${widget.examen.fechaDisponible}'),
            Text('Cierre: ${widget.examen.fechaLimite}'),
            const SizedBox(height: 16),
            Expanded(
              child: _preguntas.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _preguntas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final q = _preguntas[index];
                        final id = q['id'] as int;
                        final enunciado = q['enunciado']?.toString() ?? '';
                        final opciones = (q['opciones'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                        return _buildPreguntaCard(
                          numero: index + 1,
                          enunciado: enunciado,
                          opciones: opciones,
                          valorSeleccionado: _respuestas[id],
                          onChanged: (val) => setState(() => _respuestas[id] = val),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _entregado ? null : _entregar,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar examen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntaCard({
    required int numero,
    required String enunciado,
    required List<String> opciones,
    required valorSeleccionado,
    required ValueChanged<dynamic> onChanged,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pregunta $numero', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(enunciado),
            const SizedBox(height: 12),
            Column(
              children: opciones
                  .map((o) => RadioListTile<String>(
                        title: Text(o),
                        value: o,
                        groupValue: valorSeleccionado as String?,
                        onChanged: (val) => onChanged(val),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ModeloExamen>('examen', widget.examen))
      ..add(DiagnosticsProperty<bool>('entregado', _entregado))
      ..add(DiagnosticsProperty<Duration>('restante', _restante))
      ..add(DiagnosticsProperty<List<Map<String, dynamic>>>('_preguntas', _preguntas));
  }
}

// ==================== DIALOGO MEJORADO DE EXAMEN ENVIADO ====================

class _DialogoExamenEnviado extends StatefulWidget {
  const _DialogoExamenEnviado({
    required this.calificacion,
    required this.onAceptar,
  });

  final double calificacion;
  final VoidCallback onAceptar;

  @override
  State<_DialogoExamenEnviado> createState() => _DialogoExamenEnviadoState();
}

class _DialogoExamenEnviadoState extends State<_DialogoExamenEnviado>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esAprobado = widget.calificacion >= 11.0;
    final colorPrincipal = esAprobado ? Colors.green : Colors.red;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Examen enviado',
          style: TextStyle(color: colorPrincipal),
        ),
        content: Text(
          'Respuestas enviadas. Puntuación preliminar: ${widget.calificacion.toStringAsFixed(2)} / 20',
          style: TextStyle(color: colorPrincipal),
        ),
        actions: [
          TextButton(
            onPressed: widget.onAceptar,
            child: const Text('Aceptar'),
          )
        ],
      ),
    );
  }
}