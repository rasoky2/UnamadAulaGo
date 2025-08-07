import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/profesor/home.profesor.riverpod.dart';
import 'package:aulago/screens/profesor/cursos.profesor.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pantalla simplificada del dashboard del profesor
/// Solo contiene la vista de inicio, la navegación la maneja ProfesorLayout
class PantallaDashboardProfesor extends ConsumerWidget {
  const PantallaDashboardProfesor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cursosAsync = ref.watch(cursosProfesorProvider);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          _construirHeaderBienvenida(context),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Resumen rápido
          _construirResumenRapido(context),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Lista de cursos
          _construirSeccionCursos(context, cursosAsync),
        ],
      ),
    );
  }

  Widget _construirHeaderBienvenida(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido de vuelta!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona tus cursos y estudiantes desde aquí',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumenRapido(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    if (ancho < 700) {
      return const Column(
        children: [
          _TarjetaEstadistica(
            icono: Icons.book,
            titulo: 'Cursos Activos',
            valor: '3',
            color: Colors.blue,
          ),
          SizedBox(height: AppConstants.defaultPadding),
          _TarjetaEstadistica(
            icono: Icons.people,
            titulo: 'Estudiantes',
            valor: '45',
            color: Colors.green,
          ),
          SizedBox(height: AppConstants.defaultPadding),
          _TarjetaEstadistica(
            icono: Icons.assignment,
            titulo: 'Tareas Pendientes',
            valor: '8',
            color: Colors.orange,
          ),
        ],
      );
    }
    return const Row(
      children: [
        Expanded(
          child: _TarjetaEstadistica(
            icono: Icons.book,
            titulo: 'Cursos Activos',
            valor: '3',
            color: Colors.blue,
          ),
        ),
        SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: _TarjetaEstadistica(
            icono: Icons.people,
            titulo: 'Estudiantes',
            valor: '45',
            color: Colors.green,
          ),
        ),
        SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: _TarjetaEstadistica(
            icono: Icons.assignment,
            titulo: 'Tareas Pendientes',
            valor: '8',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _construirSeccionCursos(BuildContext context, AsyncValue<List<ModeloCurso>> cursosAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mis Cursos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                // TODO: Navegar a la página de cursos completa
                debugPrint('🔗 Navegando a ver todos los cursos');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Ver todos'),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        cursosAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.largePadding),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => _construirErrorWidget(err),
          data: (cursos) => _construirGridCursos(context, cursos),
        ),
      ],
    );
  }

  Widget _construirErrorWidget(Object error) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar cursos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _construirGridCursos(BuildContext context, List<ModeloCurso> cursos) {
    if (cursos.isEmpty) {
      return _construirEstadoVacio();
    }
    final ancho = MediaQuery.of(context).size.width;
    final crossAxisCount = ancho < 700 ? 1 : (ancho < 1100 ? 2 : 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: cursos.length,
      itemBuilder: (context, index) {
        final curso = cursos[index];
        return _TarjetaCurso(curso: curso);
      },
    );
  }

  Widget _construirEstadoVacio() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding * 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppConstants.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            'No tienes cursos asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Contacta al administrador para que te asigne cursos',
            style: TextStyle(
              color: AppConstants.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {

  const _TarjetaEstadistica({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(StringProperty('titulo', titulo))
      ..add(StringProperty('valor', valor))
      ..add(ColorProperty('color', color));
  }
}

class _TarjetaCurso extends StatelessWidget {
  const _TarjetaCurso({required this.curso});

  final ModeloCurso curso;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del curso
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.codigoCurso,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Text(
                        curso.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            Row(
              children: [
                _InfoItem(
                  icono: Icons.schedule,
                  texto: '${curso.creditos} créditos',
                ),
                const SizedBox(width: 16),
                const _InfoItem(
                  icono: Icons.people,
                  texto: '24 estudiantes', // TODO: Obtener dato real
                ),
              ],
            ),
            
            const Spacer(),
            
            // Botón de acción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PantallaGestionCurso(curso: curso),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: const Text('Gestionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCurso>('curso', curso));
  }
}

class _InfoItem extends StatelessWidget {

  const _InfoItem({
    required this.icono,
    required this.texto,
  });
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icono,
          size: 14,
          color: AppConstants.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(StringProperty('texto', texto));
  }
} 

class ResponsiveScaffold extends StatelessWidget {

  const ResponsiveScaffold({
    required this.mobileBody,
    required this.desktopBody,
    this.appBar,
    this.drawer,
    super.key,
  });
  final Widget mobileBody;
  final Widget desktopBody;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    return Scaffold(
      appBar: appBar,
      drawer: esMovil ? drawer : null,
      body: esMovil ? mobileBody : desktopBody,
    );
  }
} 
