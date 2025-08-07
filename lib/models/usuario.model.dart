import 'package:flutter/foundation.dart';

@immutable
class ModeloUsuario {

  const ModeloUsuario({
    required this.id,
    required this.codigoUsuario,
    required this.nombreCompleto,
    this.correoElectronico,
    required this.rol,
    required this.activo,
    required this.fechaCreacion,
    this.perfil,
  });

  factory ModeloUsuario.fromJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] as String,
      codigoUsuario: json['codigo_usuario'] as String? 
        ?? json['codigo_profesor'] as String?
        ?? json['id'] as String, // fallback seguro
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      correoElectronico: json['correo_electronico'] as String?,
      rol: json['rol'] as String? ?? 'profesor',
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion']) ?? DateTime.now()
        : DateTime.now(),
    );
  }

  factory ModeloUsuario.fromEstudianteJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] as String,
      codigoUsuario: json['codigo_estudiante'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      correoElectronico: json['correo_electronico'] as String?,
      rol: 'estudiante',
      activo: (json['estado'] as String? ?? 'inactivo') == 'activo',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  factory ModeloUsuario.fromProfesorJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] as String,
      codigoUsuario: json['codigo_profesor'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      correoElectronico: json['correo_electronico'] as String?,
      rol: 'profesor',
      activo: (json['estado'] as String? ?? 'inactivo') == 'activo',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
  final String id;
  final String codigoUsuario;
  final String nombreCompleto;
  final String? correoElectronico;
  final String rol;
  final bool activo;
  final DateTime fechaCreacion;

  // Este campo se usará para almacenar el perfil específico (Estudiante, Profesor) después de cargarlo.
  final dynamic perfil;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_usuario': codigoUsuario,
      'nombre_completo': nombreCompleto,
      'correo_electronico': correoElectronico,
      'rol': rol,
      'activo': activo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  ModeloUsuario copyWith({
    String? id,
    String? codigoUsuario,
    String? nombreCompleto,
    String? correoElectronico,
    String? rol,
    bool? activo,
    DateTime? fechaCreacion,
    perfil,
  }) {
    return ModeloUsuario(
      id: id ?? this.id,
      codigoUsuario: codigoUsuario ?? this.codigoUsuario,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      perfil: perfil ?? this.perfil,
    );
  }

  // Getters para una fácil comprobación de roles
  bool get esEstudiante => rol == 'estudiante';
  bool get esProfesor => rol == 'profesor';
  bool get esAdmin => rol == 'admin';

  String get iniciales {
    if (nombreCompleto.isEmpty) {
      return '?';
    }
    final parts = nombreCompleto.trim().split(' ');
    if (parts.length > 1) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }
} 