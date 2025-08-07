import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PerfilAlumnoWidget extends ConsumerWidget {
  const PerfilAlumnoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(proveedorAuthProvider).usuario;
    if (usuario == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userX,
              size: 64,
              color: AppConstants.textTertiary,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontró información del alumno',
              style: TextStyle(
                fontSize: 18,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(esMovil ? 16 : 24),
      child: Column(
        children: [
          _construirTarjetaPerfil(context, usuario, esMovil),
          const SizedBox(height: 24),
          _construirBotonCerrarSesion(context, ref, esMovil),
        ],
      ),
    );
  }

  Widget _construirTarjetaPerfil(BuildContext context, usuario, bool esMovil) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esMovil ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con avatar y nombre
          _construirHeaderPerfil(usuario, esMovil),
          const SizedBox(height: 24),
          
          // Información del usuario
          _construirInformacionUsuario(usuario, esMovil),
          
          const SizedBox(height: 24),
          
          // Botón editar perfil
          _construirBotonEditarPerfil(context, esMovil),
        ],
      ),
    );
  }

  Widget _construirHeaderPerfil(usuario, bool esMovil) {
    return Row(
      children: [
        // Avatar
        Container(
          width: esMovil ? 60 : 80,
          height: esMovil ? 60 : 80,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(esMovil ? 30 : 40),
            border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            LucideIcons.user,
            size: esMovil ? 30 : 40,
            color: AppConstants.primaryColor,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Información del nombre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombreCompleto,
                style: TextStyle(
                  fontSize: esMovil ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${usuario.codigoUsuario}',
                style: TextStyle(
                  fontSize: esMovil ? 13 : 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirInformacionUsuario(usuario, bool esMovil) {
    return Column(
      children: [
        _construirInfoItem(
          icon: LucideIcons.mail,
          label: 'Correo electrónico',
          value: usuario.correoElectronico ?? 'No disponible',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        _construirInfoItem(
          icon: LucideIcons.userCheck,
          label: 'Rol',
          value: usuario.rol,
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        _construirInfoItem(
          icon: LucideIcons.circle,
          label: 'Estado',
          value: usuario.activo ? 'Activo' : 'Inactivo',
          esMovil: esMovil,
          valueColor: usuario.activo ? Colors.green : Colors.red,
        ),
        if (usuario.perfil != null && usuario.perfil is Map<String, dynamic>) ...[
          const SizedBox(height: 16),
          _construirInfoItem(
            icon: LucideIcons.graduationCap,
            label: 'Carrera',
            value: usuario.perfil['carrera'] ?? 'No disponible',
            esMovil: esMovil,
          ),
          const SizedBox(height: 16),
          _construirInfoItem(
            icon: LucideIcons.bookOpen,
            label: 'Semestre',
            value: usuario.perfil['semestre']?.toString() ?? 'No disponible',
            esMovil: esMovil,
          ),
        ],
        const SizedBox(height: 16),
        _construirInfoItem(
          icon: LucideIcons.phone,
          label: 'Teléfono',
          value: usuario.perfil?.telefono ?? 'No disponible',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        _construirInfoItem(
          icon: LucideIcons.mapPin,
          label: 'Dirección',
          value: usuario.perfil?.direccion ?? 'No disponible',
          esMovil: esMovil,
        ),
      ],
    );
  }

  Widget _construirInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool esMovil,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: esMovil ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: esMovil ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppConstants.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirBotonEditarPerfil(BuildContext context, bool esMovil) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _mostrarDialogoEditarPerfil(context, esMovil),
        icon: const Icon(Icons.edit),
        label: const Text('Editar Perfil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: esMovil ? 16 : 24,
            vertical: esMovil ? 12 : 16,
          ),
          textStyle: TextStyle(
            fontSize: esMovil ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEditarPerfil(BuildContext context, bool esMovil) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DialogoEditarPerfilWidget(esMovil: esMovil),
    );
  }

  Widget _construirBotonCerrarSesion(BuildContext context, WidgetRef ref, bool esMovil) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Confirmar cierre de sesión'),
              content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            await ref.read(proveedorAuthProvider.notifier).cerrarSesion();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
        },
        icon: const Icon(LucideIcons.logOut),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: esMovil ? 16 : 24,
            vertical: esMovil ? 12 : 16,
          ),
          textStyle: TextStyle(
            fontSize: esMovil ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Widget para el diálogo de edición de perfil
class _DialogoEditarPerfilWidget extends ConsumerStatefulWidget {
  const _DialogoEditarPerfilWidget({required this.esMovil});
  final bool esMovil;

  @override
  ConsumerState<_DialogoEditarPerfilWidget> createState() => _DialogoEditarPerfilWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('esMovil', esMovil));
  }
}

class _DialogoEditarPerfilWidgetState extends ConsumerState<_DialogoEditarPerfilWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(proveedorAuthProvider).usuario;
    
    // Separar nombre completo en nombres y apellidos
    String nombres = '';
    String apellidos = '';
    
    if (usuario != null) {
      final nombresSeparados = usuario.nombreCompleto.split(' ');
      if (nombresSeparados.isNotEmpty) {
        nombres = nombresSeparados.first;
        if (nombresSeparados.length > 1) {
          apellidos = nombresSeparados.skip(1).join(' ');
        }
      }
    }
    
    _nombresController = TextEditingController(text: nombres);
    _apellidosController = TextEditingController(text: apellidos);
    _emailController = TextEditingController(text: usuario?.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: usuario?.perfil?['telefono'] ?? '');
    _direccionController = TextEditingController(text: usuario?.perfil?['direccion'] ?? '');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Perfil'),
      content: SizedBox(
        width: widget.esMovil ? double.infinity : 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombresController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apellidosController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardarPerfil,
          child: _guardando 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(proveedorAuthProvider).usuario;
      if (usuario == null) {
        throw Exception('Usuario no encontrado');
      }

      final datos = {
        'nombre_completo': '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim(),
        'correo_electronico': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String(),
      };

      final repository = EstudianteRepository();
      final success = await repository.actualizarPerfilEstudiante(usuario.id, datos);

      if (mounted) {
        if (success) {
          // Refrescar el provider de auth
          ref.invalidate(proveedorAuthProvider);
          
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar el perfil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
