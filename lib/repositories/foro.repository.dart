import 'package:aulago/models/foro.model.dart';
import 'package:aulago/repositories/base.repository.dart';

/// Repositorio para gestión de foros
class ForoRepository extends BaseRepository<ModeloForo> {
  @override
  String get tableName => 'foros';
  
  @override
  String get repositoryName => 'ForoRepository';
  
  @override
  ModeloForo fromJson(Map<String, dynamic> json) {
    return ModeloForo.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ModeloForo entity) {
    return {
      'id': entity.id,
      'titulo': entity.titulo,
      'descripcion': entity.descripcion,
      'fecha_creacion': entity.fechaCreacion?.toIso8601String(),
    };
  }
  
  @override
  String getId(ModeloForo entity) {
    return entity.id;
  }
} 