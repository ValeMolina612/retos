import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

// Estado de animo -> id de genero en TMDB (null = tendencias de la semana)
const Map<String, int?> animos = {
  '🔥 Tendencias': null,
  '😄 Feliz': 35, // Comedia
  '😢 Triste': 18, // Drama
  '🤠 Aventurero': 12, // Aventura
  '❤️ Romantico': 10749, // Romance
  '😱 Con ganas de miedo': 27, // Terror
};

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recomendador de Peliculas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const PeliculasPage(),
    );
  }
}

// ---------------------------------------------------------------- Modelo
class Pelicula {
  final String titulo;
  final String resumen;
  final String? poster;
  final double calificacion;
  final String fecha;

  Pelicula({
    required this.titulo,
    required this.resumen,
    required this.poster,
    required this.calificacion,
    required this.fecha,
  });

  factory Pelicula.fromJson(Map<String, dynamic> json) {
    final String? path = json['poster_path'] as String?;
    final String overview = (json['overview'] ?? '') as String;
    return Pelicula(
      titulo: (json['title'] ?? 'Sin titulo') as String,
      resumen: overview.isEmpty ? 'Sin descripcion disponible.' : overview,
      poster: path == null ? null : 'https://image.tmdb.org/t/p/w500$path',
      calificacion: ((json['vote_average'] ?? 0) as num).toDouble(),
      fecha: (json['release_date'] ?? '') as String,
    );
  }
}

// -------------------------------------------------------------- Servicio
class TmdbService {
  Future<List<Pelicula>> obtener(int? generoId) async {
    if (tmdbApiKey.isEmpty) {
      throw Exception(
        'Configura TMDB_API_KEY al iniciar la app para consultar películas.',
      );
    }

    final bool esTendencia = generoId == null;
    final Uri uri = Uri.https(
      'api.themoviedb.org',
      esTendencia ? '/3/trending/movie/week' : '/3/discover/movie',
      {
        'api_key': tmdbApiKey,
        'language': 'es-MX',
        if (!esTendencia) 'sort_by': 'popularity.desc',
        if (!esTendencia) 'with_genres': '$generoId',
      },
    );

    final http.Response r = await http.get(uri);
    if (r.statusCode != 200) {
      throw Exception('Error ${r.statusCode}. Revisa tu API key de TMDB.');
    }
    final Map<String, dynamic> data = jsonDecode(r.body) as Map<String, dynamic>;
    final List<dynamic> results = data['results'] as List<dynamic>;
    return results
        .map((e) => Pelicula.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ---------------------------------------------------------------- Pantalla
class PeliculasPage extends StatefulWidget {
  const PeliculasPage({super.key});

  @override
  State<PeliculasPage> createState() => _PeliculasPageState();
}

class _PeliculasPageState extends State<PeliculasPage> {
  final TmdbService _servicio = TmdbService();
  String _animo = '🔥 Tendencias';
  List<Pelicula> _peliculas = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _servicio.obtener(animos[_animo]);
      if (!mounted) return;
      setState(() => _peliculas = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar las peliculas.\n$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _alAzar() {
    if (_peliculas.isEmpty) return;
    final Pelicula p = _peliculas[Random().nextInt(_peliculas.length)];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SingleChildScrollView(child: PeliculaCard(pelicula: p)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      cuerpo = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    } else {
      cuerpo = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _peliculas.length,
        itemBuilder: (_, i) => PeliculaCard(pelicula: _peliculas[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Pelicula del fin de semana')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _alAzar,
        icon: const Icon(Icons.casino),
        label: const Text('Sorprendeme'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 8,
              children: animos.keys
                  .map(
                    (a) => ChoiceChip(
                      label: Text(a),
                      selected: _animo == a,
                      onSelected: (_) {
                        setState(() => _animo = a);
                        _cargar();
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Tarjeta (Card)
class PeliculaCard extends StatelessWidget {
  final Pelicula pelicula;
  const PeliculaCard({super.key, required this.pelicula});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            height: 165,
            child: pelicula.poster == null
                ? const Icon(Icons.movie, size: 48)
                : Image.network(
                    pelicula.poster!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pelicula.titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⭐ ${pelicula.calificacion.toStringAsFixed(1)}   ${pelicula.fecha}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pelicula.resumen,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
