import 'package:aulago/models/usuario.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SidebarProfesor extends ConsumerWidget {
  const SidebarProfesor({
    required this.usuario,
    this.esCompacto = false,
    required this.onItemSeleccionado,
    super.key,
  });
  final ModeloUsuario usuario;
  final bool esCompacto;
  final Function(int) onItemSeleccionado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: esCompacto ? 240 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo y título
          _LogoProfesor(esCompacto: esCompacto),
          
          // Información del usuario
          _InfoUsuario(usuario: usuario, esCompacto: esCompacto),
          
          // Menú de navegación
          Expanded(
            child: _MenuNavegacion(
              esCompacto: esCompacto,
              onItemSeleccionado: onItemSeleccionado,
            ),
          ),
          
          // Botón de cerrar sesión
          _BotonCerrarSesion(esCompacto: esCompacto),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ModeloUsuario>('usuario', usuario))
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
      ..add(ObjectFlagProperty<Function(int p1)>.has('onItemSeleccionado', onItemSeleccionado));
  }
}

class _LogoProfesor extends StatelessWidget {
  const _LogoProfesor({this.esCompacto = false});
  final bool esCompacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(esCompacto ? 16 : AppConstants.largePadding),
      child: Column(
        children: [
          Container(
            width: esCompacto ? 40 : 60,
            height: esCompacto ? 40 : 60,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(esCompacto ? 8 : 12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: esCompacto ? 20 : 30,
            ),
          ),
          if (!esCompacto) ...[
            const SizedBox(height: 12),
            const Text(
              'Panel Docente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'UNAMAD',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('esCompacto', esCompacto));
  }
}

class _InfoUsuario extends StatelessWidget {
  const _InfoUsuario({
    required this.usuario,
    this.esCompacto = false,
  });
  final ModeloUsuario usuario;
  final bool esCompacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(esCompacto ? 12 : AppConstants.defaultPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: esCompacto ? 16 : 20,
            backgroundColor: AppConstants.primaryColor,
            child: Text(
              usuario.iniciales,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: esCompacto ? 14 : 16,
              ),
            ),
          ),
          if (!esCompacto) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    usuario.codigoUsuario,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ModeloUsuario>('usuario', usuario))
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto));
  }
}

class _MenuNavegacion extends StatelessWidget {
  const _MenuNavegacion({
    this.esCompacto = false,
    required this.onItemSeleccionado,
  });
  final bool esCompacto;
  final Function(int) onItemSeleccionado;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: esCompacto ? 8 : AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Sección Dashboard
          if (!esCompacto) const _SeccionMenu('INICIO'),
          _ItemMenu(
            icono: LucideIcons.layoutDashboard,
            titulo: esCompacto ? 'Inicio' : 'Panel Principal',
            indice: 0,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(0),
          ),
          
          SizedBox(height: esCompacto ? 8 : AppConstants.defaultPadding),
          
          // Sección Gestión Académica
          if (!esCompacto) const _SeccionMenu('GESTIÓN ACADÉMICA'),
          _ItemMenu(
            icono: LucideIcons.book,
            titulo: 'Mis Cursos',
            indice: 1,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(1),
          ),
          _ItemMenu(
            icono: LucideIcons.graduationCap,
            titulo: 'Calificaciones',
            indice: 2,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(2),
          ),
          _ItemMenu(
            icono: LucideIcons.calendar,
            titulo: 'Calendario',
            indice: 3,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(3),
          ),
          
          SizedBox(height: esCompacto ? 8 : AppConstants.defaultPadding),
          
          // Sección Personal
          if (!esCompacto) const _SeccionMenu('PERSONAL'),
          _ItemMenu(
            icono: LucideIcons.user,
            titulo: 'Mi Perfil',
            indice: 4,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(4),
          ),
          _ItemMenu(
            icono: LucideIcons.settings,
            titulo: 'Configuración',
            indice: 5,
            esCompacto: esCompacto,
            onTap: () => onItemSeleccionado(5),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
      ..add(ObjectFlagProperty<Function(int p1)>.has('onItemSeleccionado', onItemSeleccionado));
  }
}

class _SeccionMenu extends StatelessWidget {
  const _SeccionMenu(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppConstants.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('titulo', titulo));
  }
}

class _ItemMenu extends ConsumerWidget {
  const _ItemMenu({
    required this.icono,
    required this.titulo,
    required this.indice,
    this.esCompacto = false,
    required this.onTap,
  });
  final IconData icono;
  final String titulo;
  final int indice;
  final bool esCompacto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implementar provider para el índice actual del profesor
    final indiceActual = 0; // Temporalmente fijo
    final esActivo = indiceActual == indice;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: esActivo ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: InkWell(
          onTap: () {
            debugPrint('🖱️ ItemMenu Profesor: Clicked $titulo (índice: $indice)');
            onTap();
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: esCompacto ? 8 : AppConstants.defaultPadding,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icono,
                  size: 18,
                  color: esActivo
                      ? AppConstants.primaryColor
                      : AppConstants.textSecondary,
                ),
                if (!esCompacto) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: esActivo ? FontWeight.w600 : FontWeight.normal,
                        color: esActivo
                            ? AppConstants.primaryColor
                            : AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icono', icono))
      ..add(StringProperty('titulo', titulo))
      ..add(IntProperty('indice', indice))
      ..add(DiagnosticsProperty<bool>('esCompacto', esCompacto))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}

class _BotonCerrarSesion extends ConsumerWidget {
  const _BotonCerrarSesion({this.esCompacto = false});
  final bool esCompacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(esCompacto ? 12 : AppConstants.defaultPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            debugPrint('🚪 Profesor: Cerrando sesión');
            await ref.read(proveedorAuthProvider.notifier).cerrarSesion();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          icon: const Icon(LucideIcons.logOut, size: 16),
          label: Text(esCompacto ? '' : 'Cerrar Sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: esCompacto ? 8 : AppConstants.defaultPadding,
              vertical: esCompacto ? 8 : 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('esCompacto', esCompacto));
  }
}

// Mantener la clase original para compatibilidad
class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isActive = false,
    super.key,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isActive
            ? theme.primaryColor
            : theme.colorScheme.onSurface.withAlpha(153),
      ),
      title: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? theme.primaryColor : theme.colorScheme.onSurface,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: isActive ? theme.primaryColor.withAlpha(26) : Colors.transparent,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('text', text))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(DiagnosticsProperty<bool>('isActive', isActive));
  }
}
