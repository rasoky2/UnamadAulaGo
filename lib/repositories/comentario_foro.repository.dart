import 'package:aulago/models/foro.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

class ComentarioForoRepository extends BaseRepository<ComentarioForo> {
  @override
  String get tableName => 'comentarios_foro';

  @override
  String get repositoryName => 'ComentarioForoRepository';

  @override
  ComentarioForo fromJson(Map<String, dynamic> json) => ComentarioForo.fromJson(json);

  @override
  Map<String, dynamic> toJson(ComentarioForo entity) => entity.toJson();

  @override
  String getId(ComentarioForo entity) => entity.id.toString();

  /// Obtiene comentarios de una publicación específica con información del autor
  Future<List<Map<String, dynamic>>> obtenerComentariosConAutor(int publicacionId) async {
    try {
      // Obtener comentarios básicos
      final comentarios = await supabase
          .from(tableName)
          .select()
          .eq('publicacion_id', publicacionId)
          .order('fecha_creacion', ascending: true);

      // Enriquecer con información del autor
      final comentariosConAutor = <Map<String, dynamic>>[];
      
      for (final com in comentarios) {
        final Map<String, dynamic> comentarioEnriquecido = Map.from(com);
        final tipoAutor = com['tipo_autor'] as String? ?? 'estudiante';
        final autorId = com['autor_id'];
        
        if (autorId != null) {
          if (tipoAutor == 'estudiante') {
            final estudiante = await supabase
                .from('estudiantes')
                .select('nombre_completo, foto_perfil_url')
                .eq('id', autorId)
                .maybeSingle();
            comentarioEnriquecido['autor_nombre'] = estudiante?['nombre_completo'] ?? 'Estudiante';
            comentarioEnriquecido['autor_foto'] = estudiante?['foto_perfil_url'];
          } else if (tipoAutor == 'profesor') {
            final profesor = await supabase
                .from('profesores')
                .select('nombre_completo, foto_perfil_url')
                .eq('id', autorId)
                .maybeSingle();
            comentarioEnriquecido['autor_nombre'] = profesor?['nombre_completo'] ?? 'Profesor';
            comentarioEnriquecido['autor_foto'] = profesor?['foto_perfil_url'];
          }
        }
        
        comentariosConAutor.add(comentarioEnriquecido);
      }

      ApiLogger.logGet(
        table: tableName,
        statusCode: 200,
        response: {
          'items_count': comentariosConAutor.length,
          'publicacion_id': publicacionId,
          'items': comentariosConAutor,
        },
        filters: {'publicacion_id': publicacionId, 'with_author': true},
      );

      return comentariosConAutor;
    } catch (e) {
      ApiLogger.logError(
        operation: 'OBTENER_COMENTARIOS_CON_AUTOR',
        table: tableName,
        error: e,
        additionalInfo: 'Publicación ID: $publicacionId',
      );
      rethrow;
    }
  }

  /// Crea un nuevo comentario usando el método base con logging
  Future<Map<String, dynamic>> crearComentario(Map<String, dynamic> datos) async {
    try {
      final result = await supabase
          .from(tableName)
          .insert(datos)
          .select()
          .single();
      
      ApiLogger.logPost(
        table: tableName,
        statusCode: 201,
        response: result,
        requestBody: datos,
      );
      
      return result;
    } catch (e) {
      ApiLogger.logError(
        operation: 'CREAR_COMENTARIO',
        table: tableName,
        error: e,
        additionalInfo: 'Datos: $datos',
      );
      rethrow;
    }
  }
}


