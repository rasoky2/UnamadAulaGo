import 'dart:io';
import 'package:aulago/models/lectura.model.dart';
import 'package:aulago/repositories/lectura.repository.dart';
import 'package:aulago/repositories/storage.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturasTab extends StatefulWidget {
  const LecturasTab({super.key, required this.cursoId});
  final String cursoId;

  @override
  State<LecturasTab> createState() => _LecturasTabState();
}

class _LecturasTabState extends State<LecturasTab> {
  final _repo = LecturaRepository();
  final _storage = StorageRepository();
  late Future<List<Lectura>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.obtenerLecturas();
  }

  Future<void> _refrescar() async {
    setState(() {
      _future = _repo.obtenerLecturas();
    });
  }

  Future<void> _crearLecturaDialog() async {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final enlaceCtrl = TextEditingController();
    Uint8List? bytes;
    File? archivo;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lectura'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: enlaceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enlace (PDF o wiki) opcional',
                    helperText: 'Si no seleccionas archivo, puedes pegar un enlace',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['pdf'],
                        withData: kIsWeb,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final f = result.files.first;
                        if (kIsWeb) {
                          bytes = f.bytes;
                        } else if (f.path != null) {
                          archivo = File(f.path!);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Archivo seleccionado: ${f.name}')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Seleccionar PDF'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              String url;
              if (bytes != null) {
                url = await _storage.subirLecturaPdfDesdeBytes(
                  cursoId: widget.cursoId,
                  titulo: tituloCtrl.text.trim(),
                  bytes: bytes!,
                );
              } else if (archivo != null) {
                url = await _storage.subirLecturaPdf(
                  cursoId: widget.cursoId,
                  titulo: tituloCtrl.text.trim(),
                  archivo: archivo!,
                );
              } else if (enlaceCtrl.text.trim().isNotEmpty) {
                url = enlaceCtrl.text.trim();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione un PDF o ingrese un enlace')),
                  );
                }
                return;
              }

              await _repo.crearLectura(Lectura(
                id: 0,
                titulo: tituloCtrl.text.trim(),
                descripcion: descripcionCtrl.text.trim().isEmpty ? null : descripcionCtrl.text.trim(),
                enlacePdf: url,
              ));
              if (mounted) {
                Navigator.pop(ctx);
                await _refrescar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lectura creada'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _crearLecturaDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nueva lectura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Lectura>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final lecturas = snapshot.data ?? const <Lectura>[];
              if (lecturas.isEmpty) {
                return const Center(child: Text('No hay lecturas registradas'));
              }
              return ListView.separated(
                itemCount: lecturas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final l = lecturas[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(l.titulo),
                      subtitle: Text(l.descripcion ?? l.enlacePdf),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Abrir enlace',
                            onPressed: () async {
                              final uri = Uri.tryParse(l.enlacePdf);
                              if (uri == null) return;
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No se pudo abrir el enlace'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _repo.eliminarLectura(l.id);
                              await _refrescar();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


