import 'dart:io';
import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository para manejar operaciones de Supabase Storage
class StorageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Sube una foto de perfil al bucket de avatares
  /// [usuarioId] - ID único del usuario (puede ser student_id, profesor_id, etc.)
  /// [archivo] - Archivo de imagen a subir
  /// [tipoUsuario] - 'estudiante', 'profesor', 'admin'
  /// Retorna la URL pública de la imagen subida
  Future<String> subirFotoPerfil({
    required String usuarioId,
    required File archivo,
    required String tipoUsuario,
  }) async {
    try {
      debugPrint('[StorageRepository] Iniciando subida de foto de perfil');
      debugPrint('[StorageRepository] Usuario ID: $usuarioId, Tipo: $tipoUsuario');
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = archivo.path.split('.').last.toLowerCase();
      final nombreArchivo = '${tipoUsuario}_${usuarioId}_$timestamp.$extension';
      final rutaCompleta = 'avatars/$nombreArchivo';
      
      debugPrint('[StorageRepository] Ruta del archivo: $rutaCompleta');
      
      // Subir archivo al bucket
      await _supabase.storage
          .from('avatars')
          .upload(rutaCompleta, archivo);
      
      // Obtener URL pública
      final urlPublica = _supabase.storage
          .from('avatars')
          .getPublicUrl(rutaCompleta);
      
      ApiLogger.logPost(
        table: 'storage.avatars',
        statusCode: 201,
        response: {'url': urlPublica, 'path': rutaCompleta},
        requestBody: {
          'usuario_id': usuarioId,
          'tipo_usuario': tipoUsuario,
          'archivo': nombreArchivo,
        },
      );
      
      debugPrint('[StorageRepository] Foto subida exitosamente: $urlPublica');
      
      // Actualizar foto_perfil_url en las tablas correspondientes
      await _actualizarFotoPerfilEnBaseDatos(usuarioId, urlPublica, tipoUsuario);
      
      return urlPublica;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'SUBIR_FOTO_PERFIL',
        table: 'storage.avatars',
        error: e,
        additionalInfo: 'Usuario: $usuarioId, Tipo: $tipoUsuario',
      );
      debugPrint('[StorageRepository] Error al subir foto: $e');
      rethrow;
    }
  }
  
  /// Sube una foto de perfil desde bytes (útil para web)
  Future<String> subirFotoPerfilDesdeBytes({
    required String usuarioId,
    required Uint8List bytes,
    required String extension,
    required String tipoUsuario,
  }) async {
    try {
      debugPrint('[StorageRepository] Iniciando subida de foto desde bytes');
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreArchivo = '${tipoUsuario}_${usuarioId}_$timestamp.$extension';
      final rutaCompleta = 'avatars/$nombreArchivo';
      
      // Subir bytes al bucket
      await _supabase.storage
          .from('avatars')
          .uploadBinary(rutaCompleta, bytes);
      
      // Obtener URL pública
      final urlPublica = _supabase.storage
          .from('avatars')
          .getPublicUrl(rutaCompleta);
      
      ApiLogger.logPost(
        table: 'storage.avatars',
        statusCode: 201,
        response: {'url': urlPublica, 'path': rutaCompleta},
        requestBody: {
          'usuario_id': usuarioId,
          'tipo_usuario': tipoUsuario,
          'archivo': nombreArchivo,
          'size_bytes': bytes.length,
        },
      );
      
      debugPrint('[StorageRepository] Foto subida exitosamente desde bytes: $urlPublica');
      
      // Actualizar foto_perfil_url en las tablas correspondientes
      await _actualizarFotoPerfilEnBaseDatos(usuarioId, urlPublica, tipoUsuario);
      
      return urlPublica;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'SUBIR_FOTO_PERFIL_BYTES',
        table: 'storage.avatars',
        error: e,
        additionalInfo: 'Usuario: $usuarioId, Tipo: $tipoUsuario, Size: ${bytes.length} bytes',
      );
      rethrow;
    }
  }
  
  /// Elimina una foto de perfil del storage
  Future<void> eliminarFotoPerfil(String urlFoto) async {
    try {
      debugPrint('[StorageRepository] Eliminando foto de perfil: $urlFoto');
      
      // Extraer la ruta del archivo desde la URL
      final uri = Uri.parse(urlFoto);
      final segments = uri.pathSegments;
      
      // Buscar el segmento que contiene 'avatars'
      final avatarsIndex = segments.indexOf('avatars');
      if (avatarsIndex == -1 || avatarsIndex >= segments.length - 1) {
        throw Exception('URL de foto inválida: no se puede extraer la ruta');
      }
      
      final rutaArchivo = segments.skip(avatarsIndex + 1).join('/');
      debugPrint('[StorageRepository] Ruta extraída: avatars/$rutaArchivo');
      
      // Eliminar del bucket
      await _supabase.storage
          .from('avatars')
          .remove(['avatars/$rutaArchivo']);
      
      ApiLogger.logDelete(
        table: 'storage.avatars',
        statusCode: 200,
        response: {'deleted': true},
        id: rutaArchivo,
      );
      
      debugPrint('[StorageRepository] Foto eliminada exitosamente');
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'ELIMINAR_FOTO_PERFIL',
        table: 'storage.avatars',
        error: e,
        additionalInfo: 'URL: $urlFoto',
      );
      rethrow;
    }
  }
  
  /// Lista todos los archivos en el bucket de avatares (útil para administración)
  Future<List<FileObject>> listarAvatares() async {
    try {
      debugPrint('[StorageRepository] Listando avatares');
      
      final archivos = await _supabase.storage
          .from('avatars')
          .list(path: 'avatars');
      
      ApiLogger.logGet(
        table: 'storage.avatars',
        statusCode: 200,
        response: {'count': archivos.length, 'files': archivos},
      );
      
      debugPrint('[StorageRepository] ${archivos.length} avatares encontrados');
      return archivos;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'LISTAR_AVATARES',
        table: 'storage.avatars',
        error: e,
      );
      rethrow;
    }
  }

  /// Elimina una foto de perfil y actualiza las tablas correspondientes
  Future<void> eliminarFotoPerfilConActualizacion({
    required String urlFoto,
    required String usuarioId,
    required String tipoUsuario,
  }) async {
    try {
      debugPrint('[StorageRepository] Eliminando foto de perfil y actualizando BD');
      debugPrint('[StorageRepository] Usuario ID: $usuarioId, Tipo: $tipoUsuario');
      
      // Eliminar del storage
      await eliminarFotoPerfil(urlFoto);
      
      // Actualizar las tablas a null
      await _actualizarFotoPerfilEnBaseDatos(usuarioId, null, tipoUsuario);
      
      debugPrint('[StorageRepository] ✅ Foto eliminada y BD actualizada');
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'ELIMINAR_FOTO_PERFIL_CON_BD',
        table: 'storage.avatars,usuarios,${tipoUsuario}s',
        error: e,
        additionalInfo: 'Usuario: $usuarioId, URL: $urlFoto',
      );
      debugPrint('[StorageRepository] ❌ Error al eliminar foto con actualización: $e');
      rethrow;
    }
  }

  /// Actualiza la foto_perfil_url en las tablas usuarios y específica (estudiantes/profesores)
  Future<void> _actualizarFotoPerfilEnBaseDatos(String usuarioId, String? nuevaUrl, String tipoUsuario) async {
    try {
      debugPrint('[StorageRepository] Actualizando foto_perfil_url en base de datos');
      debugPrint('[StorageRepository] Usuario ID: $usuarioId, Tipo: $tipoUsuario, URL: $nuevaUrl');
      
      // 1. Actualizar en la tabla usuarios (principal)
      await _supabase
          .from('usuarios')
          .update({'foto_perfil_url': nuevaUrl})
          .eq('id', usuarioId);
      
      debugPrint('[StorageRepository] ✅ Actualizada tabla usuarios');
      
      // 2. Actualizar en la tabla específica según el tipo de usuario
      if (tipoUsuario == 'estudiante') {
        await _supabase
            .from('estudiantes')
            .update({'foto_perfil_url': nuevaUrl})
            .eq('usuario_id', usuarioId);
        debugPrint('[StorageRepository] ✅ Actualizada tabla estudiantes');
      } else if (tipoUsuario == 'profesor') {
        await _supabase
            .from('profesores')
            .update({'foto_perfil_url': nuevaUrl})
            .eq('usuario_id', usuarioId);
        debugPrint('[StorageRepository] ✅ Actualizada tabla profesores');
      }
      
      ApiLogger.logPost(
        table: 'usuarios,${tipoUsuario}s',
        statusCode: 200,
        response: {
          'updated_tables': ['usuarios', '${tipoUsuario}s'],
          'foto_perfil_url': nuevaUrl,
          'usuario_id': usuarioId,
        },
      );
      
      debugPrint('[StorageRepository] ✅ Foto de perfil actualizada en todas las tablas');
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'ACTUALIZAR_FOTO_PERFIL_BD',
        table: 'usuarios,${tipoUsuario}s',
        error: e,
        additionalInfo: 'Usuario: $usuarioId, URL: $nuevaUrl',
      );
      debugPrint('[StorageRepository] ❌ Error al actualizar foto_perfil_url en BD: $e');
      // No re-lanzar el error para que la subida no falle, solo loggear
    }
  }

  // ==================== GESTIÓN DE ARCHIVOS DE ENTREGAS ====================

  /// Extensiones de archivo permitidas para entregas
  static const List<String> extensionesPermitidas = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'zip', 'rar', 'txt'
  ];

  /// Tipos MIME permitidos para entregas
  static const Map<String, String> tiposMimePermitidos = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    'txt': 'text/plain',
  };

  // ==================== LECTURAS ====================
  /// Sube un PDF de lectura al bucket `lecturas` y devuelve URL pública
  Future<String> subirLecturaPdf({
    required String cursoId,
    required String titulo,
    required File archivo,
  }) async {
    final extension = archivo.path.split('.').last.toLowerCase();
    if (extension != 'pdf') {
      throw Exception('Solo se permiten archivos PDF para lecturas.');
    }
    final tamano = await archivo.length();
    if (tamano > 52428800) {
      throw Exception('El archivo es demasiado grande. Máximo 50MB');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seguro = titulo.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final nombreArchivo = 'curso_${cursoId}_${timestamp}_$seguro.pdf';
    final ruta = 'lecturas/$nombreArchivo';
    await _supabase.storage.from('lecturas').upload(ruta, archivo);
    return _supabase.storage.from('lecturas').getPublicUrl(ruta);
  }

  /// Variante desde bytes (web)
  Future<String> subirLecturaPdfDesdeBytes({
    required String cursoId,
    required String titulo,
    required Uint8List bytes,
  }) async {
    if (bytes.length > 52428800) {
      throw Exception('El archivo es demasiado grande. Máximo 50MB');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final seguro = titulo.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final nombreArchivo = 'curso_${cursoId}_${timestamp}_$seguro.pdf';
    final ruta = 'lecturas/$nombreArchivo';
    await _supabase.storage.from('lecturas').uploadBinary(ruta, bytes, fileOptions: const FileOptions(contentType: 'application/pdf'));
    return _supabase.storage.from('lecturas').getPublicUrl(ruta);
  }

  /// Sube un archivo de entrega de tarea
  /// [estudianteId] - ID del estudiante que sube el archivo
  /// [tareaId] - ID de la tarea
  /// [archivo] - Archivo a subir
  /// [nombreOriginal] - Nombre original del archivo
  /// Retorna la URL pública del archivo subido
  Future<String> subirArchivoEntrega({
    required String estudianteId,
    required String tareaId,
    required File archivo,
    required String nombreOriginal,
  }) async {
    try {
      debugPrint('[StorageRepository] Iniciando subida de archivo de entrega');
      debugPrint('[StorageRepository] Estudiante: $estudianteId, Tarea: $tareaId');
      debugPrint('[StorageRepository] Archivo: $nombreOriginal');
      
      // Validar extensión
      final extension = nombreOriginal.split('.').last.toLowerCase();
      if (!extensionesPermitidas.contains(extension)) {
        throw Exception('Tipo de archivo no permitido: .$extension');
      }
      
      // Validar tamaño (50MB máximo)
      final tamano = await archivo.length();
      if (tamano > 52428800) { // 50MB
        throw Exception('El archivo es demasiado grande. Máximo: 50MB');
      }
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreSeguro = nombreOriginal.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final nombreArchivo = 'tarea_${tareaId}_estudiante_${estudianteId}_${timestamp}_$nombreSeguro';
      final rutaCompleta = 'entregas/$nombreArchivo';
      
      debugPrint('[StorageRepository] Ruta del archivo: $rutaCompleta');
      debugPrint('[StorageRepository] Tamaño: ${(tamano / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Subir archivo al bucket
      await _supabase.storage
          .from('entregas')
          .upload(rutaCompleta, archivo);
      
      // Obtener URL pública
      final urlPublica = _supabase.storage
          .from('entregas')
          .getPublicUrl(rutaCompleta);
      
      ApiLogger.logPost(
        table: 'storage.entregas',
        statusCode: 201,
        response: {'url': urlPublica, 'path': rutaCompleta},
        requestBody: {
          'estudiante_id': estudianteId,
          'tarea_id': tareaId,
          'nombre_original': nombreOriginal,
          'archivo': nombreArchivo,
          'size_bytes': tamano,
        },
      );
      
      debugPrint('[StorageRepository] ✅ Archivo de entrega subido: $urlPublica');
      return urlPublica;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'SUBIR_ARCHIVO_ENTREGA',
        table: 'storage.entregas',
        error: e,
        additionalInfo: 'Estudiante: $estudianteId, Tarea: $tareaId, Archivo: $nombreOriginal',
      );
      debugPrint('[StorageRepository] ❌ Error al subir archivo de entrega: $e');
      rethrow;
    }
  }

  /// Sube un archivo de entrega desde bytes (útil para web)
  Future<String> subirArchivoEntregaDesdeBytes({
    required String estudianteId,
    required String tareaId,
    required Uint8List bytes,
    required String nombreOriginal,
  }) async {
    try {
      debugPrint('[StorageRepository] Iniciando subida de archivo de entrega desde bytes');
      debugPrint('[StorageRepository] Estudiante: $estudianteId, Tarea: $tareaId');
      debugPrint('[StorageRepository] Archivo: $nombreOriginal, Tamaño: ${bytes.length} bytes');
      
      // Validar extensión
      final extension = nombreOriginal.split('.').last.toLowerCase();
      if (!extensionesPermitidas.contains(extension)) {
        throw Exception('Tipo de archivo no permitido: .$extension');
      }
      
      // Validar tamaño (50MB máximo)
      if (bytes.length > 52428800) { // 50MB
        throw Exception('El archivo es demasiado grande. Máximo: 50MB');
      }
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreSeguro = nombreOriginal.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final nombreArchivo = 'tarea_${tareaId}_estudiante_${estudianteId}_${timestamp}_$nombreSeguro';
      final rutaCompleta = 'entregas/$nombreArchivo';
      
      // Subir bytes al bucket
      await _supabase.storage
          .from('entregas')
          .uploadBinary(rutaCompleta, bytes);
      
      // Obtener URL pública
      final urlPublica = _supabase.storage
          .from('entregas')
          .getPublicUrl(rutaCompleta);
      
      ApiLogger.logPost(
        table: 'storage.entregas',
        statusCode: 201,
        response: {'url': urlPublica, 'path': rutaCompleta},
        requestBody: {
          'estudiante_id': estudianteId,
          'tarea_id': tareaId,
          'nombre_original': nombreOriginal,
          'archivo': nombreArchivo,
          'size_bytes': bytes.length,
        },
      );
      
      debugPrint('[StorageRepository] ✅ Archivo de entrega subido desde bytes: $urlPublica');
      return urlPublica;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'SUBIR_ARCHIVO_ENTREGA_BYTES',
        table: 'storage.entregas',
        error: e,
        additionalInfo: 'Estudiante: $estudianteId, Tarea: $tareaId, Archivo: $nombreOriginal',
      );
      debugPrint('[StorageRepository] ❌ Error al subir archivo de entrega desde bytes: $e');
      rethrow;
    }
  }

  /// Elimina un archivo de entrega del storage
  Future<void> eliminarArchivoEntrega(String urlArchivo) async {
    try {
      debugPrint('[StorageRepository] Eliminando archivo de entrega: $urlArchivo');
      
      // Extraer la ruta del archivo desde la URL
      final uri = Uri.parse(urlArchivo);
      final segments = uri.pathSegments;
      
      // Buscar el segmento que contiene 'entregas'
      final entregasIndex = segments.indexOf('entregas');
      if (entregasIndex == -1 || entregasIndex >= segments.length - 1) {
        throw Exception('URL de archivo inválida: no se puede extraer la ruta');
      }
      
      final rutaArchivo = segments.skip(entregasIndex + 1).join('/');
      debugPrint('[StorageRepository] Ruta extraída: entregas/$rutaArchivo');
      
      // Eliminar del bucket
      await _supabase.storage
          .from('entregas')
          .remove(['entregas/$rutaArchivo']);
      
      ApiLogger.logDelete(
        table: 'storage.entregas',
        statusCode: 200,
        response: {'deleted': true},
        id: rutaArchivo,
      );
      
      debugPrint('[StorageRepository] ✅ Archivo de entrega eliminado exitosamente');
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'ELIMINAR_ARCHIVO_ENTREGA',
        table: 'storage.entregas',
        error: e,
        additionalInfo: 'URL: $urlArchivo',
      );
      debugPrint('[StorageRepository] ❌ Error al eliminar archivo de entrega: $e');
      rethrow;
    }
  }

  /// Lista archivos de entrega para una tarea específica
  Future<List<FileObject>> listarArchivosEntrega(String tareaId) async {
    try {
      debugPrint('[StorageRepository] Listando archivos de entrega para tarea: $tareaId');
      
      final archivos = await _supabase.storage
          .from('entregas')
          .list(path: 'entregas');
      
      // Filtrar archivos que corresponden a la tarea
      final archivosTarea = archivos.where((archivo) => 
          archivo.name.contains('tarea_$tareaId')).toList();
      
      ApiLogger.logGet(
        table: 'storage.entregas',
        statusCode: 200,
        response: {'count': archivosTarea.length, 'files': archivosTarea, 'tarea_id': tareaId},
      );
      
      debugPrint('[StorageRepository] ${archivosTarea.length} archivos encontrados para tarea $tareaId');
      return archivosTarea;
      
    } catch (e) {
      ApiLogger.logError(
        operation: 'LISTAR_ARCHIVOS_ENTREGA',
        table: 'storage.entregas',
        error: e,
        additionalInfo: 'Tarea ID: $tareaId',
      );
      debugPrint('[StorageRepository] ❌ Error al listar archivos de entrega: $e');
      rethrow;
    }
  }

  /// Obtiene información del archivo desde la URL
  static Map<String, String> extraerInfoArchivo(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final nombreArchivo = segments.last;
    
    // Extraer información del nombre del archivo
    // Formato: tarea_{tareaId}_estudiante_{estudianteId}_{timestamp}_{nombreOriginal}
    final partes = nombreArchivo.split('_');
    
    String nombreOriginal = nombreArchivo;
    String extension = 'unknown';
    
    if (partes.length >= 6) {
      // Reconstruir nombre original (puede tener guiones bajos)
      nombreOriginal = partes.skip(5).join('_');
    }
    
    if (nombreOriginal.contains('.')) {
      extension = nombreOriginal.split('.').last.toLowerCase();
    }
    
    return {
      'nombre_original': nombreOriginal,
      'extension': extension,
      'nombre_archivo': nombreArchivo,
      'tipo_mime': tiposMimePermitidos[extension] ?? 'application/octet-stream',
    };
  }

  /// Valida si un archivo es válido para entrega
  static bool esArchivoValido(String nombreArchivo) {
    final extension = nombreArchivo.split('.').last.toLowerCase();
    return extensionesPermitidas.contains(extension);
  }

  /// Obtiene el icono apropiado para el tipo de archivo
  static String obtenerIconoArchivo(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
        return '🗜️';
      case 'txt':
        return '📰';
      default:
        return '📎';
    }
  }
}
