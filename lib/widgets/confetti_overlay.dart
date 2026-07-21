import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps [child] with a burst of falling confetti that can be triggered
/// on demand via [ConfettiOverlayState.play] (grab it with a GlobalKey).
class ConfettiOverlay extends StatefulWidget {
  final Widget child;

  const ConfettiOverlay({super.key, required this.child});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  List<_Particle> _particles = const [];

  static const _colors = [
    Colors.amber,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.orangeAccent,
  ];

  /// Launches a fresh burst of particles from the top of this widget.
  void play() {
    final random = Random();
    setState(() {
      _particles = List.generate(70, (_) {
        return _Particle(
          startX: random.nextDouble(),
          // Mostly upward-and-outward launch angles, in radians.
          angle: -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9,
          speed: 260 + random.nextDouble() * 260,
          rotationSpeed: (random.nextDouble() - 0.5) * 12,
          color: _colors[random.nextInt(_colors.length)],
          size: 6 + random.nextDouble() * 6,
          delay: random.nextDouble() * 0.15,
        );
      });
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double startX; // fraction of width, 0..1
  final double angle; // launch angle in radians
  final double speed; // px/s
  final double rotationSpeed; // radians/s
  final Color color;
  final double size;
  final double delay; // fraction of the animation to wait before launching

  const _Particle({
    required this.startX,
    required this.angle,
    required this.speed,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  static const _gravity = 650.0;
  static const _durationSeconds = 1.8;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (t <= 0) continue;

      final elapsed = t * _durationSeconds;
      final vx = cos(particle.angle) * particle.speed;
      final vy = sin(particle.angle) * particle.speed;
      final dx = vx * elapsed;
      final dy = vy * elapsed + 0.5 * _gravity * elapsed * elapsed;

      final opacity = (1 - t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final x = particle.startX * size.width + dx;
      final y = size.height * 0.2 + dy;

      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * elapsed);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
