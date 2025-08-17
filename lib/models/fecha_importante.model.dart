import 'package:flutter/foundation.dart';

/// Modelo para representar una Fecha Importante en UNAMAD
class ModeloFechaImportante {
  const ModeloFechaImportante({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaEvento,
    this.categoria,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ModeloFechaImportante.fromJson(Map<String, dynamic> json) {
    return ModeloFechaImportante(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      fechaEvento: json['fecha_evento'] != null 
          ? DateTime.tryParse(json['fecha_evento'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      categoria: json['categoria'] as String?,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null 
          ? DateTime.tryParse(json['fecha_actualizacion'].toString())
          : null,
    );
  }

  final int? id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEvento;
  final String? categoria;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_evento': fechaEvento.toIso8601String().substring(0, 10), // Solo fecha, sin hora
      'categoria': categoria,
    };
    
    // NO incluir id en toJson ya que es una columna IDENTITY
    // El id solo se usa para identificar la entidad, no para actualizaciones
    
    return json;
  }

  ModeloFechaImportante copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    DateTime? fechaEvento,
    String? categoria,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ModeloFechaImportante(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModeloFechaImportante && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ModeloFechaImportante(id: $id, titulo: $titulo, fechaEvento: $fechaEvento)';
  }

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(StringProperty('id', id.toString()))
      ..add(StringProperty('titulo', titulo))
      ..add(StringProperty('descripcion', descripcion))
      ..add(StringProperty('fechaEvento', fechaEvento.toIso8601String()))
      ..add(StringProperty('categoria', categoria));
  }
}
