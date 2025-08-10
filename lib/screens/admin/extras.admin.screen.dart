import 'package:flutter/material.dart';

class PantallaExtrasAdmin extends StatefulWidget {
  const PantallaExtrasAdmin({super.key});

  @override
  State<PantallaExtrasAdmin> createState() => _PantallaExtrasAdminState();
}

class _PantallaExtrasAdminState extends State<PantallaExtrasAdmin> {
  // TODO: (implementación) Conectar a repositorios reales de anuncios y fechas_importantes
  final _formAnuncio = GlobalKey<FormState>();
  final _tituloAnuncio = TextEditingController();
  final _contenidoAnuncio = TextEditingController();

  final _formFecha = GlobalKey<FormState>();
  final _tituloFecha = TextEditingController();
  final _descripcionFecha = TextEditingController();
  DateTime? _fechaEvento;

  @override
  void dispose() {
    _tituloAnuncio.dispose();
    _contenidoAnuncio.dispose();
    _tituloFecha.dispose();
    _descripcionFecha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestión de Anuncios', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formAnuncio,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloAnuncio,
                      decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contenidoAnuncio,
                      decoration: const InputDecoration(labelText: 'Contenido', border: OutlineInputBorder()),
                      minLines: 3,
                      maxLines: 6,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        onPressed: () {
                          if (!_formAnuncio.currentState!.validate()) return;
                          // TODO: Guardar en tabla anuncios
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Anuncio guardado (mock)'), backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Gestión de Fechas Importantes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formFecha,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tituloFecha,
                      decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionFecha,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Fecha del evento', border: OutlineInputBorder()),
                            child: Text(_fechaEvento == null ? 'Seleccionar' : _fechaEvento!.toIso8601String().substring(0, 10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaEvento ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) setState(() => _fechaEvento = picked);
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Elegir fecha'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        onPressed: () {
                          if (!_formFecha.currentState!.validate() || _fechaEvento == null) return;
                          // TODO: Guardar en tabla fechas_importantes
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fecha importante guardada (mock)'), backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


