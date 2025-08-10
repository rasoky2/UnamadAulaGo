import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/screens/alumno/widgets/item_navegacion.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Widget Contenedor y Proveedor de Datos (ConsumerWidget)
/// Se encarga de la lógica de estado y de pasar los datos a la UI.
class PantallaTareasAlumno extends ConsumerWidget {
  const PantallaTareasAlumno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiante = ref.watch(usuarioActualProvider);
    final futureTareas = TareaRepository().obtenerTareas();

    if (estudiante == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<List<ModeloTarea>>(
      future: futureTareas,
      builder: (context, snapshot) {
        final tareasAsync = snapshot.connectionState == ConnectionState.waiting
            ? const AsyncValue<List<ModeloTarea>>.loading()
            : snapshot.hasError
                ? AsyncValue<List<ModeloTarea>>.error(snapshot.error!, StackTrace.current)
                : AsyncValue<List<ModeloTarea>>.data(snapshot.data ?? []);
        return _TareasView(
          estudiante: estudiante,
          tareasAsync: tareasAsync,
          onRetry: () {
            // No hay provider que invalidar; reconstruimos el FutureBuilder
            (context as Element).markNeedsBuild();
          },
        );
      },
    );
  }
}

/// Es una vista pura que solo se encarga de renderizar la UI con los datos que recibe.
class _TareasView extends StatelessWidget {

  const _TareasView({
    required this.estudiante,
    required this.tareasAsync,
    required this.onRetry,
  });
  final ModeloUsuario estudiante;
  final AsyncValue<List<ModeloTarea>> tareasAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      body: Column(
        children: [
          _Header(estudiante: estudiante),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 75,
                  child: tareasAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${err.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: onRetry,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    data: (tareas) => SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Breadcrumb(),
                          const SizedBox(height: AppConstants.largePadding),
                          const _TituloTareas(),
                          const SizedBox(height: AppConstants.largePadding),
                          _ListaTareas(tareas: tareas),
                        ],
                      ),
                    ),
                  ),
                ),
                const _PanelLateral(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ModeloUsuario>('estudiante', estudiante))
    ..add(DiagnosticsProperty<AsyncValue<List<ModeloTarea>>>('tareasAsync', tareasAsync))
    ..add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry));
  }
}

// --- Widgets de UI puros y sin estado ---

class _Header extends StatelessWidget {
  const _Header({required this.estudiante});
  final ModeloUsuario estudiante;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.largePadding,
        vertical: AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // ~5% opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'UNAMAD',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.backgroundLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppConstants.primaryColor.withAlpha(77)), // ~30% opacity
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppConstants.primaryColor),
                SizedBox(width: 6),
                Text(
                  '2024-I', // FIX: (Dato dinámico)
                  style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Text(
                estudiante.nombreCompleto.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Alumnos',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppConstants.primaryColor.withAlpha(26), // ~10% opacity
                child: const Icon(Icons.person, size: 16, color: AppConstants.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloUsuario>('estudiante', estudiante));
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () {}, // FIX: (Navegación)
          child: const Text('Inicio', style: TextStyle(fontSize: 14, color: AppConstants.primaryColor)),
        ),
        const Text(' / ', style: TextStyle(color: AppConstants.textTertiary)),
        TextButton(
          onPressed: () {}, // FIX: (Navegación)
          child: const Text(
            'MI CURSO DE EJEMPLO', // FIX: (Dato dinámico)
            style: TextStyle(fontSize: 14, color: AppConstants.primaryColor),
          ),
        ),
        const Text(' / ', style: TextStyle(color: AppConstants.textTertiary)),
        const Text('Tareas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.primaryColor)),
      ],
    );
  }
}

class _TituloTareas extends StatelessWidget {
  const _TituloTareas();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.assignment_outlined, color: AppConstants.primaryColor, size: 24),
        const SizedBox(width: 12),
        const Text('Tareas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
        const Spacer(),
        ElevatedButton(
          onPressed: () {}, // FIX: (Navegación)
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Regresar', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _ListaTareas extends StatelessWidget {
  const _ListaTareas({required this.tareas});
  final List<ModeloTarea> tareas;

  @override
  Widget build(BuildContext context) {
    if (tareas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            '¡Genial! No tienes tareas pendientes por ahora.',
            style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: tareas.map((tarea) => _TarjetaTarea(tarea: tarea)).toList(),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<ModeloTarea>('tareas', tareas));
  }
}

class _TarjetaTarea extends StatelessWidget {
  const _TarjetaTarea({required this.tarea});
  final ModeloTarea tarea;

  @override
  Widget build(BuildContext context) {
    final fechaCierre = tarea.fechaEntrega;
    final esUrgente = fechaCierre.isBefore(DateTime.now().add(const Duration(days: 2)));

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // ~5% opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: esUrgente ? const Border(left: BorderSide(color: Colors.red, width: 4)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withAlpha(26), // ~10% opacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_outlined, color: AppConstants.primaryColor, size: 24),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                ),
                if (tarea.nombreCurso != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    tarea.nombreCurso!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppConstants.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Fecha de cierre:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppConstants.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMMEEEEd('es').add_jm().format(fechaCierre),
                      style: TextStyle(
                        fontSize: 12,
                        color: esUrgente ? Colors.red : AppConstants.textPrimary,
                        fontWeight: esUrgente ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enunciado de la tarea:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  tarea.descripcion ?? 'Sin descripción.',
                  style: const TextStyle(fontSize: 14, color: AppConstants.textPrimary, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pendiente', // FIX: (Implementar lógica de estado)
                  style: TextStyle(fontSize: 11, color: AppConstants.textTertiary),
                ),
              ),
              if (esUrgente) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26), // ~10% opacity
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'URGENTE',
                    style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloTarea>('tarea', tarea));
  }
}

class _PanelLateral extends StatelessWidget {
  const _PanelLateral();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code, color: AppConstants.primaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MI CURSO DE EJEMPLO', // FIX: (Dato dinámico)
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.largePadding),
          ItemNavegacion(titulo: 'Anuncios', icono: Icons.campaign_outlined, onTap: () {}),
          ItemNavegacion(titulo: 'Unidades', icono: Icons.folder_outlined, onTap: () {}),
          ItemNavegacion(titulo: 'Exámenes', icono: Icons.quiz_outlined, onTap: () {}),


          ItemNavegacion(titulo: 'Tareas', icono: Icons.assignment_outlined, activo: true, onTap: () {}),
          ItemNavegacion(titulo: 'Calificaciones', icono: Icons.grade_outlined, onTap: () {}),
          ItemNavegacion(titulo: 'Calendario', icono: Icons.calendar_today_outlined, onTap: () {}),



          ItemNavegacion(titulo: 'Wikis', icono: Icons.public_outlined, onTap: () {}),
        ],
      ),
    );
  }
}