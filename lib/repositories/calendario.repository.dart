import 'package:aulago/models/evento_calendario.model.dart';
import 'package:aulago/models/examen.model.dart';
import 'package:aulago/models/tarea.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

/// Repository para manejar eventos del calendario del estudiante
class CalendarioRepository extends BaseRepository<EventoCalendario> {
  CalendarioRepository(); // Tabla virtual

  @override
  EventoCalendario fromJson(Map<String, dynamic> json) {
    // Este método no se usa directamente ya que construimos los eventos manualmente
    throw UnimplementedError('Use los métodos específicos para obtener eventos');
  }

  @override
  Map<String, dynamic> toJson(EventoCalendario item) {
    // Este método no se usa directamente
    throw UnimplementedError('Los eventos del calendario no se almacenan directamente');
  }

  @override
  String get repositoryName => 'CalendarioRepository';

  @override
  String get tableName => 'calendario'; // Tabla virtual

  @override
  String getId(EventoCalendario item) => item.id;

  /// Obtiene todos los eventos del calendario para un estudiante
  Future<List<EventoCalendario>> obtenerEventosEstudiante(int estudianteId) async {
    try {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Obteniendo eventos para estudiante: $estudianteId');
      }

      final eventos = <EventoCalendario>[];

      // Obtener eventos en paralelo
      final resultados = await Future.wait([
        _obtenerTareasComoEventos(estudianteId),
        _obtenerExamenesComoEventos(estudianteId),
        _obtenerForosComoEventos(estudianteId),
      ]);

      // Combinar todos los eventos
      eventos..addAll(resultados[0]) // Tareas
      ..addAll(resultados[1]) // Exámenes
      ..addAll(resultados[2]) // Foros

      // Ordenar por fecha (más próximos primero)
      ..sort((a, b) => a.fechaEvento.compareTo(b.fechaEvento));

      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Total eventos obtenidos: ${eventos.length}');
      }
      return eventos;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Error obteniendo eventos del estudiante: $e');
      }
      rethrow;
    }
  }

  /// Obtiene eventos para un mes específico
  Future<List<EventoCalendario>> obtenerEventosDelMes(
    int estudianteId,
    int anio,
    int mes,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Obteniendo eventos del mes $mes/$anio para estudiante: $estudianteId');
      }

      final primerDia = DateTime(anio, mes);
      final ultimoDia = DateTime(anio, mes + 1, 0);

      final eventos = await obtenerEventosEstudiante(estudianteId);

      // Filtrar eventos del mes
      final eventosDelMes = eventos.where((evento) {
        return evento.fechaEvento.isAfter(primerDia.subtract(const Duration(days: 1))) &&
               evento.fechaEvento.isBefore(ultimoDia.add(const Duration(days: 1)));
      }).toList();

      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Eventos del mes $mes/$anio: ${eventosDelMes.length}');
      }
      return eventosDelMes;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Error obteniendo eventos del mes: $e');
      }
      rethrow;
    }
  }

  /// Obtiene eventos para una fecha específica
  Future<List<EventoCalendario>> obtenerEventosDelDia(
    int estudianteId,
    DateTime fecha,
  ) async {
    try {
      final eventos = await obtenerEventosDelMes(estudianteId, fecha.year, fecha.month);
      
      return eventos.where((evento) => evento.fechaEvento.esMismoDia(fecha)).toList();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Error obteniendo eventos del día: $e');
      }
      rethrow;
    }
  }

  /// Obtiene eventos próximos (siguiente semana)
  Future<List<EventoCalendario>> obtenerEventosProximos(int estudianteId) async {
    try {
      final ahora = DateTime.now();
      final enUnaSemana = ahora.add(const Duration(days: 7));

      final eventos = await obtenerEventosEstudiante(estudianteId);

      // Filtrar eventos próximos y no vencidos
      final eventosProximos = eventos.where((evento) {
        return !evento.esFechaPasada &&
               evento.fechaEvento.isBefore(enUnaSemana.add(const Duration(days: 1)));
      }).toList()

      // Ordenar por prioridad (más urgentes primero)
      ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

      return eventosProximos.take(10).toList(); // Limitar a 10 eventos

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarioRepository] Error obteniendo eventos próximos: $e');
      }
      rethrow;
    }
  }

  /// Obtiene tareas como eventos del calendario
  Future<List<EventoCalendario>> _obtenerTareasComoEventos(int estudianteId) async {
    try {
      final response = await supabase
          .from('tareas')
          .select('''
            *,
            cursos:curso_id (
              id,
              nombre
            )
          ''')
          .neq('estado', 'inactiva')
          .gte('fecha_entrega', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      if (kDebugMode) {
        debugPrint('Tareas obtenidas: ${response.length}');
      }

      final eventos = <EventoCalendario>[];

      for (final tareaJson in response) {
        try {
          final tarea = ModeloTarea.fromJson(tareaJson);
          final cursoNombre = tareaJson['cursos']?['nombre'] as String?;

          final evento = EventoCalendario.desdeTarea(tarea, cursoNombre: cursoNombre);
          eventos.add(evento);

        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error procesando tarea: $e');
          }
        }
      }

      return eventos;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error obteniendo tareas: $e');
      }
      return [];
    }
  }

  /// Obtiene exámenes como eventos del calendario
  Future<List<EventoCalendario>> _obtenerExamenesComoEventos(int estudianteId) async {
    try {
      final response = await supabase
          .from('examenes')
          .select('''
            *,
            cursos:curso_id (
              id,
              nombre
            )
          ''')
          .neq('estado', 'borrador')
          .gte('fecha_limite', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      if (kDebugMode) {
        debugPrint('Exámenes obtenidos: ${response.length}');
      }

      final eventos = <EventoCalendario>[];

      for (final examenJson in response) {
        try {
          final examen = ModeloExamen.fromJson(examenJson);
          final cursoNombre = examenJson['cursos']?['nombre'] as String?;

          final evento = EventoCalendario.desdeExamen(examen, cursoNombre: cursoNombre);
          eventos.add(evento);

        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error procesando examen: $e');
          }
        }
      }

      return eventos;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error obteniendo exámenes: $e');
      }
      return [];
    }
  }

  /// Obtiene foros como eventos del calendario
  Future<List<EventoCalendario>> _obtenerForosComoEventos(int estudianteId) async {
    try {
      final response = await supabase
          .from('foros')
          .select('''
            id,
            titulo,
            descripcion,
            fecha_creacion,
            curso_id,
            cursos:curso_id (
              id,
              nombre
            )
          ''')
          .eq('estado', 'activo')
          .gte('fecha_creacion', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      if (kDebugMode) {
        debugPrint('Foros obtenidos: ${response.length}');
      }

      final eventos = <EventoCalendario>[];

      for (final foroJson in response) {
        try {
          final foroId = foroJson['id'].toString();
          final titulo = foroJson['titulo'] as String;
          final descripcion = foroJson['descripcion'] as String?;
          final fechaCreacion = DateTime.parse(foroJson['fecha_creacion'] as String);
          final cursoId = foroJson['curso_id'] as int?;
          final cursoNombre = foroJson['cursos']?['nombre'] as String?;

          final evento = EventoCalendario.desdeForo(
            foroId,
            titulo,
            fechaCreacion,
            descripcion: descripcion,
            cursoNombre: cursoNombre,
            cursoId: cursoId,
          );

          eventos.add(evento);

        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error procesando foro: $e');
          }
        }
      }

      return eventos;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error obteniendo foros: $e');
      }
      return [];
    }
  }
}
