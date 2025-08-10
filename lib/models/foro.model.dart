import 'package:json_annotation/json_annotation.dart';


@JsonSerializable()
class Foro {

  factory Foro.fromJson(Map<String, dynamic> json) {
    return Foro(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id'].toString()) ?? 0,
      unidadId: json['unidad_id'] is int ? json['unidad_id'] : int.tryParse(json['unidad_id']?.toString() ?? ''),
      creadoPor: json['creado_por'] is int ? json['creado_por'] : int.tryParse(json['creado_por']?.toString() ?? ''),
      fechaCreacion: DateTime.parse(json['fecha_creacion'].toString()),
      estado: json['estado'] as String,
    );
  }

  const Foro({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.cursoId,
    this.unidadId,
    this.creadoPor,
    required this.fechaCreacion,
    required this.estado,
  });
  final int id;
  final String titulo;
  final String? descripcion;
  final int cursoId;
  final int? unidadId;
  final int? creadoPor;
  final DateTime fechaCreacion;
  final String estado;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'curso_id': cursoId,
      'unidad_id': unidadId,
      'creado_por': creadoPor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'estado': estado,
    };
  }
}

@JsonSerializable()
class PublicacionForo {

  factory PublicacionForo.fromJson(Map<String, dynamic> json) {
    return PublicacionForo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      foroId: json['foro_id'] is int ? json['foro_id'] : int.tryParse(json['foro_id'].toString()) ?? 0,
      titulo: json['titulo'] as String,
      contenido: json['contenido'] as String,
      autorId: json['autor_id'] is int ? json['autor_id'] : int.tryParse(json['autor_id'].toString()) ?? 0,
      tipoAutor: json['tipo_autor'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'].toString()),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'].toString()),
      estado: json['estado'] as String,
    );
  }

  const PublicacionForo({
    required this.id,
    required this.foroId,
    required this.titulo,
    required this.contenido,
    required this.autorId,
    required this.tipoAutor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.estado,
  });
  final int id;
  final int foroId;
  final String titulo;
  final String contenido;
  final int autorId;
  final String tipoAutor;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String estado;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foro_id': foroId,
      'titulo': titulo,
      'contenido': contenido,
      'autor_id': autorId,
      'tipo_autor': tipoAutor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'estado': estado,
    };
  }
}

@JsonSerializable()
class ComentarioForo {

  factory ComentarioForo.fromJson(Map<String, dynamic> json) {
    return ComentarioForo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      publicacionId: json['publicacion_id'] is int ? json['publicacion_id'] : int.tryParse(json['publicacion_id'].toString()) ?? 0,
      contenido: json['contenido'] as String,
      autorId: json['autor_id'] is int ? json['autor_id'] : int.tryParse(json['autor_id'].toString()) ?? 0,
      tipoAutor: json['tipo_autor'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'].toString()),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'].toString()),
      estado: json['estado'] as String,
    );
  }

  const ComentarioForo({
    required this.id,
    required this.publicacionId,
    required this.contenido,
    required this.autorId,
    required this.tipoAutor,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.estado,
  });
  final int id;
  final int publicacionId;
  final String contenido;
  final int autorId;
  final String tipoAutor;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String estado;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicacion_id': publicacionId,
      'contenido': contenido,
      'autor_id': autorId,
      'tipo_autor': tipoAutor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'estado': estado,
    };
  }
} 