import 'package:aulago/models/examen.model.dart';
import 'package:aulago/providers/examen.riverpod.dart';
import 'package:aulago/screens/alumno/detalle_examen.alumno.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ExamenesWidget extends ConsumerWidget {

  const ExamenesWidget({
    super.key,
    required this.onRegresar,
    required this.cursoId,
  });
  final VoidCallback onRegresar;
  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examenesAsync = ref.watch(examenesProvider(cursoId));
    debugPrint('[ExamenesWidget] Solicitando exámenes para cursoId: $cursoId');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                Icons.quiz,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Exámenes',
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
          
          // Tabla de exámenes
          examenesAsync.when(
            data: (examenes) {
              debugPrint('[ExamenesWidget] Exámenes recibidos: cantidad =  [1m${examenes.length} [0m');
              if (examenes.isEmpty) {
                return const Center(
                  child: Text(
                    "No hay exámenes disponibles",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                );
              }
              return _construirTablaExamenes(context, examenes);
            },
            loading: () {
              debugPrint('[ExamenesWidget] Cargando exámenes...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              debugPrint('[ExamenesWidget] Error al cargar exámenes: $err');
              return Center(
                child: Text(
                  "Error al cargar los exámenes: $err",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirTablaExamenes(BuildContext context, List<ModeloExamen> examenes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                    'Fechas',
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
          
          // Filas de exámenes
          ...List.generate(examenes.length, (index) {
            final examen = examenes[index];
            return _construirFilaExamen(context, examen, index);
          }),
        ],
      ),
    );
  }

  Widget _construirFilaExamen(BuildContext context, ModeloExamen examen, int index) {
    final esParImpar = index % 2 == 0;
    final String estado = examen.estadoEntrega ?? 'No iniciado';
    final Color colorEstado = _obtenerColorEstado(estado);
    final String fechaInicioStr = DateFormat('dd/MM/yy HH:mm').format(examen.fechaDisponible);
    final String fechaFinStr = DateFormat('dd/MM/yy HH:mm').format(examen.fechaLimite);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esParImpar ? Colors.grey.shade50 : Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examen.titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.1),
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
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Disponible: $fechaInicioStr", style: const TextStyle(fontSize: 12)),
                    Text("Cierre: $fechaFinStr", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  examen.calificacion?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('[ExamenesWidget] Botón VER presionado para examen: ${examen.titulo} | cursoId: $cursoId');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleExamenAlumnoScreen(examen: examen),
                        ),
                      );
                    },
                    child: const Text('Ver'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'calificado':
        return Colors.green;
      case 'en curso':
        return Colors.blue;
      case 'no iniciado':
        return Colors.orange;
      case 'programado':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar))
      ..add(StringProperty('cursoId', cursoId));
  }
} 