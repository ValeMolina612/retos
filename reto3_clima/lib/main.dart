import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String owmApiKey = String.fromEnvironment('OPENWEATHERMAP_API_KEY');

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima Minimalista',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const ClimaPage(),
    );
  }
}

// ---------------------------------------------------------------- Modelo
class Clima {
  final String ciudad;
  final double temp;
  final double sensacion;
  final int humedad;
  final double viento;
  final String descripcion;
  final String icono;

  Clima({
    required this.ciudad,
    required this.temp,
    required this.sensacion,
    required this.humedad,
    required this.viento,
    required this.descripcion,
    required this.icono,
  });

  factory Clima.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> main = json['main'] as Map<String, dynamic>;
    final Map<String, dynamic> wind = json['wind'] as Map<String, dynamic>;
    final Map<String, dynamic> weather =
        (json['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final String desc = weather['description'] as String;

    return Clima(
      ciudad: json['name'] as String,
      temp: (main['temp'] as num).toDouble(),
      sensacion: (main['feels_like'] as num).toDouble(),
      humedad: (main['humidity'] as num).toInt(),
      viento: (wind['speed'] as num).toDouble(),
      descripcion: desc.isEmpty ? desc : desc[0].toUpperCase() + desc.substring(1),
      icono: weather['icon'] as String,
    );
  }
}

// -------------------------------------------------------------- Servicio
class ClimaService {
  Future<Clima> porCiudad(String ciudad) async {
    if (owmApiKey.isEmpty) {
      throw Exception(
        'Configura OPENWEATHERMAP_API_KEY al iniciar la app para consultar el clima.',
      );
    }

    final Uri uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': ciudad,
      'appid': owmApiKey,
      'units': 'metric',
      'lang': 'es',
    });

    final http.Response r = await http.get(uri);
    if (r.statusCode == 404) throw Exception('No encontre esa ciudad.');
    if (r.statusCode == 401) {
      throw Exception('API key invalida o aun no activada.');
    }
    if (r.statusCode != 200) throw Exception('Error ${r.statusCode}.');
    return Clima.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
}

// ---------------------------------------------------------------- Pantalla
class ClimaPage extends StatefulWidget {
  const ClimaPage({super.key});

  @override
  State<ClimaPage> createState() => _ClimaPageState();
}

class _ClimaPageState extends State<ClimaPage> {
  final ClimaService _servicio = ClimaService();
  final TextEditingController _controller = TextEditingController(text: 'Celaya');

  Clima? _clima;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    final String ciudad = _controller.text.trim();
    if (ciudad.isEmpty) return;

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final Clima c = await _servicio.porCiudad(ciudad);
      if (!mounted) return;
      setState(() => _clima = c);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clima = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    if (_cargando) {
      contenido = const CircularProgressIndicator();
    } else if (_error != null) {
      contenido = Text(_error!, textAlign: TextAlign.center);
    } else if (_clima != null) {
      final Clima c = _clima!;
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(c.ciudad, style: Theme.of(context).textTheme.headlineMedium),
          Image.network(
            'https://openweathermap.org/img/wn/${c.icono}@4x.png',
            width: 140,
            height: 140,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.cloud, size: 100),
          ),
          Text(
            '${c.temp.toStringAsFixed(1)}°C',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.w300),
          ),
          Text(c.descripcion, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dato(Icons.thermostat, 'Sensacion', '${c.sensacion.toStringAsFixed(1)}°C'),
              _dato(Icons.water_drop, 'Humedad', '${c.humedad}%'),
              _dato(Icons.air, 'Viento', '${c.viento.toStringAsFixed(1)} m/s'),
            ],
          ),
        ],
      );
    } else {
      contenido = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🌦️ Clima')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Ciudad',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscar,
                ),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            Expanded(child: Center(child: SingleChildScrollView(child: contenido))),
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String titulo, String valor) {
    return Column(
      children: [
        Icon(icono),
        const SizedBox(height: 4),
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        Text(valor, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
