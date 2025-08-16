/// Modelo para representar una Tarea en UNAMAD
class ModeloTarea {

  factory ModeloTarea.fromJson(Map<String, dynamic> json) {
    return ModeloTarea(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      instrucciones: json['instrucciones'] as String?,
      fechaAsignacion: json['fecha_asignacion'] != null ? DateTime.tryParse(json['fecha_asignacion'].toString()) : null,
      fechaEntrega: json['fecha_entrega'] != null ? DateTime.tryParse(json['fecha_entrega'].toString()) ?? DateTime.now() : DateTime.now(),
      puntosMaximos: (json['puntos_maximos'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'activa',
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id']?.toString() ?? '') ?? 0,
      nombreCurso: json['cursos'] != null && json['cursos'] is Map<String, dynamic> ? (json['cursos']['nombre'] as String?) : null,
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null ? DateTime.tryParse(json['fecha_actualizacion'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  const ModeloTarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.instrucciones,
    this.fechaAsignacion,
    required this.fechaEntrega,
    required this.puntosMaximos,
    required this.estado,
    required this.cursoId,
    this.nombreCurso,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });
  final int id;
  final String titulo;
  final String? descripcion;
  final String? instrucciones;
  final DateTime? fechaAsignacion;
  final DateTime fechaEntrega;
  final double puntosMaximos;
  final String estado;
  final int cursoId;
  final String? nombreCurso;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'instrucciones': instrucciones,
      'fecha_asignacion': fechaAsignacion?.toIso8601String(),
      'fecha_entrega': fechaEntrega.toIso8601String(),
      'puntos_maximos': puntosMaximos,
      'estado': estado,
      'curso_id': cursoId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  /// Método para enviar solo los campos editables (sin ID ni fechas automáticas)
  Map<String, dynamic> toJsonEditable() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'instrucciones': instrucciones,
      'fecha_entrega': fechaEntrega.toIso8601String(),
      'puntos_maximos': puntosMaximos,
      'estado': estado,
      'curso_id': cursoId,
    };
  }

  bool get estaVencida => DateTime.now().isAfter(fechaEntrega);
  bool get esIndividual => false; // No hay tipoTarea, por lo que no se puede determinar si es individual
  bool get esGrupal => false; // No hay tipoTarea, por lo que no se puede determinar si es grupal
  Duration get tiempoRestante => fechaEntrega.difference(DateTime.now());

  ModeloTarea copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? instrucciones,
    DateTime? fechaAsignacion,
    DateTime? fechaEntrega,
    double? puntosMaximos,
    String? estado,
    int? cursoId,
    String? nombreCurso,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ModeloTarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      instrucciones: instrucciones ?? this.instrucciones,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      puntosMaximos: puntosMaximos ?? this.puntosMaximos,
      estado: estado ?? this.estado,
      cursoId: cursoId ?? this.cursoId,
      nombreCurso: nombreCurso ?? this.nombreCurso,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}