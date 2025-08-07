import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoconferenciasWidget extends ConsumerWidget {

  const VideoconferenciasWidget({
    super.key,
    required this.grupoClaseId,
    required this.onRegresar,
  });
  final String grupoClaseId;
  final VoidCallback onRegresar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoconferenciasAsync = ref.watch(videoconferenciasProvider(grupoClaseId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.video,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Videoconferencias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onRegresar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Regresar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          videoconferenciasAsync.when(
            data: (videoconferencias) => _construirTablaVideoconferencias(context, videoconferencias),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTablaVideoconferencias(BuildContext context, List<Map<String, dynamic>> videoconferencias) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _construirHeaderTabla(),
          if (videoconferencias.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: const Text(
                'No hay videoconferencias programadas',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List.generate(videoconferencias.length, (index) {
              final videoconferencia = videoconferencias[index];
              return _construirFilaVideoconferencia(context, videoconferencia, index);
            }),
        ],
      ),
    );
  }

  Widget _construirHeaderTabla() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFE91E63),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Título', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            flex: 2,
            child: Text('Fecha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: Text('Estado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text('Acciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaVideoconferencia(BuildContext context, Map<String, dynamic> videoconferencia, int index) {
    final esParImpar = index % 2 == 0;
    final estado = videoconferencia['estado'] ?? 'programada';
    final Color colorEstado = _obtenerColorEstado(estado);
    final bool esEnVivo = estado == 'en_vivo';
    
    final fechaInicio = DateTime.tryParse(videoconferencia['fecha_inicio'] ?? '') ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esParImpar ? Colors.grey.shade50 : Colors.white,
        border: esEnVivo ? const Border(left: BorderSide(color: Colors.red, width: 4)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              videoconferencia['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(fechaInicio.toLocal()),
              style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorEstado.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado.replaceAll('_', ' ').replaceFirst(estado[0], estado[0].toUpperCase()),
                style: TextStyle(color: colorEstado, fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: _construirBotonAccion(context, videoconferencia),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonAccion(BuildContext context, Map<String, dynamic> videoconferencia) {
    final estado = videoconferencia['estado'] ?? 'programada';
    final enlace = videoconferencia['enlace_reunion'];
    final enlaceGrabacion = videoconferencia['enlace_grabacion'];

    if (estado == 'en_vivo' && enlace != null) {
      return ElevatedButton(
        onPressed: () => _abrirEnlace(context, enlace),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        child: const Text('Unirse', style: TextStyle(fontSize: 12)),
      );
    } else if (estado == 'finalizada' && enlaceGrabacion != null) {
      return TextButton(
        onPressed: () => _abrirEnlace(context, enlaceGrabacion),
        child: const Text('Grabación', style: TextStyle(fontSize: 12)),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _abrirEnlace(BuildContext context, String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'en_vivo':
        return Colors.red;
      case 'finalizada':
        return Colors.grey;
      case 'programada':
        return AppConstants.primaryColor;
      case 'cancelada':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('grupoClaseId', grupoClaseId))
    ..add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar));
  }
}