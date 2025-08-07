import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WikiWidget extends StatefulWidget {

  const WikiWidget({
    super.key,
    required this.onRegresar,
  });
  final VoidCallback onRegresar;

  @override
  State<WikiWidget> createState() => _WikiWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar));
  }
}

class _WikiWidgetState extends State<WikiWidget> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _categoriaSeleccionada = 'Todos';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono y botón regresar
          Row(
            children: [
              const Icon(
                LucideIcons.bookOpen200,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Wiki del Curso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onRegresar,
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
          
          // Barra de búsqueda
          _construirBarraBusqueda(),
          const SizedBox(height: 24),
          
          // Lista de artículos
          _construirListaArticulos(),
        ],
      ),
    );
  }

  Widget _construirBarraBusqueda() {
    final categorias = ['Todos', 'HTML/CSS', 'JavaScript', 'Backend', 'Bases de Datos'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _controladorBusqueda,
            decoration: InputDecoration(
              hintText: 'Buscar en la wiki...',
              prefixIcon: const Icon(LucideIcons.search200, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtros por categoría
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categorias.map((categoria) {
                final bool esSeleccionada = _categoriaSeleccionada == categoria;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(categoria),
                    selected: esSeleccionada,
                    onSelected: (seleccionada) {
                      setState(() {
                        _categoriaSeleccionada = categoria;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: const Color(0xFFE91E63).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFFE91E63),
                    labelStyle: TextStyle(
                      color: esSeleccionada ? const Color(0xFFE91E63) : AppConstants.textSecondary,
                      fontWeight: esSeleccionada ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaArticulos() {
    final articulos = [
      {
        'titulo': 'Introducción a HTML5 Semántico',
        'descripcion': 'Aprende a usar las etiquetas semánticas de HTML5 correctamente',
        'autor': 'Dr. Juan Carlos Mamani',
        'fechaActualizacion': '3 días',
        'categoria': 'HTML/CSS',
        'dificultad': 'Básico',
        'tiempoLectura': '10 min',
        'visitas': 245,
        'likes': 18,
      },
      {
        'titulo': 'CSS Grid Layout Completo',
        'descripcion': 'Guía completa para dominar CSS Grid desde lo básico hasta lo avanzado',
        'autor': 'Mg. María Elena Quispe',
        'fechaActualizacion': '1 semana',
        'categoria': 'HTML/CSS',
        'dificultad': 'Intermedio',
        'tiempoLectura': '25 min',
        'visitas': 189,
        'likes': 27,
      },
      {
        'titulo': 'JavaScript ES6+ Características',
        'descripcion': 'Guía completa de las nuevas características de JavaScript moderno',
        'autor': 'Dr. Juan Carlos Mamani',
        'fechaActualizacion': '5 días',
        'categoria': 'JavaScript',
        'dificultad': 'Avanzado',
        'tiempoLectura': '30 min',
        'visitas': 134,
        'likes': 22,
      },
      {
        'titulo': 'APIs REST con Node.js',
        'descripcion': 'Creación de APIs RESTful modernas con Express.js y mejores prácticas',
        'autor': 'Dr. Juan Carlos Mamani',
        'fechaActualizacion': '1 semana',
        'categoria': 'Backend',
        'dificultad': 'Avanzado',
        'tiempoLectura': '35 min',
        'visitas': 98,
        'likes': 31,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artículos de la Wiki',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(articulos.length, (index) {
          final articulo = articulos[index];
          return _construirItemArticulo(articulo);
        }),
      ],
    );
  }

  Widget _construirItemArticulo(Map<String, dynamic> articulo) {
    final Color colorCategoria = _obtenerColorCategoria(articulo['categoria']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de categoría
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorCategoria.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _obtenerIconoCategoria(articulo['categoria']),
              color: colorCategoria,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Contenido del artículo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        articulo['titulo'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _obtenerColorDificultad(articulo['dificultad']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        articulo['dificultad'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _obtenerColorDificultad(articulo['dificultad']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  articulo['descripcion'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Por ${articulo['autor']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      LucideIcons.clock200,
                      size: 10,
                      color: AppConstants.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      articulo['tiempoLectura'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Actualizado hace ${articulo['fechaActualizacion']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Estadísticas y acción
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.eye200,
                    size: 12,
                    color: AppConstants.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${articulo['visitas']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    LucideIcons.heart200,
                    size: 12,
                    color: AppConstants.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${articulo['likes']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Leer artículo
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorCategoria,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Leer',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _obtenerColorCategoria(String categoria) {
    switch (categoria) {
      case 'HTML/CSS':
        return Colors.orange;
      case 'JavaScript':
        return Colors.yellow.shade700;
      case 'Backend':
        return Colors.green;
      case 'Bases de Datos':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'HTML/CSS':
        return LucideIcons.code200;
      case 'JavaScript':
        return LucideIcons.zap200;
      case 'Backend':
        return LucideIcons.server200;
      case 'Bases de Datos':
        return LucideIcons.database200;
      default:
        return LucideIcons.file200;
    }
  }

  Color _obtenerColorDificultad(String dificultad) {
    switch (dificultad.toLowerCase()) {
      case 'básico':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }
} 