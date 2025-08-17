import 'package:flutter/foundation.dart';

/// Modelo para representar un Anuncio en UNAMAD
class ModeloAnuncio {
  const ModeloAnuncio({
    this.id,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ModeloAnuncio.fromJson(Map<String, dynamic> json) {
    return ModeloAnuncio(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null 
          ? DateTime.tryParse(json['fecha_actualizacion'].toString())
          : null,
    );
  }

  final int? id;
  final String titulo;
  final String contenido;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'titulo': titulo,
      'contenido': contenido,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
    
    // NO incluir id en toJson ya que es una columna IDENTITY
    // El id solo se usa para identificar la entidad, no para actualizaciones
    
    return json;
  }

  ModeloAnuncio copyWith({
    int? id,
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ModeloAnuncio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModeloAnuncio && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ModeloAnuncio(id: $id, titulo: $titulo)';
  }

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(StringProperty('id', id.toString()))
      ..add(StringProperty('titulo', titulo))
      ..add(StringProperty('contenido', contenido))
      ..add(StringProperty('fechaCreacion', fechaCreacion.toIso8601String()));
  }
}
