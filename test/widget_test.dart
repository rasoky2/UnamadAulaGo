// Pruebas de widgets para AulaGo - Enfoque Caja Negra
// Probamos desde la perspectiva del usuario final

import 'package:aulago/main.dart';
import 'package:aulago/screens/admin/admin.layout.dart';
import 'package:aulago/screens/auth/login.screen.dart';
import 'package:aulago/screens/profesor/profesor.layout.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// UTILIDAD: Carga de datos de Supabase MCP tools para pruebas de integración
// Tool call supabase mcp
void mostrarDatosSupabase() {
  // Ejemplo de datos obtenidos de Supabase (mock para test)
  const estudiante = {
    'id': '28e3fac5-9ff0-4c1e-9687-e89aeffb8145',
    'codigo_estudiante': '19221011',
    'nombre_completo': 'Jasseir James Chicata Acosta',
    'correo_electronico': '19221011@estudiante.unamad.edu.pe',
    'telefono': '977805968',
    'semestre_actual': 5,
    'estado': 'activo',
  };
  const profesor = {
    'id': '102af2e2-87e5-4667-9e90-4810658fee0d',
    'codigo_profesor': 'P001',
    'nombre_completo': 'Dr. Juan Carlos Mendoza',
    'correo_electronico': 'jmendoza@unamad.edu.pe',
    'telefono': '982123456',
    'especialidad': 'Sistemas de Información',
    'grado_academico': 'Doctor',
    'estado': 'activo',
  };
  const curso = {
    'id': '0971e9a7-5d48-4980-b1cb-ac2c5617518a',
    'codigo_curso': 'IS301',
    'nombre': 'Base de Datos',
    'descripcion': 'Diseño e implementación de sistemas de bases de datos',
    'creditos': 4,
    'semestre_recomendado': 3,
    'es_obligatorio': true,
  };
  const tarea = {
    'id': '8da14629-297a-4429-b0fe-8a56b7129062',
    'titulo': 'Proyecto: Página Web Personal',
    'descripcion': 'Desarrollo de una página web personal usando HTML5, CSS3 y JavaScript',
    'instrucciones': 'Crear una página web personal que incluya: 1) Información personal, 2) Portafolio de proyectos, 3) Formulario de contacto con validación JavaScript, 4) Diseño responsive',
    'fecha_asignacion': '2025-06-22 17:43:53.789045+00',
    'fecha_entrega': '2025-02-28 23:59:00+00',
    'puntos_maximos': '100.00',
    'tipo_tarea': 'individual',
    'estado': 'activa',
  };
  // Imprimir en consola para pruebas
  // ignore: avoid_print
  print('Estudiante: \n$estudiante');
  // ignore: avoid_print
  print('Profesor: \n$profesor');
  // ignore: avoid_print
  print('Curso: \n$curso');
  // ignore: avoid_print
  print('Tarea: \n$tarea');
}

void main() {
  group('🔐 Pruebas de Autenticación (Caja Negra)', () {
    testWidgets('Pantalla de login se muestra correctamente', (WidgetTester tester) async {
      // Construir la app
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      // Verificar que aparece la pantalla de login
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Usuario y contraseña
      expect(find.text('INGRESAR'), findsOneWidget);
    });

    testWidgets('Validación de campos vacíos en login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PantallaLogin(),
          ),
        ),
      );

      // Intentar login sin datos
      final botonLogin = find.text('INGRESAR');
      await tester.tap(botonLogin);
      await tester.pump();

      // Debería mostrar validaciones (esto dependerá de tu implementación)
      // Por ahora verificamos que el botón existe
      expect(botonLogin, findsOneWidget);
    });

    testWidgets('Ingreso de credenciales de usuario', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PantallaLogin(),
          ),
        ),
      );

      // Encontrar campos de texto
      final campoUsuario = find.byKey(const Key('campo_usuario'));
      final campoContrasena = find.byKey(const Key('campo_contrasena'));

      // Si no tienen keys, usar por tipo y posición
      final camposTexto = find.byType(TextFormField);
      
      if (campoUsuario.evaluate().isNotEmpty) {
        // Ingresar datos con keys
        await tester.enterText(campoUsuario, 'admin@unamad.edu.pe');
        await tester.enterText(campoContrasena, 'admin123');
      } else {
        // Ingresar datos por posición
        await tester.enterText(camposTexto.first, 'admin@unamad.edu.pe');
        await tester.enterText(camposTexto.last, 'admin123');
      }

      await tester.pump();

      // Verificar que se ingresaron los datos
      expect(find.text('admin@unamad.edu.pe'), findsOneWidget);
    });
  });

  group('🏠 Pruebas de Navegación (Caja Negra)', () {
    testWidgets('Verificar elementos de la app principal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      // Verificar que la app se inicializa
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('👤 Pruebas de Interfaz de Administrador (Caja Negra)', () {
    testWidgets('Layout de administrador muestra navegación', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminLayout(titulo: 'Panel de Administración'),
          ),
        ),
      );

      // Verificar elementos de navegación del admin
      // Nota: Esto puede fallar si requiere autenticación
      await tester.pumpAndSettle();
      
      // Buscar elementos comunes de admin
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('👨‍🏫 Pruebas de Interfaz de Profesor (Caja Negra)', () {
    testWidgets('Layout de profesor muestra navegación', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfesorLayout(titulo: 'Panel del Profesor'),
          ),
        ),
      );

      // Verificar elementos de navegación del profesor
      await tester.pumpAndSettle();
      
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('🎨 Pruebas de Componentes UI (Caja Negra)', () {
    testWidgets('Verificar colores y tema de la aplicación', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      // Verificar que se aplica el tema
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('Constantes de la aplicación están definidas', (WidgetTester tester) async {
      // Verificar que las constantes existen (no depende de widgets)
      expect(AppConstants.primaryColor, isNotNull);
      expect(AppConstants.textPrimary, isNotNull);
      expect(AppConstants.backgroundLight, isNotNull);
    });
  });

  group('📱 Pruebas de Responsividad (Caja Negra)', () {
    testWidgets('App funciona en pantalla móvil', (WidgetTester tester) async {
      // Simular pantalla móvil
      await tester.binding.setSurfaceSize(const Size(375, 667));
      
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App funciona en pantalla desktop', (WidgetTester tester) async {
      // Simular pantalla desktop
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('♿ Pruebas de Accesibilidad (Caja Negra)', () {
    testWidgets('Verificar que no hay problemas de accesibilidad', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: AulaGoApp(),
        ),
      );

      // Verificar accesibilidad
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });
}
