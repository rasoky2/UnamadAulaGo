import 'dart:io';
import 'package:aulago/repositories/storage.repository.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para permitir a los usuarios subir o cambiar su foto de perfil
/// 
/// Características:
/// - ✅ Soporte completo para Web, Android, iOS y Desktop
/// - 📸 Cámara y galería (solo móviles)
/// - 📁 Explorador de archivos (todas las plataformas)
/// - 🔒 Validaciones de tamaño (máx 5MB) y formato (JPG, PNG, WebP)
/// - 🎨 UI moderna con iconos y descripciones
/// - ⚡ Estados de carga y feedback al usuario
/// - 🗑️ Eliminación de foto existente
class FotoPerfilUploadWidget extends StatefulWidget {
  const FotoPerfilUploadWidget({
    super.key,
    required this.usuarioId,
    required this.nombreCompleto,
    required this.tipoUsuario,
    this.fotoActualUrl,
    this.onFotoSubida,
    this.radio = 40,
  });

  final String usuarioId;
  final String nombreCompleto;
  final String tipoUsuario;
  final String? fotoActualUrl;
  final Function(String nuevaUrl)? onFotoSubida;
  final double radio;

  @override
  State<FotoPerfilUploadWidget> createState() => _FotoPerfilUploadWidgetState();
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('usuarioId', usuarioId))
    ..add(StringProperty('nombreCompleto', nombreCompleto))
    ..add(StringProperty('tipoUsuario', tipoUsuario))
    ..add(StringProperty('fotoActualUrl', fotoActualUrl))
    ..add(ObjectFlagProperty<Function(String nuevaUrl)?>.has('onFotoSubida', onFotoSubida))
    ..add(DoubleProperty('radio', radio));
  }
}

class _FotoPerfilUploadWidgetState extends State<FotoPerfilUploadWidget> {
  final StorageRepository _storageRepo = StorageRepository();
  final ImagePicker _picker = ImagePicker();
  bool _subiendo = false;
  String? _fotoUrlTemporal;

  @override
  void initState() {
    super.initState();
    _validarDatosIniciales();
  }

  void _validarDatosIniciales() {
    // Validar que los datos requeridos estén presentes
    if (widget.nombreCompleto.isEmpty) {
      debugPrint('[FotoPerfilUploadWidget] ⚠️ nombreCompleto está vacío');
    }
    if (widget.tipoUsuario.isEmpty) {
      debugPrint('[FotoPerfilUploadWidget] ⚠️ tipoUsuario está vacío');
    }
    if (widget.usuarioId.isEmpty) {
      debugPrint('[FotoPerfilUploadWidget] ⚠️ usuarioId está vacío');
    }
    
    debugPrint('[FotoPerfilUploadWidget] ✅ Datos iniciales validados');
  }

  // Métodos auxiliares para obtener texto según la plataforma
  String _obtenerTituloArchivo() {
    if (kIsWeb) {
      return 'Seleccionar archivo';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'Elegir desde archivos';
    } else {
      return 'Elegir desde archivos';
    }
  }

