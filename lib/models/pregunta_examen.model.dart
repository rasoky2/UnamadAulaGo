/// Modelo para representar una pregunta de examen
class PreguntaExamen {
  const PreguntaExamen({
    required this.id,
    required this.examenId,
    required this.enunciado,
    required this.tipo,
    required this.opciones,
    this.respuestaCorrecta,
    this.puntos = 1.0,
  });

  /// Constructor para crear una nueva pregunta (sin ID)
  PreguntaExamen.crear({
    required this.examenId,
    required this.enunciado,
    this.tipo = 'opcion_multiple',
    required this.opciones,
    this.respuestaCorrecta,
    this.puntos = 2.0,
  }) : id = 0;

  factory PreguntaExamen.fromJson(Map<String, dynamic> json) {
    return PreguntaExamen(
      id: json['id'] as int,
      examenId: json['examen_id'] as int,
      enunciado: json['enunciado'] as String,
      tipo: json['tipo'] as String,
      opciones: json['opciones'] is List
          ? List<String>.from(json['opciones'] as List<dynamic>)
          : <String>[],
      respuestaCorrecta: json['respuesta_correcta'] as String?,
      puntos: json['puntos'] != null 
          ? (json['puntos'] as num).toDouble() 
          : 1.0,
    );
  }

  final int id;
  final int examenId;
  final String enunciado;
  final String tipo;
  final List<String> opciones;
  final String? respuestaCorrecta;
  final double puntos;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'examen_id': examenId,
      'enunciado': enunciado,
      'tipo': tipo,
      'opciones': opciones,
      'respuesta_correcta': respuestaCorrecta,
      'puntos': puntos,
    };
    
    // Solo incluir ID si no es 0 (para actualizaciones)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Copia la pregunta con nuevos valores
  PreguntaExamen copyWith({
    int? id,
    int? examenId,
    String? enunciado,
    String? tipo,
    List<String>? opciones,
    String? respuestaCorrecta,
    double? puntos,
  }) {
    return PreguntaExamen(
      id: id ?? this.id,
      examenId: examenId ?? this.examenId,
      enunciado: enunciado ?? this.enunciado,
      tipo: tipo ?? this.tipo,
      opciones: opciones ?? this.opciones,
      respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
      puntos: puntos ?? this.puntos,
    );
  }

  /// Verifica si una respuesta dada es correcta
  bool esRespuestaCorrecta(String respuesta) {
    return respuestaCorrecta?.toLowerCase() == respuesta.toLowerCase();
  }

  /// Obtiene la letra de la opción correcta (A, B, C, D)
  String? get letraRespuestaCorrecta {
    if (respuestaCorrecta == null) {
      return null;
    }
    final index = opciones.indexOf(respuestaCorrecta!);
    if (index == -1) {
      return null;
    }
    return String.fromCharCode(65 + index); // A, B, C, D...
  }

  /// Obtiene la letra de una respuesta dada
  String? getLetraRespuesta(String respuesta) {
    final index = opciones.indexOf(respuesta);
    if (index == -1) {
      return null;
    }
    return String.fromCharCode(65 + index); // A, B, C, D...
  }
}
