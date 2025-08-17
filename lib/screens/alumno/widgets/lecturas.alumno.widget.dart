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
    _cargarLecturas();
  }

  @override
  void didUpdateWidget(LecturasAlumnoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el cursoId, recargar las lecturas
    if (oldWidget.cursoId != widget.cursoId) {
      _cargarLecturas();
    }
  }

  void _cargarLecturas() {
    debugPrint('[LecturasAlumno] Cargando lecturas para curso: ${widget.cursoId}');
    
    // Validar que el cursoId sea válido
    final cursoIdInt = int.tryParse(widget.cursoId);
    if (cursoIdInt == null) {
      debugPrint('[LecturasAlumno] Error: cursoId inválido: ${widget.cursoId}');
      return;
    }
    
    setState(() {
      _future = _repo.obtenerLecturasPorCurso(cursoIdInt);
    });
  }

  Future<void> _refrescar() async {
    _cargarLecturas();
  }

  Future<void> _abrir(Lectura l) async {
    final uri = Uri.tryParse(l.enlacePdf);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con información del curso
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: AppConstants.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Lecturas del Curso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              // Botón de refresh
              IconButton(
                onPressed: _refrescar,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar lecturas',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de lecturas
        Expanded(
          child: FutureBuilder<List<Lectura>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando lecturas...'),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar lecturas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curso ID: ${widget.cursoId}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refrescar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              
              final lecturas = snapshot.data ?? const <Lectura>[];
              
              if (lecturas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No hay lecturas para este curso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Curso ID: ${widget.cursoId}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'El profesor aún no ha agregado lecturas para este curso.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: _refrescar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lecturas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final l = lecturas[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book, 
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          l.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (l.descripcion != null && l.descripcion!.isNotEmpty) ...[
                              Text(
                                l.descripcion!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              l.enlacePdf,
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Abrir lectura',
                          onPressed: () => _abrir(l),
                          style: IconButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                            foregroundColor: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


