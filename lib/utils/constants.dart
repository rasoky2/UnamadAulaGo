import 'package:flutter/material.dart';

class AppConstants {
  // Credenciales de Supabase
  static const String supabaseUrl = 'https://nvemipvduvzlvpnofxua.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52ZW1pcHZkdXZ6bHZwbm9meHVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2MDkxOTUsImV4cCI6MjA2NjE4NTE5NX0.Y8MQ_558xbQUHuAbQCPNNAl0sf_6zRlTppHCL-s-MMQ';
  
  // Colores oficiales UNAMAD basados en el manual de identidad corporativa
  static const Color primaryColor = Color(0xFFE91E63); // Fucsia institucional
  static const Color secondaryColor = Color(0xFF2E7D3E); // Verde amazónico
  static const Color accentColor = Color(0xFFFF5722); // Naranja complementario
  
  // Colores por facultades (según manual oficial)
  static const Map<String, Color> facultyColors = {
    'administracion': Color(0xFFFF6600), // Naranja - Administración y Negocios
    'contabilidad': Color(0xFF8B0000), // Rojo Vino - Contabilidad y Finanzas
    'derecho': Color(0xFF8B0000), // Rojo Vino - Derecho y Ciencias Políticas
    'ecoturismo': Color(0xFF808000), // Verde Olivo - Ecoturismo
    'educacion': Color(0xFF0066CC), // Azul - Educación
    'enfermeria': Color(0xFF40E0D0), // Turquesa - Enfermería
    'agroindustrial': Color(0xFFDC143C), // Rojo - Ingeniería Agroindustrial
    'forestal': Color(0xFF006400), // Verde Oscuro - Ingeniería Forestal
    'sistemas': Color(0xFF9370DB), // Lila - Sistemas e Informática
    'veterinaria': Color(0xFF800000), // Granate - Medicina Veterinaria
  };
  
  // Colores de estado
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Colores de UI específicos
  static const Color darkButton = Color(0xFF072D3E); // Azul oscuro para botones de acción
  
  // Colores de superficie
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Textos
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  
  // Espaciado y dimensiones
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Iconos y tamaños
  static const double iconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double smallIconSize = 16.0;
  
  // Información de UNAMAD
  static const String universityName = 'Universidad Nacional Amazónica de Madre de Dios';
  static const String universityShortName = 'UNAMAD';
  static const String universityAddress = 'AV. Jorge Chávez N° 1160';
  static const String universityPhone = '+51 975842679';
  static const String universityEmail = 'tramite-documentario@unamad.edu.pe';
  
  // Configuración de la app
  static const String appName = 'AulaGo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Aula Virtual UNAMAD';
  
  // Duraciones de animación
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Roles de usuario
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';
  
  // Estados de matrícula
  static const String enrollmentStatusActive = 'active';
  static const String enrollmentStatusInactive = 'inactive';
  static const String enrollmentStatusGraduated = 'graduated';
  static const String enrollmentStatusDropped = 'dropped';
  
  // Tipos de contenido
  static const String lessonTypeVideo = 'video';
  static const String lessonTypeReading = 'reading';
  static const String lessonTypeQuiz = 'quiz';
  static const String lessonTypeAssignment = 'assignment';
  static const String lessonTypeDiscussion = 'discussion';
  
  // Códigos de facultades
  static const String facultyEngineeringCode = 'FI';
  static const String facultyEducationCode = 'FE';
  static const String facultyEcotourismCode = 'FET';
  
  // Semestres académicos
  static const int maxSemesters = 12;
  static const int defaultSemesters = 10;
} 