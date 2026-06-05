import 'package:flutter/material.dart';

class PokemonTheme {
  static const Map<String, Color> typeColors = {
    'Fuego': Color(0xFFFF6B35),
    'Agua': Color(0xFF4FC3F7),
    'Planta': Color(0xFF81C784),
    'Eléctrico': Color(0xFFFFD740),
    'Fantasma': Color(0xFF9575CD),
    'Lucha': Color(0xFFEF5350),
    'Normal': Color(0xFFBDBDBD),
    'Psíquico': Color(0xFFF48FB1),
    'Hielo': Color(0xFF80DEEA),
    'Dragón': Color(0xFF5C6BC0),
  };

  static Color typeColor(String type) =>
      typeColors[type] ?? const Color(0xFFBDBDBD);

  // Color del gradiente del card según tipo
  static List<Color> typeGradient(String type) {
    final base = typeColor(type);
    return [
      base.withOpacity(0.85),
      base.withOpacity(0.4),
      Colors.black.withOpacity(0.7),
    ];
  }

  // Emoji del tipo
  static String typeEmoji(String type) {
    const emojis = {
      'Fuego': '🔥',
      'Agua': '💧',
      'Planta': '🌿',
      'Eléctrico': '⚡',
      'Fantasma': '👻',
      'Lucha': '🥊',
      'Normal': '⭐',
      'Psíquico': '🔮',
      'Hielo': '❄️',
      'Dragón': '🐉',
    };
    return emojis[type] ?? '⭐';
  }

  // Sprite URL desde PokeAPI (solo imagen, no stats)
  static String spriteUrl(String name) {
    const sprites = {
      'Pikachu': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
      'Charmander': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/4.png',
      'Bulbasur': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png',
      'Squirtle': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/7.png',
      'Gengar': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/94.png',
      'Snorlax': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/143.png',
      'Meowth': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/52.png',
      'Machop': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/66.png',
      'Flareon': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/136.png',
      'Vaporeon': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/134.png',
      'Magnemite': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/81.png',
      'Ponyta': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/77.png',
    };
    return sprites[name] ??
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/0.png';
  }
}
