import 'package:aulago/models/anuncio.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar anuncios en Supabase
class AnuncioRepository extends BaseRepository<ModeloAnuncio> {
  @override
  String get tableName => 'anuncios';
  
  @override
  String get repositoryName => 'AnuncioRepository';

  @override
  ModeloAnuncio fromJson(Map<String, dynamic> json) {
    return ModeloAnuncio.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloAnuncio entity) {
    return entity.toJson();
  }
  
  @override
  String getId(ModeloAnuncio entity) {
    return entity.id?.toString() ?? '0';
  }

  /// Obtiene todos los anuncios ordenados por fecha de creación
  Future<List<ModeloAnuncio>> obtenerAnuncios() async {
    try {
      debugPrint('[AnuncioRepository] Obteniendo anuncios...');
      
      final response = await supabase
          .from(tableName)
          .select()
          .order('fecha_creacion', ascending: false);
      
      final List<ModeloAnuncio> anuncios = (response as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint('[AnuncioRepository] ✅ Anuncios obtenidos: ${anuncios.length}');
      return anuncios;
    } catch (e) {
      debugPrint('[AnuncioRepository] ❌ Error al obtener anuncios: $e');
      rethrow;
    }
  }

  /// Crea un nuevo anuncio usando BaseRepository
  Future<ModeloAnuncio> crearAnuncio(ModeloAnuncio anuncio) async {
    try {
      debugPrint('[AnuncioRepository] Creando anuncio: ${anuncio.titulo}');
      final resultado = await crear(anuncio.toJson());
      debugPrint('[AnuncioRepository] ✅ Anuncio creado: ID ${resultado.id}');
      return resultado;
    } catch (e) {
      debugPrint('[AnuncioRepository] ❌ Error al crear anuncio: $e');
      rethrow;
    }
  }

  /// Actualiza un anuncio existente usando BaseRepository
  Future<ModeloAnuncio> actualizarAnuncio(int id, ModeloAnuncio anuncio) async {
    try {
      debugPrint('[AnuncioRepository] Actualizando anuncio ID: $id');
      final resultado = await actualizar(id.toString(), anuncio.toJson());
      debugPrint('[AnuncioRepository] ✅ Anuncio actualizado: ID ${resultado.id}');
      return resultado;
    } catch (e) {
      debugPrint('[AnuncioRepository] ❌ Error al actualizar anuncio: $e');
      rethrow;
    }
  }

  /// Elimina un anuncio usando BaseRepository
  Future<bool> eliminarAnuncio(int id) async {
    try {
      debugPrint('[AnuncioRepository] Eliminando anuncio ID: $id');
      await eliminar(id.toString());
      debugPrint('[AnuncioRepository] ✅ Anuncio eliminado: ID $id');
      return true;
    } catch (e) {
      debugPrint('[AnuncioRepository] ❌ Error al eliminar anuncio: $e');
      rethrow;
    }
  }
}
