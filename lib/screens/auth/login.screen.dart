import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/routes/routes.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});

  @override
  ConsumerState<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends ConsumerState<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _ocultarContrasena = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
    _verificarSesionExistente();
  }

  /// Verifica si hay una sesión activa al iniciar la app
  Future<void> _verificarSesionExistente() async {
    // Esperar un frame para que el provider se inicialice
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(proveedorAuthProvider);
      
      if (authState.estaAutenticado && mounted) {
        debugPrint('🚀 AutoLogin: Sesión existente detectada');
        debugPrint('👤 AutoLogin: ${authState.usuario?.nombreCompleto}');
        
        final rutaInicial = AppRoutes.obtenerRutaInicial(authState.usuario?.rol);
        
        if (mounted) {
          // Mostrar mensaje de carga rápida
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Restaurando sesión...',
                      style: GoogleFonts.notoSans(),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // Navegar después de un breve delay
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(rutaInicial);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final codigoGuardado = prefs.getString('codigoUsuario');
    if (codigoGuardado != null) {
      setState(() {
        _codigoController.text = codigoGuardado;
        _rememberMe = true;
      });
    }
  }

  Future<void> _guardarPreferencias(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('codigoUsuario', codigo);
    } else {
      await prefs.remove('codigoUsuario');
    }
  }

  Future<void> _manejarLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final codigo = _codigoController.text.trim();
    final contrasena = _contrasenaController.text;

    await ref.read(proveedorAuthProvider.notifier).iniciarSesion(codigo, contrasena);
    
    // El estado se actualiza en el provider, así que lo leemos después de la operación.
    final authState = ref.read(proveedorAuthProvider);

    if (mounted) {
      if (authState.estaAutenticado) {
        await _guardarPreferencias(codigo);
        
        // Debug: Imprimir información del usuario
        debugPrint('🔍 Login: Usuario autenticado exitosamente');
        debugPrint('👤 Login: Nombre completo: ${authState.usuario?.nombreCompleto}');
        debugPrint('🎭 Login: Rol del usuario: "${authState.usuario?.rol}"');
        debugPrint('🆔 Login: ID del usuario: ${authState.usuario?.id}');
        
        // Usamos el método centralizado para obtener la ruta según el rol
        final rutaInicial = AppRoutes.obtenerRutaInicial(authState.usuario?.rol);
        debugPrint('🎯 Login: Ruta inicial determinada: $rutaInicial');
        
          if (mounted) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Bienvenido, ${authState.usuario?.nombreCompleto}!',
                style: GoogleFonts.notoSans(),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          
          Navigator.of(context).pushReplacementNamed(rutaInicial);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authState.mensajeError ?? 'Error desconocido al iniciar sesión.',
                style: GoogleFonts.notoSans(),
              ),
              backgroundColor: AppConstants.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: SafeArea(
        child: isDesktop ? _construirLayoutEscritorio() : _construirLayoutMovil(),
      ),
    );
  }

  Widget _construirLayoutEscritorio() {
    return Row(
      children: [
        // Panel izquierdo - Formulario de login
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.white,
            child: _construirPanelFormulario(),
          ),
        ),
        // Panel derecho - Imagen de fondo
        Expanded(
          flex: 7,
          child: _construirPanelImagen(),
        ),
      ],
    );
  }

  Widget _construirLayoutMovil() {
    return Container(
      color: Colors.white,
      child: _construirPanelFormulario(),
    );
  }

  Widget _construirPanelFormulario() {
    final estadoAuth = ref.watch(proveedorAuthProvider);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo UNAMAD - Centrado
              _construirLogo(),
              const SizedBox(height: 40),
              
              // Título - Centrado
              Text(
                'AULA VIRTUAL',
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E5A96), // Azul UNAMAD
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo código de usuario
                    _construirCampoTexto(
                      controller: _codigoController,
                      icono: LucideIcons.user200,
                      hintText: '19221011',
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Ingresa tu código de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo contraseña
                    _construirCampoContrasena(),
                    const SizedBox(height: 16),
                    
                    // Checkbox "Recordarme"
                    _buildRememberMeCheckbox(),
                    
                    const SizedBox(height: 24),
                    
                    // Botón ingresar
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: estadoAuth.cargando ? null : _manejarLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63), // Rosa UNAMAD
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: estadoAuth.cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'INGRESAR',
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Enlace "¿Olvidaste tu contraseña?" - Centrado
                    Center(
                      child: TextButton(
                        onPressed: _mostrarDialogoAyuda,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E5A96),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Información de usuario de prueba
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.info200,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Usuario de prueba',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Código: 19221011\nContraseña: 123456789',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirLogo() {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        height: 70,
        width: 262,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controller,
    required IconData icono,
    required String hintText,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.notoSans(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icono,
            color: Colors.grey.shade600,
            size: 20,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.notoSans(
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _construirCampoContrasena() {
    return _construirCampoTexto(
      controller: _contrasenaController,
      icono: LucideIcons.lock200,
      hintText: '••••••••',
      obscureText: _ocultarContrasena,
      suffixIcon: IconButton(
        icon: Icon(
          _ocultarContrasena ? LucideIcons.eyeOff200 : LucideIcons.eye200,
          color: Colors.grey.shade600,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _ocultarContrasena = !_ocultarContrasena;
          });
        },
      ),
      validator: (valor) {
        if (valor == null || valor.isEmpty) {
          return 'Ingresa tu contraseña';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: const Color(0xFFE91E63),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Text(
            'Recordarme',
            style: GoogleFonts.notoSans(
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirPanelImagen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE91E63).withValues(alpha: 0.8),
            const Color(0xFF2E5A96).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo de estudiantes
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1523240795612-9a054b0db644?ixlib=rb-4.0.3&auto=format&fit=crop&w=1950&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Overlay con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFE91E63).withValues(alpha: 0.6),
                  const Color(0xFF2E5A96).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          
          // Elementos decorativos flotantes
          _construirElementosFlotantes(),
        ],
      ),
    );
  }

  Widget _construirElementosFlotantes() {
    return Stack(
      children: [
        // Rombo rosa (superior derecho)
        Positioned(
          top: 50,
          right: 100,
          child: Transform.rotate(
            angle: 0.785398, // 45 grados
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
              ),
            ),
          ),
        ),
        
        // Rombo azul (centro derecho)
        Positioned(
          top: 200,
          right: 50,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF2E5A96),
              ),
            ),
          ),
        ),
        
        // Rombo rosa pequeño (inferior)
        Positioned(
          bottom: 100,
          right: 120,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
              ),
            ),
          ),
        ),
        
        // Rombo azul (superior izquierdo)
        Positioned(
          top: 150,
          left: 80,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF2E5A96),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.notoSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E5A96),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para recuperar tu contraseña, comunícate con:',
              style: GoogleFonts.notoSans(),
            ),
            const SizedBox(height: 16),
            _construirInfoContacto(
              icono: LucideIcons.mail200,
              texto: 'soporte@unamad.edu.pe',
            ),
            const SizedBox(height: 8),
            _construirInfoContacto(
              icono: LucideIcons.phone200,
              texto: '(082) 571-023',
            ),
            const SizedBox(height: 8),
            _construirInfoContacto(
              icono: LucideIcons.mapPin200,
              texto: 'Oficina de Sistemas - UNAMAD',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE91E63),
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirInfoContacto({
    required IconData icono,
    required String texto,
  }) {
    return Row(
      children: [
        Icon(
          icono,
          size: 16,
          color: const Color(0xFF2E5A96),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
} 