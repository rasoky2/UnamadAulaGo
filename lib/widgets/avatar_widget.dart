import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget personalizado para mostrar avatares de usuario con foto de perfil o iniciales
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.fotoUrl,
    required this.nombreCompleto,
    this.tipoUsuario = 'estudiante',
    this.radio = 20,
    this.mostrarBordeOnline = false,
  });

  final String? fotoUrl;
  final String nombreCompleto;
  final String tipoUsuario; // 'estudiante', 'profesor', 'admin'
  final double radio;
  final bool mostrarBordeOnline;

  @override
  Widget build(BuildContext context) {
    final colorFondo = _getColorFondo();
    final iniciales = _getIniciales();

    return Container(
      width: radio * 2,
      height: radio * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: mostrarBordeOnline 
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: ClipOval(
        child: fotoUrl != null && fotoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: fotoUrl!,
                width: radio * 2,
                height: radio * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(colorFondo, iniciales),
                errorWidget: (context, url, error) => _buildPlaceholder(colorFondo, iniciales),
              )
            : _buildPlaceholder(colorFondo, iniciales),
      ),
    );
  }

  Widget _buildPlaceholder(Color colorFondo, String iniciales) {
    return Container(
      width: radio * 2,
      height: radio * 2,
      decoration: BoxDecoration(
        color: colorFondo,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          iniciales,
          style: TextStyle(
            color: Colors.white,
            fontSize: radio * 0.7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getColorFondo() {
    switch (tipoUsuario.toLowerCase()) {
      case 'profesor':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      case 'estudiante':
      default:
        return Colors.blue;
    }
  }

  String _getIniciales() {
    if (nombreCompleto.isEmpty) {
      return '?';
    }
    
    final palabras = nombreCompleto.trim().split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    } else if (palabras.isNotEmpty) {
      return palabras[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('nombreCompleto', nombreCompleto))
    ..add(StringProperty('fotoUrl', fotoUrl))
    ..add(StringProperty('tipoUsuario', tipoUsuario))
    ..add(DoubleProperty('radio', radio))
    ..add(DiagnosticsProperty<bool>('mostrarBordeOnline', mostrarBordeOnline));
  }
}

/// Widget específico para avatares en los foros
class ForoAvatarWidget extends StatelessWidget {
  const ForoAvatarWidget({
    super.key,
    this.fotoUrl,
    required this.nombreCompleto,
    required this.tipoUsuario,
    this.radio = 16,
  });

  final String? fotoUrl;
  final String nombreCompleto;
  final String tipoUsuario;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return AvatarWidget(
      fotoUrl: fotoUrl,
      nombreCompleto: nombreCompleto,
      tipoUsuario: tipoUsuario,
      radio: radio,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('fotoUrl', fotoUrl))
    ..add(StringProperty('nombreCompleto', nombreCompleto))
    ..add(StringProperty('tipoUsuario', tipoUsuario))
    ..add(DoubleProperty('radio', radio));
  }
}
