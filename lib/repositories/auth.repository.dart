import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {

  AuthRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<ModeloUsuario> iniciarSesion(String codigo, String contrasena) async {
    try {
      // 1. PRIORITARIO: Buscar en la tabla 'usuarios' unificada
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('codigo_usuario', codigo)
          .maybeSingle();

      ApiLogger.logGet(
        table: 'usuarios',
        statusCode: 200,
        response: response,
        filters: {'codigo_usuario': codigo},
      );

      if (response != null && response.isNotEmpty) {
        // Verificar contraseña
        if (response['contrasena_hash'] == contrasena) {
          final usuario = ModeloUsuario.fromJson(response);
          
          // Verificar si está activo
          if (!usuario.activo) {
            throw Exception('El usuario se encuentra inactivo. Comuníquese con soporte.');
          }
          
          // Si es estudiante, cargar datos completos del estudiante
          if (usuario.esEstudiante) {
            try {
              final estudianteResponse = await _supabase
                  .from('estudiantes')
                  .select()
                  .eq('usuario_id', usuario.id)
                  .maybeSingle();
              
              if (estudianteResponse != null) {
                final estudianteCompleto = EstudianteAdmin.fromJson(estudianteResponse);
                final usuarioConPerfil = usuario.copyWith(perfil: estudianteCompleto);
                await _establecerSesion(usuario.id, usuario.rol);
                await guardarDatosUsuario(usuarioConPerfil);
                
                ApiLogger.logGet(
                  table: 'usuarios',
                  statusCode: 200,
                  response: {'authenticated': true, 'rol': usuario.rol, 'perfil_cargado': true},
                  filters: {'resultado': 'login_exitoso'},
                );
                
                return usuarioConPerfil;
              }
            } catch (e) {
              ApiLogger.logError(
                operation: 'cargar_perfil_estudiante',
                table: 'estudiantes',
                error: e,
                additionalInfo: 'No se pudo cargar perfil completo del estudiante',
              );
            }
          }
          
          await _establecerSesion(usuario.id, usuario.rol);
          await guardarDatosUsuario(usuario);
          
          ApiLogger.logGet(
            table: 'usuarios',
            statusCode: 200,
            response: {'authenticated': true, 'rol': usuario.rol},
            filters: {'resultado': 'login_exitoso'},
          );
          
          return usuario;
        } else {
          // Usuario encontrado pero contraseña incorrecta
          throw Exception('El código de usuario o la contraseña son incorrectos.');
        }
      }

      // 2. FALLBACK: Buscar en tabla estudiantes (datos legacy)
      try {
        final estudianteResponse = await _supabase
            .from('estudiantes')
            .select()
            .eq('codigo_estudiante', codigo)
            .maybeSingle();
        
        if (estudianteResponse != null && estudianteResponse['contrasena_hash'] == contrasena) {
        ApiLogger.logGet(
          table: 'estudiantes',
          statusCode: 200,
          response: estudianteResponse,
            filters: {'codigo_estudiante': codigo, 'fallback': true},
        );
        
            final usuario = ModeloUsuario.fromEstudianteJson(estudianteResponse);
            if (!usuario.activo) {
                throw Exception('El usuario se encuentra inactivo. Comuníquese con soporte.');
            }
            // Cargar datos completos del estudiante para el perfil
            final estudianteCompleto = EstudianteAdmin.fromJson(estudianteResponse);
            final usuarioConPerfil = usuario.copyWith(perfil: estudianteCompleto);
            await _establecerSesion(usuario.id, usuario.rol);
          await guardarDatosUsuario(usuarioConPerfil);
            return usuarioConPerfil;
        }
      } catch (e) {
        // Log pero continuar al siguiente fallback
        ApiLogger.logError(
          operation: 'fallback_estudiantes',
          table: 'estudiantes',
          error: e,
          additionalInfo: 'Continuando con fallback profesores',
        );
      }

      // 3. FALLBACK: Buscar en tabla profesores (datos legacy)
      try {
        final profesorResponse = await _supabase
            .from('profesores')
            .select()
            .eq('codigo_profesor', codigo)
            .maybeSingle();
        
        if (profesorResponse != null && profesorResponse['contrasena_hash'] == contrasena) {
        ApiLogger.logGet(
          table: 'profesores',
          statusCode: 200,
          response: profesorResponse,
            filters: {'codigo_profesor': codigo, 'fallback': true},
        );
        
            final usuario = ModeloUsuario.fromProfesorJson(profesorResponse);
             if (!usuario.activo) {
                throw Exception('El usuario se encuentra inactivo. Comuníquese con soporte.');
            }
            await _establecerSesion(usuario.id, usuario.rol);
          await guardarDatosUsuario(usuario);
            return usuario;
        }
      } catch (e) {
        // Log pero continuar al error final
        ApiLogger.logError(
          operation: 'fallback_profesores',
          table: 'profesores',
          error: e,
          additionalInfo: 'Fallback final fallido',
        );
      }

      // 4. Si no se encuentra en ninguna tabla
      throw Exception('El código de usuario o la contraseña son incorrectos.');

    } catch (e) {
      ApiLogger.logError(
        operation: 'iniciarSesion',
        table: 'usuarios',
        error: e,
        additionalInfo: 'Código usuario: $codigo',
      );
      rethrow;
    }
  }

  Future<ModeloUsuario?> verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userRole = prefs.getString('userRole');

    if (userId == null) {
      ApiLogger.logError(
        operation: 'verificarSesion',
        table: 'session',
        error: 'No userId found in SharedPreferences',
        additionalInfo: 'Sesión no válida',
      );
      return null;
    }

    // Para estudiantes, siempre cargar datos frescos para obtener el perfil completo
    if (userRole == 'estudiante') {
      ApiLogger.logGet(
        table: 'session_cache',
        statusCode: 200,
        response: {
          'cache_skipped': true,
          'reason': 'estudiante_needs_fresh_data',
          'user_role': userRole,
        },
      );
    } else {
      // Para otros roles, intentar recuperar desde caché local
      final usuarioCache = await recuperarDatosUsuario();
      if (usuarioCache != null) {
        ApiLogger.logGet(
          table: 'session_cache',
          statusCode: 200,
          response: {
            'cache_hit': true,
            'user_name': usuarioCache.nombreCompleto,
            'role': usuarioCache.rol,
          },
        );
        return usuarioCache;
      }
    }

    try {
      // 1. PRIORITARIO: Buscar en tabla usuarios unificada
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
      ApiLogger.logGet(
        table: 'usuarios',
        statusCode: 200,
          response: {'found': true, 'rol': response['rol']},
          filters: {'id': userId, 'verificacion': 'exitosa'},
      );
      
        final usuario = ModeloUsuario.fromJson(response);
        
        // Verificar si sigue activo
        if (!usuario.activo) {
      ApiLogger.logError(
        operation: 'verificarSesion',
            table: 'usuarios',
            error: 'Usuario inactivo',
            additionalInfo: 'Cerrando sesión automáticamente',
          );
          await cerrarSesion();
          return null;
        }
        
        // Si es estudiante, cargar datos completos del estudiante
        if (usuario.esEstudiante) {
          try {
            final estudianteResponse = await _supabase
                .from('estudiantes')
                .select()
                .eq('usuario_id', usuario.id)
                .maybeSingle();
            
            if (estudianteResponse != null) {
              final estudianteCompleto = EstudianteAdmin.fromJson(estudianteResponse);
              return usuario.copyWith(perfil: estudianteCompleto);
            }
          } catch (e) {
            ApiLogger.logError(
              operation: 'verificarSesion_perfil_estudiante',
              table: 'estudiantes',
              error: e,
              additionalInfo: 'No se pudo cargar perfil completo del estudiante',
            );
          }
        }
        
        return usuario;
      }

      // 2. FALLBACK: Buscar en tablas legacy basado en el rol
      ApiLogger.logGet(
        table: 'usuarios',
        statusCode: 404,
        response: {'found': false},
        filters: {'id': userId, 'fallback_iniciado': true},
      );
      
      if (userRole == 'estudiante') {
        try {
          final resp = await _supabase
              .from('estudiantes')
              .select()
              .eq('id', userId)
              .maybeSingle();
        
          if (resp != null) {
        ApiLogger.logGet(
          table: 'estudiantes',
          statusCode: 200,
              response: {'found': true, 'fallback': true},
          filters: {'id': userId},
        );
            final usuario = ModeloUsuario.fromEstudianteJson(resp);
            // Cargar datos completos del estudiante para el perfil
            final estudianteCompleto = EstudianteAdmin.fromJson(resp);
            return usuario.copyWith(perfil: estudianteCompleto);
          }
        } catch (e) {
          ApiLogger.logError(
            operation: 'verificarSesion_fallback',
            table: 'estudiantes',
            error: e,
            additionalInfo: 'Fallback estudiante falló',
          );
        }
      } else if (userRole == 'profesor') {
        try {
          final resp = await _supabase
              .from('profesores')
              .select()
              .eq('id', userId)
              .maybeSingle();
        
          if (resp != null) {
        ApiLogger.logGet(
          table: 'profesores',
          statusCode: 200,
              response: {'found': true, 'fallback': true},
          filters: {'id': userId},
        );
        return ModeloUsuario.fromProfesorJson(resp);
      }
        } catch (e) {
          ApiLogger.logError(
            operation: 'verificarSesion_fallback',
            table: 'profesores',
            error: e,
            additionalInfo: 'Fallback profesor falló',
          );
        }
      }

      // 3. Si no se encuentra en ninguna tabla, limpiar sesión
      ApiLogger.logError(
        operation: 'verificarSesion',
        table: 'all_tables',
        error: 'Usuario no encontrado en ninguna tabla',
        additionalInfo: 'Limpiando sesión inválida',
      );
      
      await cerrarSesion();
      return null;

    } catch (e) {
      ApiLogger.logError(
        operation: 'verificarSesion',
        table: 'usuarios',
        error: e,
        additionalInfo: 'Error general en verificación de sesión',
      );
      
      // En caso de error de red u otro, no limpiar la sesión automáticamente
      // El usuario podría estar offline
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Limpiar todos los datos del usuario
    await prefs.remove('userId');
    await prefs.remove('userRole');
    await prefs.remove('userNombreCompleto');
    await prefs.remove('userCodigoUsuario');
    await prefs.remove('userCorreoElectronico');
    await prefs.remove('userActivo');
    await prefs.remove('sessionTimestamp');
    await prefs.remove('userDataTimestamp');
    
    ApiLogger.logPost(
      table: 'session',
      statusCode: 200,
      response: {
        'logout': true,
        'cleared_cache': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Limpia el caché de datos del usuario para forzar recarga
  Future<void> limpiarCacheUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('userNombreCompleto');
    await prefs.remove('userCodigoUsuario');
    await prefs.remove('userCorreoElectronico');
    await prefs.remove('userActivo');
    await prefs.remove('userDataTimestamp');
    
    ApiLogger.logPost(
      table: 'user_data_cache',
      statusCode: 200,
      response: {
        'cache_cleared': true,
        'reason': 'force_refresh',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _establecerSesion(String userId, String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userRole', userRole);
    
    // Guardar timestamp de la sesión para validación
    await prefs.setInt('sessionTimestamp', DateTime.now().millisecondsSinceEpoch);
    
    ApiLogger.logPost(
      table: 'session',
      statusCode: 200,
      response: {
        'user_id': userId,
        'role': userRole,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Guarda los datos completos del usuario en SharedPreferences
  Future<void> guardarDatosUsuario(ModeloUsuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Para estudiantes, no guardar en caché para mantener datos frescos
    if (usuario.esEstudiante) {
      ApiLogger.logPost(
        table: 'user_data_cache',
        statusCode: 200,
        response: {
          'cached': false,
          'reason': 'estudiante_fresh_data_only',
          'user_name': usuario.nombreCompleto,
          'role': usuario.rol,
        },
      );
      return;
    }
    
    // Datos básicos ya guardados en _establecerSesion
    await prefs.setString('userNombreCompleto', usuario.nombreCompleto);
    await prefs.setString('userCodigoUsuario', usuario.codigoUsuario);
    await prefs.setString('userCorreoElectronico', usuario.correoElectronico ?? '');
    await prefs.setBool('userActivo', usuario.activo);
    
    // Timestamp para validar vigencia de los datos
    await prefs.setInt('userDataTimestamp', DateTime.now().millisecondsSinceEpoch);
    
    ApiLogger.logPost(
      table: 'user_data_cache',
      statusCode: 200,
      response: {
        'cached': true,
        'user_name': usuario.nombreCompleto,
        'role': usuario.rol,
      },
    );
  }

  /// Recupera los datos del usuario desde SharedPreferences
  Future<ModeloUsuario?> recuperarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = prefs.getString('userId');
    final userRole = prefs.getString('userRole');
    final nombreCompleto = prefs.getString('userNombreCompleto');
    final codigoUsuario = prefs.getString('userCodigoUsuario');
    final correoElectronico = prefs.getString('userCorreoElectronico');
    final activo = prefs.getBool('userActivo');
    final dataTimestamp = prefs.getInt('userDataTimestamp');
    
    // Verificar que tengamos datos básicos
    if (userId == null || userRole == null || nombreCompleto == null || codigoUsuario == null) {
      return null;
    }
    
    // Verificar que los datos no sean demasiado antiguos (7 días)
    if (dataTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysDiff = (now - dataTimestamp) / (1000 * 60 * 60 * 24);
      
      if (daysDiff > 7) {
        ApiLogger.logError(
          operation: 'recuperarDatosUsuario',
          table: 'user_data_cache',
          error: 'Datos en caché demasiado antiguos',
          additionalInfo: 'Días transcurridos: ${daysDiff.toStringAsFixed(1)}',
        );
        return null;
      }
    }
    
    // Crear el modelo de usuario desde caché
    final usuario = ModeloUsuario(
      id: userId,
      codigoUsuario: codigoUsuario,
      nombreCompleto: nombreCompleto,
      correoElectronico: correoElectronico?.isEmpty == true ? null : correoElectronico,
      rol: userRole,
      activo: activo ?? true,
      fechaCreacion: DateTime.now(), // Usar fecha actual como fallback
    );
    
    ApiLogger.logGet(
      table: 'user_data_cache',
      statusCode: 200,
      response: {
        'recovered': true,
        'user_name': nombreCompleto,
        'role': userRole,
        'cache_age_hours': dataTimestamp != null 
          ? ((DateTime.now().millisecondsSinceEpoch - dataTimestamp) / (1000 * 60 * 60)).toStringAsFixed(1)
          : 'unknown',
      },
    );
    
    return usuario;
  }
} 