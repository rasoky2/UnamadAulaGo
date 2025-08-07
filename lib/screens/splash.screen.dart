import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/routes/routes.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class PantallaSplash extends ConsumerWidget {
  const PantallaSplash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado de autenticación para reaccionar a los cambios
    ref.listen<EstadoAuth>(proveedorAuthProvider, (previous, next) {
      // Si ya no está cargando, decidimos a dónde navegar
      if (!next.cargando) {
        if (next.estaAutenticado && next.usuario != null) {
          final usuario = next.usuario!;
          String route;
          if (usuario.esAdmin) {
            route = AppRoutes.homeAdmin;
          } else if (usuario.esProfesor) {
            route = AppRoutes.homeProfesor;
          } else {
            route = AppRoutes.homeAlumno;
          }
          Navigator.of(context).pushReplacementNamed(route);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.primaryColor, // Azul UNAMAD
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo-alt.png', // Logo en blanco
              width: 200,
            ),
            const SizedBox(height: 32),
            Text(
              'AULA VIRTUAL',
              style: GoogleFonts.notoSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 