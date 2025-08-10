import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Provider para obtener estudiantes matriculados en un curso específico
final estudiantesCursoProvider = FutureProvider.family<List<EstudianteAdmin>, String>((ref, cursoId) async {
  try {
    final matriculaRepo = MatriculaRepository();
    final estudianteRepo = EstudianteRepository();
    
    // Obtener matrículas del curso
    final todasMatriculas = await matriculaRepo.obtenerMatriculas();
    final matriculasCurso = todasMatriculas.where((m) => m.cursoId?.toString() == cursoId).toList();
    
    // Obtener datos completos de estudiantes
    final estudiantes = <EstudianteAdmin>[];
    for (final matricula in matriculasCurso) {
      try {
        // matricula.estudianteId es el ID en la tabla estudiantes, no usuario_id
        final estudiante = await estudianteRepo.obtenerEstudiantePorId(matricula.estudianteId);
        if (estudiante != null) {
          estudiantes.add(estudiante);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error obteniendo estudiante ${matricula.estudianteId}: $e');
        }
      }
    }
    
    // Ordenar por nombre
    estudiantes.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    return estudiantes;
  } catch (e) {
    if (kDebugMode) {
      print('Error obteniendo estudiantes del curso $cursoId: $e');
    }
    throw Exception('Error al cargar estudiantes: $e');
  }
});

class EstudiantesTab extends ConsumerWidget {
  const EstudiantesTab({super.key, required this.cursoId});
  final String cursoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estudiantesAsync = ref.watch(estudiantesCursoProvider(cursoId));
    
    return estudiantesAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estudiantes...'),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estudiantes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta recargar la página',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      data: (estudiantes) {
        if (estudiantes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.users, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay estudiantes matriculados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aún no se han matriculado estudiantes en este curso',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // Header con estadísticas
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor.withValues(alpha: 0.1),
                    AppConstants.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.users,
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
                          'Estudiantes Matriculados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${estudiantes.length} ${estudiantes.length == 1 ? 'estudiante' : 'estudiantes'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de estudiantes
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: estudiantes.length,
                itemBuilder: (context, index) {
                  final estudiante = estudiantes[index];
                  return _construirTarjetaEstudiante(estudiante, index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _construirTarjetaEstudiante(EstudianteAdmin estudiante, int numero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a perfil del estudiante o mostrar detalles
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Número de orden
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Avatar del estudiante
              AvatarWidget(
                nombreCompleto: estudiante.nombreCompleto,
                fotoUrl: estudiante.fotoPerfilUrl,
                tipoUsuario: 'estudiante',
                radio: 24,
              ),
              const SizedBox(width: 16),
              
              // Información del estudiante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre completo
                    Text(
                      estudiante.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Código de estudiante
                    Row(
                      children: [
                        Icon(
                          LucideIcons.creditCard,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            estudiante.codigoEstudiante,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Correo electrónico
                    if (estudiante.correoElectronico?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mail,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              estudiante.correoElectronico!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Teléfono (si existe)
                    if (estudiante.telefono?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              estudiante.telefono!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Estado/Indicadores
              Column(
                children: [
                  // Estado activo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estudiante.activo 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estudiante.activo ? LucideIcons.check : LucideIcons.x,
                          size: 12,
                          color: estudiante.activo ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estudiante.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: estudiante.activo ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Icono de acción
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
} 