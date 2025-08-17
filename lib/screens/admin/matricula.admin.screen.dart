import 'package:aulago/models/carrera.model.dart';
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/estudiante.model.dart';
import 'package:aulago/models/matricula.model.dart';
import 'package:aulago/repositories/carrera.repository.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/estudiante.repository.dart';
import 'package:aulago/repositories/matricula.repository.dart';
import 'package:aulago/repositories/periodo_academico.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:aulago/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matriculasProvider = StateNotifierProvider<_MatriculasNotifier, List<ModeloMatricula>>((ref) {
  return _MatriculasNotifier();
});

class _MatriculasNotifier extends StateNotifier<List<ModeloMatricula>> {
  _MatriculasNotifier() : super([]) {
    cargarMatriculas();
  }
  final _repo = MatriculaRepository();
  Future<void> cargarMatriculas() async {
    final lista = await _repo.obtenerMatriculasDetallado();
    state = lista;
  }
  Future<bool> crearMatricula(ModeloMatricula matricula) async {
    try {
      await _repo.crearMatricula(matricula);
      await cargarMatriculas();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> actualizarMatricula(int id, ModeloMatricula matricula) async {
    try {
      await _repo.actualizarMatricula(id, matricula);
      await cargarMatriculas();
      return true;
    } catch (_) {
      return false;
    }
  }
  Future<bool> eliminarMatricula(int id) async {
    try {
      await _repo.eliminarMatricula(id);
      await cargarMatriculas();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PantallaMatriculasAdmin extends ConsumerStatefulWidget {
  const PantallaMatriculasAdmin({super.key});
  @override
  ConsumerState<PantallaMatriculasAdmin> createState() => _PantallaMatriculasAdminState();
}

class _PantallaMatriculasAdminState extends ConsumerState<PantallaMatriculasAdmin> {
  final TextEditingController _searchController = TextEditingController();
  final CarreraRepository _carreraRepo = CarreraRepository();
  List<ModeloCarrera> _carreras = const [];
  int? _filtroCarreraId;
  String _filtroTexto = '';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final matriculas = ref.watch(matriculasProvider);
    final filtro = _filtroTexto.trim().toLowerCase();
    List<ModeloMatricula> listaFiltrada = matriculas;
    if (_filtroCarreraId != null) {
      listaFiltrada = listaFiltrada.where((m) => m.carreraId == _filtroCarreraId).toList();
    }
    if (filtro.isNotEmpty) {
      listaFiltrada = listaFiltrada.where((e) {
        final nombre = (e.estudianteNombre ?? '').toLowerCase();
        final codigo = (e.estudianteCodigo ?? '').toLowerCase();
        final curso = (e.cursoNombre ?? '').toLowerCase();
        return nombre.contains(filtro) || codigo.contains(filtro) || curso.contains(filtro);
      }).toList();
    }
    return Column(
      children: [
        _construirHeader(),
        const SizedBox(height: AppConstants.defaultPadding),
        Expanded(child: _construirContenido(listaFiltrada)),
      ],
    );
  }
  Widget _construirHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Gestión de Matrículas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => ref.read(matriculasProvider.notifier).cargarMatriculas(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoMatricula(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Matrícula'),
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Buscador por nombre/código/curso
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por estudiante (nombre/código) o curso...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _filtroTexto = v),
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<List<ModeloCarrera>>(
                future: _carreras.isEmpty ? _carreraRepo.obtenerCarreras() : Future.value(_carreras),
                builder: (context, snapshot) {
                  final items = (snapshot.data ?? _carreras);
                  if (_carreras.isEmpty && items.isNotEmpty) {
                    _carreras = items;
                  }
                  return SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<int>(
                      value: _filtroCarreraId,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por carrera',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Todas las carreras')),
                        ...items.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre))),
                      ],
                      onChanged: (v) => setState(() => _filtroCarreraId = v),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Eliminado: barra de búsqueda duplicada. La búsqueda vive ahora en el header con filtros.
  Widget _construirContenido(List<ModeloMatricula> matriculas) {
    if (matriculas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg, size: 64, color: AppConstants.textTertiary),
            SizedBox(height: 16),
            Text('No se encontraron matrículas', style: TextStyle(fontSize: 18, color: AppConstants.textSecondary)),
            SizedBox(height: 8),
            Text('Ajusta la búsqueda o crea la primera matrícula', style: TextStyle(color: AppConstants.textTertiary)),
          ],
        ),
      );
    }

    // Agrupar por estudiante para mejorar la UX
    final Map<int, List<ModeloMatricula>> grupos = {};
    for (final m in matriculas) {
      grupos.putIfAbsent(m.estudianteId, () => []).add(m);
    }
    // Ordenar por nombre del estudiante
    final entradasOrdenadas = grupos.entries.toList()
      ..sort((a, b) {
        final an = a.value.first.estudianteNombre ?? '';
        final bn = b.value.first.estudianteNombre ?? '';
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entradasOrdenadas.length,
      itemBuilder: (context, index) {
        final entry = entradasOrdenadas[index];
        final alumnoMatriculas = entry.value;
        final alumno = alumnoMatriculas.first;
        final alumnoNombre = alumno.estudianteNombre ?? 'Estudiante';
        final alumnoCodigo = alumno.estudianteCodigo ?? '';
        final totalCursos = alumnoMatriculas.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: AvatarWidget(
              fotoUrl: alumno.estudianteFotoUrl,
              nombreCompleto: alumnoNombre,
              tipoUsuario: 'estudiante',
              radio: 18,
              mostrarBordeOnline: true,
            ),
            title: Text(alumnoNombre),
            subtitle: Text(alumnoCodigo.isEmpty ? '$totalCursos curso(s)' : '$alumnoCodigo • $totalCursos curso(s)'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            children: [
              for (final m in alumnoMatriculas)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined, size: 20),
                  title: Text(m.cursoNombre ?? 'Curso', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      if (m.cursoCodigo != null) m.cursoCodigo,
                      if (m.profesorNombre != null) 'Prof: ${m.profesorNombre}',
                      if (m.periodoNombre != null) m.periodoNombre,
                    ].whereType<String>().join(' • '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Eliminar matrícula',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarEliminar(context, m),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  void _mostrarDialogoMatricula(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _DialogoMatricula(),
    );
  }
  void _confirmarEliminar(BuildContext context, ModeloMatricula matricula) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la matrícula de ${matricula.estudianteNombre} en ${matricula.cursoNombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await ref.read(matriculasProvider.notifier).eliminarMatricula(matricula.id);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Matrícula eliminada exitosamente' : 'Error al eliminar matrícula'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DialogoMatricula extends ConsumerStatefulWidget {
  const _DialogoMatricula();
  @override
  ConsumerState<_DialogoMatricula> createState() => _DialogoMatriculaState();
}
class _DialogoMatriculaState extends ConsumerState<_DialogoMatricula> {
  final _formKey = GlobalKey<FormState>();
  final CarreraRepository _carreraRepo = CarreraRepository();
  final CursoRepository _cursoRepo = CursoRepository();
  final EstudianteRepository _estudianteRepo = EstudianteRepository();
  final PeriodoAcademicoRepository _periodoRepo = PeriodoAcademicoRepository();

  List<ModeloCarrera> _carreras = const [];
  List<ModeloCursoDetallado> _cursosDet = const [];
  List<EstudianteAdmin> _estudiantes = const [];
  List<Map<String, dynamic>> _periodos = const [];

  int? _carreraId;
  int? _cursoId;
  int? _estudianteId;
  int? _periodoId;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  Future<void> _cargarInicial() async {
    final carreras = await _carreraRepo.obtenerCarreras();
    final periodos = await _periodoRepo.obtenerPeriodosAcademicos();
    if (!mounted) {
      return;
    }
    setState(() {
      _carreras = carreras;
      _periodos = periodos;
      // Preseleccionar primera carrera y periodo para disparar la carga de cursos/estudiantes
      if (_carreraId == null && _carreras.isNotEmpty) {
        _carreraId = _carreras.first.id;
      }
      if (_periodoId == null && _periodos.isNotEmpty) {
        _periodoId = (_periodos.first['id'] as int?);
      }
    });
    if (_carreraId != null) {
      await _cargarCursosYEstudiantes(_carreraId!);
    }
  }

  Future<void> _cargarCursosYEstudiantes(int carreraId) async {
    // Cursos con profesor
    final cursosDet = await _cursoRepo.obtenerCursosConProfesor();
    // Filtrar por carrera
    final cursosFiltrados = cursosDet.where((c) => c.curso.carreraId == carreraId).toList();
    // Estudiantes por carrera
    final todosEst = await _estudianteRepo.obtenerEstudiantes();
    final estFiltrados = todosEst.where((e) => e.carreraId == carreraId).toList();
    if (!mounted) {
      return;
    }
    setState(() {
      _cursosDet = cursosFiltrados;
      _estudiantes = estFiltrados;
      _cursoId = null;
      _estudianteId = null;
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Matrícula'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Carrera
                DropdownButtonFormField<int>(
                  value: _carreraId,
                  decoration: const InputDecoration(labelText: 'Carrera *', border: OutlineInputBorder()),
                  items: _carreras
                      .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _carreraId = v;
                      _cursoId = null;
                      _estudianteId = null;
                    });
                    if (v != null) {
                      _cargarCursosYEstudiantes(v);
                    }
                  },
                  validator: (v) => v == null ? 'Seleccione una carrera' : null,
                ),
                const SizedBox(height: 16),

                // Curso (muestra profesor)
                DropdownButtonFormField<int>(
                  value: _cursoId,
                  decoration: const InputDecoration(labelText: 'Curso *', border: OutlineInputBorder()),
                  items: _cursosDet
                      .map((cd) => DropdownMenuItem<int>(
                            value: cd.curso.id,
                            child: Text('${cd.curso.codigoCurso} - ${cd.curso.nombre} • Prof: ${cd.profesor?.nombreCompleto ?? '—'}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _cursoId = v),
                  validator: (v) => v == null ? 'Seleccione un curso' : null,
                ),
                const SizedBox(height: 16),

                // Estudiante (filtrado por carrera)
                DropdownButtonFormField<int>(
                  value: _estudianteId,
                  decoration: const InputDecoration(labelText: 'Estudiante *', border: OutlineInputBorder()),
                  items: _estudiantes
                      .map((e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text('${e.codigoEstudiante} - ${e.nombreCompleto}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _estudianteId = v),
                  validator: (v) => v == null ? 'Seleccione un estudiante' : null,
                ),
                const SizedBox(height: 16),

                // Periodo Académico
                DropdownButtonFormField<int>(
                  value: _periodoId,
                  decoration: const InputDecoration(labelText: 'Periodo Académico *', border: OutlineInputBorder()),
                  items: _periodos
                      .map((p) {
                        final nombre = 'Año ${p['anio']} - Sem ${p['semestre']}';
                        return DropdownMenuItem<int>(value: p['id'] as int, child: Text(nombre));
                      })
                      .toList(),
                  onChanged: (v) => setState(() => _periodoId = v),
                  validator: (v) => v == null ? 'Seleccione un periodo' : null,
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
          onPressed: _guardarMatricula,
          child: const Text('Crear'),
        ),
      ],
    );
  }
  Future<void> _guardarMatricula() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Evitar duplicados
    final repo = MatriculaRepository();
    final existe = await repo.existeMatricula(
      estudianteId: _estudianteId ?? 0,
      cursoId: _cursoId ?? 0,
      periodoId: _periodoId ?? 0,
    );
    if (existe) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El estudiante ya está matriculado en ese curso y periodo'), backgroundColor: Colors.orange),
      );
      return;
    }

    final matricula = ModeloMatricula(
      id: 0,
      estudianteId: _estudianteId ?? 0,
      cursoId: _cursoId,
      periodoAcademicoId: _periodoId ?? 0,
      fechaMatricula: DateTime.now(),
    );
    final notifier = ref.read(matriculasProvider.notifier);
    final success = await notifier.crearMatricula(matricula);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Matrícula creada exitosamente' : 'Error al crear matrícula'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
