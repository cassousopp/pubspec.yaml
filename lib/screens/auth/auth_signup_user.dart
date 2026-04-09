// lib/screens/auth/auth_signup_user.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSignupUser extends StatefulWidget {
  const AuthSignupUser({super.key});

  @override
  State<AuthSignupUser> createState() => _AuthSignupUserState();
}

class _AuthSignupUserState extends State<AuthSignupUser> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool loading = false;
  bool obscurePass = true;
  String? errorMessage;

  // Liste des pays disponibles
  final List<Map<String, String>> countryList = [
    {"flag": "🇫🇷", "code": "+33"},
    {"flag": "🇧🇪", "code": "+32"},
    {"flag": "🇨🇮", "code": "+225"},
    {"flag": "🇨🇲", "code": "+237"},
    {"flag": "🇸🇳", "code": "+221"},
    {"flag": "🇨🇬", "code": "+242"},
    {"flag": "🇬🇦", "code": "+241"},
  ];

  String selectedCode = "+33";

  Future<void> register() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || username.isEmpty || phone.isEmpty) {
      setState(() {
        errorMessage = "Veuillez remplir tous les champs.";
      });
      return;
    }

    // Validation email
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        errorMessage = "Veuillez entrer une adresse email valide.";
      });
      return;
    }

    // Validation mot de passe (minimum 6 caractères)
    if (pass.length < 6) {
      setState(() {
        errorMessage = "Le mot de passe doit contenir au moins 6 caractères.";
      });
      return;
    }

    // Validation téléphone 
    if (phone.length < 8) {
      setState(() {
        errorMessage = "Veuillez entrer un numéro de téléphone valide.";
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final res = await supabase.auth.signUp(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      if (res.user == null) {
        setState(() {
          errorMessage = "Impossible de créer le compte. Cet email existe peut-être déjà.";
        });
        return;
      }

      final userId = res.user!.id;
      final finalPhone = "$selectedCode $phone";

      try {
        await supabase.from("profiles").insert({
          "id": userId,
          "username": username,
          "phone": finalPhone,
          "email": email,
        });
      } catch (profileError) {
        setState(() {
          errorMessage = "Compte créé, mais l'enregistrement du profil a échoué: $profileError";
        });
        if (mounted) setState(() => loading = false);
        return;
      }

      if (!mounted) return;
      setState(() => loading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Compte créé ✔"),
          content: const Text("Votre compte NEXUS a été créé avec succès."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/pairing');
              },
              child: const Text("OK", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } on AuthApiException catch (e) {
      setState(() => errorMessage = "Erreur d'authentification: ${e.message}");
    } catch (e) {
      setState(() => errorMessage = "Une erreur est survenue: $e");
    }

    if (mounted) setState(() => loading = false);
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
              
              const Text(
                "Créer un compte",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Rejoignez NEXUS",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              _buildLabel("Nom d'utilisateur"),
              _buildTextField(ctrl: usernameCtrl, hint: "Thomas", icon: Icons.person_outline),
              
              const SizedBox(height: 20),
              
              _buildLabel("Numéro de téléphone"),
              _buildPhoneField(),
              
              const SizedBox(height: 20),
              
              _buildLabel("Email"),
              _buildTextField(ctrl: emailCtrl, hint: "thomas@mail.com", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              
              const SizedBox(height: 20),
              
              _buildLabel("Mot de passe"),
              _buildTextField(
                ctrl: passCtrl, 
                hint: "••••••••", 
                icon: Icons.lock_outline, 
                obscureText: obscurePass,
                isPassword: true,
                onToggleObscure: () => setState(() => obscurePass = !obscurePass),
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("S'inscrire", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildSocialButton(
                    Icons.g_mobiledata_rounded, 
                    const Color(0xFFDB4437),
                    "Google"
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSocialButton(
                    Icons.apple_rounded, 
                    Colors.black,
                    "Apple"
                  )),
                ],
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

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: selectedCode,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: countryList.map((c) {
                return DropdownMenuItem<String>(
                  value: c["code"],
                  child: Text("${c["flag"]} ${c["code"]}", style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCode = v!),
            ),
          ),
          VerticalDivider(color: Colors.grey.shade300, width: 1, indent: 12, endIndent: 12),
          Expanded(
            child: TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: "06 12 34 56 78",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ),
        ],
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
