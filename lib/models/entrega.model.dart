enum EstadoEntrega {
  entregado,
  calificado,
  tarde,
  noEntregado,
}

String estadoEntregaToString(EstadoEntrega estado) {
  switch (estado) {
    case EstadoEntrega.entregado:
      return 'Entregado';
    case EstadoEntrega.calificado:
      return 'Calificado';
    case EstadoEntrega.tarde:
      return 'Tarde';
    case EstadoEntrega.noEntregado:
      return 'No entregado';
  }
}

EstadoEntrega estadoEntregaFromString(String? estado) {
  switch (estado) {
    case 'Entregado':
      return EstadoEntrega.entregado;
    case 'Calificado':
      return EstadoEntrega.calificado;
    case 'Tarde':
      return EstadoEntrega.tarde;
    case 'No entregado':
      return EstadoEntrega.noEntregado;
    default:
      return EstadoEntrega.entregado;
  }
}

/// Información de un archivo adjunto en una entrega
class ArchivoAdjunto {
  ArchivoAdjunto({
    required this.nombreOriginal,
    required this.urlArchivo,
    required this.tamano,
    required this.extension,
    this.fechaSubida,
  });

  factory ArchivoAdjunto.fromJson(Map<String, dynamic> json) {
    return ArchivoAdjunto(
      nombreOriginal: json['nombre_original'] as String? ?? '',
      urlArchivo: json['url_archivo'] as String? ?? '',
      tamano: (json['tamano'] as num?)?.toInt() ?? 0,
      extension: json['extension'] as String? ?? '',
      fechaSubida: json['fecha_subida'] != null 
        ? DateTime.tryParse(json['fecha_subida'].toString()) 
        : null,
    );
  }

  final String nombreOriginal;
  final String urlArchivo;
  final int tamano; // En bytes
  final String extension;
  final DateTime? fechaSubida;

  Map<String, dynamic> toJson() {
    return {
      'nombre_original': nombreOriginal,
      'url_archivo': urlArchivo,
      'tamano': tamano,
      'extension': extension,
      'fecha_subida': fechaSubida?.toIso8601String(),
    };
  }

  /// Obtiene el tamaño formateado del archivo
  String get tamanoFormateado {
    if (tamano < 1024) {
      return '${tamano}B';
    }
    if (tamano < 1024 * 1024) {
      return '${(tamano / 1024).toStringAsFixed(1)}KB';
    }
    return '${(tamano / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Obtiene el icono del archivo basado en su extensión
  String get icono {
    switch (extension.toLowerCase()) {
      case 'pdf': return '📄';
      case 'doc':
      case 'docx': return '📝';
      case 'xls':
      case 'xlsx': return '📊';
      case 'zip':
      case 'rar': return '🗜️';
      case 'txt': return '📰';
      default: return '📎';
    }
  }
}

class ModeloEntrega {
  ModeloEntrega({
    required this.id,
    required this.tareaId,
    required this.estudianteId,
    required this.fechaEntrega,
    required this.estado,
    this.calificacion,
    this.comentarioProfesor,
    this.comentarioEstudiante,
    this.archivosAdjuntos = const [],
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory ModeloEntrega.fromJson(Map<String, dynamic> json) {
    return ModeloEntrega(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      tareaId: json['tarea_id'] is int ? json['tarea_id'] : int.tryParse(json['tarea_id'].toString()) ?? 0,
      estudianteId: json['estudiante_id'] is int ? json['estudiante_id'] : int.tryParse(json['estudiante_id'].toString()) ?? 0,
      fechaEntrega: DateTime.parse(json['fecha_entrega'].toString()),
      estado: estadoEntregaFromString(json['estado'] as String?),
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      comentarioProfesor: json['comentario_profesor'] as String?,
      comentarioEstudiante: json['comentario_estudiante'] as String?,
      archivosAdjuntos: json['archivos_adjuntos'] != null
        ? (json['archivos_adjuntos'] as List<dynamic>)
            .map((archivo) => ArchivoAdjunto.fromJson(archivo as Map<String, dynamic>))
            .toList()
        : [],
      fechaCreacion: json['fecha_creacion'] != null 
        ? DateTime.tryParse(json['fecha_creacion'].toString()) 
        : null,
      fechaActualizacion: json['fecha_actualizacion'] != null 
        ? DateTime.tryParse(json['fecha_actualizacion'].toString()) 
        : null,
    );
  }

  /// Constructor para crear una nueva entrega
  ModeloEntrega.crear({
    required this.tareaId,
    required this.estudianteId,
    required this.fechaEntrega,
    this.comentarioEstudiante,
    this.archivosAdjuntos = const [],
  }) : id = 0,
       estado = EstadoEntrega.entregado,
       calificacion = null,
       comentarioProfesor = null,
       fechaCreacion = DateTime.now(),
       fechaActualizacion = DateTime.now();

  final int id;
  final int tareaId;
  final int estudianteId;
  final DateTime fechaEntrega;
  final EstadoEntrega estado;
  final double? calificacion;
  final String? comentarioProfesor;
  final String? comentarioEstudiante;
  final List<ArchivoAdjunto> archivosAdjuntos;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'tarea_id': tareaId,
      'estudiante_id': estudianteId,
      'fecha_entrega': fechaEntrega.toIso8601String(),
      'estado': estadoEntregaToString(estado),
      'calificacion': calificacion,
      'comentario_profesor': comentarioProfesor,
      'comentario_estudiante': comentarioEstudiante,
      'archivos_adjuntos': archivosAdjuntos.map((archivo) => archivo.toJson()).toList(),
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
    
    // Solo incluir ID si no es 0 (para actualizaciones)
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Copia el modelo con nuevos valores
  ModeloEntrega copyWith({
    int? id,
    int? tareaId,
    int? estudianteId,
    DateTime? fechaEntrega,
    EstadoEntrega? estado,
    double? calificacion,
    String? comentarioProfesor,
    String? comentarioEstudiante,
    List<ArchivoAdjunto>? archivosAdjuntos,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return ModeloEntrega(
      id: id ?? this.id,
      tareaId: tareaId ?? this.tareaId,
      estudianteId: estudianteId ?? this.estudianteId,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      estado: estado ?? this.estado,
      calificacion: calificacion ?? this.calificacion,
      comentarioProfesor: comentarioProfesor ?? this.comentarioProfesor,
      comentarioEstudiante: comentarioEstudiante ?? this.comentarioEstudiante,
      archivosAdjuntos: archivosAdjuntos ?? this.archivosAdjuntos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Indica si la entrega fue realizada tarde
  bool get esTarde => fechaEntrega.isBefore(DateTime.now());

  /// Obtiene el color del estado
  String get colorEstado {
    switch (estado) {
      case EstadoEntrega.entregado:
        return esTarde ? '#FF9800' : '#4CAF50'; // Naranja si es tarde, verde si a tiempo
      case EstadoEntrega.calificado:
        return '#2196F3'; // Azul
      case EstadoEntrega.tarde:
        return '#F44336'; // Rojo
      case EstadoEntrega.noEntregado:
        return '#9E9E9E'; // Gris
    }
  }

  /// Obtiene el total de archivos adjuntos
  int get totalArchivos => archivosAdjuntos.length;

  /// Obtiene el tamaño total de todos los archivos
  String get tamanoTotalFormateado {
    final totalBytes = archivosAdjuntos.fold<int>(0, (suma, archivo) => suma + archivo.tamano);
    if (totalBytes < 1024) {
      return '${totalBytes}B';
    }
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
} 