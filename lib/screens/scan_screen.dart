import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'battle_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  String _status = 'Escaneá un dibujo';
  bool _connected = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkConnection();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final ok = await ApiService.checkConnection();
    if (!mounted) return;
    setState(() => _connected = ok);
  }

  Future<void> _scan(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo == null) return;

      if (!mounted) return;
      setState(() {
        _loading = true;
        _status = 'Analizando dibujo...';
      });

      final pokemon = await ApiService.scanImage(File(photo.path));

      if (!mounted) return;

      if (pokemon == null) {
        setState(() {
          _loading = false;
          _status = 'No se reconoció ningún Pokémon';
        });
        return;
      }

      setState(() => _loading = false);

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => BattleScreen(pokemon: pokemon),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Error al escanear';
      });
    }
  }

  // iOS usa CupertinoActionSheet en lugar de BottomSheet de Material
  void _showPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text(
          'Escanear Pokémon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        message: const Text('Elegí cómo querés obtener la imagen'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _scan(ImageSource.camera);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 10),
                Text('Usar cámara'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _scan(ImageSource.gallery);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 20),
                SizedBox(width: 10),
                Text('Elegir de galería'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: -30,
            child: Transform.rotate(
              angle: -0.33,
              child: Container(
                width: 180,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3DD),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            top: 110,
            right: -40,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF3F9),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 140,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D8),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Poké Scan',
                              style: TextStyle(
                                color: Color(0xFF2E3338),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Convierte tus dibujos en encuentros reales',
                              style: TextStyle(
                                color: Color(0xFF5D636B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0D6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              'Nuevo',
                              style: TextStyle(
                                color: Color(0xFFB8630A),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ConnectionDot(connected: _connected),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFB0BEC5).withValues(alpha: 0.09),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC947),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Listo para escanear',
                                style: TextStyle(
                                  color: Color(0xFF2E3338),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_loading)
                          Column(
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFFFF9A3D),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _status,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF5D636B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: GestureDetector(
                              onTap: _showPicker,
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F1E8),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _connected
                                        ? const Color(0xFF6DC7F9)
                                        : const Color(0xFFD8D8D8),
                                    width: 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 18,
                                      right: 20,
                                      child: Transform.rotate(
                                        angle: 0.35,
                                        child: Container(
                                          width: 60,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F7FF),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      left: 20,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4FC3F7)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          _connected
                                              ? 'Conectado'
                                              : 'Desconectado',
                                          style: TextStyle(
                                            color: _connected
                                                ? const Color(0xFF1E5E8A)
                                                : const Color(0xFFA3A3A3),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 60,
                                            color: _connected
                                                ? const Color(0xFF4FC3F7)
                                                : const Color(0xFFB0B7BD),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Toca para escanear',
                                            style: TextStyle(
                                              color: _connected
                                                  ? const Color(0xFF2E3338)
                                                  : const Color(0xFF7A7A7A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 22),
                        Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('Error') ||
                                    _status.contains('No se reconoció')
                                ? const Color(0xFFD23232)
                                : const Color(0xFF5D636B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBadge(
                          icon: Icons.auto_awesome,
                          label: 'Encuentros rápidos',
                          description:
                              'Tu dibujo se transforma en combate al instante',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/collection'),
                      color: const Color(0xFF82C7F8),
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.circle_grid_3x3_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mi colección',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
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

class _ConnectionDot extends StatelessWidget {
  final bool connected;
  const _ConnectionDot({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'Conectado' : 'Desconectado',
          style: TextStyle(
            color: connected ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
