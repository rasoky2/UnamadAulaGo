import 'package:aulago/models/anuncio.model.dart';
import 'package:aulago/models/curso.model.dart';
import 'package:aulago/models/fecha_importante.model.dart';
import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/anuncio.repository.dart';
import 'package:aulago/repositories/curso.repository.dart';
import 'package:aulago/repositories/fecha_importante.repository.dart';
import 'package:aulago/screens/alumno/cursos.alumno.screen.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Providers para anuncios y fechas importantes
final anunciosAlumnoProvider = FutureProvider<List<ModeloAnuncio>>((ref) {
  final repo = AnuncioRepository();
  return repo.obtenerAnuncios();
});

final fechasImportantesAlumnoProvider = FutureProvider<List<ModeloFechaImportante>>((ref) {
  final repo = FechaImportanteRepository();
  return repo.obtenerFechasImportantes();
});

class PantallaInicioAlumno extends ConsumerWidget {
  const PantallaInicioAlumno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoAuth = ref.watch(proveedorAuthProvider);
    final estudiante = ref.watch(usuarioActualProvider);
    final cursosFuture = CursoRepository().obtenerCursos();
    final anunciosAsync = ref.watch(anunciosAlumnoProvider);
    final fechasAsync = ref.watch(fechasImportantesAlumnoProvider);
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 700;

    if (!estadoAuth.estaAutenticado || estudiante == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (esMovil) {
      // Móvil: lista simple y bloques apilados, sin AppBar
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          FutureBuilder<List<ModeloCurso>>(
            future: cursosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final cursos = snapshot.data ?? [];
              final cursosDetallados = cursos
                  .map((c) => ModeloCursoDetallado(curso: c))
                  .toList();
               return _buildSeccionCursosMovil(context, cursosDetallados);
            },
          ),
          const SizedBox(height: 28),
          _construirAnunciosGrande(anunciosAsync),
          const SizedBox(height: 28),
          _construirFechasImportantesGrande(fechasAsync),
        ],
      );
    }

    // Escritorio/tablet: layout original
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<ModeloCurso>>(
            future: cursosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final cursos = snapshot.data ?? [];
              final cursosDetallados = cursos
                  .map((c) => ModeloCursoDetallado(curso: c))
                  .toList();
              return _buildSeccionCursos(context, cursosDetallados);
            },
          ),
          const SizedBox(height: 40),
          _buildBottomSections(
            anunciosAsync,
            fechasAsync,
            true,
          ),
        ],
      ),
    );
  }




  Widget _buildSeccionCursos(BuildContext context, List<ModeloCursoDetallado> cursos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.book200,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cursos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        Column(
          children: cursos.map((curso) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _construirItemCursoIndividual(context, curso),
          )).toList(),
        ),
      ],
    );
  }

  Widget _construirItemCursoIndividual(BuildContext context, ModeloCursoDetallado curso) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.code200,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.curso.nombre.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${curso.curso.codigoCurso}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (curso.carrera?.nombre != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                curso.carrera!.nombre,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.primaryColor.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${curso.curso.creditos} créditos',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.warningColor.withAlpha(200),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: () {
                    // Abrir layout de cursos con el curso seleccionado
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PantallaCursosAlumno(initialCursoId: curso.curso.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.darkButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ingresar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSections(AsyncValue<List<ModeloAnuncio>> anunciosAsync, AsyncValue<List<ModeloFechaImportante>> fechasAsync, bool esMovil) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        
        if (ancho < 600) {
          return Column(
            children: [
              _construirAnunciosGrande(anunciosAsync),
              const SizedBox(height: 32),
              _construirFechasImportantesGrande(fechasAsync),
            ],
          );
        } else if (ancho < 900) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _construirAnunciosGrande(anunciosAsync)),
                  const SizedBox(width: 24),
                  Expanded(child: _construirFechasImportantesGrande(fechasAsync)),
                ],
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _construirAnunciosGrande(anunciosAsync)),
              const SizedBox(width: 32),
              Expanded(child: _construirFechasImportantesGrande(fechasAsync)),
            ],
          );
        }
      },
    );
  }

  Widget _construirAnunciosGrande(AsyncValue<List<ModeloAnuncio>> anunciosAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.megaphone, 
                  size: 24, 
                  color: AppConstants.secondaryColor
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Anuncios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver más'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          anunciosAsync.when(
            data: (anuncios) {
              if (anuncios.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.bellOff,
                        size: 48,
                        color: AppConstants.textTertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay anuncios registrados',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppConstants.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Datos no encontrados',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textTertiary.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: anuncios.map((anuncio) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(anuncio.titulo),
                      subtitle: Text(anuncio.contenido),
                      leading: const Icon(LucideIcons.bell),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(
              child: Text('Datos no cargados'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFechasImportantesGrande(AsyncValue<List<ModeloFechaImportante>> fechasAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.calendar, 
                  size: 24, 
                  color: AppConstants.primaryColor
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Fechas importantes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          fechasAsync.when(
            data: (fechas) {
              if (fechas.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.calendarOff,
                        size: 48,
                        color: AppConstants.textTertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay fechas importantes',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppConstants.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Datos no encontrados',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textTertiary.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: fechas.map((fecha) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(fecha.titulo),
                      subtitle: Text(fecha.descripcion ?? 'Sin descripción'),
                      leading: const Icon(LucideIcons.calendarCheck),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Center(child: Text('Datos no cargados')),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionCursosMovil(BuildContext context, List<ModeloCursoDetallado> cursos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cursos.map((curso) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _construirItemCursoMovil(context, curso),
        )),
      ],
    );
  }

  Widget _construirItemCursoMovil(BuildContext context, ModeloCursoDetallado curso) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.code200,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.curso.nombre.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${curso.curso.codigoCurso}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (curso.carrera?.nombre != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                curso.carrera!.nombre,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.primaryColor.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${curso.curso.creditos} créditos',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.warningColor.withAlpha(200),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PantallaCursosAlumno(initialCursoId: curso.curso.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.darkButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ingresar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


} 