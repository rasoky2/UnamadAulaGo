class EstadisticasAdmin {

  const EstadisticasAdmin({
    this.totalEstudiantes = 0,
    this.totalProfesores = 0,
    this.totalCursos = 0,
    this.totalTareas = 0,
    this.totalExamenes = 0,
    this.totalAnuncios = 0,
    this.totalFechasImportantes = 0,
    this.estudiantesActivos = 0,
    this.profesoresActivos = 0,
    this.cursosActivos = 0,
    this.porcentajeActivosHoy = 0.0,
    this.ultimaActividad,
    this.alertasSistema = const [],
    this.actividadesRecientes = const [],
    this.cargando = false,
    this.error,
  });
  final int totalEstudiantes;
  final int totalProfesores;
  final int totalCursos;
  final int totalTareas;
  final int totalExamenes;
  final int totalAnuncios;
  final int totalFechasImportantes;
  final int estudiantesActivos;
  final int profesoresActivos;
  final int cursosActivos;
  final double porcentajeActivosHoy;
  final DateTime? ultimaActividad;
  final List<AlertaSistema> alertasSistema;
  final List<ActividadReciente> actividadesRecientes;
  final bool cargando;
  final String? error;

  EstadisticasAdmin copyWith({
    int? totalEstudiantes,
    int? totalProfesores,
    int? totalCursos,
    int? totalTareas,
    int? totalExamenes,
    int? totalAnuncios,
    int? totalFechasImportantes,
    int? estudiantesActivos,
    int? profesoresActivos,
    int? cursosActivos,
    double? porcentajeActivosHoy,
    DateTime? ultimaActividad,
    List<AlertaSistema>? alertasSistema,
    List<ActividadReciente>? actividadesRecientes,
    bool? cargando,
    String? error,
  }) {
    return EstadisticasAdmin(
      totalEstudiantes: totalEstudiantes ?? this.totalEstudiantes,
      totalProfesores: totalProfesores ?? this.totalProfesores,
      totalCursos: totalCursos ?? this.totalCursos,
      totalTareas: totalTareas ?? this.totalTareas,
      totalExamenes: totalExamenes ?? this.totalExamenes,
      totalAnuncios: totalAnuncios ?? this.totalAnuncios,
      totalFechasImportantes: totalFechasImportantes ?? this.totalFechasImportantes,
      estudiantesActivos: estudiantesActivos ?? this.estudiantesActivos,
      profesoresActivos: profesoresActivos ?? this.profesoresActivos,
      cursosActivos: cursosActivos ?? this.cursosActivos,
      porcentajeActivosHoy: porcentajeActivosHoy ?? this.porcentajeActivosHoy,
      ultimaActividad: ultimaActividad ?? this.ultimaActividad,
      alertasSistema: alertasSistema ?? this.alertasSistema,
      actividadesRecientes: actividadesRecientes ?? this.actividadesRecientes,
      cargando: cargando ?? this.cargando,
      error: error ?? this.error,
    );
  }
}

class AlertaSistema {

  const AlertaSistema({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.fechaCreacion,
    this.leida = false,
  });
  final String id;
  final String titulo;
  final String descripcion;
  final TipoAlerta tipo;
  final DateTime fechaCreacion;
  final bool leida;
}

enum TipoAlerta {
  info,
  warning,
  error,
  success,
}

class ActividadReciente {

  const ActividadReciente({
    required this.id,
    required this.accion,
    required this.usuario,
    required this.fecha,
    required this.detalles,
  });
  final String id;
  final String accion;
  final String usuario;
  final DateTime fecha;
  final String detalles;
}

class ConfiguracionSistema {

  const ConfiguracionSistema({
    required this.periodoAcademico,
    required this.modoMantenimiento,
    required this.respaldoAutomatico,
    required this.ultimoRespaldo,
  });
  final String periodoAcademico;
  final bool modoMantenimiento;
  final bool respaldoAutomatico;
  final DateTime ultimoRespaldo;
} 