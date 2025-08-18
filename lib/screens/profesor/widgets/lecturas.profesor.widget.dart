import 'dart:io';

import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/lectura.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/lectura.repository.dart';
import 'package:aulago/repositories/profesor.repository.dart';
import 'package:aulago/repositories/storage.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturasTab extends StatefulWidget {
  const LecturasTab({super.key, required this.cursoId});
  final String cursoId;

  @override
  State<LecturasTab> createState() => _LecturasTabState();
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _LecturasTabState extends State<LecturasTab> {
  final _repo = LecturaRepository();
  final _cursoRepo = CursoRepository();
  final _profesorRepo = ProfesorRepository();
  final _storage = StorageRepository();
  late Future<List<Lectura>> _future;
  List<ModeloCurso> _cursosProfesor = const [];
  String? _cursoSeleccionadoId;
  bool _cargandoCursos = true;

  @override
  void initState() {
    super.initState();
    // Inicializar para evitar LateInitializationError en el primer build
    _future = Future.value(const <Lectura>[]);
    // Preseleccionar con el curso recibido (si vino)
    if (widget.cursoId.isNotEmpty) {
      _cursoSeleccionadoId = widget.cursoId;
    }
    _cargarCursosDelProfesor();
  }

  @override
  void didUpdateWidget(LecturasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el cursoId, recargar las lecturas
    if (oldWidget.cursoId != widget.cursoId) {
      _cursoSeleccionadoId = widget.cursoId;
      _cargarLecturas();
    }
  }

  void _cargarLecturas() {
    final cursoIdUsado = _cursoSeleccionadoId ?? widget.cursoId;
    debugPrint('[LecturasTab] Cargando lecturas para curso: $cursoIdUsado');
    
    // Validar que el cursoId sea válido
    final cursoIdInt = int.tryParse(cursoIdUsado);
    if (cursoIdInt == null) {
      debugPrint('[LecturasTab] Error: cursoId inválido: $cursoIdUsado');
      setState(() {
        _future = Future.value(const <Lectura>[]);
      });
      return;
    }
    
    setState(() {
      _future = _repo.obtenerLecturasPorCurso(cursoIdInt);
    });
  }

  Future<void> _cargarCursosDelProfesor() async {
    setState(() => _cargandoCursos = true);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final ModeloUsuario? usuario = container.read(usuarioActualProvider);
      if (usuario == null) {
        setState(() {
          _cursosProfesor = const [];
          _cargandoCursos = false;
        });
        return;
      }
      final profesorId = await _profesorRepo.obtenerProfesorIdPorUsuarioId(usuario.id);
      if (profesorId == null) {
        setState(() {
          _cursosProfesor = const [];
          _cargandoCursos = false;
        });
        return;
      }
      // Fallback: traer todos y filtrar por profesor_id presente en JSON
      final cursos = await _cursoRepo.obtenerCursos();
      final filtrados = cursos.where((c) {
        try {
          final pid = c.toJson()['profesor_id'];
          if (pid is int) {
            return pid == profesorId;
          }
          if (pid is String) {
            return int.tryParse(pid) == profesorId;
          }
          return false;
        } catch (_) { return false; }
      }).toList();
      setState(() {
        _cursosProfesor = filtrados;
        // Seleccionar el curso inicial si no hay uno seleccionado
        if (_cursoSeleccionadoId == null && _cursosProfesor.isNotEmpty) {
          _cursoSeleccionadoId = _cursosProfesor.first.id.toString();
        }
        _cargandoCursos = false;
      });
      _cargarLecturas();
    } catch (e) {
      setState(() {
        _cursosProfesor = const [];
        _cargandoCursos = false;
        _future = Future.value(const <Lectura>[]);
      });
    }
  }

  Future<void> _refrescar() async {
    _cargarLecturas();
  }

  String _cursoSeleccionadoNombre() {
    final sel = _cursoSeleccionadoId;
    if (sel == null) {
      return 'Sin curso';
    }
    final curso = _cursosProfesor.firstWhere(
      (c) => c.id.toString() == sel,
      orElse: () => const ModeloCurso(
        id: 0,
        carreraId: 0,
        codigoCurso: '—',
        nombre: 'Sin curso',
        creditos: 0,
        horasTeoria: 0,
        horasPractica: 0,
        semestreRecomendado: null,
        esObligatorio: false,
        fechaCreacion: null,
        profesorId: null,
        descripcion: null,
      ),
    );
    return '${curso.codigoCurso} - ${curso.nombre}';
  }

  Future<void> _crearLecturaDialog() async {
    if (_cursoSeleccionadoId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un curso antes de crear una lectura'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final enlaceCtrl = TextEditingController();
    
    // Estado del formulario
    bool esEnlace = true; // Por defecto enlace
    Uint8List? bytes;
    File? archivo;
    bool isSubiendo = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nueva lectura'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Información del curso
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Curso seleccionado: ${_cursoSeleccionadoNombre()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  TextFormField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título *', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // Descripción
                  TextFormField(
                    controller: descripcionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Selector de tipo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de lectura:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Enlace'),
                                  subtitle: const Text('URL o enlace web'),
                                  value: true,
                                  groupValue: esEnlace,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      esEnlace = value!;
                                      // Limpiar archivo si se cambia a enlace
                                      if (esEnlace) {
                                        bytes = null;
                                        archivo = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Archivo PDF'),
                                  subtitle: const Text('Subir archivo PDF'),
                                  value: false,
                                  groupValue: esEnlace,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      esEnlace = value!;
                                      // Limpiar enlace si se cambia a archivo
                                      if (!esEnlace) {
                                        enlaceCtrl.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo según el tipo seleccionado
                  if (esEnlace) ...[
                    TextFormField(
                      controller: enlaceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Enlace *',
                        helperText: 'Ingrese la URL completa (ej: https://ejemplo.com)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (v) {
                        if (esEnlace && (v == null || v.trim().isEmpty)) {
                          return 'El enlace es requerido';
                        }
                        if (v != null && v.trim().isNotEmpty) {
                          final uri = Uri.tryParse(v.trim());
                          if (uri == null || !uri.hasScheme) {
                            return 'Ingrese una URL válida con http:// o https://';
                          }
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    // Selector de archivo PDF
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (archivo == null && bytes == null) ...[
                            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            const Text(
                              'No se ha seleccionado ningún archivo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ] else ...[
                            Icon(
                              Icons.picture_as_pdf, 
                              size: 48, 
                              color: archivo != null || bytes != null ? Colors.green : Colors.red
                            ),
                            const SizedBox(height: 8),
                            Text(
                              archivo != null ? 'Archivo: ${archivo!.path.split('/').last}' : 'Archivo seleccionado',
                              style: TextStyle(
                                color: archivo != null || bytes != null ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: const ['pdf'],
                                withData: kIsWeb,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                final f = result.files.first;
                                setStateDialog(() {
                                  if (kIsWeb) {
                                    bytes = f.bytes;
                                    archivo = null;
                                  } else if (f.path != null) {
                                    archivo = File(f.path!);
                                    bytes = null;
                                  }
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Archivo seleccionado: ${f.name}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Seleccionar PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubiendo ? null : () => Navigator.pop(ctx), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: isSubiendo ? null : () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                
                // Validar que se haya seleccionado un archivo si es PDF
                if (!esEnlace && archivo == null && bytes == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un archivo PDF'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setStateDialog(() {
                  isSubiendo = true;
                });
                
                try {
                  String url;
                  final cursoIdInt = int.parse(_cursoSeleccionadoId!);
                  
                  if (!esEnlace) {
                    // Subir archivo PDF
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
                    } else {
                      throw Exception('No se pudo procesar el archivo');
                    }
                  } else {
                    // Usar enlace
                    url = enlaceCtrl.text.trim();
                  }

                  // Crear la lectura con el cursoId
                  await _repo.crearLectura(Lectura(
                    titulo: tituloCtrl.text.trim(),
                    descripcion: descripcionCtrl.text.trim().isEmpty ? null : descripcionCtrl.text.trim(),
                    enlacePdf: url,
                    cursoId: cursoIdInt,
                  ));
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    await _refrescar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lectura creada exitosamente'), 
                        backgroundColor: Colors.green
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('[CrearLectura] Error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear la lectura: $e'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setStateDialog(() {
                      isSubiendo = false;
                    });
                  }
                }
              },
              child: isSubiendo 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de curso
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _cargandoCursos
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _cursoSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Curso',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _cursosProfesor
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id.toString(),
                                  child: Text('${c.codigoCurso} - ${c.nombre}'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _cursoSeleccionadoId = v;
                          });
                          _cargarLecturas();
                        },
                      ),
              ),
            ],
          ),
        ),
        // Header con información del curso y botones
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Lecturas', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _crearLecturaDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva lectura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_cursoSeleccionadoId != null)
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      _cursoSeleccionadoNombre(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                return const Center(child: CircularProgressIndicator());
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
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade300),
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
                      ElevatedButton.icon(
                        onPressed: _crearLecturaDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primera lectura'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
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
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf, 
                            color: Colors.red.shade600,
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
                              Text(l.descripcion!),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Abrir enlace',
                              onPressed: () async {
                                final uri = Uri.tryParse(l.enlacePdf);
                                if (uri == null) {
                                  return;
                                }
                                if (await canLaunchUrl(uri)) {
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
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar lectura',
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar eliminación'),
                                    content: Text('¿Está seguro de eliminar la lectura "${l.titulo}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmar == true) {
                                  try {
                                    await _repo.eliminarLectura(l.id!);
                                    await _refrescar();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Lectura eliminada'), 
                                          backgroundColor: Colors.green
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al eliminar: $e'), 
                                          backgroundColor: Colors.red
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
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


