import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {

  ChatRepository(this._supabase);
  final SupabaseClient _supabase;

  Stream<List<Map<String, dynamic>>> obtenerMensajesGrupales(String grupoClaseId) {
    return _supabase
        .from('mensajes_chat_grupal')
        .stream(primaryKey: ['id'])
        .eq('grupo_clase_id', grupoClaseId)
        .order('fecha_envio', ascending: true)
        .map((listaDeMapas) {
          // La respuesta del stream es una lista de mapas
          return listaDeMapas;
        });
  }

  Future<void> enviarMensajeGrupal({
    required String grupoClaseId,
    required String usuarioId,
    required String contenido,
  }) async {
    await _supabase.from('mensajes_chat_grupal').insert({
      'grupo_clase_id': grupoClaseId,
      'estudiante_id': usuarioId, // La columna en la BD se llama estudiante_id
      'contenido': contenido,
    });
  }
} 