/// Modelo para representar un Período Académico en UNAMAD
class ModeloPeriodoAcademico {

  const ModeloPeriodoAcademico({
    required this.id,
    required this.nombre,
    required this.anio,
    required this.semestre,
    required this.fechaInicio,
    required this.fechaFin,
    this.fechaMatriculaInicio,
    this.fechaMatriculaFin,
    this.estado = 'planificado',
    this.fechaCreacion,
  });

  factory ModeloPeriodoAcademico.fromJson(Map<String, dynamic> json) {
    return ModeloPeriodoAcademico(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      anio: json['anio'] as int,
      semestre: json['semestre'] as int,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      fechaMatriculaInicio: json['fecha_matricula_inicio'] != null
          ? DateTime.parse(json['fecha_matricula_inicio'])
          : null,
      fechaMatriculaFin: json['fecha_matricula_fin'] != null
          ? DateTime.parse(json['fecha_matricula_fin'])
          : null,
      estado: json['estado'] as String? ?? 'planificado',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }
  final String id;
  final String nombre;
  final int anio;
  final int semestre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime? fechaMatriculaInicio;
  final DateTime? fechaMatriculaFin;
  final String estado;
  final DateTime? fechaCreacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'anio': anio,
      'semestre': semestre,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_fin': fechaFin.toIso8601String().split('T')[0],
      'fecha_matricula_inicio': fechaMatriculaInicio?.toIso8601String().split('T')[0],
      'fecha_matricula_fin': fechaMatriculaFin?.toIso8601String().split('T')[0],
      'estado': estado,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }

  bool get estaActivo => estado == 'activo';
  bool get esActual => estado == 'activo' && 
      DateTime.now().isAfter(fechaInicio) && 
      DateTime.now().isBefore(fechaFin);
} 