/// Modelo para representar un curso disponible para matriculación
class CursoMatriculacion {

  const CursoMatriculacion({
    required this.id,
    required this.codigoCurso,
    required this.nombre,
    this.descripcion,
    required this.creditos,
    this.semestreRecomendado,
    required this.esObligatorio,
    required this.carreraNombre,
    required this.carreraId,
  });

  factory CursoMatriculacion.fromJson(Map<String, dynamic> json) {
    return CursoMatriculacion(
      id: json['id'] as String,
      codigoCurso: json['codigo_curso'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      creditos: json['creditos'] as int? ?? 3,
      semestreRecomendado: json['semestre_recomendado'] as int?,
      esObligatorio: json['es_obligatorio'] as bool? ?? true,
      carreraNombre: json['carreras']['nombre'] as String,
      carreraId: json['carreras']['id'] as String,
    );
  }
  final String id;
  final String codigoCurso;
  final String nombre;
  final String? descripcion;
  final int creditos;
  final int? semestreRecomendado;
  final bool esObligatorio;
  final String carreraNombre;
  final String carreraId;
}

/// Formulario para matriculación múltiple
class FormularioMatriculaMultiple {

  const FormularioMatriculaMultiple({
    required this.estudianteId,
    required this.cursosSeleccionados,
  });
  final String estudianteId;
  final List<SeleccionCurso> cursosSeleccionados;

  List<Map<String, dynamic>> toMatriculasJson() {
    return cursosSeleccionados.map((seleccion) => {
      'estudiante_id': estudianteId,
      'periodo_academico_id': seleccion.periodoAcademicoId,
      'curso_id': seleccion.cursoId,
    }).toList();
  }
}

/// Modelo para representar la selección de un curso
class SeleccionCurso {

  const SeleccionCurso({
    required this.cursoId,
    required this.cursoNombre,
    required this.periodoAcademicoId,
  });
  final String cursoId;
  final String cursoNombre;
  final String periodoAcademicoId;
}

/// Modelo para la tabla de matrículas
class ModeloMatricula {

  const ModeloMatricula({
    required this.id,
    required this.estudianteId,
    required this.periodoAcademicoId,
    this.cursoId,
    this.estado = 'matriculado',
    this.fechaMatricula,
    this.notaFinal,
    this.fechaRetiro,
    this.estudianteNombre,
    this.estudianteCodigo,
    this.cursoNombre,
    this.cursoCodigo,
    this.profesorNombre,
    this.periodoNombre,
    this.estudianteFotoUrl,
    this.carreraId,
  });

  factory ModeloMatricula.fromJson(Map<String, dynamic> json) {
    final estudiante = json['estudiantes'] ?? {};
    final curso = json['cursos'] ?? {};
    final profesor = curso['profesores'] ?? {};
    final periodo = json['periodos_academicos'] ?? {};
    return ModeloMatricula(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      estudianteId: json['estudiante_id'] is int ? json['estudiante_id'] : int.tryParse(json['estudiante_id'].toString()) ?? 0,
      periodoAcademicoId: json['periodo_academico_id'] is int ? json['periodo_academico_id'] : int.tryParse(json['periodo_academico_id'].toString()) ?? 0,
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id']?.toString() ?? ''),
      estado: json['estado'] as String? ?? 'matriculado',
      fechaMatricula: json['fecha_matricula'] != null ? DateTime.tryParse(json['fecha_matricula'].toString()) : null,
      notaFinal: json['nota_final'] != null ? (json['nota_final'] as num).toDouble() : null,
      fechaRetiro: json['fecha_retiro'] != null ? DateTime.tryParse(json['fecha_retiro'].toString()) : null,
      estudianteNombre: estudiante['nombre_completo'] as String?,
      estudianteCodigo: estudiante['codigo_estudiante'] as String?,
      cursoNombre: curso['nombre'] as String?,
      cursoCodigo: curso['codigo_curso'] as String?,
      profesorNombre: profesor['nombre_completo'] as String?,
      periodoNombre: periodo['nombre'] as String?,
      estudianteFotoUrl: estudiante['foto_perfil_url']?.toString(),
      carreraId: (curso['carrera_id'] as num?)?.toInt(),
    );
  }
  final int id;
  final int estudianteId;
  final int periodoAcademicoId;
  final int? cursoId;
  final String estado;
  final DateTime? fechaMatricula;
  final double? notaFinal;
  final DateTime? fechaRetiro;

  // Campos extendidos para UI/admin
  final String? estudianteNombre;
  final String? estudianteCodigo;
  final String? cursoNombre;
  final String? cursoCodigo;
  final String? profesorNombre;
  final String? periodoNombre;
  final String? estudianteFotoUrl;
  final int? carreraId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudiante_id': estudianteId,
      'periodo_academico_id': periodoAcademicoId,
      'curso_id': cursoId,
      'estado': estado,
      'fecha_matricula': fechaMatricula?.toIso8601String(),
      'nota_final': notaFinal,
      'fecha_retiro': fechaRetiro?.toIso8601String(),
    };
  }
}

enum FiltroEstadoMatricula { todos, matriculado, retirado, transferido }

class MatriculasAdminData {

  const MatriculasAdminData({
    this.cargando = false,
    this.error,
    this.matriculas = const [],
    this.totalPaginas = 1,
    this.pagina = 1,
    this.totalMatriculas = 0,
    this.filtroEstado = FiltroEstadoMatricula.todos,
    this.filtroTexto = '',
  });
  final bool cargando;
  final String? error;
  final List<ModeloMatricula> matriculas;
  final int totalPaginas;
  final int pagina;
  final int totalMatriculas;
  final FiltroEstadoMatricula filtroEstado;
  final String filtroTexto;

  MatriculasAdminData copyWith({
    bool? cargando,
    String? error,
    List<ModeloMatricula>? matriculas,
    int? totalPaginas,
    int? pagina,
    int? totalMatriculas,
    FiltroEstadoMatricula? filtroEstado,
    String? filtroTexto,
  }) {
    return MatriculasAdminData(
      cargando: cargando ?? this.cargando,
      error: error ?? this.error,
      matriculas: matriculas ?? this.matriculas,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      pagina: pagina ?? this.pagina,
      totalMatriculas: totalMatriculas ?? this.totalMatriculas,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroTexto: filtroTexto ?? this.filtroTexto,
    );
  }
}

class FormularioMatricula {

  const FormularioMatricula({
    required this.estudianteId,
    required this.cursoId,
    required this.periodoAcademicoId,
  });
  final String estudianteId;
  final String cursoId;
  final String periodoAcademicoId;

  Map<String, dynamic> toJson() => {
    'estudiante_id': estudianteId,
    'curso_id': cursoId,
    'periodo_academico_id': periodoAcademicoId,
  };
} 