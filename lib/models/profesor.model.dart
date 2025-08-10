import 'package:aulago/models/usuario.model.dart';

class ProfesorAdmin {

  factory ProfesorAdmin.fromJson(Map<String, dynamic> json) {
    final idStr = json['id']?.toString() ?? '0';

    // Si no vino el join de usuarios, construir el usuario desde la propia fila de profesores
    final ModeloUsuario usuario = json['usuarios'] != null
        ? ModeloUsuario.fromJson(json['usuarios'] as Map<String, dynamic>)
        : ModeloUsuario.fromProfesorJson(json);
    
    return ProfesorAdmin(
      id: idStr,
      usuario: usuario,
      especialidad: json['especialidad']?.toString(),
      gradoAcademico: json['grado_academico']?.toString(),
      facultadId: json['facultad_id']?.toString(),
      facultadNombre: (json['facultades'] as Map<String, dynamic>?)?['nombre']?.toString(),
      fechaCreacion: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
      fechaActualizacion: DateTime.tryParse(json['fecha_actualizacion']?.toString() ?? '') ?? DateTime.now(),
      estado: json['estado']?.toString() ?? 'activo',
    );
  }


  const ProfesorAdmin({
    required this.id,
    required this.usuario,
    this.especialidad,
    this.gradoAcademico,
    this.facultadId,
    this.facultadNombre,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.estado = 'activo',
  });
  final String id;
  final ModeloUsuario usuario;

  final String? especialidad;
  final String? gradoAcademico;
  final String? facultadId;
  final String? facultadNombre;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String estado;
  
  // Getters para facilitar el acceso a los datos del usuario
  String get codigoProfesor => usuario.codigoUsuario;
  String get nombreCompleto => usuario.nombreCompleto;
  String? get correoElectronico => usuario.correoElectronico;
  bool get activo => usuario.activo;
  bool get visibleActivo => estado == 'activo';

  ProfesorAdmin copyWith({
    String? id,
    ModeloUsuario? usuario,
    String? especialidad,
    String? gradoAcademico,
    String? facultadId,
    String? facultadNombre,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? estado,
  }) {
    return ProfesorAdmin(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      especialidad: especialidad ?? this.especialidad,
      gradoAcademico: gradoAcademico ?? this.gradoAcademico,
      facultadId: facultadId ?? this.facultadId,
      facultadNombre: facultadNombre ?? this.facultadNombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      estado: estado ?? this.estado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuario.id,
      'especialidad': especialidad,
      'grado_academico': gradoAcademico,
      'facultad_id': facultadId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'estado': estado,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ProfesorAdmin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProfesorAdmin(id: $id, nombre: ${usuario.nombreCompleto}, estado: $estado)';
  }
}

class CursoProfesor {

  const CursoProfesor({
    required this.cursoId,
    required this.codigoCurso,
    required this.nombreCurso,
    required this.creditos,
    this.carreraNombre,
    this.estudiantesMatriculados = 0,
  });

  factory CursoProfesor.fromJson(Map<String, dynamic> json) {
    return CursoProfesor(
      cursoId: json['curso_id'] as String,
      codigoCurso: json['codigo_curso'] as String,
      nombreCurso: json['curso_nombre'] as String,
      creditos: (json['creditos'] as num).toInt(),
      carreraNombre: json['carrera'] as String?,
      estudiantesMatriculados: (json['estudiantes_matriculados'] as num?)?.toInt() ?? 0,
    );
  }
  final String cursoId;
  final String codigoCurso;
  final String nombreCurso;
  final int creditos;
  final String? carreraNombre;
  final int estudiantesMatriculados;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CursoProfesor && other.cursoId == cursoId;
  }

  @override
  int get hashCode => cursoId.hashCode;
}

class FacultadAdmin {

  const FacultadAdmin({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
  });

  factory FacultadAdmin.fromJson(Map<String, dynamic> json) {
    return FacultadAdmin(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }
  final String id;
  final String nombre;
  final String codigo;
  final String? descripcion;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FacultadAdmin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 