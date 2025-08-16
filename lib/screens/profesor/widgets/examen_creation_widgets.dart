import 'package:aulago/models/pregunta_examen.model.dart';
import 'package:flutter/material.dart';

// ==================== CLASES AUXILIARES PARA CREACIÓN DE EXAMEN ====================

/// Clase utilitaria para cálculos de puntos del examen
class CalculadorPuntos {
  /// Calcula el total de puntos de una lista de preguntas
  static double calcularPuntosTotales(List<PreguntaTemporal> preguntas) {
    return preguntas.fold<double>(0, (sum, pregunta) => sum + pregunta.puntos);
  }
  
  /// Calcula cuántos puntos faltan para alcanzar el máximo
  static double calcularPuntosFaltantes(List<PreguntaTemporal> preguntas, double puntosMaximos) {
    final puntosActuales = calcularPuntosTotales(preguntas);
    final faltantes = puntosMaximos - puntosActuales;
    return faltantes > 0 ? faltantes : 0;
  }
  
  /// Verifica si los puntos están balanceados (no exceden ni faltan muchos)
  static EstadoPuntos obtenerEstadoPuntos(List<PreguntaTemporal> preguntas, double puntosMaximos) {
    final puntosActuales = calcularPuntosTotales(preguntas);
    final diferencia = (puntosActuales - puntosMaximos).abs();
    
    if (puntosActuales == puntosMaximos) {
      return EstadoPuntos.perfecto;
    } else if (puntosActuales > puntosMaximos) {
      return EstadoPuntos.excedido;
    } else if (diferencia <= 2) {
      return EstadoPuntos.cercano;
    } else {
      return EstadoPuntos.faltante;
    }
  }
  
  /// Sugiere puntos por pregunta para alcanzar el máximo
  static double sugerirPuntosPorPregunta(int numPreguntas, double puntosMaximos) {
    if (numPreguntas == 0) {
      return 0;
    }
    return puntosMaximos / numPreguntas;
  }
  
  /// Distribuye automáticamente los puntos entre las preguntas
  static void distribuirPuntosAutomaticamente(List<PreguntaTemporal> preguntas, double puntosMaximos) {
    if (preguntas.isEmpty) {
      return;
    }
    
    final puntosPorPregunta = puntosMaximos / preguntas.length;
    for (final pregunta in preguntas) {
      pregunta.puntos = double.parse(puntosPorPregunta.toStringAsFixed(1));
    }
  }
}

/// Enum para representar el estado de los puntos del examen
enum EstadoPuntos {
  perfecto,  // Puntos exactos
  cercano,   // Diferencia <= 2 puntos
  faltante,  // Faltan puntos
  excedido,  // Puntos excedidos
}

/// Clase temporal para manejar preguntas durante la creación
class PreguntaTemporal {
  final TextEditingController enunciadoController = TextEditingController();
  final List<TextEditingController> opcionesControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int respuestaCorrecta = 0;
  double puntos = 2.0;

  void dispose() {
    enunciadoController.dispose();
    for (final controller in opcionesControllers) {
      controller.dispose();
    }
  }

  bool esValida() {
    if (enunciadoController.text.trim().isEmpty) {
      return false;
    }
    
    int opcionesLlenas = 0;
    for (final controller in opcionesControllers) {
      if (controller.text.trim().isNotEmpty) {
        opcionesLlenas++;
      }
    }
    
    // Al menos 2 opciones deben estar llenas
    if (opcionesLlenas < 2) {
      return false;
    }
    
    // La respuesta correcta debe estar en una opción que tenga texto
    if (respuestaCorrecta >= opcionesControllers.length) {
      return false;
    }
    if (opcionesControllers[respuestaCorrecta].text.trim().isEmpty) {
      return false;
    }
    
    return true;
  }

  PreguntaExamen toPreguntaExamen() {
    final opciones = opcionesControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    final respuestaCorrectaTexto = opcionesControllers[respuestaCorrecta].text.trim();
    
    return PreguntaExamen.crear(
      examenId: 0, // Se asignará después
      enunciado: enunciadoController.text.trim(),
      opciones: opciones,
      respuestaCorrecta: respuestaCorrectaTexto,
      puntos: puntos,
    );
  }

