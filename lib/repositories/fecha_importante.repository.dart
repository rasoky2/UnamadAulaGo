import 'package:aulago/models/fecha_importante.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar fechas importantes en Supabase
class FechaImportanteRepository extends BaseRepository<ModeloFechaImportante> {
  @override
  String get tableName => 'fechas_importantes';
  
  @override
  String get repositoryName => 'FechaImportanteRepository';

  @override
  ModeloFechaImportante fromJson(Map<String, dynamic> json) {
    return ModeloFechaImportante.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloFechaImportante entity) {
    return entity.toJson();
  }
  
  @override
  String getId(ModeloFechaImportante entity) {
    return entity.id.toString();
  }

  /// Obtiene todas las fechas importantes ordenadas por fecha del evento
  Future<List<ModeloFechaImportante>> obtenerFechasImportantes() async {
    try {
      debugPrint('[FechaImportanteRepository] Obteniendo fechas importantes...');
      
      final response = await supabase
          .from(tableName)
          .select()
          .order('fecha_evento', ascending: true);
      
      final List<ModeloFechaImportante> fechas = (response as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint('[FechaImportanteRepository] ✅ Fechas importantes obtenidas: ${fechas.length}');
      return fechas;
    } catch (e) {
      debugPrint('[FechaImportanteRepository] ❌ Error al obtener fechas importantes: $e');
      rethrow;
    }
  }

  /// Crea una nueva fecha importante usando BaseRepository
  Future<ModeloFechaImportante> crearFechaImportante(ModeloFechaImportante fecha) async {
    try {
      debugPrint('[FechaImportanteRepository] Creando fecha importante: ${fecha.titulo}');
      final resultado = await crear(fecha.toJson());
      debugPrint('[FechaImportanteRepository] ✅ Fecha importante creada: ID ${resultado.id}');
      return resultado;
    } catch (e) {
      debugPrint('[FechaImportanteRepository] ❌ Error al crear fecha importante: $e');
      rethrow;
    }
  }

  /// Actualiza una fecha importante existente usando BaseRepository
  Future<ModeloFechaImportante> actualizarFechaImportante(int id, ModeloFechaImportante fecha) async {
    try {
      debugPrint('[FechaImportanteRepository] Actualizando fecha importante ID: $id');
      final resultado = await actualizar(id.toString(), fecha.toJson());
      debugPrint('[FechaImportanteRepository] ✅ Fecha importante actualizada: ID ${resultado.id}');
      return resultado;
    } catch (e) {
      debugPrint('[FechaImportanteRepository] ❌ Error al actualizar fecha importante: $e');
      rethrow;
    }
  }

  /// Elimina una fecha importante usando BaseRepository
  Future<bool> eliminarFechaImportante(int id) async {
    try {
      debugPrint('[FechaImportanteRepository] Eliminando fecha importante ID: $id');
      await eliminar(id.toString());
      debugPrint('[FechaImportanteRepository] ✅ Fecha importante eliminada: ID $id');
      return true;
    } catch (e) {
      debugPrint('[FechaImportanteRepository] ❌ Error al eliminar fecha importante: $e');
      rethrow;
    }
  }
}
