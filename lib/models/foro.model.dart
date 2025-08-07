/// Modelo para representar un Foro en UNAMAD
class ModeloForo {
  const ModeloForo({
    required this.id,
    this.grupoClaseId,
    required this.titulo,
    this.descripcion,
    this.estaBloqueado = false,
    this.creadoPor,
    this.fechaCreacion,
  });

  factory ModeloForo.fromJson(Map<String, dynamic> json) {
    return ModeloForo(
      id: json['id'] as String,
      grupoClaseId: json['grupo_clase_id'] as String?,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      estaBloqueado: json['esta_bloqueado'] as bool? ?? false,
      creadoPor: json['creado_por'] as String?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }

  final String? creadoPor;
  final String? descripcion;
  final bool estaBloqueado;
  final DateTime? fechaCreacion;
  final String? grupoClaseId;
  final String id;
  final String titulo;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grupo_clase_id': grupoClaseId,
      'titulo': titulo,
      'descripcion': descripcion,
      'esta_bloqueado': estaBloqueado,
      'creado_por': creadoPor,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }
} 