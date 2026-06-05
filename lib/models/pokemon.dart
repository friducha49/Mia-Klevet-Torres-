class Pokemon {
  final String name;
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final String similarity;
  final DateTime capturedAt;
  bool captured;

  Pokemon({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.similarity,
    required this.capturedAt,
    this.captured = false,
  });

  Pokemon copyWith({int? hp, bool? captured}) {
    return Pokemon(
      name: name,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      attack: attack,
      defense: defense,
      similarity: similarity,
      capturedAt: capturedAt,
      captured: captured ?? this.captured,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hp': hp,
        'maxHp': maxHp,
        'attack': attack,
        'defense': defense,
        'similarity': similarity,
        'capturedAt': capturedAt.toIso8601String(),
        'captured': captured,
      };

  factory Pokemon.fromJson(Map<String, dynamic> json) => Pokemon(
        name: json['name'],
        hp: json['hp'],
        maxHp: json['maxHp'],
        attack: json['attack'],
        defense: json['defense'] ?? 40,
        similarity: json['similarity'] ?? '',
        capturedAt: DateTime.parse(json['capturedAt']),
        captured: json['captured'] ?? false,
      );

  // Color por tipo basado en nombre
  String get type {
    const tipos = {
      'Pikachu': 'Eléctrico',
      'Charmander': 'Fuego',
      'Bulbasur': 'Planta',
      'Squirtle': 'Agua',
      'Gengar': 'Fantasma',
      'Snorlax': 'Normal',
      'Meowth': 'Normal',
      'Machop': 'Lucha',
      'Flareon': 'Fuego',
      'Vaporeon': 'Agua',
      'Magnemite': 'Eléctrico',
      'Ponyta': 'Fuego',
    };
    return tipos[name] ?? 'Normal';
  }
}
