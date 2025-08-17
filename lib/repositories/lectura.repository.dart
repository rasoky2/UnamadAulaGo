import 'package:aulago/models/lectura.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:flutter/foundation.dart';

class LecturaRepository extends BaseRepository<Lectura> {
  @override
  String get tableName => 'lecturas';

  @override
  String get repositoryName => 'LecturaRepository';

  @override
  Lectura fromJson(Map<String, dynamic> json) => Lectura.fromJson(json);

  @override
  Map<String, dynamic> toJson(Lectura entity) => entity.toJson();

  @override
  String getId(Lectura entity) => entity.id?.toString() ?? '0';

  Future<List<Lectura>> obtenerLecturas() async {
    final result = await obtener(limite: 1000, offset: 0);
    return result.items;
  }

  /// Obtiene lecturas filtradas por curso específico
  Future<List<Lectura>> obtenerLecturasPorCurso(int cursoId) async {
    try {
      debugPrint('[$repositoryName] Obteniendo lecturas para curso: $cursoId');
      
      final response = await supabase
          .from(tableName)
          .select()
          .eq('curso_id', cursoId)
          .order('id', ascending: false);

      final lecturas = response.map(fromJson).toList();
      debugPrint('[$repositoryName] Lecturas obtenidas para curso $cursoId: ${lecturas.length}');
      return lecturas;
    } catch (e) {
      debugPrint('[$repositoryName] Error al obtener lecturas por curso: $e');
      rethrow;
    }
  }

  Future<Lectura> crearLectura(Lectura lectura) async {
    return crear(lectura.toJson());
  }

  Future<Lectura> actualizarLectura(int id, Lectura lectura) async {
    return actualizar(id.toString(), lectura.toJson());
  }

  Future<bool> eliminarLectura(int id) async {
    await eliminar(id.toString());
    return true;
  }
}


