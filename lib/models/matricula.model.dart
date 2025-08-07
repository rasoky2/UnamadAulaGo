/// Modelo para representar una Matrícula en UNAMAD
class ModeloMatricula {

  const ModeloMatricula({
    required this.id,
    required this.estudianteId,
    this.cursoId,
    required this.periodoAcademicoId,
    this.fechaMatricula,
    this.estado = 'matriculado',
    this.notaFinal,
    this.fechaRetiro,
    this.estudianteNombre,
    this.estudianteCorreo,
    this.estudianteCodigo,
    this.cursoNombre,
    this.cursoCodigo,
    this.profesorNombre,
    this.periodoNombre,
  });

  factory ModeloMatricula.fromJson(Map<String, dynamic> json) {
    return ModeloMatricula(
      id: json['id'] as String,
      estudianteId: json['estudiante_id'] as String,
      cursoId: json['curso_id'] as String?,
      periodoAcademicoId: json['periodo_academico_id'] as String,
      fechaMatricula: json['fecha_matricula'] != null ? DateTime.parse(json['fecha_matricula']) : null,
      estado: json['estado'] as String? ?? 'matriculado',
      notaFinal: (json['nota_final'] as num?)?.toDouble(),
      fechaRetiro: json['fecha_retiro'] != null ? DateTime.parse(json['fecha_retiro']) : null,
      estudianteNombre: json['estudiantes']?['nombre_completo'] as String?,
      estudianteCorreo: json['estudiantes']?['correo_electronico'] as String?,
      estudianteCodigo: json['estudiantes']?['codigo_estudiante'] as String?,
      cursoNombre: json['cursos']?['nombre'] as String?,
      cursoCodigo: json['cursos']?['codigo_curso'] as String?,
      profesorNombre: json['cursos']?['profesores']?['nombre_completo'] as String?,
      periodoNombre: json['periodos_academicos']?['nombre'] as String?,
    );
  }
  final String id;
  final String estudianteId;
  final String? cursoId; // Solo cursoId
  final String periodoAcademicoId;
  final DateTime? fechaMatricula;
  final String estado;
  final double? notaFinal;
  final DateTime? fechaRetiro;

  // Datos relacionados del estudiante
  final String? estudianteNombre;
  final String? estudianteCorreo;
  final String? estudianteCodigo;

  // Datos relacionados del curso
  final String? cursoNombre;
  final String? cursoCodigo;
  final String? profesorNombre;

  // Datos del período académico
  final String? periodoNombre;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudiante_id': estudianteId,
      'curso_id': cursoId,
      'periodo_academico_id': periodoAcademicoId,
      'fecha_matricula': fechaMatricula?.toIso8601String(),
      'estado': estado,
      'nota_final': notaFinal,
      'fecha_retiro': fechaRetiro?.toIso8601String(),
    };
  }
}

/// Modelo para formulario de nueva matrícula
class FormularioMatricula {

  const FormularioMatricula({
    required this.estudianteId,
    this.cursoId,
    required this.periodoAcademicoId,
    this.estado = 'matriculado',
  });
  final String estudianteId;
  final String? cursoId;
  final String periodoAcademicoId;
  final String estado;

  Map<String, dynamic> toJson() {
    return {
      'estudiante_id': estudianteId,
      'curso_id': cursoId,
      'periodo_academico_id': periodoAcademicoId,
      'estado': estado,
      'fecha_matricula': DateTime.now().toIso8601String(),
    };
  }
}

/// Enum para filtros de estado de matrícula
enum FiltroEstadoMatricula {
  todos,
  matriculado,
  retirado,
  transferido,
}

/// Data class para el estado del provider de matrículas
class MatriculasAdminData {

  const MatriculasAdminData({
    this.matriculas = const [],
    this.cargando = false,
    this.error,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.totalMatriculas = 0,
    this.filtroEstado = FiltroEstadoMatricula.todos,
    this.filtroTexto = '',
  });
  final List<ModeloMatricula> matriculas;
  final bool cargando;
  final String? error;
  final int pagina;
  final int totalPaginas;
  final int totalMatriculas;
  final FiltroEstadoMatricula filtroEstado;
  final String filtroTexto;

