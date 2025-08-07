import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/repositories/auth.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

// Estado de autenticación
@immutable
class EstadoAuth {

  const EstadoAuth({
    this.estaAutenticado = false,
    this.cargando = true,
    this.usuario,
    this.mensajeError,
  });
  final bool estaAutenticado;
  final bool cargando;
  final ModeloUsuario? usuario;
  final String? mensajeError;

  EstadoAuth copyWith({
    bool? estaAutenticado,
    bool? cargando,
    ModeloUsuario? usuario,
    String? Function()? mensajeError,
  }) {
    return EstadoAuth(
      estaAutenticado: estaAutenticado ?? this.estaAutenticado,
      cargando: cargando ?? this.cargando,
      usuario: usuario ?? this.usuario,
      mensajeError: mensajeError != null ? mensajeError() : this.mensajeError,
    );
  }
}

// Provider de autenticación refactorizado
class ProveedorAuth extends StateNotifier<EstadoAuth> {
  
  ProveedorAuth(this._authRepository) : super(const EstadoAuth()) {
    _inicializarAuth();
  }
  final AuthRepository _authRepository;

  /// Inicialización de autenticación al crear el provider
  Future<void> _inicializarAuth() async {
    // Intentar cargar desde caché primero para respuesta rápida
    final usuarioCache = await _authRepository.recuperarDatosUsuario();
    if (usuarioCache != null) {
      state = state.copyWith(
        estaAutenticado: true,
        usuario: usuarioCache,
        cargando: false,
        mensajeError: () => null,
      );
      
      debugPrint('🚀 Inicio rápido: Usuario cargado desde caché');
      debugPrint('👤 Cache: ${usuarioCache.nombreCompleto} (${usuarioCache.rol})');
    }
    
    // Verificar sesión en background (por si hay cambios)
    await verificarSesion();
  }

  /// Inicia sesión con credenciales del usuario
  Future<bool> iniciarSesion(String codigo, String contrasena) async {
    // Validaciones básicas
    if (codigo.trim().isEmpty || contrasena.trim().isEmpty) {
      state = state.copyWith(
        cargando: false,
        mensajeError: () => 'Por favor, complete todos los campos',
      );
      return false;
    }

    state = state.copyWith(cargando: true, mensajeError: () => null);
    
    try {
      final usuario = await _authRepository.iniciarSesion(codigo.trim(), contrasena);
      
      state = state.copyWith(
        estaAutenticado: true,
        usuario: usuario,
        cargando: false,
        mensajeError: () => null,
      );
      
      debugPrint('🔍 Login: Usuario autenticado exitosamente');
      debugPrint('👤 Login: Nombre completo: ${usuario.nombreCompleto}');
      debugPrint('🎭 Login: Rol del usuario: "${usuario.rol}"');
      debugPrint('🆔 Login: ID del usuario: ${usuario.id}');
      
      return true;
    } catch (e) {
      final mensajeError = e.toString().replaceFirst('Exception: ', '');
      
      state = state.copyWith(
        estaAutenticado: false,
        cargando: false,
        mensajeError: () => mensajeError,
      );
      
      debugPrint('❌ Login: Error de autenticación: $mensajeError');
      return false;
    }
  }

  /// Cierra la sesión del usuario
  Future<void> cerrarSesion() async {
    try {
    await _authRepository.cerrarSesion();
      
      state = const EstadoAuth(
        cargando: false,
      );
      
      debugPrint('🚪 Logout: Sesión cerrada exitosamente');
    } catch (e) {
      debugPrint('❌ Logout: Error al cerrar sesión: $e');
      // Aún así, limpiamos el state local
      state = const EstadoAuth(
        cargando: false,
      );
  }
  }

  /// Verifica si hay una sesión activa válida
  Future<void> verificarSesion() async {
    state = state.copyWith(cargando: true, mensajeError: () => null);
    
    try {
      final usuario = await _authRepository.verificarSesion();
      
      if (usuario != null) {
        state = state.copyWith(
          estaAutenticado: true,
          usuario: usuario,
          cargando: false,
          mensajeError: () => null,
        );
        
        debugPrint('✅ Session: Sesión válida encontrada');
        debugPrint('👤 Session: Usuario: ${usuario.nombreCompleto}');
        debugPrint('🎭 Session: Rol: ${usuario.rol}');
      } else {
        state = state.copyWith(
          estaAutenticado: false,
          cargando: false,
          mensajeError: () => null,
        );
        
        debugPrint('ℹ️ Session: No hay sesión activa');
      }
    } catch (e) {
      state = state.copyWith(
        estaAutenticado: false,
        cargando: false,
        mensajeError: () => 'Error al verificar sesión. Intente nuevamente.',
      );
      
      debugPrint('❌ Session: Error al verificar sesión: $e');
    }
  }

  /// Refresca los datos del usuario actual
  Future<void> refrescarUsuario() async {
    if (!state.estaAutenticado || state.usuario == null) {
      return;
    }

    try {
      state = state.copyWith(cargando: true);
      
      // Para estudiantes, limpiar caché antes de refrescar
      if (state.usuario!.esEstudiante) {
        await limpiarCacheUsuario();
      }
      
      await verificarSesion();
    } catch (e) {
      debugPrint('❌ Refresh: Error al refrescar usuario: $e');
      state = state.copyWith(cargando: false);
    }
  }

  /// Limpia la caché de datos del usuario (fuerza recarga desde servidor)
  Future<void> limpiarCache() async {
    await _authRepository.cerrarSesion();
    debugPrint('🧹 Cache: Caché de usuario limpiada');
  }

  /// Limpia solo el caché de datos del usuario sin cerrar sesión
  Future<void> limpiarCacheUsuario() async {
    await _authRepository.limpiarCacheUsuario();
    debugPrint('🧹 Cache: Caché de datos de usuario limpiada');
  }
}

// Provider para el repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

// Provider principal
final proveedorAuthProvider = StateNotifierProvider<ProveedorAuth, EstadoAuth>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ProveedorAuth(authRepository);
});

// Provider para obtener el usuario actual fácilmente
final usuarioActualProvider = Provider<ModeloUsuario?>((ref) {
  return ref.watch(proveedorAuthProvider).usuario;
});

final estaAutenticadoProvider = Provider<bool>((ref) {
  final auth = ref.watch(proveedorAuthProvider);
  return auth.estaAutenticado;
});

final esEstudianteProvider = Provider<bool>((ref) {
  final auth = ref.watch(proveedorAuthProvider);
  return auth.usuario?.rol == 'estudiante';
});

final esProfesorProvider = Provider<bool>((ref) {
  final auth = ref.watch(proveedorAuthProvider);
  return auth.usuario?.rol == 'profesor';
});

final esAdministradorProvider = Provider<bool>((ref) {
  final auth = ref.watch(proveedorAuthProvider);
  final rol = auth.usuario?.rol;
  return rol == 'administrador' || rol == 'admin';
});

final nombreUsuarioProvider = Provider<String>((ref) {
  final usuario = ref.watch(proveedorAuthProvider).usuario;
  return usuario?.nombreCompleto ?? 'Invitado';
});

final codigoUsuarioProvider = Provider<String>((ref) {
  final auth = ref.watch(proveedorAuthProvider);
  return auth.usuario?.codigoUsuario ?? '';
}); 
