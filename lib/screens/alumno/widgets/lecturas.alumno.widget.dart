import 'package:aulago/models/lectura.model.dart';
import 'package:aulago/repositories/lectura.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturasAlumnoWidget extends StatefulWidget {
  const LecturasAlumnoWidget({super.key, required this.cursoId});
  final String cursoId;

  @override
  State<LecturasAlumnoWidget> createState() => _LecturasAlumnoWidgetState();
}

class _LecturasAlumnoWidgetState extends State<LecturasAlumnoWidget> {
  final _repo = LecturaRepository();
  late Future<List<Lectura>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.obtenerLecturas();
  }

  bool _perteneceAlCurso(Lectura l) {
    final enlace = l.enlacePdf;
    final pattern = 'curso_${widget.cursoId}_';
    if (enlace.contains(pattern)) return true;
    // Soporte para enlaces externos almacenando `?cursoId=ID` o `&cursoId=ID`
    return enlace.contains('cursoId=${widget.cursoId}');
  }

  Future<void> _abrir(Lectura l) async {
    final uri = Uri.tryParse(l.enlacePdf);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Lectura>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final todas = snapshot.data ?? const <Lectura>[];
        final lecturas = todas.where(_perteneceAlCurso).toList();
        if (lecturas.isEmpty) {
          return const Center(child: Text('Aún no hay lecturas para este curso'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lecturas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final l = lecturas[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book, color: AppConstants.primaryColor),
                title: Text(l.titulo),
                subtitle: Text(l.descripcion ?? l.enlacePdf, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Abrir',
                  onPressed: () => _abrir(l),
                ),
              ),
            );
          },
        );
      },
    );
  }
}


