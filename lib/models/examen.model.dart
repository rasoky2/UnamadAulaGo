/// Modelo para representar un examen
class ModeloExamen {
  const ModeloExamen({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.instrucciones,
    required this.fechaDisponible,
    required this.fechaLimite,
    this.duracionMinutos = 120,
    this.intentosPermitidos = 1,
    this.puntosMaximos = 20.0,
    this.tipoExamen = 'parcial',
    this.aleatorizarPreguntas = false,
    this.estado = 'borrador',
    this.fechaCreacion,
    this.cursoId,
    this.fechaActualizacion,
    this.fechaPublicacionResultados,
  });

  factory ModeloExamen.fromJson(Map<String, dynamic> json) {
    return ModeloExamen(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      instrucciones: json['instrucciones'] as String?,
      fechaDisponible: DateTime.parse(json['fecha_disponible'].toString()),
      fechaLimite: DateTime.parse(json['fecha_limite'].toString()),
      duracionMinutos: json['duracion_minutos'] as int? ?? 120,
      intentosPermitidos: json['intentos_permitidos'] as int? ?? 1,
      puntosMaximos: (json['puntos_maximos'] as num?)?.toDouble() ?? 20.0,
      tipoExamen: json['tipo_examen'] as String? ?? 'parcial',
      aleatorizarPreguntas: json['aleatorizar_preguntas'] as bool? ?? false,
      // campo eliminado: requiere_camara
      estado: json['estado'] as String? ?? 'borrador',
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) : null,
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id']?.toString() ?? ''),
      fechaActualizacion: json['fecha_actualizacion'] != null ? DateTime.tryParse(json['fecha_actualizacion'].toString()) : null,
      fechaPublicacionResultados: json['fecha_publicacion_resultados'] != null
          ? DateTime.tryParse(json['fecha_publicacion_resultados'].toString())
          : null,
    );
  }
  final int id;
  final String titulo;
  final String? descripcion;
  final String? instrucciones;
  final DateTime fechaDisponible;
  final DateTime fechaLimite;
  final int duracionMinutos;
  final int intentosPermitidos;
  final double puntosMaximos;
  final String tipoExamen;
  final bool aleatorizarPreguntas;
  final String estado;
  final DateTime? fechaCreacion;
  final int? cursoId;
  final DateTime? fechaActualizacion;
  final DateTime? fechaPublicacionResultados;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'instrucciones': instrucciones,
      'fecha_disponible': fechaDisponible.toIso8601String(),
      'fecha_limite': fechaLimite.toIso8601String(),
      'duracion_minutos': duracionMinutos,
      'intentos_permitidos': intentosPermitidos,
      'puntos_maximos': puntosMaximos,
      'tipo_examen': tipoExamen,
      'aleatorizar_preguntas': aleatorizarPreguntas,
      'estado': estado,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'curso_id': cursoId,
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
      'fecha_publicacion_resultados': fechaPublicacionResultados?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModeloExamen &&
        other.id == id &&
        other.titulo == titulo &&
        other.descripcion == descripcion &&
        other.fechaDisponible == fechaDisponible &&
        other.fechaLimite == fechaLimite &&
        other.estado == estado &&
        other.puntosMaximos == puntosMaximos &&
        other.tipoExamen == tipoExamen &&
        other.aleatorizarPreguntas == aleatorizarPreguntas &&
        other.fechaPublicacionResultados == fechaPublicacionResultados;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      titulo,
      descripcion,
      fechaDisponible,
      fechaLimite,
      estado,
      puntosMaximos,
      tipoExamen,
      aleatorizarPreguntas,
      fechaPublicacionResultados,
    );
  }
}