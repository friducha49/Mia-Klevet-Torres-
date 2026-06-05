import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../services/api_service.dart';
import '../utils/pokemon_theme.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Pokemon> _collection = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    setState(() => _loading = true);
    final list = await ApiService.getCollection();
    setState(() {
      _collection = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4EC),
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: -40,
            child: Transform.rotate(
              angle: -0.45,
              child: Container(
                width: 280,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D2),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            top: 160,
            right: -50,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 200,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7EFFA),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -30,
            child: Transform.rotate(
              angle: 0.15,
              child: Container(
                width: 180,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7E8),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF7A7A7A).withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFF4D5663),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Mi colección',
                              style: TextStyle(
                                color: Color(0xFF2A313D),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tus Pokémon guardados y listos para explorar',
                              style: TextStyle(
                                color: Color(0xFF6B7484),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5B8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_collection.length}',
                          style: const TextStyle(
                            color: Color(0xFF9B4A00),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: Text(
                    '${_collection.length} capturados',
                    style: const TextStyle(
                      color: Color(0xFF8A92A0),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4FC3F7),
                          ),
                        )
                      : _collection.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.catching_pokemon,
                                      size: 56, color: Color(0xFFB0BEC5)),
                                  SizedBox(height: 14),
                                  Text(
                                    'No capturaste ningún Pokémon todavía',
                                    style: TextStyle(
                                      color: Color(0xFF8A92A0),
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GridView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: _collection.length,
                                itemBuilder: (_, i) => _PokemonCard(
                                  pokemon: _collection[i],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  const _PokemonCard({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final typeColor = PokemonTheme.typeColor(pokemon.type);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.2),
            const Color(0xFF0D0D1A),
          ],
        ),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sprite
            CachedNetworkImage(
              imageUrl: PokemonTheme.spriteUrl(pokemon.name),
              height: 80,
              errorWidget: (_, __, ___) => Icon(
                Icons.catching_pokemon,
                size: 60,
                color: typeColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),

            // Nombre
            Text(
              pokemon.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),

            // Tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withOpacity(0.4)),
              ),
              child: Text(
                '${PokemonTheme.typeEmoji(pokemon.type)} ${pokemon.type}',
                style: TextStyle(
                  color: typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                    label: 'HP',
                    value: '${pokemon.maxHp}',
                    color: Colors.greenAccent),
                _StatChip(
                    label: 'ATK',
                    value: '${pokemon.attack}',
                    color: const Color(0xFFFF6B35)),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              _formatDate(pokemon.capturedAt),
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
