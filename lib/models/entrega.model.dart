enum EstadoEntrega {
  entregado,
  calificado,
  tarde,
  noEntregado,
}

String estadoEntregaToString(EstadoEntrega estado) {
  switch (estado) {
    case EstadoEntrega.entregado:
      return 'Entregado';
    case EstadoEntrega.calificado:
      return 'Calificado';
    case EstadoEntrega.tarde:
      return 'Tarde';
    case EstadoEntrega.noEntregado:
      return 'No entregado';
  }
}

EstadoEntrega estadoEntregaFromString(String? estado) {
  switch (estado) {
    case 'Entregado':
      return EstadoEntrega.entregado;
    case 'Calificado':
      return EstadoEntrega.calificado;
    case 'Tarde':
      return EstadoEntrega.tarde;
    case 'No entregado':
      return EstadoEntrega.noEntregado;
    default:
      return EstadoEntrega.entregado;
  }
}

class ModeloEntrega {

  ModeloEntrega({
    required this.id,
    required this.tareaId,
    required this.estudianteId,
    required this.fechaEntrega,
    required this.estado,
    this.calificacion,
    this.comentarioProfesor,
  });

  factory ModeloEntrega.fromJson(Map<String, dynamic> json) {
    return ModeloEntrega(
      id: json['id'],
      tareaId: json['tarea_id'],
      estudianteId: json['estudiante_id'],
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      estado: estadoEntregaFromString(json['estado'] as String?),
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      comentarioProfesor: json['comentario_profesor'],
    );
  }
  final String id;
  final String tareaId;
  final String estudianteId;
  final DateTime fechaEntrega;
  final EstadoEntrega estado;
  final double? calificacion;
  final String? comentarioProfesor;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarea_id': tareaId,
      'estudiante_id': estudianteId,
      'fecha_entrega': fechaEntrega.toIso8601String(),
      'estado': estadoEntregaToString(estado),
      'calificacion': calificacion,
      'comentario_profesor': comentarioProfesor,
    };
  }
} 