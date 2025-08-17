import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/foto_perfil_upload.widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PerfilAlumnoWidget extends ConsumerStatefulWidget {
  const PerfilAlumnoWidget({super.key});

  @override
  ConsumerState<PerfilAlumnoWidget> createState() => _PerfilAlumnoWidgetState();
}

class _PerfilAlumnoWidgetState extends ConsumerState<PerfilAlumnoWidget> {
  EstudianteAdmin? _estudiante;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosEstudiante();
  }

  Future<void> _cargarDatosEstudiante() async {
    try {
      final usuario = ref.read(proveedorAuthProvider).usuario;
      if (usuario != null) {
        final repository = EstudianteRepository();
        final estudiante = await repository.obtenerEstudiantePorUsuarioId(usuario.id);
        
        if (mounted) {
          setState(() {
            _estudiante = estudiante;
            _cargando = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos del estudiante: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando perfil del estudiante...',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
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
          
          // Botón de refresh
          _construirBotonRefresh(esMovil),
          const SizedBox(height: 16),
          
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
        // Avatar con foto de perfil
        FotoPerfilUploadWidget(
          usuarioId: usuario.id.toString(),
          nombreCompleto: _estudiante?.nombreCompleto ?? usuario.nombreCompleto,
          tipoUsuario: 'estudiante',
          fotoActualUrl: _estudiante?.fotoPerfilUrl ?? usuario.fotoPerfilUrl,
          radio: esMovil ? 30 : 40,
          onFotoSubida: (nuevaUrl) async {
            // Actualizar la foto en la base de datos
            try {
              final repository = EstudianteRepository();
              // Necesitamos obtener el estudiante completo por usuario_id
              final estudianteCompleto = await repository.obtenerEstudiantePorUsuarioId(usuario.id);
              if (estudianteCompleto != null) {
                final estudianteActualizado = estudianteCompleto.copyWith(fotoPerfilUrl: nuevaUrl);
                await repository.actualizarEstudiante(estudianteCompleto.id, estudianteActualizado);
                
                // Actualizar el estado local
                if (mounted) {
                  setState(() {
                    _estudiante = estudianteActualizado;
                  });
                }
              }
            } catch (e) {
              debugPrint('Error al actualizar foto de perfil: $e');
            }
          },
        ),
        
        const SizedBox(width: 16),
        
        // Información del nombre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _estudiante?.nombreCompleto ?? usuario.nombreCompleto,
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
                'Código: ${_estudiante?.codigoEstudiante ?? usuario.codigoUsuario}',
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
        // Información básica del usuario
        _construirInfoItem(
          icon: LucideIcons.mail,
          label: 'Correo electrónico',
          value: usuario.correoElectronico ?? 'No disponible',
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
        
        // Información detallada del estudiante desde el repositorio
        if (_estudiante != null) ...[
          const SizedBox(height: 24),
          _construirSeccionEstudiante(esMovil),
          const SizedBox(height: 24),
          _construirSeccionEstadisticas(esMovil),
        ],
      ],
    );
  }

  Widget _construirSeccionEstudiante(bool esMovil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.graduationCap,
                size: 16,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Académica',
                style: TextStyle(
                  fontSize: esMovil ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Código de estudiante
        _construirInfoItem(
          icon: LucideIcons.hash,
          label: 'Código de estudiante',
          value: _estudiante!.codigoEstudiante,
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Carrera
        _construirInfoItem(
          icon: LucideIcons.bookOpen,
          label: 'Carrera',
          value: _estudiante!.carreraNombre ?? 'Carrera no especificada',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Semestre actual
        _construirInfoItem(
          icon: LucideIcons.calendar,
          label: 'Semestre actual',
          value: _estudiante!.semestreActual?.toString() ?? 'No especificado',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Teléfono
        _construirInfoItem(
          icon: LucideIcons.phone,
          label: 'Teléfono',
          value: _estudiante!.telefono ?? 'No disponible',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Dirección
        _construirInfoItem(
          icon: LucideIcons.mapPin,
          label: 'Dirección',
          value: _estudiante!.direccion ?? 'No disponible',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Fecha de nacimiento
        if (_estudiante!.fechaNacimiento != null) ...[
          _construirInfoItem(
            icon: LucideIcons.cake,
            label: 'Fecha de nacimiento',
            value: _formatearFecha(_estudiante!.fechaNacimiento!),
            esMovil: esMovil,
          ),
          const SizedBox(height: 16),
        ],
        
        // Fecha de ingreso
        _construirInfoItem(
          icon: LucideIcons.calendarDays,
          label: 'Fecha de ingreso',
          value: _estudiante!.fechaIngreso != null 
              ? _formatearFecha(_estudiante!.fechaIngreso!)
              : 'No especificada',
          esMovil: esMovil,
        ),
        const SizedBox(height: 16),
        
        // Fecha de creación del registro
        if (_estudiante!.fechaCreacion != null) ...[
          _construirInfoItem(
            icon: LucideIcons.clock,
            label: 'Fecha de creación del registro',
            value: _formatearFecha(_estudiante!.fechaCreacion!),
            esMovil: esMovil,
          ),
          const SizedBox(height: 16),
        ],
        
        // Fecha de última actualización
        if (_estudiante!.fechaActualizacion != null) ...[
          _construirInfoItem(
            icon: LucideIcons.refreshCw,
            label: 'Última actualización',
            value: _formatearFecha(_estudiante!.fechaActualizacion!),
            esMovil: esMovil,
          ),
        ],
      ],
    );
  }

  Widget _construirSeccionEstadisticas(bool esMovil) {
    if (_estudiante!.estadisticas == null) {
      return const SizedBox.shrink();
    }

    final stats = _estudiante!.estadisticas!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.bar_chart,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas Académicas',
                style: TextStyle(
                  fontSize: esMovil ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Cursos activos
        _construirInfoItem(
          icon: LucideIcons.bookOpen,
          label: 'Cursos activos',
          value: stats.cursosActivos.toString(),
          esMovil: esMovil,
          valueColor: Colors.green,
        ),
        const SizedBox(height: 16),
        
        // Créditos totales
        _construirInfoItem(
          icon: LucideIcons.award,
          label: 'Créditos totales',
          value: stats.creditosTotales.toString(),
          esMovil: esMovil,
          valueColor: Colors.blue,
        ),
        const SizedBox(height: 16),
        
        // Promedio general
        _construirInfoItem(
          icon: LucideIcons.trendingUp,
          label: 'Promedio general',
          value: stats.promedioGeneral > 0 ? stats.promedioGeneral.toStringAsFixed(2) : 'No disponible',
          esMovil: esMovil,
          valueColor: stats.promedioGeneral >= 11 ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 16),
        
        // Porcentaje de asistencia
        _construirInfoItem(
          icon: Icons.person_pin,
          label: 'Porcentaje de asistencia',
          value: stats.porcentajeAsistencia > 0 ? '${stats.porcentajeAsistencia.toStringAsFixed(1)}%' : 'No disponible',
          esMovil: esMovil,
          valueColor: stats.porcentajeAsistencia >= 80 ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 16),
        
        // Tareas completadas
        _construirInfoItem(
          icon: Icons.check_circle,
          label: 'Tareas completadas',
          value: stats.tareasCompletadas.toString(),
          esMovil: esMovil,
          valueColor: Colors.green,
        ),
        const SizedBox(height: 16),
        
        // Tareas pendientes
        _construirInfoItem(
          icon: LucideIcons.clock,
          label: 'Tareas pendientes',
          value: stats.tareasPendientes.toString(),
          esMovil: esMovil,
          valueColor: stats.tareasPendientes > 0 ? Colors.orange : Colors.green,
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

  Widget _construirBotonRefresh(bool esMovil) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              setState(() => _cargando = true);
              await _cargarDatosEstudiante();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar datos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: const BorderSide(color: AppConstants.primaryColor),
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
        ),
      ],
    );
  }

  void _mostrarDialogoEditarPerfil(BuildContext context, bool esMovil) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DialogoEditarPerfilWidget(esMovil: esMovil),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
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
  bool _cargandoDatos = true;
  EstudianteAdmin? _estudiante;

  @override
  void initState() {
    super.initState();
    _cargarDatosEstudiante();
  }

  Future<void> _cargarDatosEstudiante() async {
    try {
      final usuario = ref.read(proveedorAuthProvider).usuario;
      if (usuario != null) {
        final repository = EstudianteRepository();
        final estudiante = await repository.obtenerEstudiantePorUsuarioId(usuario.id);
        
        if (estudiante != null && mounted) {
          setState(() {
            _estudiante = estudiante;
            _cargandoDatos = false;
          });
          _inicializarControladores(estudiante);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos del estudiante: $e');
      if (mounted) {
        setState(() {
          _cargandoDatos = false;
        });
        // Fallback a datos básicos del usuario
        _inicializarControladoresBasicos();
      }
    }
  }

  void _inicializarControladores(EstudianteAdmin estudiante) {
    // Separar nombre completo en nombres y apellidos
    final nombresSeparados = estudiante.nombreCompleto.split(' ');
    final nombres = nombresSeparados.isNotEmpty ? nombresSeparados.first : '';
    final apellidos = nombresSeparados.length > 1 ? nombresSeparados.skip(1).join(' ') : '';
    
    _nombresController = TextEditingController(text: nombres);
    _apellidosController = TextEditingController(text: apellidos);
    _emailController = TextEditingController(text: estudiante.correoElectronico ?? '');
    _telefonoController = TextEditingController(text: estudiante.telefono ?? '');
    _direccionController = TextEditingController(text: estudiante.direccion ?? '');
    _fechaNacimiento = estudiante.fechaNacimiento;
  }

  void _inicializarControladoresBasicos() {
    final usuario = ref.read(proveedorAuthProvider).usuario;
    if (usuario != null) {
      final nombresSeparados = usuario.nombreCompleto.split(' ');
      final nombres = nombresSeparados.isNotEmpty ? nombresSeparados.first : '';
      final apellidos = nombresSeparados.length > 1 ? nombresSeparados.skip(1).join(' ') : '';
      
      _nombresController = TextEditingController(text: nombres);
      _apellidosController = TextEditingController(text: apellidos);
      _emailController = TextEditingController(text: usuario.correoElectronico ?? '');
      _telefonoController = TextEditingController(text: '');
      _direccionController = TextEditingController(text: '');
    }
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
        child: _cargandoDatos
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando datos del perfil...'),
                    ],
                  ),
                ),
              )
            : Form(
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
                    hintText: 'Solo letras',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value!)) {
                      return 'Solo se permiten letras';
                    }
                    if (value.trim().length < 2) {
                      return 'Mínimo 2 caracteres';
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
                    hintText: 'Solo letras',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value!)) {
                      return 'Solo se permiten letras';
                    }
                    if (value.trim().length < 2) {
                      return 'Mínimo 2 caracteres';
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
                    hintText: 'usuario@unamad.edu.pe',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Campo requerido';
                    }
                    if (!value!.endsWith('@unamad.edu.pe')) {
                      return 'El email debe terminar en @unamad.edu.pe';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@unamad\.edu\.pe$').hasMatch(value)) {
                      return 'Formato de email inválido';
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
                    hintText: 'Máximo 9 dígitos',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length != 9) {
                        return 'El teléfono debe tener 9 dígitos';
                      }
                      if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
                        return 'Solo se permiten números';
                      }
                    }
                    return null;
                  },
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

      if (_estudiante == null) {
        throw Exception('Datos del estudiante no cargados');
      }

      // Crear estudiante actualizado usando copyWith
      final estudianteActualizado = _estudiante!.copyWith(
        nombreCompleto: '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim(),
        correoElectronico: _emailController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
      );

      final repository = EstudianteRepository();
      await repository.actualizarEstudiante(_estudiante!.id, estudianteActualizado);
      
      if (mounted) {
        // Refrescar el provider de auth
        ref.invalidate(proveedorAuthProvider);
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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