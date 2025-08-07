import 'package:flutter/foundation.dart';

/// Modelo para representar una Carrera en UNAMAD
class ModeloCarrera {

  const ModeloCarrera({
    required this.id,
    required this.facultadId,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.duracionSemestres,
    this.directorNombre,
    this.directorEmail,
    required this.fechaCreacion,
  });

  factory ModeloCarrera.fromJson(Map<String, dynamic> json) {
    return ModeloCarrera(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      facultadId: json['facultad_id'] as String? ?? '',
      duracionSemestres: json['duracion_semestres'] is int ? json['duracion_semestres'] as int : int.tryParse(json['duracion_semestres']?.toString() ?? '') ?? 0,
      directorNombre: json['director_nombre'] as String? ?? '',
      directorEmail: json['director_email'] as String? ?? '',
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
  final String id;
  final String facultadId;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final int duracionSemestres;
  final String? directorNombre;
  final String? directorEmail;
  final DateTime fechaCreacion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facultad_id': facultadId,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'duracion_semestres': duracionSemestres,
      'director_nombre': directorNombre,
      'director_email': directorEmail,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  ModeloCarrera copyWith({
    String? id,
    String? facultadId,
    String? nombre,
    String? codigo,
    String? descripcion,
    int? duracionSemestres,
    String? directorNombre,
    String? directorEmail,
    DateTime? fechaCreacion,
  }) {
    return ModeloCarrera(
      id: id ?? this.id,
      facultadId: facultadId ?? this.facultadId,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      duracionSemestres: duracionSemestres ?? this.duracionSemestres,
      directorNombre: directorNombre ?? this.directorNombre,
      directorEmail: directorEmail ?? this.directorEmail,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ModeloCarrera && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ModeloCarrera(id: $id, nombre: $nombre, codigo: $codigo)';
  }

  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(StringProperty('id', id))
      ..add(StringProperty('facultadId', facultadId))
      ..add(StringProperty('nombre', nombre))
      ..add(StringProperty('codigo', codigo))
      ..add(StringProperty('descripcion', descripcion))
      ..add(IntProperty('duracionSemestres', duracionSemestres))
      ..add(StringProperty('directorNombre', directorNombre))
      ..add(StringProperty('directorEmail', directorEmail))
      ..add(DiagnosticsProperty<DateTime>('fechaCreacion', fechaCreacion));
  }
}

// Modelo para datos de la pantalla de administración de carreras
class CarrerasAdminData {

  const CarrerasAdminData({
    this.carreras = const [],
    this.cargando = false,
    this.error,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.totalCarreras = 0,
    this.filtroTexto,
    this.filtroFacultad,
  });
  final List<ModeloCarrera> carreras;
  final bool cargando;
  final String? error;
  final int pagina;
  final int totalPaginas;
  final int totalCarreras;
  final String? filtroTexto;
  final String? filtroFacultad;

  CarrerasAdminData copyWith({
    List<ModeloCarrera>? carreras,
    bool? cargando,
    String? error,
    int? pagina,
    int? totalPaginas,
    int? totalCarreras,
    String? filtroTexto,
    String? filtroFacultad,
  }) {
    return CarrerasAdminData(
      carreras: carreras ?? this.carreras,
      cargando: cargando ?? this.cargando,
      error: error,
      pagina: pagina ?? this.pagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      totalCarreras: totalCarreras ?? this.totalCarreras,
      filtroTexto: filtroTexto?.isEmpty == true ? null : (filtroTexto ?? this.filtroTexto),
      filtroFacultad: filtroFacultad?.isEmpty == true ? null : (filtroFacultad ?? this.filtroFacultad),
    );
  }

  CarrerasAdminData limpiarEstado({bool mantenerCarreras = false}) {
    return CarrerasAdminData(
      carreras: mantenerCarreras ? carreras : [],
      totalCarreras: mantenerCarreras ? totalCarreras : 0,
    );
  }
}

// Modelo para crear/editar carreras
class CrearEditarCarreraData {

  const CrearEditarCarreraData({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.facultadId,
    required this.duracionSemestres,
    this.directorNombre,
    this.directorEmail,
  });
  final String? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final String facultadId;
  final int duracionSemestres;
  final String? directorNombre;
  final String? directorEmail;

  Map<String, dynamic> toJson() {
    final data = {
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'facultad_id': facultadId,
      'duracion_semestres': duracionSemestres,
      'director_nombre': directorNombre,
      'director_email': directorEmail,
    };

    if (id != null) {
      data['id'] = id!;
    }

    return data;
  }

  CrearEditarCarreraData copyWith({
    String? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    String? facultadId,
    int? duracionSemestres,
    String? directorNombre,
    String? directorEmail,
  }) {
    return CrearEditarCarreraData(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      facultadId: facultadId ?? this.facultadId,
      duracionSemestres: duracionSemestres ?? this.duracionSemestres,
      directorNombre: directorNombre ?? this.directorNombre,
      directorEmail: directorEmail ?? this.directorEmail,
    );
  }

  bool get esValido {
    return nombre.trim().isNotEmpty &&
           codigo.trim().isNotEmpty &&
           facultadId.isNotEmpty &&
           duracionSemestres > 0;
  }
} 