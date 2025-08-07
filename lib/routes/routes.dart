import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/screens/admin/admin.layout.dart';
import 'package:aulago/screens/alumno/alumno.layout.dart';
import 'package:aulago/screens/alumno/cursos.alumno.screen.dart';
import 'package:aulago/screens/alumno/home.alumno.screen.dart';
import 'package:aulago/screens/alumno/widgets/perfil.alumno.widget.dart';
import 'package:aulago/screens/auth/login.screen.dart';
import 'package:aulago/screens/profesor/profesor.layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRoutes {
  static const String login = '/login';
  static const String homeAlumno = '/home-alumno';
  static const String homeProfesor = '/home-profesor';
  static const String homeAdmin = '/home-admin';

  static Map<String, Widget Function(BuildContext)> get routes {
    debugPrint('🛣️ AppRoutes: Configurando rutas de la aplicación');
    
    return {
       // Ruta de autenticación
       login: (context) {
         debugPrint('🔐 AppRoutes: Navegando a PantallaLogin');
         return const PantallaLogin();
       },
       
       // Rutas para roles de usuario específicos
       homeAlumno: (context) {
         debugPrint('👨‍🎓 AppRoutes: Navegando a PantallaInicioAlumno');
         return Consumer(
  builder: (context, ref, _) {
    final usuario = ref.watch(proveedorAuthProvider).usuario;
    return UnamadLayout(
      titulo: 'Inicio',
      nombreUsuario: usuario?.nombreCompleto ?? '',
      contenido: const PantallaInicioAlumno(),
    );
  },
);
       },
       
       // Ruta única de profesor - ProfesorLayout maneja toda la navegación interna
       homeProfesor: (context) {
         debugPrint('👨‍🏫 AppRoutes: Navegando a ProfesorLayout (maneja navegación interna)');
         return const ProfesorLayout(
           titulo: 'Portal del Profesor',
         );
       },
       
       // Ruta única de administración - AdminLayout maneja toda la navegación interna
       homeAdmin: (context) {
         debugPrint('🏠 AppRoutes: Navegando a AdminLayout (maneja navegación interna)');
         return const AdminLayout(
           titulo: 'Panel Administrativo',
         );
       },
       '/cursos': (context) => const PantallaCursosAlumno(),
       '/perfil': (context) => Consumer(
  builder: (context, ref, _) {
    final usuario = ref.watch(proveedorAuthProvider).usuario;
    return UnamadLayout(
      titulo: 'Perfil',
      nombreUsuario: usuario?.nombreCompleto ?? '',
      contenido: const PerfilAlumnoWidget(),
    );
  },
),
    };
  }

  /// Obtiene la ruta inicial basada en el rol del usuario
  static String obtenerRutaInicial(String? rol) {
    debugPrint('🎯 AppRoutes: Determinando ruta inicial para rol: $rol');
    
    switch (rol?.toLowerCase()) {
      case 'alumno':
      case 'estudiante':
        debugPrint('📚 AppRoutes: Ruta inicial -> HomeAlumno');
        return homeAlumno;
      case 'profesor':
        debugPrint('👨‍🏫 AppRoutes: Ruta inicial -> HomeProfesor');
        return homeProfesor;
      case 'administrador':
      case 'admin':
      case 'administrator':
        debugPrint('⚙️ AppRoutes: Ruta inicial -> HomeAdmin');
        return homeAdmin;
      default:
        debugPrint('🔐 AppRoutes: Ruta inicial por defecto -> Login (rol desconocido: $rol)');
        return login;
    }
  }

  /// Verifica si una ruta requiere autenticación
  static bool requiereAutenticacion(String ruta) {
    final rutasPublicas = [login];
    final requiere = !rutasPublicas.contains(ruta);
    debugPrint('🔒 AppRoutes: Ruta $ruta requiere autenticación: $requiere');
    return requiere;
  }

  /// Verifica si una ruta es de administración
  static bool esRutaAdmin(String ruta) {
    final esAdmin = ruta == homeAdmin;
    debugPrint('⚙️ AppRoutes: Ruta $ruta es de administración: $esAdmin');
    return esAdmin;
  }

  /// Verifica si una ruta es de profesor
  static bool esRutaProfesor(String ruta) {
    final esProfesor = ruta == homeProfesor;
    debugPrint('👨‍🏫 AppRoutes: Ruta $ruta es de profesor: $esProfesor');
    return esProfesor;
  }

  /// Obtiene el título de una ruta específica
  static String obtenerTituloRuta(String ruta) {
    debugPrint('📄 AppRoutes: Obteniendo título para ruta: $ruta');
    
    switch (ruta) {
      case homeAdmin:
        return 'Panel Administrativo';
      case homeAlumno:
        return 'Portal del Estudiante';
      case homeProfesor:
        return 'Portal del Profesor';
      case login:
        return 'Iniciar Sesión';
      default:
        return 'AulaGo';
    }
  }

  /// Maneja rutas no encontradas
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final rutaNombre = settings.name ?? '/';
    debugPrint('🚫 AppRoutes: Ruta no encontrada: $rutaNombre');
    
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Página no encontrada'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Página no encontrada',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'La página que buscas no existe.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 