  /// Crea una PreguntaTemporal desde una PreguntaExamen existente
  static PreguntaTemporal fromPreguntaExamen(PreguntaExamen pregunta) {
    final preguntaTemp = PreguntaTemporal();
    
    // Establecer el enunciado
    preguntaTemp.enunciadoController.text = pregunta.enunciado;
    
    // Establecer las opciones
    for (int i = 0; i < pregunta.opciones.length && i < preguntaTemp.opcionesControllers.length; i++) {
      preguntaTemp.opcionesControllers[i].text = pregunta.opciones[i];
    }
    
    // Establecer la respuesta correcta
    final respuestaCorrectaTexto = pregunta.respuestaCorrecta;
    if (respuestaCorrectaTexto != null) {
      final indexRespuestaCorrecta = pregunta.opciones.indexOf(respuestaCorrectaTexto);
      if (indexRespuestaCorrecta != -1) {
        preguntaTemp.respuestaCorrecta = indexRespuestaCorrecta;
      }
    }
    
    // Establecer los puntos
    preguntaTemp.puntos = pregunta.puntos;
    
    return preguntaTemp;
  }
}

/// Widget para mostrar y editar una pregunta
class PreguntaCard extends StatefulWidget {
  const PreguntaCard({
    required this.pregunta,
    required this.numero,
    this.onEliminar,
    super.key,
  });

  final PreguntaTemporal pregunta;
  final int numero;
  final VoidCallback? onEliminar;

  @override
  State<PreguntaCard> createState() => _PreguntaCardState();
}

