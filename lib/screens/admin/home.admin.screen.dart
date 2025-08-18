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
          // Tarjetas de estadísticas principales
          _EstadisticasSistema(
              estadisticas: estadisticas,
              onRefresh: () {
                ref.read(estadisticasAdminProvider.notifier).refrescar();
              }),

          const SizedBox(height: AppConstants.largePadding),

          // Estadísticas adicionales
          _EstadisticasAdicionales(estadisticas: estadisticas),

          const SizedBox(height: AppConstants.largePadding),

          // Alertas del sistema
          if (estadisticas.alertasSistema.isNotEmpty)
            _AlertasSistema(alertas: estadisticas.alertasSistema),

          if (estadisticas.alertasSistema.isNotEmpty)
            const SizedBox(height: AppConstants.largePadding),
        ],
      ),
    );
  }
}

// Estadísticas del sistema UI puro
class _EstadisticasSistema extends StatelessWidget {
  const _EstadisticasSistema(
      {required this.estadisticas, required this.onRefresh});
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
                  subtitulo: '${estadisticas.estudiantesActivos} activos',
                  icono: Icons.school,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Profesores',
                  valor: estadisticas.totalProfesores.toString(),
                  subtitulo: '${estadisticas.profesoresActivos} activos',
                  icono: Icons.person_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Cursos',
                  valor: estadisticas.totalCursos.toString(),
                  subtitulo: '${estadisticas.cursosActivos} activos',
                  icono: Icons.book,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _TarjetaEstadistica(
                  titulo: 'Actividad',
                  valor:
                      '${estadisticas.porcentajeActivosHoy.toStringAsFixed(1)}%',
                  subtitulo: 'Últimos 30 días',
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
    properties
      ..add(
          DiagnosticsProperty<EstadisticasAdmin>('estadisticas', estadisticas))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRefresh', onRefresh));
  }
}

// Estadísticas adicionales del sistema
class _EstadisticasAdicionales extends StatelessWidget {
  const _EstadisticasAdicionales({required this.estadisticas});

  final EstadisticasAdmin estadisticas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Adicionales',
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
              child: _TarjetaEstadisticaAdicional(
                titulo: 'Tareas',
                valor: estadisticas.totalTareas.toString(),
                subtitulo: 'Total de tareas',
                icono: Icons.assignment,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _TarjetaEstadisticaAdicional(
                titulo: 'Exámenes',
                valor: estadisticas.totalExamenes.toString(),
                subtitulo: 'Total de exámenes',
                icono: Icons.quiz,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _TarjetaEstadisticaAdicional(
                titulo: 'Anuncios',
                valor: estadisticas.totalAnuncios.toString(),
                subtitulo: 'Anuncios del sistema',
                icono: Icons.announcement,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _TarjetaEstadisticaAdicional(
                titulo: 'Fechas Importantes',
                valor: estadisticas.totalFechasImportantes.toString(),
                subtitulo: 'Eventos programados',
                icono: Icons.event,
                color: Colors.teal,
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
    properties.add(DiagnosticsProperty<EstadisticasAdmin>('estadisticas', estadisticas));
  }
}

class _TarjetaEstadisticaAdicional extends StatelessWidget {
  const _TarjetaEstadisticaAdicional({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
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
    ..add(StringProperty('subtitulo', subtitulo))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(ColorProperty('color', color));
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  const _TarjetaEstadistica({
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icono,
    required this.color,
  });
  final String titulo;
  final String valor;
  final String? subtitulo;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ],
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
    properties
      ..add(StringProperty('titulo', titulo))
      ..add(StringProperty('valor', valor))
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(ColorProperty('color', color));
      properties.add(StringProperty('subtitulo', subtitulo));
  }
}

// Alertas del sistema
class _AlertasSistema extends StatelessWidget {
  const _AlertasSistema({required this.alertas});

  final List<AlertaSistema> alertas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Alertas del Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alertas.length}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...alertas.map((alerta) => _TarjetaAlerta(alerta: alerta)),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<AlertaSistema>('alertas', alertas));
  }
}

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta});

  final AlertaSistema alerta;

  Color _getColorTipo() {
    switch (alerta.tipo) {
      case TipoAlerta.error:
        return Colors.red;
      case TipoAlerta.warning:
        return Colors.orange;
      case TipoAlerta.info:
        return Colors.blue;
      case TipoAlerta.success:
        return Colors.green;
    }
  }

  IconData _getIconoTipo() {
    switch (alerta.tipo) {
      case TipoAlerta.error:
        return Icons.error;
      case TipoAlerta.warning:
        return Icons.warning;
      case TipoAlerta.info:
        return Icons.info;
      case TipoAlerta.success:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorTipo();
    final icono = _getIconoTipo();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    alerta.descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () {
                // TODO: Implementar descarte de alertas
              },
              tooltip: 'Descartar alerta',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlertaSistema>('alerta', alerta));
  }
}

// Clase pública para mantener compatibilidad (deprecated)
@Deprecated('Usar PantallaInicioAdmin en su lugar')
class PantallaDashboardAdmin extends PantallaHomeAdmin {
  @Deprecated('Usar PantallaInicioAdmin en su lugar')
  const PantallaDashboardAdmin({super.key});
}
