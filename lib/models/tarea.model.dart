/// Modelo para representar una Tarea en UNAMAD
class ModeloTarea {

  factory ModeloTarea.fromJson(Map<String, dynamic> json) {
    return ModeloTarea(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      instrucciones: json['instrucciones'] as String?,
      fechaAsignacion: json['fecha_asignacion'] is String
          ? DateTime.parse(json['fecha_asignacion'])
          : (json['fecha_asignacion'] is DateTime
              ? json['fecha_asignacion']
              : null),
      fechaEntrega: json['fecha_entrega'] is String
          ? DateTime.parse(json['fecha_entrega'])
          : (json['fecha_entrega'] is DateTime
              ? json['fecha_entrega']
              : DateTime.now().add(const Duration(days: 7))),
      puntosMaximos: (json['puntos_maximos'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'activa',
      cursoId: json['curso_id'] as String? ?? '',
      nombreCurso: json['cursos'] != null && json['cursos'] is Map<String, dynamic> ? (json['cursos']['nombre'] as String?) : null,
      fechaCreacion: json['fecha_creacion'] is String
          ? DateTime.tryParse(json['fecha_creacion']) ?? DateTime.now()
          : (json['fecha_creacion'] is DateTime
              ? json['fecha_creacion']
              : DateTime.now()),
      fechaActualizacion: json['fecha_actualizacion'] is String
          ? DateTime.tryParse(json['fecha_actualizacion']) ?? DateTime.now()
          : (json['fecha_actualizacion'] is DateTime
              ? json['fecha_actualizacion']
              : DateTime.now()),
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
  final String id;
  final String titulo;
  final String? descripcion;
  final String? instrucciones;
  final DateTime? fechaAsignacion;
  final DateTime fechaEntrega;
  final double puntosMaximos;
  final String estado;
  final String cursoId;
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
      'nombre_curso': nombreCurso,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  bool get estaVencida => DateTime.now().isAfter(fechaEntrega);
  bool get esIndividual => false; // No hay tipoTarea, por lo que no se puede determinar si es individual
  bool get esGrupal => false; // No hay tipoTarea, por lo que no se puede determinar si es grupal
  Duration get tiempoRestante => fechaEntrega.difference(DateTime.now());

  ModeloTarea copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? instrucciones,
    DateTime? fechaAsignacion,
    DateTime? fechaEntrega,
    double? puntosMaximos,
    String? estado,
    String? cursoId,
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