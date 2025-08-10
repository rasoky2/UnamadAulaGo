import 'package:aulago/models/evento_calendario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/calendario.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarioWidget extends ConsumerStatefulWidget {

  const CalendarioWidget({
    super.key,
    required this.onRegresar,
  });
  final VoidCallback onRegresar;

  @override
  ConsumerState<CalendarioWidget> createState() => _CalendarioWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar));
  }
}

class _CalendarioWidgetState extends ConsumerState<CalendarioWidget> {
  final CalendarioRepository _calendarioRepo = CalendarioRepository();
  
  // Estado del calendario
  DateTime _fechaActual = DateTime.now();
  DateTime _fechaSeleccionada = DateTime.now();
  List<EventoCalendario> _eventosDelMes = [];
  List<EventoCalendario> _eventosDelDiaSeleccionado = [];
  bool _cargandoEventos = false;
  
  // Vista del calendario
  VistaCalendario _vistaActual = VistaCalendario.mes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventosDelMes();
    });
  }

  /// Carga los eventos del mes actual
  Future<void> _cargarEventosDelMes() async {
    final estadoAuth = ref.read(proveedorAuthProvider);
    if (estadoAuth.usuario == null) {
      return;
    }

    setState(() => _cargandoEventos = true);

    try {
      final eventos = await _calendarioRepo.obtenerEventosDelMes(
        estadoAuth.usuario!.id,
        _fechaActual.year,
        _fechaActual.month,
      );

      setState(() {
        _eventosDelMes = eventos;
        _cargarEventosDelDia(_fechaSeleccionada);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargandoEventos = false);
    }
  }

  /// Carga los eventos del día seleccionado
  void _cargarEventosDelDia(DateTime fecha) {
    final eventosDelDia = _eventosDelMes
        .where((evento) => evento.fechaEvento.esMismoDia(fecha))
        .toList()

    ..sort((a, b) => a.fechaEvento.compareTo(b.fechaEvento));

    setState(() {
      _fechaSeleccionada = fecha;
      _eventosDelDiaSeleccionado = eventosDelDia;
    });
  }

  /// Navega al mes anterior
  void _mesAnterior() {
    setState(() {
      _fechaActual = DateTime(_fechaActual.year, _fechaActual.month - 1);
    });
    _cargarEventosDelMes();
  }

  /// Navega al mes siguiente
  void _mesSiguiente() {
    setState(() {
      _fechaActual = DateTime(_fechaActual.year, _fechaActual.month + 1);
    });
    _cargarEventosDelMes();
  }

  /// Cambia la vista del calendario
  void _cambiarVista(VistaCalendario nuevaVista) {
    setState(() {
      _vistaActual = nuevaVista;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.calendar200,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Calendario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onRegresar,
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
          
          // Widget del calendario
          Container(
            height: 600,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header del calendario
                _construirHeaderCalendario(),
                const SizedBox(height: 16),
                
                // Calendario
                Expanded(
                  child: _construirCalendario(),
                ),
                
                // Footer con opciones
                _construirFooterCalendario(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirHeaderCalendario() {
    return Row(
      children: [
        // Navegación del mes
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _cargandoEventos ? null : _mesAnterior,
                icon: const Icon(LucideIcons.chevronLeft200, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Mes anterior',
              ),
              IconButton(
                onPressed: _cargandoEventos ? null : _mesSiguiente,
                icon: const Icon(LucideIcons.chevronRight200, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Mes siguiente',
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Título del mes
        Text(
          '${_fechaActual.nombreMes} ${_fechaActual.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        
        const Spacer(),
        
        // Pestañas de vista
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: VistaCalendario.values.map((vista) => 
              _construirPestanaVista(vista.nombre, _vistaActual == vista, vista)
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _construirPestanaVista(String texto, bool activa, VistaCalendario vista) {
    return InkWell(
      onTap: () => _cambiarVista(vista),
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activa ? Colors.grey.shade100 : null,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
            color: activa ? AppConstants.textPrimary : AppConstants.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _construirCalendario() {
    if (_cargandoEventos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    const diasSemana = ['LUN.', 'MAR.', 'MIÉ.', 'JUE.', 'VIE.', 'SÁB.', 'DOM.'];
    
    return Column(
      children: [
        // Encabezados de días
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: diasSemana.map((dia) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  dia,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        
        // Filas del calendario
        Expanded(
          child: _construirFilasCalendario(),
        ),
      ],
    );
  }

  Widget _construirFilasCalendario() {
    final primerDiaDelMes = DateTime(_fechaActual.year, _fechaActual.month);
    final ultimoDiaDelMes = DateTime(_fechaActual.year, _fechaActual.month + 1, 0);
    
    // Calcular el primer día a mostrar (lunes de la semana que contiene el primer día del mes)
    final int diasParaRetroceder = primerDiaDelMes.weekday - 1;
    final primerDiaAMostrar = primerDiaDelMes.subtract(Duration(days: diasParaRetroceder));
    
    // Generar todas las fechas del calendario (6 semanas)
    final fechasCalendario = <DateTime>[];
    for (int i = 0; i < 42; i++) {
      fechasCalendario.add(primerDiaAMostrar.add(Duration(days: i)));
    }
    
    // Dividir en filas de 7 días
    final filas = <Widget>[];
    for (int i = 0; i < 6; i++) {
      final fechasDeLaFila = fechasCalendario.skip(i * 7).take(7).toList();
      filas.add(_construirFilaCalendarioReal(fechasDeLaFila, ultimoDiaDelMes));
    }
    
    return Column(children: filas);
  }

  Widget _construirFilaCalendarioReal(List<DateTime> fechas, DateTime ultimoDiaDelMes) {
    return Expanded(
      child: Row(
        children: fechas.map((fecha) {
          final esDelMesActual = fecha.month == _fechaActual.month;
          final esFechaSeleccionada = fecha.esMismoDia(_fechaSeleccionada);
          final esHoy = fecha.esMismoDia(DateTime.now());
          final eventosDelDia = _eventosDelMes.where((e) => e.fechaEvento.esMismoDia(fecha)).toList();
          
          return Expanded(
            child: _construirCeldaCalendario(
              fecha,
              esDelMesActual: esDelMesActual,
              esFechaSeleccionada: esFechaSeleccionada,
              esHoy: esHoy,
              eventos: eventosDelDia,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirCeldaCalendario(
    DateTime fecha, {
    required bool esDelMesActual,
    required bool esFechaSeleccionada,
    required bool esHoy,
    required List<EventoCalendario> eventos,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        color: esFechaSeleccionada ? Colors.blue.shade50 : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _cargarEventosDelDia(fecha),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número del día
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: esHoy
                          ? const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            )
                          : esFechaSeleccionada
                              ? BoxDecoration(
                                  color: Colors.blue.shade200,
                                  shape: BoxShape.circle,
                                )
                              : null,
                      child: Text(
                        '${fecha.day}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                          color: esHoy
                              ? Colors.white
                              : esFechaSeleccionada
                                  ? Colors.blue.shade800
                                  : esDelMesActual
                                      ? AppConstants.textPrimary
                                      : AppConstants.textTertiary,
                        ),
                      ),
                    ),
                    // Indicador de eventos
                    if (eventos.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: eventos.length > 1 ? Colors.red : Color(eventos.first.colorEvento),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                // Mini lista de eventos (solo en celdas más grandes)
                if (eventos.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: eventos.length > 2 ? 2 : eventos.length,
                      itemBuilder: (context, index) {
                        final evento = eventos[index];
                        return Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                          decoration: BoxDecoration(
                            color: Color(evento.colorEvento).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            evento.titulo,
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(evento.colorEvento),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                if (eventos.length > 2)
                  Text(
                    '+${eventos.length - 2} más',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _construirFooterCalendario() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del día seleccionado
          Row(
            children: [
              // Fecha seleccionada destacada
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_fechaSeleccionada.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM y', 'es_ES').format(_fechaSeleccionada),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    Text(
                      _eventosDelDiaSeleccionado.isEmpty 
                          ? 'No hay eventos programados'
                          : '${_eventosDelDiaSeleccionado.length} evento(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón de sincronización (futuro Google Calendar)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _mostrarDialogoSincronizacion,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            size: 16,
                            color: AppConstants.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sincronizar',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Lista de eventos del día seleccionado
          if (_eventosDelDiaSeleccionado.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Eventos del día:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _eventosDelDiaSeleccionado.length,
                itemBuilder: (context, index) {
                  final evento = _eventosDelDiaSeleccionado[index];
                  return _construirTarjetaEvento(evento);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTarjetaEvento(EventoCalendario evento) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(evento.colorEvento).withValues(alpha: 0.1),
        border: Border.all(color: Color(evento.colorEvento).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(evento.colorEvento),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  evento.tipo.nombre,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (evento.diasRestantes != null)
                Text(
                  evento.textoPrioridad,
                  style: TextStyle(
                    fontSize: 9,
                    color: evento.esFechaPasada ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            evento.titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (evento.cursoNombre != null) ...[
            const SizedBox(height: 4),
            Text(
              evento.cursoNombre!,
              style: const TextStyle(
                fontSize: 10,
                color: AppConstants.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(evento.fechaEvento),
            style: TextStyle(
              fontSize: 10,
              color: Color(evento.colorEvento),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoSincronizacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.calendar200, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Sincronización con Google Calendar'),
          ],
        ),
        content: const Text(
          'La sincronización con Google Calendar estará disponible próximamente. '
          'Podrás sincronizar automáticamente tus tareas, exámenes y eventos importantes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
} 