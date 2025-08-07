/// Modelo para representar una Facultad en UNAMAD
class ModeloFacultad {

  const ModeloFacultad({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    this.decanoNombre,
    this.decanoEmail,
    this.telefono,
    this.direccion,
    this.fechaCreacion,
  });

  factory ModeloFacultad.fromJson(Map<String, dynamic> json) {
    return ModeloFacultad(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
      decanoNombre: json['decano_nombre'] as String?,
      decanoEmail: json['decano_email'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }
  final String id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final String? decanoNombre;
  final String? decanoEmail;
  final String? telefono;
  final String? direccion;
  final DateTime? fechaCreacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'decano_nombre': decanoNombre,
      'decano_email': decanoEmail,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }
} 