import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// id de CoinGecko -> nombre para mostrar
const Map<String, String> monedas = {
  'bitcoin': 'Bitcoin (BTC)',
  'ethereum': 'Ethereum (ETH)',
  'solana': 'Solana (SOL)',
};

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convertidor Cripto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const CriptoPage(),
    );
  }
}

// -------------------------------------------------------------- Servicio
Future<Map<String, double>> obtenerPrecios() async {
  final Uri uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
    'ids': monedas.keys.join(','),
    'vs_currencies': 'usd',
  });

  final http.Response r = await http.get(uri);
  if (r.statusCode != 200) {
    throw Exception('Error ${r.statusCode}. Intenta de nuevo en un momento.');
  }
  final Map<String, dynamic> data = jsonDecode(r.body) as Map<String, dynamic>;
  return {
    for (final String id in monedas.keys)
      id: ((data[id] as Map<String, dynamic>)['usd'] as num).toDouble(),
  };
}

// Formatea 12345.6 -> 12,345.60
String formatoUsd(double v) {
  final List<String> partes = v.toStringAsFixed(2).split('.');
  final String entero = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '\$$entero.${partes[1]}';
}

// ---------------------------------------------------------------- Pantalla
class CriptoPage extends StatefulWidget {
  const CriptoPage({super.key});

  @override
  State<CriptoPage> createState() => _CriptoPageState();
}

class _CriptoPageState extends State<CriptoPage> {
  final TextEditingController _controller = TextEditingController(text: '100');
  late Future<Map<String, double>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = obtenerPrecios();
  }

  void _refrescar() {
    setState(() => _futuro = obtenerPrecios());
  }

  double get _monto => double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪙 Convertidor Cripto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar precios',
            onPressed: _refrescar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto en USD',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _refrescar, child: const Text('Reintentar')),
                        ],
                      ),
                    );
                  }

                  final Map<String, double> precios = snapshot.data!;
                  return ListView(
                    children: monedas.entries.map((e) {
                      final double precio = precios[e.key]!;
                      final double fraccion = precio == 0 ? 0 : _monto / precio;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.currency_bitcoin),
                          title: Text(e.value),
                          subtitle: Text('Precio: ${formatoUsd(precio)} USD'),
                          trailing: Text(
                            fraccion.toStringAsFixed(8),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
