import 'package:aulago/models/estadisticas_admin.model.dart';
import 'package:aulago/providers/admin/estadisticas.admin.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantalla principal que retorna directamente el contenido
class PantallaHomeAdmin extends ConsumerWidget {
  const PantallaHomeAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadisticas = ref.watch(estadisticasAdminProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas de estadísticas
          _EstadisticasSistema(estadisticas: estadisticas, onRefresh: () {
            ref.read(estadisticasAdminProvider.notifier).refrescar();
          }),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Gestión de usuarios
          _GestionUsuarios(),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Configuración del sistema
          _ConfiguracionSistema(),
        ],
      ),
    );
  }
}

// Estadísticas del sistema UI puro
class _EstadisticasSistema extends StatelessWidget {
  
  const _EstadisticasSistema({required this.estadisticas, required this.onRefresh});
  final EstadisticasAdmin estadisticas;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: estadisticas.cargando ? null : onRefresh,
              icon: estadisticas.cargando 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refrescar estadísticas',
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        if (estadisticas.cargando)
          const Center(child: CircularProgressIndicator())
        else if (estadisticas.error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  const Icon(Icons.error, color: AppConstants.errorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${estadisticas.error}',
                      style: const TextStyle(color: AppConstants.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Estudiantes',
                  valor: estadisticas.totalEstudiantes.toString(),
                  icono: Icons.school,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Profesores',
                  valor: estadisticas.totalProfesores.toString(),
                  icono: Icons.person_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Cursos',
                  valor: estadisticas.totalCursos.toString(),
                  icono: Icons.book,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Activos Hoy',
                  valor: '${estadisticas.porcentajeActivosHoy.toStringAsFixed(1)}%',
                  icono: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<EstadisticasAdmin>('estadisticas', estadisticas))
    ..add(ObjectFlagProperty<VoidCallback>.has('onRefresh', onRefresh));
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  
  const _TarjetaEstadistica({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: color, size: 24),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textSecondary,
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
    properties..add(StringProperty('titulo', titulo))
    ..add(StringProperty('valor', valor))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(ColorProperty('color', color));
  }
}

// Gestión de usuarios UI puro
class _GestionUsuarios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: _TarjetaAccionRapida(
                titulo: 'Estudiantes',
                descripcion: 'Gestionar estudiantes registrados',
                icono: Icons.school,
                color: Colors.blue,
                onTap: () => Navigator.of(context).pushNamed('/admin-estudiantes'),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _TarjetaAccionRapida(
                titulo: 'Profesores',
                descripcion: 'Gestionar profesores del sistema',
                icono: Icons.person_outline,
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gestión de profesores próximamente'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfiguracionSistema extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuración del Sistema',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: _TarjetaAccionRapida(
                titulo: 'Cursos',
                descripcion: 'Administrar cursos académicos',
                icono: Icons.book,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gestión de cursos próximamente'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _TarjetaAccionRapida(
                titulo: 'Reportes',
                descripcion: 'Generar reportes del sistema',
                icono: Icons.analytics,
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reportes próximamente'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaAccionRapida extends StatelessWidget {

  const _TarjetaAccionRapida({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.onTap,
  });
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icono, color: color, size: 24),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppConstants.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('titulo', titulo))
    ..add(StringProperty('descripcion', descripcion))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(ColorProperty('color', color))
    ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}

// Clase pública para mantener compatibilidad (deprecated)
@Deprecated('Usar PantallaInicioAdmin en su lugar')
class PantallaDashboardAdmin extends PantallaHomeAdmin {
  @Deprecated('Usar PantallaInicioAdmin en su lugar')
  const PantallaDashboardAdmin({super.key});
} 