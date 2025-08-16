class Lectura {
  const Lectura({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.enlacePdf,
    required this.cursoId,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      enlacePdf: json['enlace_pdf']?.toString() ?? '',
      cursoId: json['curso_id'] is int ? json['curso_id'] : int.tryParse(json['curso_id'].toString()) ?? 0,
    );
  }

  final int id;
  final String titulo;
  final String? descripcion;
  final String enlacePdf;
  final int cursoId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'enlace_pdf': enlacePdf,
      'curso_id': cursoId,
    };
  }
}


