// Enhanced realistic 3D Dice Roller
// Paste into lib/main.dart of a new Flutter project.
// Assets: add `assets/dice_roll.mp3` (short roll sound)
// Dependency: `audioplayers` (use `flutter pub add audioplayers`)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const DiceApp());

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realistic 3D Dice',
      theme: ThemeData.dark().copyWith(useMaterial3: true),
      home: const DiceHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiceHomePage extends StatefulWidget {
  const DiceHomePage({super.key});
  @override
  State<DiceHomePage> createState() => _DiceHomePageState();
}

class _DiceHomePageState extends State<DiceHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  final Random _rng = Random();
  int _currentValue = 1;

  // rotation state
  double _rotX = 0, _rotY = 0, _rotZ = 0;

  // target rotations
  double _startX = 0, _startY = 0, _startZ = 0;
  double _targetX = 0, _targetY = 0, _targetZ = 0;

  final AudioPlayer _player = AudioPlayer();

  final Map<int, List<double>> faceOrientations = {
    1: [0.0, 0.0, 0.0],
    2: [0.0, pi / 2, 0.0],
    3: [pi / 2, 0.0, 0.0],
    4: [-pi / 2, 0.0, 0.0],
    5: [0.0, -pi / 2, 0.0],
    6: [0.0, pi, 0.0],
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
      ..addListener(() {
        final t = _anim.value;
        setState(() {
          _rotX = _lerpAngle(_startX, _targetX, t);
          _rotY = _lerpAngle(_startY, _targetY, t);
          _rotZ = _lerpAngle(_startZ, _targetZ, t);
        });
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          // subtle settle bounce after main animation
          _settleBounce();
        }
      });

    // random initial tiny rotation
    _rotX = (_rng.nextDouble() - 0.5) * 0.4;
    _rotY = (_rng.nextDouble() - 0.5) * 0.4;
    _rotZ = (_rng.nextDouble() - 0.5) * 0.4;
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  double _lerpAngle(double a, double b, double t) => a + (b - a) * t;

  void _playRollSound() async {
    try {
      await _player.play(AssetSource('dice_roll.mp3'));
    } catch (_) {}
  }

  void _rollDice() {
    if (_controller.isAnimating) return;

    final face = _rng.nextInt(6) + 1;
    _currentValue = face;

    final target = faceOrientations[face]!;

    // store start
    _startX = _rotX;
    _startY = _rotY;
    _startZ = _rotZ;

    // extra spins for realism
    final spinsX = (2 + _rng.nextInt(3)) * 2 * pi; // 2-4 spins
    final spinsY = (2 + _rng.nextInt(3)) * 2 * pi;
    final spinsZ = (1 + _rng.nextInt(2)) * 2 * pi;

    _targetX = target[0] + spinsX + (_rng.nextDouble() - 0.5) * 0.4;
    _targetY = target[1] + spinsY + (_rng.nextDouble() - 0.5) * 0.4;
    _targetZ = target[2] + spinsZ + (_rng.nextDouble() - 0.5) * 0.4;

    // play sound
    _playRollSound();

    // start animation
    _controller.duration = const Duration(milliseconds: 1500);
    _controller.forward(from: 0.0);
  }

  void _settleBounce() async {
    // small oscillation to mimic inertia
    final settleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    final settle = CurvedAnimation(
        parent: settleController, curve: Curves.elasticOut);

    final sStartX = _rotX;
    final sStartY = _rotY;
    final sStartZ = _rotZ;

    final sTargetX = _normalizeToFace(_rotX);
    final sTargetY = _normalizeToFace(_rotY);
    final sTargetZ = _normalizeToFace(_rotZ);

    settle.addListener(() {
      final t = settle.value;
      setState(() {
        _rotX = _lerpAngle(sStartX, sTargetX, t);
        _rotY = _lerpAngle(sStartY, sTargetY, t);
        _rotZ = _lerpAngle(sStartZ, sTargetZ, t);
      });
    });

    await settleController.forward(from: 0.0);
     settleController.dispose();
  }

  double _normalizeToFace(double angle) {
    // keep angle within -pi..pi then snap small amount to that value
    return angle; // we allow final orientation as-is because targets point faces
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cubeSize = min(size.width, size.height) * 0.5;

    return Scaffold(
      appBar: AppBar(title: const Text('Realistic 3D Dice')),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Result: $_currentValue', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _rollDice,
              child: SizedBox(
                width: cubeSize,
                height: cubeSize + 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // soft shadow
                    Positioned(
                      bottom: 18,
                      child: Transform.scale(
                        scale: 1.0,
                        child: Container(
                          width: cubeSize * 0.8,
                          height: cubeSize * 0.22,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(cubeSize),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 30,
                                spreadRadius: 8,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    // cube
                    Cube3D(
                      size: cubeSize,
                      rotX: _rotX,
                      rotY: _rotY,
                      rotZ: _rotZ,
                      faceBuilder: (v) => RealisticDiceFace(number: v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _rollDice, icon: const Icon(Icons.casino), label: const Text('Roll')),
            const SizedBox(height: 8),
            const Text('Tap the cube or press Roll. Sound enabled.')
          ],
        ),
      ),
    );
  }
}

class Cube3D extends StatelessWidget {
  final double size;
  final double rotX, rotY, rotZ;
  final Widget Function(int value) faceBuilder;
  const Cube3D({required this.size, required this.rotX, required this.rotY, required this.rotZ, required this.faceBuilder, super.key});

  Matrix4 _faceTransform(Matrix4 base, Matrix4 face) {
    return Matrix4.identity()..multiply(base)..multiply(face);
  }

  @override
  Widget build(BuildContext context) {
    final base = Matrix4.identity()..setEntry(3, 2, 0.0015)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    final half = size / 2;

    final front = Matrix4.identity()..translate(0.0, 0.0, half);
    final back = Matrix4.identity()..translate(0.0, 0.0, -half)..rotateY(pi);
    final right = Matrix4.identity()..translate(half, 0.0, 0.0)..rotateY(pi / 2);
    final left = Matrix4.identity()..translate(-half, 0.0, 0.0)..rotateY(-pi / 2);
    final top = Matrix4.identity()..translate(0.0, -half, 0.0)..rotateX(-pi / 2);
    final bottom = Matrix4.identity()..translate(0.0, half, 0.0)..rotateX(pi / 2);

    Widget buildFace(int faceNumber, Matrix4 transform) {
      return Transform(
        alignment: Alignment.center,
        transform: _faceTransform(base, transform),
        child: SizedBox(width: size, height: size, child: faceBuilder(faceNumber)),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        buildFace(6, back),
        buildFace(5, left),
        buildFace(4, bottom),
        buildFace(3, top),
        buildFace(2, right),
        buildFace(1, front),
      ],
    );
  }
}

class RealisticDiceFace extends StatelessWidget {
  final int number;
  const RealisticDiceFace({required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    // layered card: base gradient, subtle specular highlight, pips
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F5F5), Color(0xFFEDEDED)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // specular highlight
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SpecularPainter()),
              ),
            ),
            // pips
            Center(child: SizedBox.expand(child: CustomPaint(painter: _PipPainter(number)))),
          ],
        ),
      ),
    );
  }
}

