import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ItemNavegacion extends StatelessWidget {

  const ItemNavegacion({
    super.key,
    required this.titulo,
    required this.icono,
    this.activo = false,
    this.onTap,
  });
  final String titulo;
  final IconData icono;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icono,
          size: 16,
          color: activo ? AppConstants.primaryColor : AppConstants.textSecondary,
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
            color: activo ? AppConstants.primaryColor : AppConstants.textSecondary,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        tileColor: activo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        dense: true,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('titulo', titulo))
    ..add(DiagnosticsProperty<IconData>('icono', icono))
    ..add(DiagnosticsProperty<bool>('activo', activo))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
} 