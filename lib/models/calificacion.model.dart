/// Modelo para una calificación de tarea o examen
class Calificacion {
  factory Calificacion.fromJson(Map<String, dynamic> json) {
    return Calificacion(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      estudianteId: json['estudiante_id'] is int ? json['estudiante_id'] : int.tryParse(json['estudiante_id'].toString()) ?? 0,
      tareaId: json['tarea_id'] is int ? json['tarea_id'] : int.tryParse(json['tarea_id']?.toString() ?? ''),
      examenId: json['examen_id'] is int ? json['examen_id'] : int.tryParse(json['examen_id']?.toString() ?? ''),
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id']?.toString() ?? ''),
      puntosObtenidos: (json['puntos_obtenidos'] as num?)?.toDouble() ?? 0.0,
      puntosTotales: (json['puntos_totales'] as num?)?.toDouble() ?? 0.0,
      fechaCalificacion: json['fecha_calificacion'] != null ? DateTime.tryParse(json['fecha_calificacion'].toString()) ?? DateTime.now() : DateTime.now(),
      calificadoPor: json['calificado_por'] is int ? json['calificado_por'] : int.tryParse(json['calificado_por']?.toString() ?? ''),
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null ? DateTime.tryParse(json['fecha_actualizacion'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
  
  Calificacion({
    required this.id,
    required this.estudianteId,
    this.tareaId,
    this.examenId,
    this.cursoId,
    required this.puntosObtenidos,
    required this.puntosTotales,
    required this.fechaCalificacion,
    this.calificadoPor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  /// Constructor para crear una nueva calificación (sin ID)
  Calificacion.crear({
    required this.estudianteId,
    this.tareaId,
    this.examenId,
    this.cursoId,
    required this.puntosObtenidos,
    required this.puntosTotales,
    DateTime? fechaCalificacion,
    this.calificadoPor,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) : 
    id = 0, 
    fechaCalificacion = fechaCalificacion ?? DateTime.now(),
    fechaCreacion = fechaCreacion ?? DateTime.now(),
    fechaActualizacion = fechaActualizacion ?? DateTime.now();

  final int id;
  final int estudianteId;
  final int? tareaId;
  final int? examenId;
  final int? cursoId;
  final double puntosObtenidos;
  final double puntosTotales;
  final DateTime fechaCalificacion;
  final int? calificadoPor;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'estudiante_id': estudianteId,
      'tarea_id': tareaId,
      'examen_id': examenId,
      'curso_id': cursoId,
      'puntos_obtenidos': puntosObtenidos,
      'puntos_totales': puntosTotales,
      'fecha_calificacion': fechaCalificacion.toIso8601String(),
      'calificado_por': calificadoPor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
    
    // Solo incluir ID si no es 0 (para actualizaciones)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Método para crear una copia con campos actualizados
  Calificacion copyWith({
    int? id,
    int? estudianteId,
    int? tareaId,
    int? examenId,
    int? cursoId,
    double? puntosObtenidos,
    double? puntosTotales,
    DateTime? fechaCalificacion,
    int? calificadoPor,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Calificacion(
      id: id ?? this.id,
      estudianteId: estudianteId ?? this.estudianteId,
      tareaId: tareaId ?? this.tareaId,
      examenId: examenId ?? this.examenId,
      cursoId: cursoId ?? this.cursoId,
      puntosObtenidos: puntosObtenidos ?? this.puntosObtenidos,
      puntosTotales: puntosTotales ?? this.puntosTotales,
      fechaCalificacion: fechaCalificacion ?? this.fechaCalificacion,
      calificadoPor: calificadoPor ?? this.calificadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
