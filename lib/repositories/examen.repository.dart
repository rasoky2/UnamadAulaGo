import 'package:aulago/models/examen.model.dart';
import 'package:aulago/models/pregunta_examen.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

class ExamenRepository extends BaseRepository<ModeloExamen> {
  @override
  String get tableName => 'examenes';
  
  @override
  String get repositoryName => 'ExamenRepository';
  
  @override
  ModeloExamen fromJson(Map<String, dynamic> json) {
    return ModeloExamen.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloExamen entity) {
    return entity.toJson();
  }

  @override
  String getId(ModeloExamen entity) {
    return entity.id.toString();
  }

  // CRUD básico
  Future<List<ModeloExamen>> obtenerExamenes() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  Future<ModeloExamen?> obtenerExamenPorId(int id) async {
    return obtenerPorId(id.toString());
  }

  Future<ModeloExamen> crearExamen(ModeloExamen examen) async {
    return crear(examen.toJson());
  }

  Future<ModeloExamen> actualizarExamen(int id, ModeloExamen examen) async {
    return actualizar(id.toString(), examen.toJson());
  }

  Future<bool> eliminarExamen(int id) async {
    await eliminar(id.toString());
    return true;
  }

  // ==================== MÉTODOS PARA PREGUNTAS ====================

  /// Crea un examen completo con sus preguntas
  Future<ModeloExamen> crearExamenConPreguntas({
    required ModeloExamen examen,
    required List<PreguntaExamen> preguntas,
  }) async {
    try {
      debugPrint('[$repositoryName] Creando examen con ${preguntas.length} preguntas');
      
      // 1. Crear el examen
      final examenCreado = await crearExamen(examen);
      
      // 2. Crear las preguntas asociadas
      for (final pregunta in preguntas) {
        final preguntaParaCrear = pregunta.copyWith(examenId: examenCreado.id);
        await _crearPregunta(preguntaParaCrear);
      }
      
      debugPrint('[$repositoryName] Examen creado exitosamente con ID: ${examenCreado.id}');
      return examenCreado;
    } catch (e) {
      debugPrint('[$repositoryName] Error al crear examen con preguntas: $e');
      rethrow;
    }
  }

  /// Crea una pregunta individual
  Future<PreguntaExamen> _crearPregunta(PreguntaExamen pregunta) async {
    try {
      final response = await supabase
          .from('preguntas_examen')
          .insert(pregunta.toJson())
          .select()
          .single();
      
      return PreguntaExamen.fromJson(response);
    } catch (e) {
      debugPrint('[$repositoryName] Error al crear pregunta: $e');
      rethrow;
    }
  }

  /// Obtiene las preguntas de un examen
  Future<List<PreguntaExamen>> obtenerPreguntasExamen(int examenId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo preguntas para examen: $examenId');
      
      final response = await supabase
          .from('preguntas_examen')
          .select()
          .eq('examen_id', examenId)
          .order('id');

      final preguntas = response.map(PreguntaExamen.fromJson).toList();
      debugPrint('[$repositoryName] Preguntas obtenidas: ${preguntas.length}');
      return preguntas;
    } catch (e) {
      debugPrint('[$repositoryName] Error al obtener preguntas: $e');
      rethrow;
    }
  }

  /// Actualiza una pregunta
  Future<PreguntaExamen> actualizarPregunta(int id, PreguntaExamen pregunta) async {
    try {
      final response = await supabase
          .from('preguntas_examen')
          .update(pregunta.toJson())
          .eq('id', id)
          .select()
          .single();
      
      return PreguntaExamen.fromJson(response);
    } catch (e) {
      debugPrint('[$repositoryName] Error al actualizar pregunta: $e');
      rethrow;
    }
  }

  /// Elimina una pregunta
  Future<bool> eliminarPregunta(int id) async {
    try {
      await supabase
          .from('preguntas_examen')
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('[$repositoryName] Error al eliminar pregunta: $e');
      rethrow;
    }
  }

  /// Elimina todas las preguntas de un examen
  Future<bool> eliminarPreguntasExamen(int examenId) async {
    try {
      await supabase
          .from('preguntas_examen')
          .delete()
          .eq('examen_id', examenId);
      
      return true;
    } catch (e) {
      debugPrint('[$repositoryName] Error al eliminar preguntas del examen: $e');
      rethrow;
    }
  }
} 