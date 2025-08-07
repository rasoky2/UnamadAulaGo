class EstadisticasAdmin {

  const EstadisticasAdmin({
    this.totalEstudiantes = 0,
    this.totalProfesores = 0,
    this.totalCursos = 0,
    this.porcentajeActivosHoy = 0.0,
    this.cargando = false,
    this.error,
  });
  final int totalEstudiantes;
  final int totalProfesores;
  final int totalCursos;
  final double porcentajeActivosHoy;
  final bool cargando;
  final String? error;

  EstadisticasAdmin copyWith({
    int? totalEstudiantes,
    int? totalProfesores,
    int? totalCursos,
    double? porcentajeActivosHoy,
    bool? cargando,
    String? error,
  }) {
    return EstadisticasAdmin(
      totalEstudiantes: totalEstudiantes ?? this.totalEstudiantes,
      totalProfesores: totalProfesores ?? this.totalProfesores,
      totalCursos: totalCursos ?? this.totalCursos,
      porcentajeActivosHoy: porcentajeActivosHoy ?? this.porcentajeActivosHoy,
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