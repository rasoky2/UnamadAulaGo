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
    this.fotoPerfilUrl,
  });

  factory ModeloUsuario.fromJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      codigoUsuario: json['codigo_usuario'] as String? 
        ?? json['codigo_profesor'] as String?
        ?? json['id'].toString(),
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      correoElectronico: json['correo_electronico'] as String?,
      rol: json['rol'] as String? ?? 'profesor',
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now()
        : DateTime.now(),
      fotoPerfilUrl: json['foto_perfil_url']?.toString(),
    );
  }

  factory ModeloUsuario.fromEstudianteJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      codigoUsuario: json['codigo_estudiante']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      correoElectronico: json['correo_electronico']?.toString(),
      rol: 'estudiante',
      activo: (json['estado']?.toString() ?? 'activo') == 'activo',
      fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now()
        : DateTime.now(),
      fotoPerfilUrl: json['foto_perfil_url']?.toString(),
    );
  }

  factory ModeloUsuario.fromProfesorJson(Map<String, dynamic> json) {
    return ModeloUsuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      codigoUsuario: json['codigo_profesor']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      correoElectronico: json['correo_electronico']?.toString(),
      rol: 'profesor',
      activo: (json['estado']?.toString() ?? 'activo') == 'activo',
      fechaCreacion: json['fecha_creacion'] != null
        ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now()
        : DateTime.now(),
      fotoPerfilUrl: json['foto_perfil_url']?.toString(),
    );
  }

  final int id;
  final String codigoUsuario;
  final String nombreCompleto;
  final String? correoElectronico;
  final String rol;
  final bool activo;
  final DateTime fechaCreacion;
  final dynamic perfil;
  final String? fotoPerfilUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_usuario': codigoUsuario,
      'nombre_completo': nombreCompleto,
      'correo_electronico': correoElectronico,
      'rol': rol,
      'activo': activo,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'foto_perfil_url': fotoPerfilUrl,
    };
  }

  ModeloUsuario copyWith({
    int? id,
    String? codigoUsuario,
    String? nombreCompleto,
    String? correoElectronico,
    String? rol,
    bool? activo,
    DateTime? fechaCreacion,
    perfil,
    String? fotoPerfilUrl,
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
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
    );
  }

  bool get esEstudiante => rol == 'estudiante';
  bool get esProfesor => rol == 'profesor';
  bool get esAdmin => rol == 'admin';

  String get iniciales {
    if (nombreCompleto.isEmpty) {
      return '?';
    }
    final parts = nombreCompleto.trim().split(' ');
    if (parts.length > 1) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }
} 