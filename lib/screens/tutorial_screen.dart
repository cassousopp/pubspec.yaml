import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tutoriel",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Barre de progression
                      Row(
                        children: [
                          _buildProgressDot(true),
                          const SizedBox(width: 8),
                          _buildProgressDot(true),
                          const SizedBox(width: 8),
                          _buildProgressDot(true),
                          const SizedBox(width: 8),
                          _buildProgressDot(true),
                        ],
                      ),
                      
                      const SizedBox(height: 40),

                      // Étape 1 : Création de compte (Ancien contenu)
                      _buildStepCard(
                        title: "Création de compte",
                        desc: "Inscrivez-vous avec votre email pour accéder à l'interface de contrôle.",
                        icon: Icons.person_add_rounded,
                        isActive: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Étape 2 : Identification du module (Ancien contenu)
                      _buildStepCard(
                        title: "Identification du module",
                        desc: "Saisissez l'ID unique et la clé secrète gravés sur votre boîtier.",
                        icon: Icons.qr_code_scanner_rounded,
                        isActive: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Étape 3 : Synchronisation (Ancien contenu)
                      _buildStepCard(
                        title: "Synchronisation",
                        desc: "Nexus se connecte en quelques secondes à nos serveurs sécurisés.",
                        icon: Icons.sync_lock_rounded,
                        isActive: true,
                      ),

                      const SizedBox(height: 16),
                      
                      // Étape 4 : Protection active (Ancien contenu)
                      _buildStepCard(
                        title: "Protection active",
                        desc: "Votre véhicule est maintenant surveillé 24h/24 par Nexus.",
                        icon: Icons.shield_rounded,
                        isActive: true,
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bouton Suivant fixé en bas
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Suivant",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool active) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF7F7F2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isActive ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 15,
              color: isActive ? Colors.grey.shade700 : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
