import 'package:aulago/models/curso.model.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
 
class UnidadesWidget extends StatelessWidget {

  const UnidadesWidget({
    super.key,
    required this.onRegresar,
    required this.cursoId,
    this.curso,
  });
  final VoidCallback onRegresar;
  final String cursoId;
  final ModeloCurso? curso;

  @override
  Widget build(BuildContext context) {
    final repo = CursoRepository();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.folder200,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Unidades del Curso',
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
          
          // Lista de unidades
          FutureBuilder<ModeloCurso?>(
            future: repo.obtenerCursoPorId(int.tryParse(cursoId) ?? 0),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error: No se pudieron cargar las unidades'));
              }
              final unidades = snapshot.data?.unidades ?? [];
              debugPrint('🟢 [UnidadesWidget] Unidades recibidas: ${unidades.length}');
              for (final Map<String, dynamic> map in unidades) {
                final listaTemas = map['temas'] as List?;
                final numero = (map['numero_unidad'] ?? map['numero']);
                debugPrint('  Unidad ${numero ?? '?'} - Temas: ${listaTemas?.length ?? 0}');
              }
              // ADVERTENCIA si faltan unidades
              final int? totalUnidades = curso?.totalUnidades;
              Widget advertencia = const SizedBox.shrink();
              if (totalUnidades != null && unidades.length < totalUnidades) {
                advertencia = Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este curso debería tener $totalUnidades unidades, pero solo hay ${unidades.length} creadas.',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  advertencia,
                  if (unidades.isEmpty)
                    const Center(child: Text('No se encontraron unidades para este curso.'))
                  else
                    _UnidadesList(
                      unidades: unidades.cast<Map<String, dynamic>>(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar))
    ..add(StringProperty('cursoId', cursoId))
    ..add(DiagnosticsProperty<ModeloCurso?>('curso', curso));
  }
}

class _UnidadesList extends StatefulWidget {

  const _UnidadesList({required this.unidades});
  final List<Map<String, dynamic>> unidades;

  @override
  __UnidadesListState createState() => __UnidadesListState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Map<String, dynamic>>('unidades', unidades));
  }
}

class __UnidadesListState extends State<_UnidadesList> {
  Set<int> unidadesExpandidas = {0}; // Primera unidad expandida por defecto

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.unidades.length, (index) {
        final unidad = widget.unidades[index];
        final estaExpandida = unidadesExpandidas.contains(index);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 20), // 0.08 * 255 ≈ 20
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header de la unidad
              InkWell(
                onTap: () {
                  setState(() {
                    if (estaExpandida) {
                      unidadesExpandidas.remove(index);
                    } else {
                      unidadesExpandidas.add(index);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icono de unidad
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.folder200,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Información de la unidad
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIDAD ${_numeroUnidad(unidad)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (unidad['titulo'] ?? 'Sin título').toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (unidad['descripcion'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Icono de expansión
                      Icon(
                        estaExpandida ? LucideIcons.chevronUp200 : LucideIcons.chevronDown200,
                        color: AppConstants.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Contenido expandible
              if (estaExpandida) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temas de la unidad
                       ...List.generate(((unidad['temas'] as List?) ?? const []).length, (temaIndex) {
                         final dynamic temaRaw = ((unidad['temas'] as List?) ?? const [])[temaIndex];
                         final Map<String, dynamic> tema = temaRaw is Map<String, dynamic>
                             ? temaRaw
                             : <String, dynamic>{'titulo': temaRaw?.toString() ?? 'Tema', 'tipo': 'lectura'};
                         return _construirItemTema(tema);
                       }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  String _numeroUnidad(Map<String, dynamic> unidad) {
    final dynamic numero = unidad['numero_unidad'] ?? unidad['numero'];
    return numero?.toString() ?? '?';
  }

  Widget _construirItemTema(Map<String, dynamic> tema) {
    final Color colorTipo = _obtenerColorTipo(tema['tipo']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorTipo.withValues(alpha: 51), // 0.2 * 255 ≈ 51
        ),
      ),
      child: Row(
        children: [
          // Icono del tema
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorTipo,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _obtenerIconoTema(tema),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          
          // Título del tema
          Expanded(
            child: Text(
              tema['titulo'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          
          // Tipo de tema
          Text(
            tema['tipo'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorTipo,
            ),
          ),
        ],
      ),
    );
  }

  IconData _obtenerIconoTema(Map<String, dynamic> tema) {
    final String? tipo = tema['tipo']?.toString().toLowerCase();
    switch (tipo) {
      case 'lectura':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'documento':
        return Icons.description_rounded;
      case 'tarea':
        return Icons.assignment_rounded;
      case 'foro':
        return Icons.forum_rounded;
    }
    // Fallback a campo icono si viene explícito
    final String icono = (tema['icono'] ?? 'file').toString();
    return _obtenerIconoPorTipo(icono);
  }

  IconData _obtenerIconoPorTipo(String tipoIcono) {
    switch (tipoIcono.toLowerCase()) {
      case 'lectura':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'documento':
        return Icons.description_rounded;
      case 'tarea':
        return Icons.assignment_rounded;
      case 'foro':
        return Icons.forum_rounded;
      case 'message-square':
        return LucideIcons.messageSquare200;
      case 'play':
        return LucideIcons.play200;
      case 'file-text':
        return LucideIcons.fileText200;
      case 'clipboard':
        return LucideIcons.clipboard200;
      case 'book-open':
        return LucideIcons.bookOpen200;
      default:
        return LucideIcons.file200;
    }
  }

  Color _obtenerColorTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'foro':
        return const Color(0xFF4CAF50);
      case 'video':
        return const Color(0xFFE91E63);
      case 'documento':
        return const Color(0xFF2196F3);
      case 'tarea':
        return const Color(0xFFFF9800);
      case 'lectura':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<int>('unidadesExpandidas', unidadesExpandidas));
  }
} 