class _SpecularPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.0)], center: const Alignment(-0.6, -0.8), radius: 0.8).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PipPainter extends CustomPainter {
  final int n;
  _PipPainter(this.n);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill..color = Colors.black87;
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = min(w, h) * 0.07;

    final leftTop = Offset(w * 0.28, h * 0.28);
    final rightBottom = Offset(w * 0.72, h * 0.72);
    final rightTop = Offset(w * 0.72, h * 0.28);
    final leftBottom = Offset(w * 0.28, h * 0.72);
    final center = Offset(cx, cy);
    final topCenter = Offset(cx, h * 0.28);
    final bottomCenter = Offset(cx, h * 0.72);

    void dot(Offset o) => canvas.drawCircle(o, r, paint);

    switch (n) {
      case 1:
        dot(center);
        break;
      case 2:
        dot(rightTop);
        dot(leftBottom);
        break;
      case 3:
        dot(center);
        dot(rightTop);
        dot(leftBottom);
        break;
      case 4:
        dot(leftTop);
        dot(rightBottom);
        dot(rightTop);
        dot(leftBottom);
        break;
      case 5:
        dot(center);
        dot(leftTop);
        dot(rightBottom);
        dot(rightTop);
        dot(leftBottom);
        break;
      case 6:
        dot(leftTop);
        dot(rightTop);
        dot(leftBottom);
        dot(rightBottom);
        dot(topCenter);
        dot(bottomCenter);
        break;
      default:
        dot(center);
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) => oldDelegate.n != n;
}
