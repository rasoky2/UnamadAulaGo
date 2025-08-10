import 'package:aulago/models/examen.model.dart';
import 'package:aulago/models/tarea.model.dart';

/// Vistas disponibles del calendario
enum VistaCalendario {
  mes('Mes'),
  semana('Semana'),
  dia('Día');

  const VistaCalendario(this.nombre);
  final String nombre;
}

/// Tipos de eventos que pueden aparecer en el calendario
enum TipoEventoCalendario {
  tarea('Tarea', 'LucideIcons.fileText'),
  examen('Examen', 'LucideIcons.graduationCap'),
  foro('Foro', 'LucideIcons.messageSquare'),
  entrega('Entrega', 'LucideIcons.upload'),
  clase('Clase', 'LucideIcons.calendar');

  const TipoEventoCalendario(this.nombre, this.icono);

  final String nombre;
  final String icono;
}

/// Modelo para representar eventos en el calendario del estudiante
class EventoCalendario {

  /// Constructor para crear evento desde un examen
  factory EventoCalendario.desdeExamen(ModeloExamen examen, {String? cursoNombre}) {
    final ahora = DateTime.now();
    final fechaLimite = examen.fechaLimite;
    final diasRestantes = fechaLimite.difference(ahora).inDays;
    
    return EventoCalendario(
      id: 'examen_${examen.id}',
      titulo: examen.titulo,
      descripcion: examen.descripcion,
      fechaEvento: fechaLimite,
      tipo: TipoEventoCalendario.examen,
      cursoNombre: cursoNombre,
      cursoId: examen.cursoId,
      esFechaPasada: fechaLimite.isBefore(ahora),
      diasRestantes: diasRestantes >= 0 ? diasRestantes : null,
      metadata: {
        'puntos_maximos': examen.puntosMaximos,
        'tipo_examen': examen.tipoExamen,
        'duracion_minutos': examen.duracionMinutos,
        'examen_id': examen.id,
        'fecha_disponible': examen.fechaDisponible,
      },
    );
  }

  /// Constructor para crear evento desde una tarea
  factory EventoCalendario.desdeTarea(ModeloTarea tarea, {String? cursoNombre}) {
    final ahora = DateTime.now();
    final fechaEntrega = tarea.fechaEntrega;
    final diasRestantes = fechaEntrega.difference(ahora).inDays;
    
    return EventoCalendario(
      id: 'tarea_${tarea.id}',
      titulo: tarea.titulo,
      descripcion: tarea.descripcion,
      fechaEvento: fechaEntrega,
      tipo: TipoEventoCalendario.tarea,
      cursoNombre: cursoNombre,
      cursoId: tarea.cursoId,
      esFechaPasada: fechaEntrega.isBefore(ahora),
      diasRestantes: diasRestantes >= 0 ? diasRestantes : null,
      metadata: {
        'puntos_maximos': tarea.puntosMaximos,
        'estado': tarea.estado,
        'tarea_id': tarea.id,
      },
    );
  }

  /// Constructor para crear evento desde un foro (fecha de creación)
  factory EventoCalendario.desdeForo(
    String foroId,
    String titulo,
    DateTime fechaCreacion, {
    String? descripcion,
    String? cursoNombre,
    int? cursoId,
  }) {
    return EventoCalendario(
      id: 'foro_$foroId',
      titulo: 'Foro: $titulo',
      descripcion: descripcion,
      fechaEvento: fechaCreacion,
      tipo: TipoEventoCalendario.foro,
      cursoNombre: cursoNombre,
      cursoId: cursoId,
      esFechaPasada: fechaCreacion.isBefore(DateTime.now()),
      metadata: {
        'foro_id': foroId,
      },
    );
  }
  const EventoCalendario({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaEvento,
    required this.tipo,
    this.cursoNombre,
    this.cursoId,
    this.esFechaPasada = false,
    this.diasRestantes,
    this.metadata,
  });

  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEvento;
  final TipoEventoCalendario tipo;
  final String? cursoNombre;
  final int? cursoId;
  final bool esFechaPasada;
  final int? diasRestantes;
  final Map<String, dynamic>? metadata;

  /// Obtiene el color asociado al tipo de evento
  int get colorEvento {
    switch (tipo) {
      case TipoEventoCalendario.tarea:
        return 0xFF2196F3; // Azul
      case TipoEventoCalendario.examen:
        return 0xFFE91E63; // Rosa/Rojo
      case TipoEventoCalendario.foro:
        return 0xFF4CAF50; // Verde
      case TipoEventoCalendario.entrega:
        return 0xFFFF9800; // Naranja
      case TipoEventoCalendario.clase:
        return 0xFF9C27B0; // Púrpura
    }
  }

  /// Obtiene el texto de prioridad basado en los días restantes
  String get textoPrioridad {
    if (esFechaPasada) {
      return 'Vencido';
    }
    if (diasRestantes == null) {
      return '';
    }
    
    if (diasRestantes! == 0) {
      return 'Hoy';
    }
    if (diasRestantes! == 1) {
      return 'Mañana';
    }
    if (diasRestantes! <= 3) {
      return 'Urgente';
    }
    if (diasRestantes! <= 7) {
      return 'Esta semana';
    }
    
    return '${diasRestantes!} días';
  }

  /// Obtiene la prioridad numérica (menor = más urgente)
  int get prioridad {
    if (esFechaPasada) {
      return 999;
    }
    if (diasRestantes == null) {
      return 500;
    }
    
    return diasRestantes!;
  }

  @override
  String toString() {
    return 'EventoCalendario{id: $id, titulo: $titulo, tipo: $tipo, fechaEvento: $fechaEvento, diasRestantes: $diasRestantes}';
  }
}

/// Extensiones útiles para trabajar con fechas
extension DateTimeExtensions on DateTime {
  /// Verifica si esta fecha es el mismo día que otra
  bool esMismoDia(DateTime otra) {
    return year == otra.year && month == otra.month && day == otra.day;
  }

  /// Obtiene el primer día del mes
  DateTime get primerDiaDelMes {
    return DateTime(year, month);
  }

  /// Obtiene el último día del mes
  DateTime get ultimoDiaDelMes {
    return DateTime(year, month + 1, 0);
  }

  /// Obtiene el nombre del mes en español
  String get nombreMes {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return meses[month - 1];
  }

  /// Obtiene el nombre del día de la semana en español
  String get nombreDia {
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    return dias[weekday - 1];
  }
}