  String _obtenerSubtituloArchivo() {
    if (kIsWeb) {
      return 'Subir imagen desde tu computadora';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'Explorar archivos del sistema';
    } else {
      return 'Explorar archivos del dispositivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = _fotoUrlTemporal ?? widget.fotoActualUrl;
    
    // Validaciones para prevenir widget blanco
    final nombreCompleto = widget.nombreCompleto.isNotEmpty 
        ? widget.nombreCompleto 
        : 'Usuario';
    
    final tipoUsuario = widget.tipoUsuario.isNotEmpty 
        ? widget.tipoUsuario 
        : 'usuario';

    // Debug logging para identificar problemas
    debugPrint('[FotoPerfilUploadWidget] Renderizando con:');
    debugPrint('  - nombreCompleto: "$nombreCompleto"');
    debugPrint('  - tipoUsuario: "$tipoUsuario"');
    debugPrint('  - fotoUrl: "$fotoUrl"');
    debugPrint('  - radio: ${widget.radio}');

    return Stack(
      children: [
        // Avatar con fallbacks robustos
        AvatarWidget(
          fotoUrl: fotoUrl,
          nombreCompleto: nombreCompleto,
          tipoUsuario: tipoUsuario,
          radio: widget.radio,
        ),
        
        // Fallback visual en caso de error (nunca debería mostrarse)
        if (nombreCompleto.isEmpty || tipoUsuario.isEmpty)
          Container(
            width: widget.radio * 2,
            height: widget.radio * 2,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: widget.radio,
              color: Colors.grey[600],
            ),
          ),
        
        // Botón de editar superpuesto
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _subiendo ? null : _mostrarOpcionesFoto,
            child: Container(
              width: widget.radio * 0.6,
              height: widget.radio * 0.6,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _subiendo
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.camera_alt,
                      size: widget.radio * 0.3,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesFoto() {
    // Validar que estemos en una plataforma válida
    if (kIsWeb) {
      debugPrint('[FotoPerfilUploadWidget] Mostrando opciones en Web');
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      debugPrint('[FotoPerfilUploadWidget] Mostrando opciones en Desktop');
    } else if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('[FotoPerfilUploadWidget] Mostrando opciones en Móvil');
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seleccionar foto de perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Opciones
                // Solo mostrar cámara y galería en dispositivos móviles (Android/iOS)
                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.blue),
                    ),
                    title: const Text('Tomar foto'),
                    subtitle: const Text('Usar la cámara del dispositivo'),
                    onTap: () {
                      Navigator.pop(context);
                      _seleccionarFoto(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_library, color: Colors.green),
                    ),
                    title: const Text('Elegir de galería'),
                    subtitle: const Text('Seleccionar desde galería de fotos'),
                    onTap: () {
                      Navigator.pop(context);
                      _seleccionarFoto(ImageSource.gallery);
                    },
                  ),
                ],
                
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_open, color: Colors.orange),
                  ),
                  title: Text(_obtenerTituloArchivo()),
                  subtitle: Text(_obtenerSubtituloArchivo()),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarDesdeArchivos();
                  },
                ),
                
                if (widget.fotoActualUrl != null && widget.fotoActualUrl!.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Eliminar foto'),
                    subtitle: const Text('Quitar foto de perfil actual'),
                    onTap: () {
                      Navigator.pop(context);
                      _eliminarFoto();
                    },
                  ),
                
                const SizedBox(height: 10),
                
                // Botón cancelar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    // Solo permitir en dispositivos móviles
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta opción solo está disponible en dispositivos móviles'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (imagen == null) {
        return;
      }

      setState(() {
        _subiendo = true;
      });

      String nuevaUrl;
      
      // Para móvil, usar archivo
      final archivo = File(imagen.path);
      nuevaUrl = await _storageRepo.subirFotoPerfil(
        usuarioId: widget.usuarioId,
        archivo: archivo,
        tipoUsuario: widget.tipoUsuario,
      );

      setState(() {
        _fotoUrlTemporal = nuevaUrl;
        _subiendo = false;
      });

      // Callback para notificar al padre
      widget.onFotoSubida?.call(nuevaUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _subiendo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarDesdeArchivos() async {
    try {
      setState(() {
        _subiendo = true;
      });

      // Usar file_picker para seleccionar archivo de imagen
      // En Windows/Web usar withData: true, en móvil usar path
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validaciones
        if (file.size > 5 * 1024 * 1024) { // 5MB
          throw Exception('El archivo es demasiado grande. Máximo 5MB permitido.');
        }

        // Validar extensión
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
        final extension = file.extension?.toLowerCase();
        if (extension == null || !allowedExtensions.contains(extension)) {
          throw Exception('Formato no válido. Use JPG, PNG o WebP.');
        }

        String nuevaUrl;

        if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          // En web/desktop, usar bytes directamente
          if (file.bytes == null) {
            throw Exception('No se pudieron leer los datos del archivo.');
          }
          
          nuevaUrl = await _storageRepo.subirFotoPerfilDesdeBytes(
            usuarioId: widget.usuarioId,
            bytes: file.bytes!,
            extension: extension,
            tipoUsuario: widget.tipoUsuario,
          );
        } else {
          // En móvil, usar el path del archivo
          if (file.path == null) {
            throw Exception('No se pudo acceder al archivo seleccionado.');
          }
          
          final archivo = File(file.path!);
          nuevaUrl = await _storageRepo.subirFotoPerfil(
            usuarioId: widget.usuarioId,
            archivo: archivo,
            tipoUsuario: widget.tipoUsuario,
          );
        }

        setState(() {
          _fotoUrlTemporal = nuevaUrl;
          _subiendo = false;
        });

        // Callback para notificar al padre
        widget.onFotoSubida?.call(nuevaUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Usuario canceló la selección
        setState(() {
          _subiendo = false;
        });
      }
    } catch (e) {
      setState(() {
        _subiendo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _eliminarFoto() async {
    if (widget.fotoActualUrl == null) {
      return;
    }

    try {
      setState(() {
        _subiendo = true;
      });

      await _storageRepo.eliminarFotoPerfilConActualizacion(
        urlFoto: widget.fotoActualUrl!,
        usuarioId: widget.usuarioId,
        tipoUsuario: widget.tipoUsuario,
      );

      setState(() {
        _fotoUrlTemporal = null;
        _subiendo = false;
      });

      // Callback para notificar al padre
      widget.onFotoSubida?.call('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil eliminada'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _subiendo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
