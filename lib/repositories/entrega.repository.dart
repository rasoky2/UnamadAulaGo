import 'package:aulago/models/entrega.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/repositories/storage.repository.dart';
import 'package:flutter/foundation.dart';

/// Repository para gestionar entregas de tareas
class EntregaRepository extends BaseRepository<ModeloEntrega> {
  final StorageRepository _storageRepo = StorageRepository();

  @override
  String get tableName => 'entregas';

  @override
  String get repositoryName => 'EntregaRepository';

  @override
  ModeloEntrega fromJson(Map<String, dynamic> json) => ModeloEntrega.fromJson(json);

  @override
  Map<String, dynamic> toJson(ModeloEntrega entity) => entity.toJson();

  @override
  String getId(ModeloEntrega entity) => entity.id.toString();

  // ==================== MÉTODOS CRUD BÁSICOS ====================

  /// Obtiene todas las entregas
  Future<List<ModeloEntrega>> obtenerEntregas() async {
    try {
      debugPrint('[EntregaRepository] Obteniendo todas las entregas');
      final result = await obtener(limite: 1000, offset: 0);
      debugPrint('[EntregaRepository] ✅ ${result.items.length} entregas obtenidas');
      return result.items;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener entregas: $e');
      rethrow;
    }
  }

  /// Obtiene entregas por tarea
  Future<List<ModeloEntrega>> obtenerEntregasPorTarea(int tareaId) async {
    try {
      debugPrint('[EntregaRepository] Obteniendo entregas para tarea: $tareaId');
      
      final response = await supabase
          .from(tableName)
          .select()
          .eq('tarea_id', tareaId)
          .order('fecha_entrega', ascending: false);
      
      final entregas = (response as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('[EntregaRepository] ✅ ${entregas.length} entregas encontradas para tarea $tareaId');
      return entregas;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener entregas por tarea: $e');
      rethrow;
    }
  }

  /// Obtiene entregas por estudiante
  Future<List<ModeloEntrega>> obtenerEntregasPorEstudiante(int estudianteId) async {
    try {
      debugPrint('[EntregaRepository] Obteniendo entregas para estudiante: $estudianteId');
      
      final response = await supabase
          .from(tableName)
          .select()
          .eq('estudiante_id', estudianteId)
          .order('fecha_entrega', ascending: false);
      
      final entregas = (response as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('[EntregaRepository] ✅ ${entregas.length} entregas encontradas para estudiante $estudianteId');
      return entregas;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener entregas por estudiante: $e');
      rethrow;
    }
  }

  /// Obtiene una entrega específica por ID
  Future<ModeloEntrega?> obtenerEntregaPorId(int id) async {
    try {
      debugPrint('[EntregaRepository] Obteniendo entrega con ID: $id');
      return await obtenerPorId(id.toString());
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener entrega por ID: $e');
      rethrow;
    }
  }

  /// Obtiene una entrega específica por tarea y estudiante
  /// Si hay múltiples entregas, retorna la más reciente
  Future<ModeloEntrega?> obtenerEntregaPorTareaYEstudiante(int tareaId, int estudianteId) async {
    try {
      debugPrint('[EntregaRepository] Buscando entrega: tarea=$tareaId, estudiante=$estudianteId');
      
      final response = await supabase
          .from(tableName)
          .select()
          .eq('tarea_id', tareaId)
          .eq('estudiante_id', estudianteId)
          .order('fecha_entrega', ascending: false) // Ordenar por fecha más reciente
          .limit(1); // Solo obtener la primera (más reciente)
      
      if ((response as List).isEmpty) {
        debugPrint('[EntregaRepository] No se encontró entrega para tarea $tareaId y estudiante $estudianteId');
        return null;
      }
      
      final entrega = fromJson(response.first);
      debugPrint('[EntregaRepository] ✅ Entrega encontrada: ID ${entrega.id}');
      return entrega;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al buscar entrega por tarea y estudiante: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS CON ARCHIVOS ====================

  /// Crea una nueva entrega con archivos
  Future<ModeloEntrega> crearEntregaConArchivos({
    required int tareaId,
    required int estudianteId,
    String? comentarioEstudiante,
    required List<Map<String, dynamic>> archivos, // [{'file': File/Uint8List, 'name': String}]
  }) async {
    try {
      debugPrint('[EntregaRepository] Creando entrega con archivos');
      debugPrint('[EntregaRepository] Tarea: $tareaId, Estudiante: $estudianteId');
      debugPrint('[EntregaRepository] Archivos a subir: ${archivos.length}');
      
      // 1. Subir archivos al storage
      final List<ArchivoAdjunto> archivosAdjuntos = [];
      
      for (int i = 0; i < archivos.length; i++) {
        final archivo = archivos[i];
        final nombreOriginal = archivo['name'] as String;
        
        debugPrint('[EntregaRepository] Subiendo archivo ${i + 1}/${archivos.length}: $nombreOriginal');
        
        String urlArchivo;
        int tamanoArchivo;
        
        if (archivo['file'] is Uint8List) {
          // Web - bytes
          final bytes = archivo['file'] as Uint8List;
          tamanoArchivo = bytes.length;
          urlArchivo = await _storageRepo.subirArchivoEntregaDesdeBytes(
            estudianteId: estudianteId.toString(),
            tareaId: tareaId.toString(),
            bytes: bytes,
            nombreOriginal: nombreOriginal,
          );
        } else {
          // Móvil/Desktop - File
          final file = archivo['file'] as dynamic; // File
          tamanoArchivo = await file.length() as int;
          urlArchivo = await _storageRepo.subirArchivoEntrega(
            estudianteId: estudianteId.toString(),
            tareaId: tareaId.toString(),
            archivo: file,
            nombreOriginal: nombreOriginal,
          );
        }
        
        final extension = nombreOriginal.split('.').last.toLowerCase();
        archivosAdjuntos.add(ArchivoAdjunto(
          nombreOriginal: nombreOriginal,
          urlArchivo: urlArchivo,
          tamano: tamanoArchivo,
          extension: extension,
          fechaSubida: DateTime.now(),
        ));
        
        debugPrint('[EntregaRepository] ✅ Archivo subido: $nombreOriginal');
      }
      
      // 2. Crear la entrega en la base de datos
      final entrega = ModeloEntrega.crear(
        tareaId: tareaId,
        estudianteId: estudianteId,
        fechaEntrega: DateTime.now(),
        comentarioEstudiante: comentarioEstudiante,
        archivosAdjuntos: archivosAdjuntos,
      );
      
      final entregaCreada = await crear(entrega.toJson());
      debugPrint('[EntregaRepository] ✅ Entrega creada exitosamente con ID: ${entregaCreada.id}');
      
      return entregaCreada;
      
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al crear entrega con archivos: $e');
      rethrow;
    }
  }

  /// Actualiza una entrega existente
  Future<ModeloEntrega> actualizarEntrega(int id, ModeloEntrega entrega) async {
    try {
      debugPrint('[EntregaRepository] Actualizando entrega ID: $id');
      return await actualizar(id.toString(), entrega.toJson());
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al actualizar entrega: $e');
      rethrow;
    }
  }

  /// Califica una entrega (usado por profesores)
  Future<ModeloEntrega> calificarEntrega({
    required int entregaId,
    required double calificacion,
    String? comentarioProfesor,
  }) async {
    try {
      debugPrint('[EntregaRepository] Calificando entrega ID: $entregaId');
      debugPrint('[EntregaRepository] Calificación: $calificacion');
      
      final entregaActual = await obtenerEntregaPorId(entregaId);
      if (entregaActual == null) {
        throw Exception('Entrega no encontrada');
      }
      
      final entregaActualizada = entregaActual.copyWith(
        calificacion: calificacion,
        comentarioProfesor: comentarioProfesor,
        estado: EstadoEntrega.calificado,
        fechaActualizacion: DateTime.now(),
      );
      
      final resultado = await actualizarEntrega(entregaId, entregaActualizada);
      debugPrint('[EntregaRepository] ✅ Entrega calificada exitosamente');
      
      return resultado;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al calificar entrega: $e');
      rethrow;
    }
  }

  /// Elimina una entrega y sus archivos
  Future<bool> eliminarEntregaCompleta(int entregaId) async {
    try {
      debugPrint('[EntregaRepository] Eliminando entrega completa ID: $entregaId');
      
      // 1. Obtener la entrega para acceder a los archivos
      final entrega = await obtenerEntregaPorId(entregaId);
      if (entrega == null) {
        throw Exception('Entrega no encontrada');
      }
      
      // 2. Eliminar archivos del storage
      for (final archivo in entrega.archivosAdjuntos) {
        try {
          await _storageRepo.eliminarArchivoEntrega(archivo.urlArchivo);
          debugPrint('[EntregaRepository] ✅ Archivo eliminado: ${archivo.nombreOriginal}');
        } catch (e) {
          debugPrint('[EntregaRepository] ⚠️ Error al eliminar archivo: ${archivo.nombreOriginal} - $e');
          // Continuar con los demás archivos
        }
      }
      
      // 3. Eliminar la entrega de la base de datos
      await eliminar(entregaId.toString());
      debugPrint('[EntregaRepository] ✅ Entrega eliminada completamente');
      
      return true;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al eliminar entrega completa: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS DE ESTADÍSTICAS ====================

  /// Obtiene estadísticas de entregas para una tarea
  Future<Map<String, int>> obtenerEstadisticasTarea(int tareaId) async {
    try {
      debugPrint('[EntregaRepository] Obteniendo estadísticas para tarea: $tareaId');
      
      final entregas = await obtenerEntregasPorTarea(tareaId);
      
      int entregadas = 0;
      int calificadas = 0;
      int tarde = 0;
      int noEntregadas = 0;
      
      for (final entrega in entregas) {
        switch (entrega.estado) {
          case EstadoEntrega.entregado:
            entregadas++;
            break;
          case EstadoEntrega.calificado:
            calificadas++;
            break;
          case EstadoEntrega.tarde:
            tarde++;
            break;
          case EstadoEntrega.noEntregado:
            noEntregadas++;
            break;
        }
      }
      
      final estadisticas = {
        'total': entregas.length,
        'entregadas': entregadas,
        'calificadas': calificadas,
        'tarde': tarde,
        'no_entregadas': noEntregadas,
      };
      
      debugPrint('[EntregaRepository] ✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener estadísticas: $e');
      rethrow;
    }
  }

  /// Obtiene entregas con información del estudiante
  Future<List<Map<String, dynamic>>> obtenerEntregasConEstudiante(int tareaId) async {
    try {
      debugPrint('[EntregaRepository] Obteniendo entregas con info de estudiante para tarea: $tareaId');
      
      final response = await supabase
          .from(tableName)
          .select('''
            *,
            estudiantes!inner(
              id,
              nombre_completo,
              codigo_estudiante,
              correo_electronico,
              foto_perfil_url
            )
          ''')
          .eq('tarea_id', tareaId)
          .order('fecha_entrega', ascending: false);
      
      final entregasConEstudiante = response
          .map((json) => json)
          .toList();
      
      debugPrint('[EntregaRepository] ✅ $entregasConEstudiante.length entregas con estudiante obtenidas');
      return entregasConEstudiante;
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al obtener entregas con estudiante: $e');
      rethrow;
    }
  }

  /// Elimina todas las entregas asociadas a una tarea específica
  /// Útil para eliminación en cascada cuando se elimina una tarea
  Future<bool> eliminarEntregasPorTarea(int tareaId) async {
    try {
      debugPrint('[EntregaRepository] 🗑️ Eliminando todas las entregas para tarea: $tareaId');
      
      // 1. Obtener todas las entregas de la tarea
      final entregas = await obtenerEntregasPorTarea(tareaId);
      debugPrint('[EntregaRepository] 📋 $entregas.length entregas encontradas para eliminar');
      
      if (entregas.isEmpty) {
        debugPrint('[EntregaRepository] ✅ No hay entregas para eliminar');
        return true;
      }
      
      // 2. Eliminar archivos de storage y entregas de la base de datos
      int entregasEliminadas = 0;
      for (final entrega in entregas) {
        try {
          // Eliminar archivos adjuntos del storage
          for (final archivo in entrega.archivosAdjuntos) {
            try {
              await _storageRepo.eliminarArchivoEntrega(archivo.urlArchivo);
              debugPrint('[EntregaRepository] ✅ Archivo eliminado: ${archivo.nombreOriginal}');
            } catch (e) {
              debugPrint('[EntregaRepository] ⚠️ Error al eliminar archivo: ${archivo.nombreOriginal} - $e');
              // Continuar con los demás archivos
            }
          }
          
          // Eliminar la entrega de la base de datos
          await eliminar(entrega.id.toString());
          entregasEliminadas++;
          debugPrint('[EntregaRepository] ✅ Entrega $entrega.id eliminada');
          
        } catch (e) {
          debugPrint('[EntregaRepository] ⚠️ Error al eliminar entrega ${entrega.id}: $e');
          // Continuar con las demás entregas
        }
      }
      
      debugPrint('[EntregaRepository] ✅ $entregasEliminadas/$entregas.length entregas eliminadas exitosamente');
      return entregasEliminadas == entregas.length;
      
    } catch (e) {
      debugPrint('[EntregaRepository] ❌ Error al eliminar entregas por tarea: $e');
      rethrow;
    }
  }
}
