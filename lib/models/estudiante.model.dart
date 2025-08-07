/// Modelo principal que representa el perfil completo de un estudiante para la vista de administrador.
/// Mapea directamente con la tabla 'estudiantes' de Supabase.
class EstudianteAdmin {

  const EstudianteAdmin({
    required this.id,
    required this.codigoEstudiante,
    required this.nombreCompleto,
    this.correoElectronico,
    this.telefono,
    this.fechaNacimiento,
    this.direccion,
    this.carreraId,
    this.carreraNombre,
    this.semestreActual,
    this.estado = 'activo',
    this.rol = 'estudiante',
    this.fechaIngreso,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.usuarioId,
    this.estadisticas,
  });

  factory EstudianteAdmin.fromJson(Map<String, dynamic> json) {
    return EstudianteAdmin(
      id: json['id']?.toString() ?? '',
      codigoEstudiante: json['codigo_estudiante']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      correoElectronico: json['correo_electronico']?.toString(),
      telefono: json['telefono']?.toString(),
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'].toString())
          : null,
      direccion: json['direccion']?.toString(),
      carreraId: json['carrera_id']?.toString(),
      carreraNombre: json['carrera_nombre']?.toString(),
      semestreActual: json['semestre_actual'] as int?,
      estado: json['estado']?.toString() ?? 'activo',
      rol: json['rol']?.toString() ?? 'estudiante',
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'].toString())
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'].toString())
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'].toString())
          : null,
      usuarioId: json['usuario_id']?.toString(),
      estadisticas: json['estadisticas'] != null
          ? ModeloEstadisticasEstudiante.fromJson(json['estadisticas'])
          : null,
    );
  }
  final String id;
  final String codigoEstudiante;
  final String nombreCompleto;
  final String? correoElectronico;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final String? carreraId;
  final String? carreraNombre;
  final int? semestreActual;
  final String estado; // 'activo' o 'inactivo'
  final String rol; // 'estudiante'
  final DateTime? fechaIngreso;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final String? usuarioId;
  final ModeloEstadisticasEstudiante? estadisticas;

  // Getters para compatibilidad con el código existente
  bool get activo => estado == 'activo';
  String get iniciales {
    final nombres = nombreCompleto.split(' ');
    if (nombres.length >= 2) {
      return '${nombres[0][0]}${nombres[1][0]}'.toUpperCase();
    }
    return nombres.isNotEmpty ? nombres[0][0].toUpperCase() : '?';
  }

  EstudianteAdmin copyWith({
    String? id,
    String? codigoEstudiante,
    String? nombreCompleto,
    String? correoElectronico,
    String? telefono,
    DateTime? fechaNacimiento,
    String? direccion,
    String? carreraId,
    String? carreraNombre,
    int? semestreActual,
    String? estado,
    String? rol,
    DateTime? fechaIngreso,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? usuarioId,
    ModeloEstadisticasEstudiante? estadisticas,
  }) {
    return EstudianteAdmin(
      id: id ?? this.id,
      codigoEstudiante: codigoEstudiante ?? this.codigoEstudiante,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
      carreraId: carreraId ?? this.carreraId,
      carreraNombre: carreraNombre ?? this.carreraNombre,
      semestreActual: semestreActual ?? this.semestreActual,
      estado: estado ?? this.estado,
      rol: rol ?? this.rol,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      usuarioId: usuarioId ?? this.usuarioId,
      estadisticas: estadisticas ?? this.estadisticas,
    );
  }
}

/// Modelo para estadísticas del estudiante.
/// Se mantiene en el mismo archivo para cohesión.
class ModeloEstadisticasEstudiante {

  const ModeloEstadisticasEstudiante({
    this.cursosActivos = 0,
    this.creditosTotales = 0,
    this.promedioGeneral = 0.0,
    this.porcentajeAsistencia = 0.0,
    this.tareasCompletadas = 0,
    this.tareasPendientes = 0,
    this.forosParticipados = 0,
  });

  factory ModeloEstadisticasEstudiante.fromJson(Map<String, dynamic> json) {
    return ModeloEstadisticasEstudiante(
      cursosActivos: json['cursos_activos'] as int? ?? 0,
      creditosTotales: json['creditos_totales'] as int? ?? 0,
      promedioGeneral: (json['promedio_general'] as num?)?.toDouble() ?? 0.0,
      porcentajeAsistencia: (json['porcentaje_asistencia'] as num?)?.toDouble() ?? 0.0,
      tareasCompletadas: json['tareas_completadas'] as int? ?? 0,
      tareasPendientes: json['tareas_pendientes'] as int? ?? 0,
      forosParticipados: json['foros_participados'] as int? ?? 0,
    );
  }
  final int cursosActivos;
  final int creditosTotales;
  final double promedioGeneral;
  final double porcentajeAsistencia;
  final int tareasCompletadas;
  final int tareasPendientes;
  final int forosParticipados;

