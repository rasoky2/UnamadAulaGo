import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ForosWidget extends ConsumerWidget {
  const ForosWidget({super.key, this.onRegresar});
  final VoidCallback? onRegresar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[ForosWidget] Solicitando foros (sin grupoClaseId)');
    final forosAsync = ref.watch(forosProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.messageSquare,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Foros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              if (onRegresar != null)
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
          
          // Grid de foros
          forosAsync.when(
            data: (foros) {
               debugPrint('[ForosWidget] Foros recibidos: cantidad = \u001b[1m${foros.length}\u001b[0m');
               if (foros.isEmpty) {
                return const Center(child: Text("Datos no encontrados"));
              }
              return _construirGridForos(foros);
            },
            loading: () {
              debugPrint('[ForosWidget] Cargando foros...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              debugPrint('[ForosWidget] Error al cargar foros: $err');
              return const Center(child: Text("Datos no cargados"));
            },
          ),
        ],
      ),
    );
  }

  Widget _construirGridForos(List<Map<String, dynamic>> foros) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: foros.length,
      itemBuilder: (context, index) {
        final foro = foros[index];
        return _construirTarjetaForo(foro);
      },
    );
  }

  Widget _construirTarjetaForo(Map<String, dynamic> foro) {
    final bool estaBloqueado = foro['esta_bloqueado'] ?? false;
    final Color colorEstado = estaBloqueado ? Colors.red : Colors.green;
    final String textoEstado = estaBloqueado ? "Cerrado" : "Activo";

    final String fechaCreacion = foro['fecha_creacion'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(foro['fecha_creacion']))
        : 'N/A';
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono del foro y estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.messageSquare,
                  color: AppConstants.primaryColor,
                  size: 32,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  textoEstado,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorEstado,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Título del foro
          Text(
            foro['titulo'] ?? 'Sin título',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          Text(
            "Creado: $fechaCreacion",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const Spacer(),
          
          // Estadísticas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${foro['total_respuestas'] ?? 0} Respuestas',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
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
    properties
      .add(ObjectFlagProperty<VoidCallback?>.has('onRegresar', onRegresar));
  }
}