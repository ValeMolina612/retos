import 'package:flutter/material.dart';

import 'package:reto1_peliculas/main.dart' as peliculas;
import 'package:reto2_gatos/main.dart' as gatos;
import 'package:reto3_clima/main.dart' as clima;

void main() {
  runApp(const RetosApp());
}

class RetosApp extends StatelessWidget {
  const RetosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retos Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RetosHomePage(),
    );
  }
}

class RetosHomePage extends StatelessWidget {
  const RetosHomePage({super.key});

  static const List<_Reto> _retos = [
    _Reto(
      titulo: 'Recomendador de películas',
      descripcion: 'Descubre tendencias o elige una película según tu ánimo.',
      icono: Icons.movie_creation_outlined,
      color: Color(0xFF6750A4),
    ),
    _Reto(
      titulo: 'Generador de memes de gatos',
      descripcion: 'Crea imágenes de gatos con tu frase y filtros favoritos.',
      icono: Icons.pets_outlined,
      color: Color(0xFFE8753D),
    ),
    _Reto(
      titulo: 'Clima minimalista',
      descripcion: 'Consulta el clima actual buscando cualquier ciudad.',
      icono: Icons.wb_cloudy_outlined,
      color: Color(0xFF2878B5),
    ),
  ];

  void _abrirReto(BuildContext context, int index) {
    final Widget pantalla = switch (index) {
      0 => const peliculas.PeliculasPage(),
      1 => const gatos.GatosPage(),
      2 => const clima.ClimaPage(),
      _ => throw RangeError.index(index, _retos),
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retos Flutter'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '¿Qué quieres explorar?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tres experiencias rápidas conectadas a servicios web.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < _retos.length; i++)
            _RetoCard(
              reto: _retos[i],
              onTap: () => _abrirReto(context, i),
            ),
        ],
      ),
    );
  }
}

class _Reto {
  const _Reto({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
}

class _RetoCard extends StatelessWidget {
  const _RetoCard({required this.reto, required this.onTap});

  final _Reto reto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: reto.color.withValues(alpha: 0.12),
          foregroundColor: reto.color,
          child: Icon(reto.icono),
        ),
        title: Text(
          reto.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(reto.descripcion),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