  Map<String, dynamic> toJson() {
    return {
      'cursos_activos': cursosActivos,
      'creditos_totales': creditosTotales,
      'promedio_general': promedioGeneral,
      'porcentaje_asistencia': porcentajeAsistencia,
      'tareas_completadas': tareasCompletadas,
      'tareas_pendientes': tareasPendientes,
      'foros_participados': forosParticipados,
    };
  }
}

/// Enum para los filtros de estado en la pantalla de administración.
enum FiltroEstadoEstudiante { todos, activos, inactivos }

/// Clase de datos inmutable para el estado del StateNotifier de EstudiantesAdmin.
class EstudiantesAdminData {

  const EstudiantesAdminData({
    this.estudiantes = const [],
    this.cargando = true,
    this.error,
    this.pagina = 1,
    this.totalPaginas = 1,
    this.totalEstudiantes = 0,
    this.filtroTexto,
    this.filtroEstado = FiltroEstadoEstudiante.todos,
    this.filtroCarrera,
  });
  final List<EstudianteAdmin> estudiantes;
  final bool cargando;
  final String? error;
  final int pagina;
  final int totalPaginas;
  final int totalEstudiantes;
  final String? filtroTexto;
  final FiltroEstadoEstudiante filtroEstado;
  final String? filtroCarrera;

  EstudiantesAdminData copyWith({
    List<EstudianteAdmin>? estudiantes,
    bool? cargando,
    String? error,
    int? pagina,
    int? totalPaginas,
    int? totalEstudiantes,
    String? filtroTexto,
    FiltroEstadoEstudiante? filtroEstado,
    String? filtroCarrera,
  }) {
    return EstudiantesAdminData(
      estudiantes: estudiantes ?? this.estudiantes,
      cargando: cargando ?? this.cargando,
      error: error, // Se resetea intencionalmente si no se pasa uno nuevo o es null
      pagina: pagina ?? this.pagina,
      totalPaginas: totalPaginas ?? this.totalPaginas,
      totalEstudiantes: totalEstudiantes ?? this.totalEstudiantes,
      filtroTexto: filtroTexto ?? this.filtroTexto,
      filtroEstado: filtroEstado ?? this.filtroEstado,
      filtroCarrera: filtroCarrera ?? this.filtroCarrera,
    );
  }

  // Método para crear un estado limpio manteniendo algunos valores
  EstudiantesAdminData limpiarEstado({
    bool mantenerFiltros = false,
  }) {
    return EstudiantesAdminData(
      filtroTexto: mantenerFiltros ? filtroTexto : null,
      filtroEstado: mantenerFiltros ? filtroEstado : FiltroEstadoEstudiante.todos,
      filtroCarrera: mantenerFiltros ? filtroCarrera : null,
    );
  }
}

/// Modelo para manejar los datos del formulario de creación/edición de estudiantes.
class FormularioEstudiante {

  const FormularioEstudiante({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.telefono,
    required this.codigoEstudiante,
    this.carreraId,
    this.semestreActual,
    this.activo = true,
    this.fechaNacimiento,
    this.direccion,
  });

  factory FormularioEstudiante.fromEstudiante(EstudianteAdmin estudiante) {
    final nombresSeparados = estudiante.nombreCompleto.split(' ');
    return FormularioEstudiante(
      id: estudiante.id,
      nombres: nombresSeparados.first,
      apellidos: nombresSeparados.skip(1).join(' '),
      email: estudiante.correoElectronico ?? '',
      telefono: estudiante.telefono,
      codigoEstudiante: estudiante.codigoEstudiante,
      carreraId: estudiante.carreraId,
      semestreActual: estudiante.semestreActual?.toString(),
      activo: estudiante.activo,
      fechaNacimiento: estudiante.fechaNacimiento,
      direccion: estudiante.direccion,
    );
  }
  final String? id;
  final String nombres;
  final String apellidos;
  final String email;
  final String? telefono;
  final String codigoEstudiante;
  final String? carreraId;
  final String? semestreActual;
  final bool activo;
  final DateTime? fechaNacimiento;
  final String? direccion;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': '$nombres $apellidos'.trim(),
      'correo_electronico': email,
      'telefono': telefono,
      'codigo_estudiante': codigoEstudiante,
      'carrera_id': carreraId,
      'semestre_actual': semestreActual != null ? int.tryParse(semestreActual!) : null,
      'estado': activo ? 'activo' : 'inactivo',
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'direccion': direccion,
      'rol': 'estudiante',
    };
  }

  FormularioEstudiante copyWith({
    String? id,
    String? nombres,
    String? apellidos,
    String? email,
    String? telefono,
    String? codigoEstudiante,
    String? carreraId,
    String? semestreActual,
    bool? activo,
    DateTime? fechaNacimiento,
    String? direccion,
  }) {
    return FormularioEstudiante(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      codigoEstudiante: codigoEstudiante ?? this.codigoEstudiante,
      carreraId: carreraId ?? this.carreraId,
      semestreActual: semestreActual ?? this.semestreActual,
      activo: activo ?? this.activo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
    );
  }
} 