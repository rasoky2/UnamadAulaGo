import 'package:aulago/models/foro.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/comentario_foro.repository.dart';
import 'package:aulago/repositories/publicacion_foro.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForoDetalleAlumnoSheet extends ConsumerStatefulWidget {
  const ForoDetalleAlumnoSheet({super.key, required this.foro});

  final Foro foro;

  @override
  ConsumerState<ForoDetalleAlumnoSheet> createState() => _ForoDetalleAlumnoSheetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Foro>('foro', foro));
  }
}

class _ForoDetalleAlumnoSheetState extends ConsumerState<ForoDetalleAlumnoSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _futurePublicaciones;
  final Set<int> _expandidos = <int>{};
  bool _showLoginWarning = false;
  final PublicacionForoRepository _publicacionRepo = PublicacionForoRepository();
  final ComentarioForoRepository _comentarioRepo = ComentarioForoRepository();

  @override
  void initState() {
    super.initState();
    _futurePublicaciones = _cargarPublicaciones();
    // Oculta cualquier SnackBar previo de la pantalla base
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _cargarPublicaciones() async {
    return _publicacionRepo.obtenerPublicacionesConAutor(widget.foro.id);
  }

  Future<List<Map<String, dynamic>>> _cargarComentarios(int publicacionId) async {
    return _comentarioRepo.obtenerComentariosConAutor(publicacionId);
  }

  Future<int?> _obtenerEstudianteIdActual() async {
    // 1) Intentar por Riverpod (estado de auth en memoria)
    final usuario = ref.read(proveedorAuthProvider).usuario;
    final userIdFromProvider = usuario?.id;
    if (userIdFromProvider != null && usuario?.rol == 'estudiante') {
      final row = await _supabase
          .from('estudiantes')
          .select('id')
          .eq('usuario_id', userIdFromProvider)
          .maybeSingle();
      if (row != null) {
        return (row['id'] as num).toInt();
      }
    }

    // 2) Fallback a SharedPreferences para robustez
    final prefs = await SharedPreferences.getInstance();
    final usuarioIdStr = prefs.getString('userId');
    final usuarioId = int.tryParse(usuarioIdStr ?? '');
    if (usuarioId == null) {
      return null;
    }
    final row = await _supabase
        .from('estudiantes')
        .select('id')
        .eq('usuario_id', usuarioId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return (row['id'] as num).toInt();
  }

  Future<void> _crearPublicacionDialog() async {
    final tituloCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nueva publicación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contenidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Publicar'),
            ),
          ],
        );
      },
    );

    if (created != true) {
      return;
    }

    final estudianteId = await _obtenerEstudianteIdActual();
    if (estudianteId == null) {
      if (mounted) {
        setState(() {
          _showLoginWarning = true;
        });
      }
      return;
    }

    await _publicacionRepo.crearPublicacion({
      'foro_id': widget.foro.id,
      'titulo': tituloCtrl.text.trim(),
      'contenido': contenidoCtrl.text.trim(),
      'autor_id': estudianteId,
      'tipo_autor': 'estudiante',
    });

    setState(() {
      _futurePublicaciones = _cargarPublicaciones();
      _showLoginWarning = false;
    });
  }

  Future<void> _crearComentarioDialog(int publicacionId) async {
    final contenidoCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nuevo comentario'),
          content: TextField(
            controller: contenidoCtrl,
            decoration: const InputDecoration(
              labelText: 'Escribe tu comentario',
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Comentar'),
            ),
          ],
        );
      },
    );

    if (created != true) {
      return;
    }

    final estudianteId = await _obtenerEstudianteIdActual();
    if (estudianteId == null) {
      if (mounted) {
        setState(() {
          _showLoginWarning = true;
        });
      }
      return;
    }

    await _comentarioRepo.crearComentario({
      'publicacion_id': publicacionId,
      'contenido': contenidoCtrl.text.trim(),
      'autor_id': estudianteId,
      'tipo_autor': 'estudiante',
    });

    // Si está expandido, recargamos comentarios forzando un rebuild
    setState(() {
      _showLoginWarning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.foro.titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.foro.descripcion != null && widget.foro.descripcion!.isNotEmpty)
                          Text(
                            widget.foro.descripcion!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futurePublicaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error al cargar publicaciones',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    );
                  }

                  final publicaciones = snapshot.data ?? const [];
                  if (publicaciones.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no hay publicaciones',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: publicaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pub = publicaciones[index];
                      final pubId = (pub['id'] as num?)?.toInt();
                      final titulo = (pub['titulo'] ?? '').toString();
                      final contenido = (pub['contenido'] ?? '').toString();
                      final fecha = DateTime.tryParse((pub['fecha_creacion'] ?? '').toString());
                      final nombreAutor = _obtenerNombreAutor(pub);
                      final tipoAutor = pub['tipo_autor'] as String? ?? 'estudiante';
                      final expandido = pubId != null && _expandidos.contains(pubId);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ForoAvatarWidget(
                                    fotoUrl: pub['autor_foto'] as String?,
                                    nombreCompleto: nombreAutor,
                                    tipoUsuario: tipoAutor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titulo.isEmpty ? 'Publicación' : titulo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Por $nombreAutor',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (fecha != null)
                                    Text(
                                      _formatElapsed(fecha),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                contenido,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: pubId == null
                                        ? null
                                        : () => _crearComentarioDialog(pubId),
                                    icon: const Icon(Icons.add_comment_outlined),
                                    label: const Text('Comentar'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: pubId == null
                                        ? null
                                        : () {
                                            setState(() {
                                              if (_expandidos.contains(pubId)) {
                                                _expandidos.remove(pubId);
                                              } else {
                                                _expandidos.add(pubId);
                                              }
                                            });
                                          },
                                    child: Text(expandido ? 'Ocultar comentarios' : 'Ver comentarios'),
                                  ),
                                ],
                              ),
                              if (expandido) ...[
                                const SizedBox(height: 8),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _cargarComentarios(pubId),
                                  builder: (context, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    }
                                    if (snap.hasError) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('Error al cargar comentarios', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                      );
                                    }
                                    final comentarios = snap.data ?? const [];
                                    if (comentarios.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text('Sin comentarios aún', style: TextStyle(color: Colors.grey[600])),
                                      );
                                    }
                                    return Column(
                                      children: comentarios.map((c) {
                                        final txt = (c['contenido'] ?? '').toString();
                                        final f = DateTime.tryParse((c['fecha_creacion'] ?? '').toString());
                                        final nombreAutorComentario = _obtenerNombreAutor(c);
                                        final tipoAutorComentario = c['tipo_autor'] as String? ?? 'estudiante';
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ForoAvatarWidget(
                                                fotoUrl: c['autor_foto'] as String?,
                                                nombreCompleto: nombreAutorComentario,
                                                tipoUsuario: tipoAutorComentario,
                                                radio: 12,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          nombreAutorComentario,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                            color: tipoAutorComentario == 'profesor' 
                                                                ? Colors.orange[700] 
                                                                : Colors.blue[700],
                                                          ),
                                                        ),
                                                        if (f != null) ...[
                                                          const Text(' • ', style: TextStyle(color: Colors.grey)),
                                                          Text(
                                                            _formatElapsed(f),
                                                            style: const TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      txt,
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Cierre de la lista de hijos de Column y del propio Column
            ],
          ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _crearPublicacionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nueva publicación'),
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (_showLoginWarning)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + 56 + 12, // encima del FAB
                child: Material(
                  elevation: 2,
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Inicia sesión como estudiante para comentar o publicar',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inDays >= 1) {
      return '${diff.inDays} d';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} h';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} min';
    }
    return 'Ahora';
  }

  String _obtenerNombreAutor(Map<String, dynamic> data) {
    // Nuevo formato: el repositorio ya incluye 'autor_nombre'
    return data['autor_nombre'] as String? ?? 'Usuario';
  }
}

Future<void> mostrarForoDetalleAlumnoSheet({
  required BuildContext context,
  required Foro foro,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 1.0,
        child: ForoDetalleAlumnoSheet(foro: foro),
      );
    },
  );
}


