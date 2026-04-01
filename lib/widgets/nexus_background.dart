import 'package:flutter/material.dart';
import 'package:nexus_app/theme/app_theme.dart';

class NexusBackground extends StatelessWidget {
  const NexusBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.1, -0.6),
          radius: 1.2,
          colors: [
            // Glow violet plus doux, moins agressif
            Color(0xFF2B1B5C),
            AppTheme.darkBackground,
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

