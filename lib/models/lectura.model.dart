class Lectura {
  const Lectura({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.enlacePdf,
    required this.cursoId,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      enlacePdf: json['enlace_pdf']?.toString() ?? '',
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id'].toString()) ?? 0,
    );
  }

  final int? id;
  final String titulo;
  final String? descripcion;
  final String enlacePdf;
  final int cursoId;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'titulo': titulo,
      'enlace_pdf': enlacePdf,
      'curso_id': cursoId,
    };
    
    // Solo incluir id si no es null (para actualizaciones)
    if (id != null) {
      json['id'] = id;
    }
    
    // Solo incluir descripción si no es null
    if (descripcion != null) {
      json['descripcion'] = descripcion;
    }
    
    return json;
  }

  Lectura copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? enlacePdf,
    int? cursoId,
  }) {
    return Lectura(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      enlacePdf: enlacePdf ?? this.enlacePdf,
      cursoId: cursoId ?? this.cursoId,
    );
  }
}


