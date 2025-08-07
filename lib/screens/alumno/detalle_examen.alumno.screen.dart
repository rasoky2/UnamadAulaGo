import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:aulago/models/examen.model.dart';

class DetalleExamenAlumnoScreen extends StatelessWidget {
  const DetalleExamenAlumnoScreen({super.key, required this.examen});
  final ModeloExamen examen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(examen.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción:  ${examen.descripcion ?? "Sin descripción"}'),
            const SizedBox(height: 16),
            Text('Fecha disponible:  ${examen.fechaDisponible}'),
            Text('Fecha límite:  ${examen.fechaLimite}'),
            const SizedBox(height: 16),
            Text('Estado:  ${examen.estadoEntrega ?? "No iniciado"}'),
            const SizedBox(height: 16),
            Text('Calificación:  ${examen.calificacion?.toString() ?? "-"}'),
            // Aquí puedes agregar botón para rendir examen si está habilitado
          ],
        ),
      ),
    );
  }
}