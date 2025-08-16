/// Modelo para representar la entrega de un examen por parte de un estudiante
class ExamenEntrega {
  const ExamenEntrega({
    required this.id,
    required this.examenId,
    required this.estudianteId,
    required this.fechaInicio,
    this.fechaFin,
    this.calificacion,
    required this.intento,
    required this.estado,
    this.respuestas = const [],
  });

  factory ExamenEntrega.fromJson(Map<String, dynamic> json) {
    return ExamenEntrega(
      id: json['id'] as int? ?? 0,
      examenId: json['examen_id'] as int? ?? 0,
      estudianteId: json['estudiante_id'] as int? ?? 0,
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio'].toString())
          : DateTime.now(),
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin'].toString()) 
          : null,
      calificacion: json['calificacion'] != null 
          ? (json['calificacion'] as num).toDouble() 
          : null,
      intento: json['intento'] as int? ?? 1,
      estado: json['estado'] as String? ?? 'no_iniciado',
      respuestas: json['respuestas'] != null
          ? (json['respuestas'] as List<dynamic>)
              .map((r) => RespuestaExamen.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  final int id;
  final int examenId;
  final int estudianteId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final double? calificacion;
  final int intento;
  final String estado;
  final List<RespuestaExamen> respuestas;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examen_id': examenId,
      'estudiante_id': estudianteId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'calificacion': calificacion,
      'intento': intento,
      'estado': estado,
      'respuestas': respuestas.map((r) => r.toJson()).toList(),
    };
  }

  /// Duración total del examen en minutos
  int? get duracionMinutos {
    if (fechaFin == null) {
      return null;
    }
    return fechaFin!.difference(fechaInicio).inMinutes;
  }

  /// Porcentaje de calificación sobre el total
  double? porcentajeCalificacion(double puntosMaximos) {
    if (calificacion == null) {
      return null;
    }
    return (calificacion! / puntosMaximos) * 100;
  }

  /// Nota sobre 20
  double? get notaSobre20 {
    if (calificacion == null) {
      return null;
    }
    // Calculamos sobre base de 5 puntos total (estructura actual de exámenes)
    final puntosTotal = respuestas.length * 2 + 1; // Ajustar según estructura real
    return (calificacion! / puntosTotal) * 20;
  }

  /// Estado con color
  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'completado':
        return 'green';
      case 'en_progreso':
        return 'orange';
      case 'no_iniciado':
        return 'grey';
      default:
        return 'blue';
    }
  }

  /// Respuestas correctas
  int get respuestasCorrectas {
    return respuestas.where((r) => r.esCorrecta == true).length;
  }

  /// Respuestas incorrectas
  int get respuestasIncorrectas {
    return respuestas.where((r) => r.esCorrecta == false).length;
  }
}

/// Modelo para representar una respuesta individual a una pregunta del examen
class RespuestaExamen {
  const RespuestaExamen({
    required this.preguntaId,
    required this.respuestaDada,
    this.esCorrecta,
    this.puntosObtenidos,
  });

  factory RespuestaExamen.fromJson(Map<String, dynamic> json) {
    return RespuestaExamen(
      preguntaId: json['pregunta_id'] as int? ?? 0,
      respuestaDada: json['respuesta_dada'] as String? ?? 'Sin respuesta',
      esCorrecta: json['es_correcta'] as bool?,
      puntosObtenidos: json['puntos_obtenidos'] != null 
          ? (json['puntos_obtenidos'] as num).toDouble() 
          : null,
    );
  }

  final int preguntaId;
  final String respuestaDada;
  final bool? esCorrecta;
  final double? puntosObtenidos;

  Map<String, dynamic> toJson() {
    return {
      'pregunta_id': preguntaId,
      'respuesta_dada': respuestaDada,
      'es_correcta': esCorrecta,
      'puntos_obtenidos': puntosObtenidos,
    };
  }
}
