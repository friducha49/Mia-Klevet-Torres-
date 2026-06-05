import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../services/api_service.dart';
import '../utils/pokemon_theme.dart';

class BattleScreen extends StatefulWidget {
  final Pokemon pokemon;
  const BattleScreen({super.key, required this.pokemon});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

enum PotionType { small, medium, large }

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  late Pokemon _enemy;
  late int _playerHp;
  final int _playerMaxHp = 100;
  bool _battleOver = false;
  bool _attacking = false;
  bool _hasPartyPokemon = false;

  int _playerLevel = 1;
  int _potionUses = 0;
  static const int _maxPotionUses = 3;

  bool _canPet = true;
  int _petUses = 0;
  DateTime? _petDisabledUntil;

  List<String> _log = [];
  final _rng = Random();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _ballController;
  late Animation<double> _ballAnim;

  @override
  void initState() {
    super.initState();
    _enemy = widget.pokemon;
    _playerHp = _playerMaxHp;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween(begin: 0.0, end: 1.0).animate(_shakeController);

    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ballAnim = CurvedAnimation(
      parent: _ballController,
      curve: Curves.bounceOut,
    );

    _log.add('¡${_enemy.name} apareció!');
    _log.add('HP: ${_enemy.hp} | ATK: ${_enemy.attack}');
    _loadPlayerParty();
  }

