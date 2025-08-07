import 'package:aulago/providers/alumno/cursos.alumno.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class LecturasWidget extends ConsumerWidget {
  const LecturasWidget({super.key, this.onRegresar});
  final VoidCallback? onRegresar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[LecturasWidget] Solicitando lecturas (sin grupoClaseId)');
    final lecturasAsync = ref.watch(lecturasProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.book,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Lecturas',
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
          
          lecturasAsync.when(
            data: (lecturas) {
              debugPrint('[LecturasWidget] Lecturas recibidas: cantidad =  [1m${lecturas.length} [0m');
              return _construirGridLecturas(lecturas);
            },
            loading: () {
              debugPrint('[LecturasWidget] Cargando lecturas...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              debugPrint('[LecturasWidget] Error al cargar lecturas: $err');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error:  [31m${err.toString()} [0m',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirGridLecturas(List<Map<String, dynamic>> lecturas) {
    if (lecturas.isEmpty) {
      return const Center(child: Text('No hay lecturas disponibles.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lecturas.length,
      itemBuilder: (context, index) {
        final lectura = lecturas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _construirTarjetaLectura(context, lectura),
        );
      },
    );
  }

  Widget _construirTarjetaLectura(BuildContext context, Map<String, dynamic> lectura) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.tryParse(lectura['enlace_pdf'] ?? '');
        if (url != null && await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace del PDF.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de lectura
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withValues(alpha: 25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.book,
                color: Color(0xFFE91E63),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // Contenido de la lectura
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la lectura
                  Text(
                    lectura['titulo'] ?? 'Sin título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Unidad
                  Text(
                    lectura['unidad'] ?? 'Sin unidad',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Text(
                    lectura['descripcion'] ?? 'Sin descripción',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Icono de flecha
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFE91E63),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty.has('onRegresar', onRegresar));
  }
}