import 'package:aulago/repositories/base.repository.dart';

/// Repositorio para gestión de videoconferencias
class VideoconferenciaRepository extends BaseRepository<Map<String, dynamic>> {
  @override
  String get tableName => 'videoconferencias';
  
  @override
  String get repositoryName => 'VideoconferenciaRepository';
  
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