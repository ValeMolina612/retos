import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Generador de Memes de Gatos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const GatosPage(),
    );
  }
}

class GatosPage extends StatefulWidget {
  const GatosPage({super.key});

  @override
  State<GatosPage> createState() => _GatosPageState();
}

class _GatosPageState extends State<GatosPage> {
  final TextEditingController _controller = TextEditingController();

  // Filtros que acepta Cataas (parametro ?filter=...)
  static const List<String> _filtros = ['ninguno', 'mono', 'sepia', 'negate', 'blur'];

  String _filtro = 'ninguno';
  String _texto = '';
  int _semilla = DateTime.now().millisecondsSinceEpoch;

  // La URL cambia segun el texto, el filtro y la semilla (para pedir otro gato)
  String _construirUrl() {
    final String base = _texto.isEmpty
        ? 'https://cataas.com/cat'
        : 'https://cataas.com/cat/says/${Uri.encodeComponent(_texto)}';

    final Map<String, String> params = {
      'fontSize': '40',
      'fontColor': 'white',
      't': '$_semilla',
      if (_filtro != 'ninguno') 'filter': _filtro,
    };
    return Uri.parse(base).replace(queryParameters: params).toString();
  }

  void _aplicarTexto() {
    setState(() => _texto = _controller.text.trim());
  }

  void _nuevoGato() {
    setState(() => _semilla = DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String url = _construirUrl();

    return Scaffold(
      appBar: AppBar(title: const Text('🐱 Memes de Gatos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 360,
              child: Image.network(
                url,
                key: ValueKey(url),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('No se pudo cargar el gato 😿\nIntenta con otro.',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Escribe tu frase',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            onSubmitted: (_) => _aplicarTexto(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Filtro: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filtro,
                items: _filtros
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _filtro = v ?? 'ninguno'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _aplicarTexto,
                  icon: const Icon(Icons.check),
                  label: const Text('Poner texto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _nuevoGato,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Otro gato'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
