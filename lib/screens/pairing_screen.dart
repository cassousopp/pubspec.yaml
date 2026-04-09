import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final deviceIdCtrl = TextEditingController();
  final deviceSecretCtrl = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> pairDevice() async {
    final supabase = Supabase.instance.client;
    final deviceId = deviceIdCtrl.text.trim();
    final deviceSecret = deviceSecretCtrl.text.trim();

    if (deviceId.isEmpty || deviceSecret.isEmpty) {
      setState(() => errorMessage = "Veuillez remplir tous les champs.");
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => errorMessage = "Vous devez être connecté.");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final module = await supabase
          .from("devices")
          .select()
          .eq("device_id", deviceId)
          .eq("device_secret", deviceSecret)
          .maybeSingle();

      if (module == null) {
        setState(() {
          errorMessage = "Identifiant ou clé secrète incorrect(e).";
          loading = false;
        });
        return;
      }

      await supabase
          .from("devices")
          .update({
            "owner_id": user.id,
            "status": "active",
            "last_seen": DateTime.now().toIso8601String(),
          })
          .eq("device_id", deviceId);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      setState(() => errorMessage = "Une erreur est survenue.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: const Text(
          "Module associé avec succès !",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text("Continuer"),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Associer un module",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Connectez votre module NEXUS",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              // Illustration Icône Cadenas
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1), size: 60),
                      Positioned(
                        bottom: 55,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC4899),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Form fields
              _buildLabel("Nom du module"),
              _buildTextField(deviceIdCtrl, "NX-Garage-01"),
              
              const SizedBox(height: 24),
              
              _buildLabel("Mot de passe du module"),
              _buildTextField(deviceSecretCtrl, "••••••••", obscureText: true),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton(
                onPressed: loading ? null : pairDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Associer le module", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Infos disponibles sur l'étiquette du module",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscureText,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}
