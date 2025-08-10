import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/tarea.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TareasWidget extends StatelessWidget {
  const TareasWidget({super.key, this.onRegresar});
  final VoidCallback? onRegresar;

  @override
  Widget build(BuildContext context) {
    debugPrint('[TareasWidget] Solicitando tareas (cliente)');
    final repo = TareaRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.clipboardCheck,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tareas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              if (onRegresar != null)
                ElevatedButton(
                  onPressed: onRegresar!,
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
          
          // Tabla de tareas
          FutureBuilder<List<ModeloTarea>>(
            future: repo.obtenerTareas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Datos no cargados'));
              }
              final tareas = snapshot.data ?? [];
              if (tareas.isEmpty) {
                return const Center(child: Text('Datos no encontrados'));
              }
              return _construirTablaTareas(tareas);
            },
          ),
        ],
      ),
    );
  }

  Widget _construirTablaTareas(List<ModeloTarea> tareas) {
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
          // Header de la tabla
          Container(
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
                  child: Text(
                    'Título',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Fecha Límite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Calificación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Filas de tareas
          ...List.generate(tareas.length, (index) {
            final tarea = tareas[index];
            return _construirFilaTarea(tarea, index);
          }),
        ],
      ),
    );
  }

  Widget _construirFilaTarea(ModeloTarea tarea, int index) {
    final esParImpar = index % 2 == 0;
    final String estado = tarea.estado.isNotEmpty ? tarea.estado : 'pendiente';
    final Color colorEstado = _obtenerColorEstado(estado);
    final String fechaLimiteStr = DateFormat('dd/MM/yyyy HH:mm').format(tarea.fechaEntrega);
    final bool esVencida = tarea.fechaEntrega.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esParImpar ? Colors.grey.shade50 : Colors.white,
        border: estado == 'Pendiente' && esVencida 
          ? const Border(left: BorderSide(color: Colors.red, width: 4))
          : null,
      ),
      child: Column(
        children: [
          // Fila principal
          Row(
            children: [
              // Título de la tarea
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        tarea.titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorEstado,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Fecha Límite
              Expanded(
                flex: 2,
                child: Text(
                  fechaLimiteStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
              // Calificación
              const Expanded(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Acciones
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implementar navegación a detalle de tarea
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF072D3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Ver', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'entregado':
        return Colors.green;
      case 'calificado':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty.has('onRegresar', onRegresar));
  }
}