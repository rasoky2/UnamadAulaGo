import 'package:aulago/models/curso.model.dart';
import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/screens/alumno/widgets/calendario.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/examenes.alumno.widget.dart';
import 'package:aulago/screens/alumno/widgets/foros.widget.dart';
import 'package:aulago/screens/alumno/widgets/lecturas.widget.dart';
import 'package:aulago/screens/alumno/widgets/tareas.widget.dart';
import 'package:aulago/screens/alumno/widgets/unidades.widget.dart';
import 'package:aulago/screens/alumno/widgets/videoconferencias.widget.dart';
import 'package:aulago/screens/alumno/widgets/wiki.widget.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moony_nav_bar/moony_nav_bar.dart';

class PantallaCursosAlumno extends ConsumerStatefulWidget {
  const PantallaCursosAlumno({super.key});

  @override
  ConsumerState<PantallaCursosAlumno> createState() => _PantallaCursosAlumnoState();
}

class _PantallaCursosAlumnoState extends ConsumerState<PantallaCursosAlumno> {
  String? herramientaActiva;

  @override
  Widget build(BuildContext context) {
    final estudiante = ref.watch(proveedorAuthProvider).usuario;
    final cursosAsync = ref.watch(cursosAlumnoProvider);
    final cursoState = ref.watch(cursoAlumnoStateProvider);
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;

    debugPrint('🟢 Curso seleccionado:  [1m${cursoState.cursoSeleccionadoId} [0m');

    if (estudiante == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (esMovil) {
      // Móvil: solo lista de cursos y herramientas, sin AppBar ni sidebar
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Mis Cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          cursosAsync.when(
            data: (cursos) => Column(
              children: cursos.map((curso) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _construirTarjetaCursoMovil(context, curso),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ],
      );
    }

    // Escritorio: mostrar el curso seleccionado dinámicamente
    return cursosAsync.when(
      data: (cursos) {
        if (cursos.isEmpty) {
          debugPrint('🟠 [DEBUG] No hay cursos disponibles para mostrar.');
          return const Center(child: Text('No tienes cursos disponibles.'));
        }
        final ModeloCursoDetallado cursoSeleccionado = cursos.firstWhere(
          (c) => c.curso.id == cursoState.cursoSeleccionadoId,
          orElse: () {
            debugPrint('🔴 [ERROR] No se encontró curso con id =  [1m${cursoState.cursoSeleccionadoId} [0m, devolviendo primero.');
            return cursos.first;
          },
        );
        debugPrint('🟣 Mostrando info de curso:  [1m${cursoSeleccionado.curso.nombre} [0m');
        return ResponsiveScaffold(
          mobileBody: _construirAreaPrincipal(cursoState.cursoSeleccionadoId),
          desktopBody: _construirContenidoCursoDetalle(context, cursoSeleccionado),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _construirContenidoCursoDetalle(BuildContext context, ModeloCursoDetallado? curso) {
    if (curso == null) {
      return const Center(
        child: Text('No tienes cursos matriculados'),
      );
    }
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    return Row(
      children: [
        Expanded(
          flex: 75,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: herramientaActiva == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _construirTituloPrincipal(curso.curso.id, nombreCurso: curso.curso.nombre),
                      const SizedBox(height: 32),
                      _construirInformacionGeneral(curso.curso.id),
                      const SizedBox(height: 40),
                      if (esMovil) _construirGridHerramientas(cursoId: curso.curso.id) else SizedBox(
                            height: 420, // altura máxima para el grid en escritorio
                            child: _construirGridHerramientas(cursoId: curso.curso.id),
                          ),
                    ],
                  )
                : _construirAreaPrincipal(curso.curso.id),
          ),
        ),
        Container(
          width: 300,
          color: Colors.white,
          child: _construirPanelLateral(),
        ),
      ],
    );
  }

  Widget _construirAreaPrincipal(String? cursoId) {
    final cursoSeleccionadoId = ref.watch(cursoAlumnoStateProvider).cursoSeleccionadoId;
    final idParaModulo = cursoId ?? cursoSeleccionadoId ?? '';
    switch (herramientaActiva) {
      case 'calendario':
        return CalendarioWidget(onRegresar: () => setState(() => herramientaActiva = null));
      case 'foros':
        return ForosWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'lecturas':
        return LecturasWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'unidades':
        return UnidadesWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
          cursoId: idParaModulo,
        );
      case 'examenes':
        return ExamenesWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
          cursoId: idParaModulo,
        );
      case 'tareas':
        return TareasWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'videoconferencias':
        return VideoconferenciasWidget(
          grupoClaseId: idParaModulo,
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'wiki':
        return WikiWidget(onRegresar: () => setState(() => herramientaActiva = null));
      default:
        return _construirContenidoPrincipal(cursoId);
    }
  }

  Widget _construirContenidoPrincipal(String? cursoId) {
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: esMovil
          ? _construirGridHerramientas()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _construirTituloPrincipal(cursoId, nombreCurso: ''),
                      const SizedBox(height: 32),
                      _construirInformacionGeneral(cursoId),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 100),
                      SizedBox(
                        height: 420, // altura máxima para el grid en escritorio
                        child: _construirGridHerramientas(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _construirTituloPrincipal(String? cursoId, {String? nombreCurso}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.book,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            (nombreCurso ?? cursoId ?? '').toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _construirInformacionGeneral(String? cursoId) {
    // Buscar el curso detallado seleccionado para obtener el profesor
    final cursos = ref.watch(cursosAlumnoProvider).maybeWhen(
      data: (c) => c,
      orElse: () => [],
    );
    final ModeloCursoDetallado? curso = cursos.isNotEmpty
      ? cursos.firstWhere(
          (c) => c.curso.id == cursoId,
          orElse: () => cursos.first as ModeloCursoDetallado,
        )
      : null;
    final String responsable =
      (curso?.profesor != null && (curso!.profesor!.nombreCompleto.isNotEmpty))
        ? curso.profesor!.nombreCompleto
        : 'No disponible';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '- Información general',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 150,
                child: Text(
                  'Responsable de asignatura:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  responsable,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text('Sección: A', style: TextStyle(fontSize: 14, color: AppConstants.textPrimary)),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ver sílabo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirGridHerramientas({String? cursoId}) {
    final herramientas = [
      {'icono': LucideIcons.folder, 'titulo': 'Unidades'},
      {'icono': LucideIcons.fileQuestionMark, 'titulo': 'Exámenes'},
      {'icono': LucideIcons.messageSquare, 'titulo': 'Foros'},
      {'icono': LucideIcons.book, 'titulo': 'Lecturas'},
      {'icono': LucideIcons.clipboard, 'titulo': 'Tareas'},
      {'icono': LucideIcons.star, 'titulo': 'Calificaciones'},
      {'icono': LucideIcons.calendar, 'titulo': 'Calendario'},
      {'icono': LucideIcons.video, 'titulo': 'Videoconferencias'},
      {'icono': LucideIcons.globe, 'titulo': 'Wiki'},
    ];
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    final crossAxisCount = esMovil ? 2 : (ancho > 1200 ? 4 : 3);
    final aspectRatio = esMovil ? 0.55 : 1.1;
    return GridView.builder(
      shrinkWrap: esMovil,
      physics: esMovil ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: esMovil ? 8 : 18,
        mainAxisSpacing: esMovil ? 8 : 18,
        childAspectRatio: aspectRatio,
      ),
      itemCount: herramientas.length,
      itemBuilder: (context, index) {
        final herramienta = herramientas[index];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              final cursoSeleccionadoId = ref.read(cursoAlumnoStateProvider).cursoSeleccionadoId;
              if (cursoId != null && cursoId.isNotEmpty && cursoId != cursoSeleccionadoId) {
                ref.read(cursoAlumnoStateProvider.notifier).seleccionarCurso(cursoId);
              }
              if (herramienta['titulo'] == 'Exámenes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExamenesWidget(
                      onRegresar: () => Navigator.pop(context),
                      cursoId: cursoId ?? '',
                    ),
                  ),
                );
              } else {
                setState(() => herramientaActiva = herramienta['titulo'].toString().toLowerCase());
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(esMovil ? 10 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(esMovil ? 10 : 16),
                onTap: () {
                  // Mantener compatibilidad con el tap interno
                  if (herramienta['titulo'] == 'Exámenes') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamenesWidget(
                          onRegresar: () => Navigator.pop(context),
                          cursoId: cursoId ?? '',
                        ),
                      ),
                    );
                  } else {
                    setState(() => herramientaActiva = herramienta['titulo'].toString().toLowerCase());
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: esMovil ? 2 : 12, vertical: esMovil ? 6 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(esMovil ? 6 : 18),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withAlpha(22),
                          borderRadius: BorderRadius.circular(esMovil ? 7 : 12),
                        ),
                        child: Icon(
                          herramienta['icono'] as IconData,
                          size: esMovil ? 20 : 38,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      SizedBox(height: esMovil ? 4 : 18),
                      Text(
                        herramienta['titulo'] as String,
                        style: TextStyle(
                          fontSize: esMovil ? 10 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirPanelLateral() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.megaphone,
                color: AppConstants.primaryColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Anuncios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No hay anuncios registrados',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          const Row(
            children: [
              Icon(
                LucideIcons.calendarDays,
                color: AppConstants.primaryColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fechas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No hay fechas importantes',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaCursoMovil(BuildContext context, ModeloCursoDetallado curso) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.code200,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.curso.nombre.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${curso.curso.codigoCurso}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (curso.carrera?.nombre != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                curso.carrera!.nombre,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.primaryColor.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${curso.curso.creditos} créditos',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.warningColor.withAlpha(200),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cursoAlumnoStateProvider.notifier).seleccionarCurso(curso.curso.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModulosCursoAlumnoScreen(cursoId: curso.curso.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.darkButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ingresar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
    properties.add(StringProperty('herramientaActiva', herramientaActiva));
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.titulo,
    required this.valor,
  });
  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    properties..add(DiagnosticsProperty<IconData>('icon', icon))
    ..add(StringProperty('titulo', titulo))
    ..add(StringProperty('valor', valor));
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

class DetalleCursoAlumnoScreen extends StatelessWidget {
  const DetalleCursoAlumnoScreen({required this.curso, super.key});
  final ModeloCursoDetallado curso;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(curso.curso.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${curso.curso.codigoCurso}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            if (curso.carrera?.nombre != null)
              Text('Carrera: ${curso.carrera!.nombre}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Créditos: ${curso.curso.creditos}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            const Text('Herramientas:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.folder),
                  label: const Text('Unidades'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment),
                  label: const Text('Tareas'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.forum),
                  label: const Text('Foros'),
                ),
                // ... agrega más herramientas según tu app ...
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ModeloCursoDetallado>('curso', curso));
  }
} 

class ModulosCursoAlumnoScreen extends ConsumerStatefulWidget {
  const ModulosCursoAlumnoScreen({required this.cursoId, super.key});
  final String cursoId;

  @override
  ConsumerState<ModulosCursoAlumnoScreen> createState() => _ModulosCursoAlumnoScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _ModulosCursoAlumnoScreenState extends ConsumerState<ModulosCursoAlumnoScreen> {
  String? herramientaActiva;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _construirAreaPrincipal(widget.cursoId),
      bottomNavigationBar: MoonyNavigationBar(
        items: <NavigationBarItem>[
          NavigationBarItem(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              debugPrint('📱 ModulosCurso: Botón retroceder presionado');
              Navigator.of(context).pop();
            },
          ),
          NavigationBarItem(
            icon: Icons.home_rounded,
            onTap: () {
              debugPrint('📱 ModulosCurso: Botón home presionado');
              Navigator.of(context).pushReplacementNamed('/home-alumno');
            },
          ),
          NavigationBarItem(
            icon: Icons.apps_outlined,
            activeIcon: Icons.apps,
            onTap: () {
              debugPrint('📱 ModulosCurso: Mostrando herramientas');
              _mostrarBottomSheetHerramientas();
            },
          ),
          NavigationBarItem(
            icon: Icons.info_outline,
            activeIcon: Icons.info,
            onTap: () {
              debugPrint('📱 ModulosCurso: Mostrando información del curso');
              _mostrarInfoCurso();
            },
          ),
        ],
        style: MoonyNavStyle(
          activeColor: AppConstants.primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _construirAreaPrincipal(String? cursoId) {
    final cursoSeleccionadoId = ref.watch(cursoAlumnoStateProvider).cursoSeleccionadoId;
    final idParaModulo = cursoId ?? cursoSeleccionadoId ?? '';
    switch (herramientaActiva) {
      case 'calendario':
        return CalendarioWidget(onRegresar: () => setState(() => herramientaActiva = null));
      case 'foros':
        return ForosWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'lecturas':
        return LecturasWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'unidades':
        return UnidadesWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
          cursoId: idParaModulo,
        );
      case 'examenes':
        return ExamenesWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
          cursoId: idParaModulo,
        );
      case 'tareas':
        return TareasWidget(
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'videoconferencias':
        return VideoconferenciasWidget(
          grupoClaseId: idParaModulo,
          onRegresar: () => setState(() => herramientaActiva = null),
        );
      case 'wiki':
        return WikiWidget(onRegresar: () => setState(() => herramientaActiva = null));
      default:
        return _construirContenidoPrincipal(cursoId);
    }
  }

  Widget _construirContenidoPrincipal(String? cursoId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puedes mostrar info del curso aquí si lo deseas
          _construirGridHerramientas(),
        ],
      ),
    );
  }

  Widget _construirGridHerramientas() {
    final herramientas = [
      {'icono': LucideIcons.folder, 'titulo': 'Unidades'},
      {'icono': LucideIcons.fileQuestionMark, 'titulo': 'Exámenes'},
      {'icono': LucideIcons.messageSquare, 'titulo': 'Foros'},
      {'icono': LucideIcons.book, 'titulo': 'Lecturas'},
      {'icono': LucideIcons.clipboard, 'titulo': 'Tareas'},
      {'icono': LucideIcons.star, 'titulo': 'Calificaciones'},
      {'icono': LucideIcons.calendar, 'titulo': 'Calendario'},
      {'icono': LucideIcons.video, 'titulo': 'Videoconferencias'},
      {'icono': LucideIcons.globe, 'titulo': 'Wiki'},
    ];

    return GridView.builder(
      shrinkWrap: true, // <--- Solución para escritorio
      physics: const NeverScrollableScrollPhysics(), // <--- Solución para escritorio
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: herramientas.length,
      itemBuilder: (context, index) {
        final herramienta = herramientas[index];
        return InkWell(
          onTap: () => setState(() => herramientaActiva = (herramienta['titulo'] as String).toLowerCase()),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // <--- Solución clave
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // <--- Reducido de 16
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    herramienta['icono'] as IconData?,
                    size: 28, // <--- Reducido de 36
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 8), // <--- Reducido de 12
                Flexible( // <--- Solución para overflow
                  child: Text(
                    herramienta['titulo'] as String,
                    style: const TextStyle(
                      fontSize: 12, // <--- Reducido de 14
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarBottomSheetHerramientas() {
    final herramientas = [
      {'icono': LucideIcons.folder, 'titulo': 'Unidades', 'color': Colors.blue},
      {'icono': LucideIcons.fileQuestionMark, 'titulo': 'Exámenes', 'color': Colors.red},
      {'icono': LucideIcons.messageSquare, 'titulo': 'Foros', 'color': Colors.green},
      {'icono': LucideIcons.book, 'titulo': 'Lecturas', 'color': Colors.orange},
      {'icono': LucideIcons.clipboard, 'titulo': 'Tareas', 'color': Colors.purple},
      {'icono': LucideIcons.star, 'titulo': 'Calificaciones', 'color': Colors.amber},
      {'icono': LucideIcons.calendar, 'titulo': 'Calendario', 'color': Colors.teal},
      {'icono': LucideIcons.video, 'titulo': 'Videoconferencias', 'color': Colors.indigo},
      {'icono': LucideIcons.globe, 'titulo': 'Wiki', 'color': Colors.cyan},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.grid3x3,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Herramientas del Curso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Grid de herramientas
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: herramientas.length,
                itemBuilder: (context, index) {
                  final herramienta = herramientas[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => herramientaActiva = herramienta['titulo'].toString().toLowerCase());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: herramienta['color'] as Color,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (herramienta['color'] as Color).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              herramienta['icono'] as IconData,
                              size: 24,
                              color: herramienta['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            herramienta['titulo'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInfoCurso() {
    final cursos = ref.watch(cursosAlumnoProvider).maybeWhen(
      data: (c) => c,
      orElse: () => [],
    );
    final curso = cursos.isNotEmpty
        ? cursos.firstWhere(
            (c) => c.curso.id == widget.cursoId,
            orElse: () => cursos.first as ModeloCursoDetallado,
          )
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.info,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Información del Curso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (curso != null) ...[
                      _InfoItem(
                        icon: LucideIcons.book,
                        titulo: 'Nombre',
                        valor: curso.curso.nombre,
                      ),
                      _InfoItem(
                        icon: LucideIcons.hash,
                        titulo: 'Código',
                        valor: curso.curso.codigoCurso,
                      ),
                      _InfoItem(
                        icon: LucideIcons.graduationCap,
                        titulo: 'Créditos',
                        valor: '${curso.curso.creditos} créditos',
                      ),
                      if (curso.carrera?.nombre != null)
                        _InfoItem(
                          icon: LucideIcons.school,
                          titulo: 'Carrera',
                          valor: curso.carrera!.nombre,
                        ),
                      if (curso.profesor?.nombreCompleto != null)
                        _InfoItem(
                          icon: LucideIcons.user,
                          titulo: 'Profesor',
                          valor: curso.profesor!.nombreCompleto,
                        ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este curso forma parte del plan de estudios y está diseñado para proporcionar los conocimientos fundamentales necesarios para el desarrollo académico y profesional.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
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
    properties.add(StringProperty('herramientaActiva', herramientaActiva));
  }
} 