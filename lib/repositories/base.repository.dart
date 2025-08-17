import 'package:aulago/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository base abstracto que proporciona funcionalidad común
/// para todos los repositories de la aplicación
abstract class BaseRepository<T> {
  final SupabaseClient supabase = Supabase.instance.client;
  
  /// Nombre de la tabla en la base de datos
  String get tableName;
  
  /// Nombre del repository para logging
  String get repositoryName;
  
  /// Convierte un Map a la entidad T
  T fromJson(Map<String, dynamic> json);
  
  /// Convierte la entidad T a Map
  Map<String, dynamic> toJson(T entity);
  
  /// Obtiene el ID de la entidad
  String getId(T entity);
  
  /// Crea una nueva entidad en la base de datos
  Future<T> crear(Map<String, dynamic> datos) async {
    debugPrint('[$repositoryName] Iniciando creación en tabla: $tableName');
    debugPrint('[$repositoryName] Datos recibidos: $datos');
    
    try {
      final result = await supabase
          .from(tableName)
          .insert(datos)
          .select()
          .single();
      
      ApiLogger.logPost(
        table: tableName,
        statusCode: 201,
        response: result,
        requestBody: datos,
      );
      
      debugPrint('[$repositoryName] Entidad creada exitosamente');
      return fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'CREAR',
        table: tableName,
        error: e,
        additionalInfo: 'Datos: $datos',
      );
      debugPrint('[$repositoryName] Error al crear: $e');
      rethrow;
    }
  }
  
  /// Obtiene una lista de entidades con filtros opcionales
  Future<({List<T> items, int total})> obtener({
    String? filtroTexto,
    Map<String, dynamic>? filtros,
    int limite = 10,
    int offset = 0,
    String? orderBy,
    bool ascending = true,
  }) async {
    debugPrint('[$repositoryName] Obteniendo entidades de: $tableName');
    debugPrint('[$repositoryName] Filtros: $filtros, texto: $filtroTexto');
    debugPrint('[$repositoryName] Paginación: limite=$limite, offset=$offset');
    
    try {
      // Construir la consulta base
      final query = supabase.from(tableName).select();
      
      // Aplicar filtros de texto si se proporcionan
      if (filtroTexto != null && filtroTexto.isNotEmpty) {
        query.or('nombre_completo.ilike.%$filtroTexto%,codigo_estudiante.ilike.%$filtroTexto%');
      }
      
      // Aplicar filtros adicionales
      if (filtros != null) {
        for (final entry in filtros.entries) {
          if (entry.value != null) {
            query.eq(entry.key, entry.value);
          }
        }
      }
      
      // Aplicar ordenamiento
      if (orderBy != null) {
        if (ascending) {
          query.order(orderBy);
        } else {
          query.order(orderBy, ascending: false);
        }
      }
      
      // Aplicar paginación
      query.range(offset, offset + limite - 1);
      
      final response = await query;
      
      // Obtener el total por separado
      final countQuery = supabase.from(tableName).select();
      if (filtros != null) {
        for (final entry in filtros.entries) {
          if (entry.value != null) {
            countQuery.eq(entry.key, entry.value);
          }
        }
      }
      final countResponse = await countQuery;
      final total = countResponse.length;
      
      final items = (response as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
      
      ApiLogger.logGet(
        table: tableName,
        statusCode: 200,
        response: {
          'items_count': items.length,
          'total': total,
          'items': response,
        },
        filters: {
          'filtroTexto': filtroTexto,
          'filtros': filtros,
          'limite': limite,
          'offset': offset,
          'orderBy': orderBy,
        },
      );
      
      debugPrint('[$repositoryName] Entidades obtenidas: ${items.length} de $total');
      return (items: items, total: total);
    } catch (e) {
      ApiLogger.logError(
        operation: 'OBTENER',
        table: tableName,
        error: e,
        additionalInfo: 'Filtros: $filtros, Texto: $filtroTexto',
      );
      debugPrint('[$repositoryName] Error al obtener: $e');
      rethrow;
    }
  }
  
  /// Obtiene una entidad por su ID
  Future<T?> obtenerPorId(String id) async {
    debugPrint('[$repositoryName] Obteniendo entidad por ID: $id');
    
    try {
      final result = await supabase
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (result == null) {
        debugPrint('[$repositoryName] Entidad no encontrada con ID: $id');
        return null;
      }
      
      ApiLogger.logGet(
        table: tableName,
        statusCode: 200,
        response: result,
        filters: {'id': id},
      );
      
      debugPrint('[$repositoryName] Entidad encontrada');
      return fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'OBTENER_POR_ID',
        table: tableName,
        error: e,
        additionalInfo: 'ID: $id',
      );
      debugPrint('[$repositoryName] Error al obtener por ID: $e');
      rethrow;
    }
  }
  
  /// Actualiza una entidad existente
  Future<T> actualizar(String id, Map<String, dynamic> datos) async {
    debugPrint('[$repositoryName] Actualizando entidad ID: $id');
    debugPrint('[$repositoryName] Datos a actualizar: $datos');
    
    try {
      // Solo agregar fecha_actualizacion si la tabla lo soporta
      final datosActualizados = {...datos};
      
      // Verificar si la tabla tiene el campo fecha_actualizacion
      if (tableName != 'carreras') {
        datosActualizados['fecha_actualizacion'] = DateTime.now().toIso8601String();
      }
      
      final result = await supabase
          .from(tableName)
          .update(datosActualizados)
          .eq('id', id)
          .select()
          .single();
      
      ApiLogger.logUpdate(
        table: tableName,
        statusCode: 200,
        response: result,
        requestBody: datosActualizados,
      );
      
      debugPrint('[$repositoryName] Entidad actualizada exitosamente');
      return fromJson(result);
    } catch (e) {
      ApiLogger.logError(
        operation: 'ACTUALIZAR',
        table: tableName,
        error: e,
        additionalInfo: 'ID: $id, Datos: $datos',
      );
      debugPrint('[$repositoryName] Error al actualizar: $e');
      rethrow;
    }
  }
  
  /// Elimina una entidad por su ID
  Future<void> eliminar(String id) async {
    debugPrint('[$repositoryName] Eliminando entidad ID: $id');
    
    try {
      await supabase
          .from(tableName)
          .delete()
          .eq('id', id);
      
      ApiLogger.logDelete(
        table: tableName,
        statusCode: 200,
        response: {'deleted': true},
        id: id,
      );
      
      debugPrint('[$repositoryName] Entidad eliminada exitosamente');
    } catch (e) {
      ApiLogger.logError(
        operation: 'ELIMINAR',
        table: tableName,
        error: e,
        additionalInfo: 'ID: $id',
      );
      debugPrint('[$repositoryName] Error al eliminar: $e');
      rethrow;
    }
  }
  
  /// Cuenta el total de entidades con filtros opcionales
  Future<int> contar({Map<String, dynamic>? filtros}) async {
    debugPrint('[$repositoryName] Contando entidades en: $tableName');
    debugPrint('[$repositoryName] Filtros: $filtros');
    
    try {
      final query = supabase.from(tableName).select();
      
      if (filtros != null) {
        for (final entry in filtros.entries) {
          if (entry.value != null) {
            query.eq(entry.key, entry.value);
          }
        }
      }
      
      final response = await query;
      final count = response.length;
      
      ApiLogger.logCount(
        table: tableName,
        statusCode: 200,
        response: count,
        filters: filtros,
      );
      
      debugPrint('[$repositoryName] Total de entidades: $count');
      return count;
    } catch (e) {
      ApiLogger.logError(
        operation: 'CONTAR',
        table: tableName,
        error: e,
        additionalInfo: 'Filtros: $filtros',
      );
      debugPrint('[$repositoryName] Error al contar: $e');
      rethrow;
    }
  }
  
  /// Ejecuta una consulta personalizada
  Future<List<T>> consultaPersonalizada({
    required String consulta,
    Map<String, dynamic>? parametros,
  }) async {
    debugPrint('[$repositoryName] Ejecutando consulta personalizada');
    debugPrint('[$repositoryName] Consulta: $consulta');
    debugPrint('[$repositoryName] Parámetros: $parametros');
    
    try {
      final response = await supabase
          .from(tableName)
          .select(consulta);
      
      final items = (response as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
      
      ApiLogger.logGet(
        table: tableName,
        statusCode: 200,
        response: {
          'items_count': items.length,
          'items': response,
        },
        filters: {
          'consulta': consulta,
          'parametros': parametros,
        },
      );
      
      debugPrint('[$repositoryName] Consulta ejecutada: ${items.length} resultados');
      return items;
    } catch (e) {
      ApiLogger.logError(
        operation: 'CONSULTA_PERSONALIZADA',
        table: tableName,
        error: e,
        additionalInfo: 'Consulta: $consulta, Parámetros: $parametros',
      );
      debugPrint('[$repositoryName] Error en consulta personalizada: $e');
      rethrow;
    }
  }
}
