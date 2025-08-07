import 'package:aulago/providers/auth.riverpod.dart';
import 'package:aulago/repositories/chat.repository.dart';
import 'package:aulago/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Providers locales para el chat
final _chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ChatRepository(supabase);
});

final _chatGrupalProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, grupoClaseId) {
  final chatRepo = ref.watch(_chatRepositoryProvider);
  return chatRepo.obtenerMensajesGrupales(grupoClaseId);
});

class ChatWidget extends ConsumerStatefulWidget {

  const ChatWidget({
    super.key,
    required this.grupoClaseId,
    required this.onRegresar,
  });
  final String grupoClaseId;
  final VoidCallback onRegresar;

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('grupoClaseId', grupoClaseId))
    ..add(ObjectFlagProperty<VoidCallback>.has('onRegresar', onRegresar));
  }
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final TextEditingController _controladorMensaje = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversacionSeleccionada;

  @override
  void initState() {
    super.initState();
    // Seleccionar el chat grupal por defecto
    _conversacionSeleccionada = widget.grupoClaseId;
  }

  @override
  void dispose() {
    _controladorMensaje.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _enviarMensaje() async {
    final contenido = _controladorMensaje.text.trim();
    final usuarioId = ref.read(proveedorAuthProvider).usuario?.id;

    if (contenido.isEmpty || usuarioId == null) {
      return;
    }
    
    try {
      final chatRepo = ref.read(_chatRepositoryProvider);
      await chatRepo.enviarMensajeGrupal(
        grupoClaseId: widget.grupoClaseId,
        usuarioId: usuarioId,
        contenido: contenido,
      );

      _controladorMensaje.clear();
      ref.invalidate(_chatGrupalProvider(widget.grupoClaseId));

      // Scroll al final después de un breve retraso
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el mensaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para simplificar, asumimos que el nombre del curso está disponible.
    // En una implementación real, esto vendría de un provider.
    const nombreCurso = 'Desarrollo de Aplicaciones Web';

    return Row(
      children: [
        // Lista de conversaciones (sidebar)
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: _construirListaConversaciones(nombreCurso),
        ),
        
        // Área de chat principal
        Expanded(
          child: _conversacionSeleccionada == null
              ? _construirAreaVacia()
              : _construirAreaChat(),
        ),
      ],
    );
  }

  Widget _construirListaConversaciones(String nombreCurso) {
    return Column(
      children: [
        // Header de conversaciones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFFE91E63)),
          child: Row(
            children: [
              const Icon(LucideIcons.messageSquare, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(onPressed: widget.onRegresar, icon: const Icon(LucideIcons.x, color: Colors.white, size: 20)),
            ],
          ),
        ),
        
        // Única conversación: el chat grupal
        Expanded(
          child: ListView(
            children: [
              _construirItemConversacion({
                'id': widget.grupoClaseId,
                'nombre': 'Grupo: $nombreCurso',
                'ultimoMensaje': 'Chat del curso',
                'noLeidos': 0, // Esto podría ser dinámico en el futuro
                'tipo': 'grupo',
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirItemConversacion(Map<String, dynamic> conversacion) {
    final esSeleccionada = _conversacionSeleccionada == conversacion['id'];
    
    return InkWell(
      onTap: () => setState(() => _conversacionSeleccionada = conversacion['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esSeleccionada ? const Color(0xFFE91E63).withValues(alpha: 26, red: 233, green: 30, blue: 99) : null,
          border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _obtenerColorTipo(conversacion['tipo']),
              child: Icon(_obtenerIconoTipo(conversacion['tipo']), color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversacion['nombre'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversacion['ultimoMensaje'],
                    style: const TextStyle(fontSize: 13, color: AppConstants.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirAreaVacia() {
    return Container(
      color: Colors.grey.shade50,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageSquare, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Selecciona una conversación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.textSecondary)),
            SizedBox(height: 8),
            Text('Elige una conversación de la lista para comenzar a chatear', style: TextStyle(fontSize: 14, color: AppConstants.textTertiary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _construirAreaChat() {
    final chatAsync = ref.watch(_chatGrupalProvider(widget.grupoClaseId));
    final usuarioActualId = ref.read(proveedorAuthProvider).usuario?.id;

    return Column(
      children: [
        // Header del chat
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: const Row(
            children: [
              Text('Chat Grupal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Lista de mensajes
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: chatAsync.when(
              data: (mensajes) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    final esMio = mensaje['estudiante_id'] == usuarioActualId;
                    return _construirBurbujaMensaje(mensaje, esMio);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error al cargar el chat: ${err.toString()}')),
            ),
          ),
        ),
        // Campo de entrada de texto
        _construirInputMensaje(),
      ],
    );
  }
  
  Widget _construirBurbujaMensaje(Map<String, dynamic> mensaje, bool esMio) {
    final fecha = DateTime.tryParse(mensaje['fecha_envio'] ?? '') ?? DateTime.now();
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: esMio ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!esMio)
              Text(
                mensaje['nombre_completo'] ?? 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppConstants.accentColor,
                ),
              ),
            if (!esMio) const SizedBox(height: 4),
            Text(
              mensaje['contenido'] ?? '',
              style: TextStyle(color: esMio ? Colors.white : AppConstants.textPrimary),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(fecha.toLocal()),
              style: TextStyle(
                fontSize: 10,
                color: esMio ? Colors.white70 : AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirInputMensaje() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controladorMensaje,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _enviarMensaje(),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.send, color: AppConstants.primaryColor),
            onPressed: _enviarMensaje,
          ),
        ],
      ),
    );
  }

  Color _obtenerColorTipo(String tipo) {
    switch (tipo) {
      case 'profesor': return Colors.blue;
      case 'grupo': return Colors.green;
      case 'estudiante': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _obtenerIconoTipo(String tipo) {
    switch (tipo) {
      case 'profesor': return LucideIcons.userCog;
      case 'grupo': return LucideIcons.users;
      case 'estudiante': return LucideIcons.user;
      default: return LucideIcons.messageSquare;
    }
  }
} 