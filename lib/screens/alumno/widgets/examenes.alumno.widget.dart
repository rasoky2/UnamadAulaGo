import 'package:aulago/models/examen.model.dart';
import 'package:aulago/repositories/examen.repository.dart';
import 'package:aulago/screens/alumno/detalle_examen.alumno.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExamenesWidget extends StatelessWidget {

  const ExamenesWidget({
    super.key,
    required this.cursoId,
  });
  final String cursoId;

  @override
  Widget build(BuildContext context) {
    debugPrint('[ExamenesWidget] Solicitando exámenes para cursoId: $cursoId');
    final repo = ExamenRepository();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono
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
            ],
          ),
          const SizedBox(height: 24),
          
          // Tabla de exámenes
          FutureBuilder<List<ModeloExamen>>(
            future: repo.obtenerExamenesPorCurso(int.parse(cursoId)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('[ExamenesWidget] Cargando exámenes...');
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint('[ExamenesWidget] Error al cargar exámenes: ${snapshot.error}');
                return Center(
                  child: Text(
                    'Error al cargar los exámenes: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                );
              }
              final examenes = snapshot.data ?? [];
              debugPrint('[ExamenesWidget] Exámenes recibidos: cantidad = ${examenes.length}');
              if (examenes.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay exámenes disponibles',
                    style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
                  ),
                );
              }
              return _construirTablaExamenes(context, examenes);
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
    final String estado = 'programado';
    final Color colorEstado = _obtenerColorEstado(estado);
    final String fechaInicioStr = DateFormat('dd/MM/yy HH:mm').format(examen.fechaDisponible);
    final String fechaFinStr = DateFormat('dd/MM/yy HH:mm').format(examen.fechaLimite);
    final DateTime ahora = DateTime.now();
    final bool disponible = ahora.isAfter(examen.fechaDisponible) && ahora.isBefore(examen.fechaLimite);

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
                child: Center(
                  child: ElevatedButton(
                    onPressed: !disponible
                        ? null
                        : () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Iniciar examen'),
                                content: Text('¿Deseas iniciar "${examen.titulo}" ahora? Tendrás ${examen.duracionMinutos} minutos o hasta la fecha de cierre.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                  ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Iniciar')),
                                ],
                              ),
                            );
                            if (confirmar == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetalleExamenAlumnoScreen(examen: examen)),
                              );
                            }
                          },
                    child: const Text('Iniciar'),
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
      ..add(StringProperty('cursoId', cursoId));
  }
} 