class _PreguntaCardState extends State<PreguntaCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.numero}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pregunta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${widget.pregunta.puntos} pts'),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 16),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: _cambiarPuntos,
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 16),
                              SizedBox(width: 8),
                              Text('Cambiar puntos'),
                            ],
                          ),
                        ),
                        if (widget.onEliminar != null)
                          PopupMenuItem(
                            onTap: widget.onEliminar,
                            child: const Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enunciado
            TextFormField(
              controller: widget.pregunta.enunciadoController,
              decoration: const InputDecoration(
                labelText: 'Enunciado de la pregunta',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.help_outline),
              ),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Opciones
            const Text(
              'Opciones de respuesta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < widget.pregunta.opcionesControllers.length; i++) ...[
              Row(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      radioTheme: RadioThemeData(
                        fillColor: WidgetStateProperty.all(Colors.blue),
                      ),
                    ),
                    child: Radio<int>(
                      value: i,
                      groupValue: widget.pregunta.respuestaCorrecta,
                      onChanged: (value) {
                        setState(() {
                          widget.pregunta.respuestaCorrecta = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: widget.pregunta.opcionesControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Opción ${String.fromCharCode(65 + i)}',
                        border: const OutlineInputBorder(),
                        suffixIcon: widget.pregunta.respuestaCorrecta == i
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Indicador de validez
            if (!widget.pregunta.esValida())
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Completa el enunciado, al menos 2 opciones y marca la respuesta correcta',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _cambiarPuntos() {
    final puntosController = TextEditingController(text: widget.pregunta.puntos.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puntos para esta pregunta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: puntosController,
              decoration: const InputDecoration(
                labelText: 'Puntos',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
                helperText: 'Ingrese un valor mayor a 0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            
            // Botones de puntos rápidos
            const Text(
              'Valores comunes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1.0, 2.0, 2.5, 3.0, 4.0, 5.0].map((valor) => 
                ActionChip(
                  label: Text('${valor.toStringAsFixed(valor == valor.roundToDouble() ? 0 : 1)} pts'),
                  onPressed: () {
                    puntosController.text = valor.toString();
                  },
                  backgroundColor: widget.pregunta.puntos == valor 
                      ? Colors.blue.shade100 
                      : null,
                ),
              ).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final puntos = double.tryParse(puntosController.text);
              if (puntos != null && puntos > 0) {
                widget.pregunta.puntos = puntos;
                setState(() {});
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese un valor válido mayor a 0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar resumen de información
class ResumenItem extends StatelessWidget {
  const ResumenItem({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color,
    this.subtitle,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.blue;
    
    return Column(
      children: [
        Icon(icono, color: itemColor, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: itemColor,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 10,
              color: itemColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Widget especializado para mostrar el resumen de puntos con indicadores
class ResumenPuntos extends StatelessWidget {
  const ResumenPuntos({
    required this.preguntas,
    required this.puntosMaximos,
    this.onDistribuirAutomaticamente,
    super.key,
  });

  final List<PreguntaTemporal> preguntas;
  final double puntosMaximos;
  final VoidCallback? onDistribuirAutomaticamente;

  @override
  Widget build(BuildContext context) {
    final puntosActuales = CalculadorPuntos.calcularPuntosTotales(preguntas);
    final puntosFaltantes = CalculadorPuntos.calcularPuntosFaltantes(preguntas, puntosMaximos);
    final estadoPuntos = CalculadorPuntos.obtenerEstadoPuntos(preguntas, puntosMaximos);
    
    Color colorEstado;
    IconData iconoEstado;
    String mensajeEstado;
    
    switch (estadoPuntos) {
      case EstadoPuntos.perfecto:
        colorEstado = Colors.green;
        iconoEstado = Icons.check_circle;
        mensajeEstado = '¡Perfecto!';
        break;
      case EstadoPuntos.cercano:
        colorEstado = Colors.blue;
        iconoEstado = Icons.info;
        mensajeEstado = 'Muy cerca';
        break;
      case EstadoPuntos.faltante:
        colorEstado = Colors.orange;
        iconoEstado = Icons.warning;
        mensajeEstado = 'Faltan ${puntosFaltantes.toStringAsFixed(1)} pts';
        break;
      case EstadoPuntos.excedido:
        colorEstado = Colors.red;
        iconoEstado = Icons.error;
        mensajeEstado = 'Excede ${(puntosActuales - puntosMaximos).toStringAsFixed(1)} pts';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          colorEstado.red,
          colorEstado.green,
          colorEstado.blue,
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromRGBO(
            colorEstado.red,
            colorEstado.green,
            colorEstado.blue,
            0.3,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ResumenItem(
                icono: Icons.help_outline,
                titulo: 'Preguntas',
                valor: '${preguntas.length}',
              ),
              ResumenItem(
                icono: Icons.calculate,
                titulo: 'Puntos Actuales',
                valor: puntosActuales.toStringAsFixed(1),
                color: colorEstado,
                subtitle: 'de ${puntosMaximos.toStringAsFixed(1)}',
              ),
              ResumenItem(
                icono: iconoEstado,
                titulo: 'Estado',
                valor: mensajeEstado,
                color: colorEstado,
              ),
            ],
          ),
          
          // Barra de progreso de puntos
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de Puntos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${((puntosActuales / puntosMaximos) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (puntosActuales / puntosMaximos).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                minHeight: 8,
              ),
            ],
          ),
          
          // Botón de distribución automática (solo si hay desequilibrio)
          if (estadoPuntos != EstadoPuntos.perfecto && onDistribuirAutomaticamente != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDistribuirAutomaticamente,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Distribuir Puntos Automáticamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorEstado,
                  side: BorderSide(color: colorEstado),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para mostrar un item en la revisión
class ItemRevision extends StatelessWidget {
  const ItemRevision({
    required this.titulo,
    required this.valor,
    super.key,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$titulo:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una pregunta en la revisión
class PreguntaRevision extends StatelessWidget {
  const PreguntaRevision({
    required this.numero,
    required this.pregunta,
    super.key,
  });

  final int numero;
  final PreguntaTemporal pregunta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pregunta $numero',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${pregunta.puntos} pts',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(pregunta.enunciadoController.text),
        const SizedBox(height: 8),
        for (int i = 0; i < pregunta.opcionesControllers.length; i++)
          if (pregunta.opcionesControllers[i].text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: pregunta.respuestaCorrecta == i 
                          ? Colors.green 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pregunta.respuestaCorrecta == i 
                              ? Colors.white 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pregunta.opcionesControllers[i].text,
                      style: TextStyle(
                        fontWeight: pregunta.respuestaCorrecta == i 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        color: pregunta.respuestaCorrecta == i 
                            ? Colors.green 
                            : Colors.black,
                      ),
                    ),
                  ),
                  if (pregunta.respuestaCorrecta == i)
                    const Icon(Icons.check, size: 16, color: Colors.green),
                ],
              ),
            ),
      ],
    );
  }
}

// ==================== FUNCIONES AUXILIARES PARA INTEGRACIÓN ====================

/// Función auxiliar para crear un ResumenPuntos fácilmente desde el widget principal
Widget crearResumenPuntos({
  required List<PreguntaTemporal> preguntas,
  required double puntosMaximos,
  VoidCallback? onDistribuirAutomaticamente,
}) {
  return ResumenPuntos(
    preguntas: preguntas,
    puntosMaximos: puntosMaximos,
    onDistribuirAutomaticamente: onDistribuirAutomaticamente,
  );
}

/// Función auxiliar para validar que un examen tenga puntos correctos
bool validarPuntosExamen(List<PreguntaTemporal> preguntas, double puntosMaximos) {
  final estadoPuntos = CalculadorPuntos.obtenerEstadoPuntos(preguntas, puntosMaximos);
  return estadoPuntos == EstadoPuntos.perfecto || estadoPuntos == EstadoPuntos.cercano;
}