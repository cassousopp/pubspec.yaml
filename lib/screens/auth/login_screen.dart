import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Illustration du vélo en haut sur fond blanc
                Image.asset(
                  'assets/images/nexus_roue.png',
                  height: size.height * 0.26,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                // Petit logo sous l'illustration
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/logo_nexus.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                // Text & Actions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        "Sécurisez votre trajet",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Connectez votre module Nexus pour une protection en temps réel.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // Main CTA
                      ElevatedButton(
                        onPressed: () => context.go('/auth'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shadowColor:
                              AppTheme.secondary.withValues(alpha: 0.4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching, size: 20),
                            SizedBox(width: 12),
                            Text("Connecter votre appareil"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Secondary CTA
                      OutlinedButton(
                        onPressed: () => context.push('/tutorial'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Tutoriel de connexion",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      
                      // Footer info
                      GestureDetector(
                        onTap: () => context.push('/auth'),
                        child: RichText(
                          text: TextSpan(
                            text: "Déjà un compte ? ",
                            style: TextStyle(color: Colors.grey.shade600),
                            children: [
                              TextSpan(
                                text: "Se connecter",
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
