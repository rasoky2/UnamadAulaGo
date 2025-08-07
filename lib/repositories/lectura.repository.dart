import 'package:aulago/repositories/base.repository.dart';

/// Repositorio para gestión de lecturas
class LecturaRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get tableName => 'lecturas';
  
  @override
  String get repositoryName => 'LecturaRepository';
  
  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) {
    return json;
  }
  
  @override
  Map<String, dynamic> toJson(Map<String, dynamic> entity) {
    return entity;
  }
  
  @override
  String getId(Map<String, dynamic> entity) {
    return entity['id'] as String;
  }
} 