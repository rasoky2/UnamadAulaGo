/// Modelo para representar una Facultad en UNAMAD
class ModeloFacultad {
  const ModeloFacultad({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    this.fechaCreacion,
  });

  factory ModeloFacultad.fromJson(Map<String, dynamic> json) {
    return ModeloFacultad(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
    );
  }
  final int id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final DateTime? fechaCreacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }
} 