  Future<void> _loadPlayerParty() async {
    final collection = await ApiService.getCollection();
    if (!mounted) return;
    setState(() {
      _hasPartyPokemon = collection.isNotEmpty;
      if (_hasPartyPokemon) {
        _log.add('Tenés Pokémon para luchar. Podés atacar o capturar.');
      } else {
        _log.add('No tenés Pokémon de apoyo. Podés intentar capturar ahora.');
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _ballController.dispose();
    super.dispose();
  }

  Future<void> _attack() async {
    if (_battleOver || _attacking || !_hasPartyPokemon) return;
    setState(() => _attacking = true);

    final playerDmg = max(
      5,
      18 + _playerLevel * 4 + _rng.nextInt(15) - _enemy.defense ~/ 4,
    );
    final newEnemyHp = max(0, _enemy.hp - playerDmg);
    _log.add('Tu Pokémon nivel $_playerLevel ataca y causa $playerDmg daño.');

    _shakeController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _enemy = _enemy.copyWith(hp: newEnemyHp));

    if (newEnemyHp <= 0) {
      setState(() {
        _battleOver = true;
        _log.add('¡${_enemy.name} está debilitado!');
        _log.add('¡El combate terminó. No podés capturarlo ahora!');
        _attacking = false;
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    await _enemyAttack();
    if (mounted) setState(() => _attacking = false);
  }

  Future<void> _enemyAttack() async {
    if (_battleOver) return;

    final enemyDmg = max(3, _enemy.attack ~/ 3 + _rng.nextInt(12));
    final newPlayerHp = max(0, _playerHp - enemyDmg);
    _log.add('${_enemy.name} te atacó y causó $enemyDmg daño.');

    setState(() => _playerHp = newPlayerHp);

    if (newPlayerHp <= 0) {
      setState(() {
        _battleOver = true;
        _log.add('¡Tu Pokémon quedó debilitado! El combate terminó.');
      });
    }
  }

  Future<void> _capture() async {
    if (_battleOver || _attacking || _enemy.hp <= 0) return;
    setState(() => _attacking = true);

    _ballController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 500));

    final enemyFactor = 1 - (_enemy.hp / _enemy.maxHp);
    final baseChance = _hasPartyPokemon ? 0.20 : 0.35;
    final captureChance = (baseChance + enemyFactor * 0.70).clamp(0.05, 0.95);
    final captured = _rng.nextDouble() < captureChance;

    _log.add(
      'Intentaste capturar a ${_enemy.name}. Probabilidad ${(captureChance * 100).round()}%.',
    );

    if (captured) {
      final saved = await ApiService.saveCaptured(
        _enemy.copyWith(captured: true),
      );
      if (!mounted) return;
      setState(() {
        _battleOver = true;
      });
      _showCaptureResult(true, saved);
    } else {
      if (!mounted) return;
      setState(() {
        _log.add('Falló la captura.');
      });
      await Future.delayed(const Duration(milliseconds: 500));
      await _enemyAttack();
      if (mounted) setState(() => _attacking = false);
    }
  }

  Future<void> _usePotion(PotionType type) async {
    if (_battleOver || _attacking) return;
    if (_potionUses >= _maxPotionUses) {
      setState(() => _log.add('Ya usaste las 3 pociones en esta batalla.'));
      return;
    }
    if (_playerHp >= _playerMaxHp) {
      setState(() => _log.add('Tu Pokémon ya tiene vida completa.'));
      return;
    }

    setState(() => _attacking = true);
    final heal = type == PotionType.small
        ? 20
        : type == PotionType.medium
            ? 35
            : 50;
    final actualHeal = min(_playerMaxHp - _playerHp, heal);
    setState(() {
      _playerHp = min(_playerMaxHp, _playerHp + heal);
      _potionUses += 1;
      _log.add(
        'Usaste poción ${_potionLabel(type)} y recuperaste $actualHeal HP. ($_potionUses/$_maxPotionUses)',
      );
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!_battleOver) await _enemyAttack();
    if (mounted) setState(() => _attacking = false);
  }

  Future<void> _useCandy() async {
    if (_battleOver || _attacking) return;
    if (_playerHp > 30) {
      setState(
        () => _log.add(
          'El caramelo solo funciona cuando tu Pokémon está debilitado.',
        ),
      );
      return;
    }

    setState(() => _attacking = true);
    final heal = 30;
    final actualHeal = min(_playerMaxHp - _playerHp, heal);
    setState(() {
      _playerHp = min(_playerMaxHp, _playerHp + heal);
      _playerLevel += 1;
      _log.add(
        'Le diste un caramelo, recuperó $actualHeal HP y subió al nivel $_playerLevel.',
      );
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!_battleOver) await _enemyAttack();
    if (mounted) setState(() => _attacking = false);
  }

  Future<void> _petPokemon() async {
    if (_battleOver || _attacking) return;
    if (!_canPet) {
      final remaining =
          _petDisabledUntil?.difference(DateTime.now()).inSeconds ?? 0;
      setState(
        () => _log.add('No podés acariciarlo aún. Esperá ${remaining}s.'),
      );
      return;
    }

    setState(() => _attacking = true);
    final heal = 10;
    final actualHeal = min(_playerMaxHp - _playerHp, heal);
    setState(() {
      _playerHp = min(_playerMaxHp, _playerHp + heal);
      _playerLevel += 1;
      _petUses += 1;
      _log.add(
        'Acariciaste a tu Pokémon, recuperó $actualHeal HP y subió al nivel $_playerLevel.',
      );
    });

    if (_petUses >= 3) {
      _canPet = false;
      _petDisabledUntil = DateTime.now().add(const Duration(seconds: 20));
      _log.add('Se cansó de los mimos. Podrás volver a acariciarlo en 20s.');
      Future.delayed(const Duration(seconds: 20), () {
        if (!mounted) return;
        setState(() {
          _canPet = true;
          _petUses = 0;
          _petDisabledUntil = null;
          _log.add('Tu Pokémon está listo para recibir mimos otra vez.');
        });
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!_battleOver) await _enemyAttack();
    if (mounted) setState(() => _attacking = false);
  }

  String _potionLabel(PotionType type) {
    switch (type) {
      case PotionType.small:
        return 'Pequeña';
      case PotionType.medium:
        return 'Mediana';
      case PotionType.large:
        return 'Grande';
    }
  }

  void _showPotionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121529),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: PotionType.values.map((type) {
              final label = _potionLabel(type);
              final heal = type == PotionType.small
                  ? 20
                  : type == PotionType.medium
                      ? 35
                      : 50;
              return ListTile(
                leading: const Icon(Icons.healing, color: Colors.white70),
                title: Text(
                  'Poción $label',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Recupera $heal HP',
                  style: const TextStyle(color: Colors.white60),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _usePotion(type);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  bool get _canPetNow => _canPet && !_battleOver && !_attacking;

  void _showCaptureResult(bool success, bool saved) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '¡${_enemy.name} capturado!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              saved ? 'Guardado en tu colección ✓' : 'Error al guardar',
              style: TextStyle(
                color: saved ? Colors.greenAccent : Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Volver',
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = PokemonTheme.typeColor(_enemy.type);
    final enemyHpPercent = _enemy.hp / _enemy.maxHp;
    final playerHpPercent = _playerHp / _playerMaxHp;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E7),
      body: Stack(
        children: [
          Positioned(
            top: 12,
            left: 10,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 130,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8C4),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: -20,
            child: Transform.rotate(
              angle: 0.34,
              child: Container(
                width: 180,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8EEF8),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: -10,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 130,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E7F1),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF8C8C8C).withOpacity(0.12),
                                blurRadius: 14,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batalla',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tu estilo, tus reglas. Lucha con todo.',
                              style: TextStyle(
                                color: Color(0xFF6B7484),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8C8C8C).withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enemigo',
                          style: TextStyle(
                            color: Color(0xFF495057),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _BattleCard(
                          name: _enemy.name,
                          type: _enemy.type,
                          typeColor: typeColor,
                          hp: _enemy.hp,
                          maxHp: _enemy.maxHp,
                          hpPercent: enemyHpPercent,
                          spriteUrl: PokemonTheme.spriteUrl(_enemy.name),
                          shakeAnim: _shakeAnim,
                          isEnemy: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8C8C8C).withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE9C8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Tú',
                            style: TextStyle(
                              color: Color(0xFF9C6503),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _PlayerCard(
                            hp: _playerHp,
                            maxHp: _playerMaxHp,
                            hpPercent: playerHpPercent,
                            level: _playerLevel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatusDot(
                        label: 'Nivel $_playerLevel',
                        color: const Color(0xFF7BB26A),
                      ),
                      _StatusDot(
                        label: 'Pociones $_potionUses/$_maxPotionUses',
                        color: const Color(0xFF4F8FB2),
                      ),
                      _StatusDot(
                        label: _hasPartyPokemon ? 'Equipo listo' : 'Sin apoyo',
                        color: _hasPartyPokemon
                            ? const Color(0xFF8DB151)
                            : const Color(0xFFF4A260),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8C8C8C).withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registro de combate',
                            style: TextStyle(
                              color: Color(0xFF3D4854),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              itemCount: _log.length,
                              itemBuilder: (_, i) {
                                final message = _log[_log.length - 1 - i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == 0
                                              ? const Color(0xFF4F8FB2)
                                              : const Color(0xFFC4CDD6),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          message,
                                          style: TextStyle(
                                            color: i == 0
                                                ? const Color(0xFF2B3440)
                                                : const Color(0xFF6B7484),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'ATACAR',
                              icon: Icons.flash_on,
                              color: const Color(0xFFEF8354),
                              enabled: !_battleOver &&
                                  !_attacking &&
                                  _hasPartyPokemon,
                              onTap: _attack,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ScaleTransition(
                              scale:
                                  _ballAnim.drive(Tween(begin: 1.0, end: 1.15)),
                              child: _ActionButton(
                                label: 'CAPTURAR',
                                icon: Icons.catching_pokemon,
                                color: const Color(0xFF57B6F3),
                                enabled: !_battleOver &&
                                    !_attacking &&
                                    _enemy.hp > 0,
                                onTap: _capture,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'POCIÓN',
                              icon: Icons.healing,
                              color: const Color(0xFF5EC3B0),
                              enabled: !_battleOver &&
                                  !_attacking &&
                                  _potionUses < _maxPotionUses &&
                                  _playerHp < _playerMaxHp,
                              onTap: _showPotionSelector,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'CARAMELO',
                              icon: Icons.cake,
                              color: const Color(0xFFF9C34C),
                              enabled: !_battleOver &&
                                  !_attacking &&
                                  _playerHp <= 30,
                              onTap: _useCandy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'MIMOS',
                              icon: Icons.pets,
                              color: const Color(0xFF8BC34A),
                              enabled: _canPetNow && _playerHp < _playerMaxHp,
                              onTap: _petPokemon,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusDot({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  final String name;
  final String type;
  final Color typeColor;
  final int hp;
  final int maxHp;
  final double hpPercent;
  final String spriteUrl;
  final Animation<double> shakeAnim;
  final bool isEnemy;

  const _BattleCard({
    required this.name,
    required this.type,
    required this.typeColor,
    required this.hp,
    required this.maxHp,
    required this.hpPercent,
    required this.spriteUrl,
    required this.shakeAnim,
    required this.isEnemy,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, child) {
        final shake = sin(shakeAnim.value * pi * 6) * 8;
        return Transform.translate(
          offset: isEnemy ? Offset(shake, 0) : Offset.zero,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: typeColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Sprite
            CachedNetworkImage(
              imageUrl: spriteUrl,
              width: 72,
              height: 72,
              errorWidget: (_, __, ___) => Icon(
                Icons.catching_pokemon,
                size: 72,
                color: typeColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: typeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          '${PokemonTheme.typeEmoji(type)} $type',
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'HP ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$hp/$maxHp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hpPercent.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                        hpPercent > 0.5
                            ? Colors.greenAccent
                            : hpPercent > 0.25
                                ? Colors.orangeAccent
                                : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final int hp;
  final int maxHp;
  final double hpPercent;
  final int level;

  const _PlayerCard({
    required this.hp,
    required this.maxHp,
    required this.hpPercent,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TÚ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel $level',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'HP ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$hp/$maxHp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hpPercent.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      hpPercent > 0.5
                          ? Colors.greenAccent
                          : hpPercent > 0.25
                              ? Colors.orangeAccent
                              : Colors.redAccent,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? color.withOpacity(0.6) : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.white24, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.white24,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
