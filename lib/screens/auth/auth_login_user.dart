import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthLoginUser extends StatefulWidget {
  const AuthLoginUser({super.key});

  @override
  State<AuthLoginUser> createState() => _AuthLoginUserState();
}

class _AuthLoginUserState extends State<AuthLoginUser> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => errorMessage = "Veuillez remplir tous les champs.");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      if (res.user != null) {
        // Navigation vers pairing en remplaçant l'historique de login
        context.go('/pairing');
      }
    } on AuthException catch (e) {
      setState(() {
        // Traduction des messages d'erreur courants de Supabase
        if (e.message.contains("Invalid login credentials")) {
          errorMessage = "Email ou mot de passe incorrect.";
        } else if (e.message.contains("Email not confirmed")) {
          errorMessage = "Veuillez confirmer votre email avant de vous connecter.";
        } else {
          errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() => errorMessage = "Une erreur inattendue est survenue.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Le bouton retour sera automatiquement ajouté car nous avons utilisé context.push
        title: Hero(tag: 'logo', child: Image.asset("assets/images/logo_nexus.png", height: 50)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Bon retour !",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Connectez-vous pour gérer votre sécurité Nexus.",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              
              const SizedBox(height: 40),

              // Champ Email
              _buildInputCard(
                controller: emailCtrl,
                label: "Adresse email",
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Champ Mot de passe
              _buildInputCard(
                controller: passCtrl,
                label: "Mot de passe",
                icon: Icons.lock_rounded,
                isPassword: true,
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Mot de passe oublié ?", style: TextStyle(color: AppTheme.secondary)),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Se connecter"),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Nouveau chez Nexus ?"),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text("Créer un compte", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primary.withValues(alpha: 0.5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
