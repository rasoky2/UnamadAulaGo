import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/facultad.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/models/usuario.model.dart';

class ModeloCurso {
  const ModeloCurso({
    required this.id,
    required this.carreraId,
    required this.codigoCurso,
    required this.nombre,
    this.descripcion,
    this.creditos = 3,
    this.horasTeoria = 2,
    this.horasPractica = 2,
    this.semestreRecomendado,
    this.esObligatorio = true,
    this.fechaCreacion,
    this.profesorId,
    this.totalUnidades,
    this.unidades = const [],
  });

  factory ModeloCurso.fromJson(Map<String, dynamic> json) {
    return ModeloCurso(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      carreraId: json['carrera_id'] is int ? json['carrera_id'] : int.tryParse(json['carrera_id'].toString()) ?? 0,
      codigoCurso: json['codigo_curso'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      creditos: json['creditos'] as int? ?? 3,
      horasTeoria: json['horas_teoria'] as int? ?? 2,
      horasPractica: json['horas_practica'] as int? ?? 2,
      semestreRecomendado: json['semestre_recomendado'] as int?,
      esObligatorio: json['es_obligatorio'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) : null,
      profesorId: json['profesor_id'] is int ? json['profesor_id'] : int.tryParse(json['profesor_id']?.toString() ?? ''),
      totalUnidades: json['total_unidades'] as int?,
      unidades: (json['unidades'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
  final int id;
  final int carreraId;
  final String codigoCurso;
  final String nombre;
  final String? descripcion;
  final int creditos;
  final int horasTeoria;
  final int horasPractica;
  final int? semestreRecomendado;
  final bool esObligatorio;
  final DateTime? fechaCreacion;
  final int? profesorId;
  final int? totalUnidades;
  final List<Map<String, dynamic>> unidades;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carrera_id': carreraId,
      'codigo_curso': codigoCurso,
      'nombre': nombre,
      'descripcion': descripcion,
      'creditos': creditos,
      'horas_teoria': horasTeoria,
      'horas_practica': horasPractica,
      'semestre_recomendado': semestreRecomendado,
      'es_obligatorio': esObligatorio,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'profesor_id': profesorId,
      'total_unidades': totalUnidades,
      'unidades': unidades,
    };
  }
}

/// Modelo extendido para mostrar información de curso con detalles adicionales
class ModeloCursoDetallado {

  const ModeloCursoDetallado({
    required this.curso,
    this.carrera,
    this.facultad,
    this.profesor,
    this.estudiantesMatriculados,
    this.tareas,
  });

  factory ModeloCursoDetallado.fromJson(Map<String, dynamic> json) {
    return ModeloCursoDetallado(
      curso: ModeloCurso.fromJson(json['curso'] ?? json),
      carrera: json['carrera'] != null 
          ? ModeloCarrera.fromJson(json['carrera']) 
          : null,
      facultad: json['facultad'] != null 
          ? ModeloFacultad.fromJson(json['facultad']) 
          : null,
      profesor: json['profesor'] != null 
          ? ModeloUsuario.fromJson(json['profesor']) 
          : null,
      estudiantesMatriculados: json['estudiantes_matriculados'] as int?,
      tareas: json['tareas'] != null
          ? (json['tareas'] as List)
              .map((t) => ModeloTarea.fromJson(t))
              .toList()
          : null,
    );
  }
  final ModeloCurso curso;
  final ModeloCarrera? carrera;
  final ModeloFacultad? facultad;
  final ModeloUsuario? profesor;
  final int? estudiantesMatriculados;
  final List<ModeloTarea>? tareas;

  Map<String, dynamic> toJson() {
    return {
      'curso': curso.toJson(),
      'carrera': carrera?.toJson(),
      'facultad': facultad?.toJson(),
      'profesor': profesor?.toJson(),
      'estudiantes_matriculados': estudiantesMatriculados,
      'tareas': tareas?.map((t) => t.toJson()).toList(),
    };
  }
} 