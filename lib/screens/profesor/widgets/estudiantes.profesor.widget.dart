import 'package:aulago/providers/profesor/widgets/estudiantes.profesor.riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EstudiantesTab extends ConsumerWidget {
  const EstudiantesTab({super.key, required this.cursoId});
  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiantesAsync = ref.watch(estudiantesDelCursoProvider(cursoId));
    
    return estudiantesAsync.when(
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
      data: (estudiantes) {
        if (estudiantes.isEmpty) {
          return const Center(child: Text('No hay estudiantes matriculados en este curso.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: estudiantes.length,
          itemBuilder: (context, index) {
            final estudiante = estudiantes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(LucideIcons.user),
                ),
                title: Text(estudiante.nombreCompleto),
                subtitle: Text(estudiante.correoElectronico ?? 'Sin correo'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
} 