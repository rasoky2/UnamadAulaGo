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
  }) : id = 0, fechaCalificacion = fechaCalificacion ?? DateTime.now();

  final int id;
  final int estudianteId;
  final int? tareaId;
  final int? examenId;
  final int? cursoId;
  final double puntosObtenidos;
  final double puntosTotales;
  final DateTime fechaCalificacion;
  final int? calificadoPor;

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
    };
    
    // Solo incluir ID si no es 0 (para actualizaciones)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }
}
