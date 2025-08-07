import 'package:flutter/foundation.dart';

/// Modelo para representar un examen
class ModeloExamen with Diagnosticable {

  const ModeloExamen({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaDisponible,
    required this.fechaLimite,
    this.estadoEntrega,
    this.calificacion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory ModeloExamen.fromJson(Map<String, dynamic> json) {
    return ModeloExamen(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaDisponible: DateTime.parse(json['fecha_disponible']),
      fechaLimite: DateTime.parse(json['fecha_limite'] as String),
      estadoEntrega: json['estado_entrega'] as String?,
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion'] as String),
    );
  }
  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaDisponible;
  final DateTime fechaLimite;
  final String? estadoEntrega;
  final double? calificacion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_disponible': fechaDisponible.toIso8601String(),
      'fecha_limite': fechaLimite.toIso8601String(),
      'estado_entrega': estadoEntrega,
      'calificacion': calificacion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModeloExamen &&
        other.id == id &&
        other.titulo == titulo &&
        other.descripcion == descripcion &&
        other.fechaDisponible == fechaDisponible &&
        other.fechaLimite == fechaLimite &&
        other.estadoEntrega == estadoEntrega &&
        other.calificacion == calificacion;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      titulo,
      descripcion,
      fechaDisponible,
      fechaLimite,
      estadoEntrega,
      calificacion,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(StringProperty('titulo', titulo))
      ..add(StringProperty('descripcion', descripcion))
      ..add(DiagnosticsProperty<DateTime>('fechaDisponible', fechaDisponible))
      ..add(DiagnosticsProperty<DateTime>('fechaLimite', fechaLimite))
      ..add(StringProperty('estadoEntrega', estadoEntrega))
      ..add(DoubleProperty('calificacion', calificacion))
      ..add(DiagnosticsProperty<DateTime>('fechaCreacion', fechaCreacion))
      ..add(DiagnosticsProperty<DateTime>(
          'fechaActualizacion', fechaActualizacion));
  }
}
