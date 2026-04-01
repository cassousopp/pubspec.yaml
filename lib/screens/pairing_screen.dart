import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/theme/app_theme.dart';
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
          errorMessage =
              "Identifiant ou clé secrète incorrect(e), ou module inaccessible.";
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
    } on PostgrestException catch (e) {
      setState(() {
        errorMessage = "Accès refusé ou requête invalide : ${e.message}";
      });
    } catch (e) {
      setState(() => errorMessage = "Erreur : $e");
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
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text("Module associé !", textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          "Votre appareil NEXUS est maintenant lié à votre compte.",
          textAlign: TextAlign.center,
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Hero(tag: 'logo', child: Image.asset("assets/images/logo_nexus.png", height: 60)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Nouveau module",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Entrez les identifiants présents sur votre boîtier Nexus.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              
              // Animated Illustration Card
              Center(
                child: Container(
                  height: size.height * 0.22,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AppTheme.primaryGradient.begin,
                      end: AppTheme.primaryGradient.end,
                      colors: AppTheme.primaryGradient.colors
                          .map((c) => c.withValues(alpha: 0.10))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.05)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Image.asset("assets/images/btr_nexus.png", height: 120),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // Inputs
              _buildTextField(
                controller: deviceIdCtrl,
                label: "Identifiant du module",
                icon: Icons.qr_code_scanner_rounded,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: deviceSecretCtrl,
                label: "Clé secrète",
                icon: Icons.vpn_key_rounded,
                isPassword: true,
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: loading ? null : pairDevice,
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Associer maintenant"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primary.withValues(alpha: 0.5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
