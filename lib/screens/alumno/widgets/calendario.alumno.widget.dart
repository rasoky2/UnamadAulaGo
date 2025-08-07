import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarioWidget extends StatefulWidget {

  const CalendarioWidget({
    super.key,
    required this.onRegresar,
  });
  final VoidCallback onRegresar;

  @override
  State<CalendarioWidget> createState() => _CalendarioWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar));
  }
}

class _CalendarioWidgetState extends State<CalendarioWidget> {
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
                LucideIcons.calendar200,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Calendario',
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
          
          // Widget del calendario
          Container(
            height: 600,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header del calendario
                _construirHeaderCalendario(),
                const SizedBox(height: 16),
                
                // Calendario
                Expanded(
                  child: _construirCalendario(),
                ),
                
                // Footer con opciones
                _construirFooterCalendario(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirHeaderCalendario() {
    return Row(
      children: [
        // Navegación del mes
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.chevronLeft200, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.chevronRight200, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Título del mes
        const Text(
          'junio 2025',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        
        const Spacer(),
        
        // Pestañas de vista
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirPestanaVista('Mes', true),
              _construirPestanaVista('Semana', false),
              _construirPestanaVista('Día', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirPestanaVista(String texto, bool activa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: activa ? Colors.grey.shade100 : null,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
          color: activa ? AppConstants.textPrimary : AppConstants.textSecondary,
        ),
      ),
    );
  }

  Widget _construirCalendario() {
    const diasSemana = ['LUN.', 'MAR.', 'MIÉ.', 'JUE.', 'VIE.', 'SÁB.', 'DOM.'];
    
    return Column(
      children: [
        // Encabezados de días
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: diasSemana.map((dia) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  dia,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
        
        // Filas del calendario
        Expanded(
          child: Column(
            children: [
              _construirFilaCalendario(['26', '27', '28', '29', '30', '31', '1'], otroMes: [true, true, true, true, true, true, false]),
              _construirFilaCalendario(['2', '3', '4', '5', '6', '7', '8']),
              _construirFilaCalendario(['9', '10', '11', '12', '13', '14', '15']),
              _construirFilaCalendario(['16', '17', '18', '19', '20', '21', '22'], destacado: [false, false, false, false, false, false, true]),
              _construirFilaCalendario(['23', '24', '25', '26', '27', '28', '29']),
              _construirFilaCalendario(['30', '1', '2', '3', '4', '5', '6'], otroMes: [false, true, true, true, true, true, true]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirFilaCalendario(List<String> dias, {List<bool>? otroMes, List<bool>? destacado}) {
    return Expanded(
      child: Row(
        children: List.generate(dias.length, (index) {
          final esOtroMes = otroMes?[index] ?? false;
          final esDestacado = destacado?[index] ?? false;
          
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                color: esDestacado ? Colors.blue.shade50 : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.topLeft,
                    child: esDestacado
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              dias[index],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            dias[index],
                            style: TextStyle(
                              fontSize: 11,
                              color: esOtroMes ? AppConstants.textTertiary : AppConstants.textPrimary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _construirFooterCalendario() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          // Fecha seleccionada destacada
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '31',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sincronizar',
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
            ),
          ),
          
          const Spacer(),
          
          // Botón agregar fechas importantes
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppConstants.primaryColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus200,
                        size: 16,
                        color: AppConstants.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Agregar más\nfechas importantes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 