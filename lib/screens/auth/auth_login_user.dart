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
  bool obscurePass = true;
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
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains("Invalid login credentials")) {
          errorMessage = "Email ou mot de passe incorrect.";
        } else {
          errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() => errorMessage = "Une erreur est survenue.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Header
              const Text(
                "Connexion",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Bon retour parmi nous",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              // Form fields
              _buildLabel("Adresse email"),
              _buildTextField(
                ctrl: emailCtrl, 
                hint: "thomas@mail.com", 
                icon: Icons.email_outlined, 
                keyboardType: TextInputType.emailAddress
              ),
              
              const SizedBox(height: 24),
              
              _buildLabel("Mot de passe"),
              _buildTextField(
                ctrl: passCtrl, 
                hint: "••••••••", 
                icon: Icons.lock_outline, 
                obscureText: obscurePass,
                isPassword: true,
                onToggleObscure: () => setState(() => obscurePass = !obscurePass),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Mot de passe oublié ?",
                    style: TextStyle(color: AppTheme.secondaryPink, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Se connecter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 32),

              // OR divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("ou", style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 32),

              // Social buttons
              Row(
                children: [
                  Expanded(child: _buildSocialButton(Icons.g_mobiledata_rounded, const Color(0xFFDB4437), "Google")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSocialButton(Icons.apple_rounded, Colors.black, "Apple")),
                ],
              ),
              
              const SizedBox(height: 48),

              Center(
                child: GestureDetector(
                  onTap: () => context.push('/signup'),
                  child: RichText(
                    text: TextSpan(
                      text: "Nouveau ici ? ",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      children: [
                        TextSpan(
                          text: "Créer un compte",
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController ctrl, 
    required String hint, 
    required IconData icon, 
    bool obscureText = false, 
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: onToggleObscure,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
