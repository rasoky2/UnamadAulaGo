import 'package:aulago/models/foro.model.dart';
import 'package:aulago/repositories/base.repository.dart';
import 'package:aulago/utils/logger.dart';

class PublicacionForoRepository extends BaseRepository<PublicacionForo> {
  @override
  String get tableName => 'publicaciones_foro';

  @override
  String get repositoryName => 'PublicacionForoRepository';

  @override
  PublicacionForo fromJson(Map<String, dynamic> json) => PublicacionForo.fromJson(json);

  @override
  Map<String, dynamic> toJson(PublicacionForo entity) => entity.toJson();

  @override
  String getId(PublicacionForo entity) => entity.id.toString();

  /// Obtiene publicaciones de un foro específico con información del autor
  Future<List<Map<String, dynamic>>> obtenerPublicacionesConAutor(int foroId) async {
    try {
      // Obtener publicaciones básicas
      final publicaciones = await supabase
          .from(tableName)
          .select()
          .eq('foro_id', foroId)
          .order('fecha_creacion', ascending: false);

      // Enriquecer con información del autor
      final publicacionesConAutor = <Map<String, dynamic>>[];
      
      for (final pub in publicaciones) {
        final Map<String, dynamic> publicacionEnriquecida = Map.from(pub);
        final tipoAutor = pub['tipo_autor'] as String? ?? 'estudiante';
        final autorId = pub['autor_id'];
        
        if (autorId != null) {
          if (tipoAutor == 'estudiante') {
            final estudiante = await supabase
                .from('estudiantes')
                .select('nombre_completo, foto_perfil_url')
                .eq('id', autorId)
                .maybeSingle();
            publicacionEnriquecida['autor_nombre'] = estudiante?['nombre_completo'] ?? 'Estudiante';
            publicacionEnriquecida['autor_foto'] = estudiante?['foto_perfil_url'];
          } else if (tipoAutor == 'profesor') {
            final profesor = await supabase
                .from('profesores')
                .select('nombre_completo, foto_perfil_url')
                .eq('id', autorId)
                .maybeSingle();
            publicacionEnriquecida['autor_nombre'] = profesor?['nombre_completo'] ?? 'Profesor';
            publicacionEnriquecida['autor_foto'] = profesor?['foto_perfil_url'];
          }
        }
        
        publicacionesConAutor.add(publicacionEnriquecida);
      }

      ApiLogger.logGet(
        table: tableName,
        statusCode: 200,
        response: {
          'items_count': publicacionesConAutor.length,
          'foro_id': foroId,
          'items': publicacionesConAutor,
        },
        filters: {'foro_id': foroId, 'with_author': true},
      );

      return publicacionesConAutor;
    } catch (e) {
      ApiLogger.logError(
        operation: 'OBTENER_PUBLICACIONES_CON_AUTOR',
        table: tableName,
        error: e,
        additionalInfo: 'Foro ID: $foroId',
      );
      rethrow;
    }
  }

  /// Crea una nueva publicación usando el método base con logging
  Future<Map<String, dynamic>> crearPublicacion(Map<String, dynamic> datos) async {
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
        operation: 'CREAR_PUBLICACION',
        table: tableName,
        error: e,
        additionalInfo: 'Datos: $datos',
      );
      rethrow;
    }
  }
}


