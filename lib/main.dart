import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/routes/routes.dart';
import 'package:aulago/screens/alumno/home.alumno.screen.dart';
import 'package:aulago/screens/auth/login.screen.dart';
import 'package:aulago/screens/splash.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  await initializeDateFormatting('es'); // Inicializa soporte de fechas en español
  
  runApp(
    const ProviderScope(
      child: AulaGoApp(),
    ),
  );
}

class AulaGoApp extends StatelessWidget {
  const AulaGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }

  ThemeData _buildTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      primary: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
      tertiary: AppConstants.accentColor,
      surface: AppConstants.surfaceColor,
      onSurface: AppConstants.textPrimary,
    );

    final TextTheme textTheme = GoogleFonts.notoSansTextTheme().copyWith(
      displayLarge: GoogleFonts.notoSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.notoSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
        letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      ),
      
      headlineLarge: GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      ),
      headlineSmall: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      ),
      
      titleLarge: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppConstants.textPrimary,
      ),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppConstants.textPrimary,
      ),
      titleSmall: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppConstants.textSecondary,
      ),
      
      bodyLarge: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppConstants.textPrimary,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppConstants.textSecondary,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppConstants.textTertiary,
        height: 1.3,
      ),
      
      labelLarge: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppConstants.primaryColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppConstants.textSecondary,
        letterSpacing: 0.1,
      ),
      labelSmall: GoogleFonts.notoSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppConstants.textTertiary,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppConstants.primaryColor.withValues(alpha: 0.3),
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          elevation: 3,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 12,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: AppConstants.cardElevation,
        shadowColor: AppConstants.primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: AppConstants.textTertiary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: AppConstants.textTertiary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 12,
        ),
        labelStyle: GoogleFonts.notoSans(
          color: AppConstants.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.notoSans(
          color: AppConstants.textTertiary,
          fontWeight: FontWeight.normal,
        ),
      ),
      
      scaffoldBackgroundColor: AppConstants.surfaceColor,
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textTertiary,
        selectedLabelStyle: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      iconTheme: const IconThemeData(
        color: AppConstants.textSecondary,
        size: AppConstants.iconSize,
      ),
      
      splashColor: AppConstants.primaryColor.withValues(alpha: 0.1),
      highlightColor: AppConstants.primaryColor.withValues(alpha: 0.05),
    );
  }
}

class EnvolvedorAuth extends ConsumerWidget {
  const EnvolvedorAuth({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoAuth = ref.watch(proveedorAuthProvider);
    
    if (estadoAuth.cargando) {
      return const PantallaSplash();
    }
    
    if (estadoAuth.estaAutenticado) {
      return const PantallaInicioAlumno();
    }
    
    return const PantallaLogin();
  }
}
