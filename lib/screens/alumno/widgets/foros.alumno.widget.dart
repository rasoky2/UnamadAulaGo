import 'package:aulago/models/foro.model.dart';
import 'package:aulago/repositories/foro.repository.dart';
import 'package:aulago/screens/alumno/widgets/foros_detalle.alumno.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForosWidget extends ConsumerStatefulWidget {

  const ForosWidget({super.key, this.cursoId});
  final String? cursoId;

  @override
  ConsumerState<ForosWidget> createState() => _ForosWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('cursoId', cursoId));
  }
}

class _ForosWidgetState extends ConsumerState<ForosWidget> {
  final ForoRepository _foroRepository = ForoRepository();
  List<Foro> _foros = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarForos();
  }

  Future<void> _cargarForos() async {
    if (widget.cursoId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final foros = await _foroRepository.obtenerForos();
      // Filtrar por cursoId en cliente
      final filtrados = foros.where((f) => f.cursoId.toString() == widget.cursoId).toList();
      setState(() {
        _foros = filtrados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar foros',
              style: TextStyle(fontSize: 18, color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarForos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_foros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay foros disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Los foros aparecerán aquí cuando el profesor los cree',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarForos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _foros.length,
        itemBuilder: (context, index) {
          final foro = _foros[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: Icon(
                  Icons.forum,
                  color: Colors.white,
                ),
              ),
              title: Text(
                foro.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (foro.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      foro.descripcion!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatearFecha(foro.fechaCreacion),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
              onTap: () async {
                await mostrarForoDetalleAlumnoSheet(context: context, foro: foro);
              },
            ),
          );
        },
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Ahora';
    }
  }
} 