  MatriculasAdminData copyWith({
    List<ModeloMatricula>? matriculas,
    bool? cargando,
    String? error,
    int? pagina,
    int? totalPaginas,
    int? totalMatriculas,
    FiltroEstadoMatricula? filtroEstado,
    String? filtroTexto,
  }) {
    return MatriculasAdminData(
      matriculas: matriculas ?? this.matriculas,
      cargando: cargando ?? this.cargando,
      error: error ?? this.error,
      pagina: pagina ?? this.pagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      totalMatriculas: totalMatriculas ?? this.totalMatriculas,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroTexto: filtroTexto ?? this.filtroTexto,
    );
  }
} 

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
    required this.gruposDisponibles,
  });

  factory CursoMatriculacion.fromJson(Map<String, dynamic> json) {
    final grupos = json['grupos_clase'] as List<dynamic>? ?? [];
    
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
      gruposDisponibles: grupos
          .map((g) => GrupoClaseMatriculacion.fromJson(g))
          .toList(),
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
  final List<GrupoClaseMatriculacion> gruposDisponibles;

  bool get tieneGruposDisponibles => gruposDisponibles.isNotEmpty;
  
  int get totalCuposDisponibles {
    return gruposDisponibles.fold<int>(0, (sum, grupo) {
      return sum + (grupo.cupoMaximo - grupo.estudiantesMatriculados);
    });
  }
}

/// Modelo para representar un grupo de clase disponible para matriculación
class GrupoClaseMatriculacion {

  const GrupoClaseMatriculacion({
    required this.id,
    required this.grupo,
    required this.cupoMaximo,
    required this.estudiantesMatriculados,
    this.aula,
    this.horario,
    this.profesorNombre,
    required this.periodoNombre,
    required this.periodoId,
  });

  factory GrupoClaseMatriculacion.fromJson(Map<String, dynamic> json) {
    return GrupoClaseMatriculacion(
      id: json['id'] as String,
      grupo: json['grupo'] as String,
      cupoMaximo: json['cupo_maximo'] as int? ?? 30,
      estudiantesMatriculados: json['estudiantes_matriculados'] as int? ?? 0,
      aula: json['aula'] as String?,
      horario: json['horario'] as Map<String, dynamic>?,
      profesorNombre: json['profesores']?['usuarios']?['nombre_completo'] as String?,
      periodoNombre: json['periodos_academicos']['nombre'] as String,
      periodoId: json['periodos_academicos']['id'] as String,
    );
  }
  final String id;
  final String grupo;
  final int cupoMaximo;
  final int estudiantesMatriculados;
  final String? aula;
  final Map<String, dynamic>? horario;
  final String? profesorNombre;
  final String periodoNombre;
  final String periodoId;

  int get cuposDisponibles => cupoMaximo - estudiantesMatriculados;
  bool get tieneCuposDisponibles => cuposDisponibles > 0;
  
  String get horarioFormateado {
    if (horario == null) {
      return 'No definido';
    }
    return horario.toString();
  }
}

/// Formulario para matriculación múltiple
class FormularioMatriculaMultiple {

  const FormularioMatriculaMultiple({
    required this.estudianteId,
    required this.cursosSeleccionados,
  });
  final String estudianteId;
  final List<SeleccionCursoGrupo> cursosSeleccionados;

  List<Map<String, dynamic>> toMatriculasJson() {
    return cursosSeleccionados.map((seleccion) => {
      'estudiante_id': estudianteId,
      'grupo_clase_id': seleccion.grupoClaseId,
      'periodo_academico_id': seleccion.periodoAcademicoId,
      'curso_id': seleccion.cursoId,
    }).toList();
  }
}

/// Modelo para representar la selección de un curso y su grupo
class SeleccionCursoGrupo {

  const SeleccionCursoGrupo({
    required this.cursoId,
    required this.cursoNombre,
    required this.grupoClaseId,
    required this.grupoNombre,
    required this.periodoAcademicoId,
  });
  final String cursoId;
  final String cursoNombre;
  final String grupoClaseId;
  final String grupoNombre;
  final String periodoAcademicoId;
} 