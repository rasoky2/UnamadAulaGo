import 'package:flutter/foundation.dart';

/// Utilidad para logging con colores en los repositorios
class ApiLogger {
  // Códigos ANSI para colores en terminal
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';

  /// Log para operaciones GET
  static void logGet({
    required String table,
    required int statusCode,
    required response,
    Map<String, dynamic>? filters,
  }) {
    final coloredMethod = '${_green}GET$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (filters != null && filters.isNotEmpty) {
      debugPrint('Filters applied: $filters');
    }
  }

  /// Log para operaciones POST
  static void logPost({
    required String table,
    required int statusCode,
    required response,
    Map<String, dynamic>? requestBody,
  }) {
    final coloredMethod = '${_blue}POST$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (requestBody != null) {
      debugPrint('Request body sent: ${_formatJson(requestBody)}');
    }
  }

  /// Log para operaciones PUT
  static void logPut({
    required String table,
    required int statusCode,
    required response,
    Map<String, dynamic>? requestBody,
  }) {
    final coloredMethod = '${_yellow}PUT$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (requestBody != null) {
      debugPrint('Request body sent: ${_formatJson(requestBody)}');
    }
  }

  /// Log para operaciones UPDATE (PATCH)
  static void logUpdate({
    required String table,
    required int statusCode,
    required response,
    Map<String, dynamic>? requestBody,
  }) {
    final coloredMethod = '${_magenta}UPDATE$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (requestBody != null) {
      debugPrint('Request body sent: ${_formatJson(requestBody)}');
    }
  }

  /// Log para operaciones DELETE
  static void logDelete({
    required String table,
    required int statusCode,
    required response,
    String? id,
  }) {
    final coloredMethod = '${_red}DELETE$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (id != null) {
      debugPrint('Deleted ID: $id');
    }
  }

  /// Log para operaciones COUNT
  static void logCount({
    required String table,
    required int statusCode,
    required Object? response,
    Map<String, dynamic>? filters,
  }) {
    final coloredMethod = '${_cyan}COUNT$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$table] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (filters != null && filters.isNotEmpty) {
      debugPrint('Filters applied: $filters');
    }
  }

  /// Log para operaciones RPC (funciones de base de datos)
  static void logRpc({
    required String functionName,
    required int statusCode,
    required Object? response,
    Map<String, dynamic>? params,
  }) {
    final coloredMethod = '${_magenta}RPC$_reset';
    final coloredStatus = _getStatusColor(statusCode);
    
    debugPrint('[$coloredMethod] [$functionName] [$coloredStatus] response:');
    debugPrint(_formatJson(response));
    
    if (params != null && params.isNotEmpty) {
      debugPrint('Parameters sent: $params');
    }
  }

  /// Log para errores
  static void logError({
    required String operation,
    required String table,
    required Object error,
    String? additionalInfo,
  }) {
    final coloredError = '${_red}ERROR$_reset';
    
    debugPrint('[$coloredError] [$operation] [$table] failed:');
    debugPrint('Error: $error');
    
    if (additionalInfo != null) {
      debugPrint('Additional info: $additionalInfo');
    }
  }

  /// Obtiene el color apropiado para el código de estado HTTP
  static String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return '$_green$statusCode$_reset';
    } else if (statusCode >= 400 && statusCode < 500) {
      return '$_red$statusCode$_reset';
    } else if (statusCode >= 500) {
      return '$_red$statusCode$_reset';
    } else {
      return '$_yellow$statusCode$_reset';
    }
  }

  /// Formatea un objeto JSON para mejor legibilidad
  static String _formatJson(Object? json) {
    if (json == null) {
      return 'null';
    }
    
    try {
      if (json is String) {
        return json;
      } else if (json is Map || json is List) {
        return json.toString();
      } else {
        return json.toString();
      }
    } catch (e) {
      return 'Error formatting JSON: $e';
    }
  }
} 