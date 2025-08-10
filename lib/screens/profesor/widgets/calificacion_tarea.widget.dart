import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalificacionTareaScreen extends ConsumerWidget {
  const CalificacionTareaScreen({super.key, required this.tareaId});
  final String tareaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar tarea #$tareaId'),
      ),
      body: const Center(
        child: Text('Módulo de calificación en actualización'),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('tareaId', tareaId));
  }
} 