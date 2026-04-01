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

  String selectedCode = "+33"; // Code par défaut (France)

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

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1️⃣ Création du compte
      final res = await supabase.auth.signUp(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      if (res.user == null) {
        setState(() {
          errorMessage = "Impossible de créer le compte.";
        });
        return;
      }

      final userId = res.user!.id;

      // 2️⃣ Construction du numéro final
      final finalPhone = "$selectedCode ${phoneCtrl.text.trim()}";

      // 3️⃣ Enregistrement dans la table profiles
      try {
        await supabase.from("profiles").insert({
          "id": userId,
          "username": username,
          "phone": finalPhone,
          "email": email,
        });
      } catch (e) {
        setState(() {
          errorMessage =
          "Compte créé, mais l’enregistrement du profil a échoué.\nVérifiez la table 'profiles'.";
        });
        loading = false;
        return;
      }

      if (!mounted) return;

      setState(() => loading = false);

      // 4️⃣ Popup succès + redirection vers login
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Compte créé ✔"),
          content: const Text(
            "Votre compte NEXUS a été créé avec succès.\nVeuillez vous connecter.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (mounted) context.go('/auth');
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on AuthApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Une erreur est survenue. Veuillez réessayer.";
      });
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: 20),
            child: Column(
              children: [
                SizedBox(height: h * 0.03),

                Image.asset(
                  "assets/images/logo_nexus.png",
                  height: h * 0.18,
                ),

                SizedBox(height: h * 0.03),

                const Text(
                  "Créer un compte",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),
                const Text(
                  "Rejoignez la communauté NEXUS",
                  style: TextStyle(color: Colors.black54),
                ),

                SizedBox(height: h * 0.04),

                // USERNAME
                TextField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔥 PHONE WITH COUNTRY SELECTOR
                Row(
                  children: [
                    // Menu déroulant pour le pays
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedCode,
                        underline: const SizedBox(),
                        items: countryList.map((c) {
                          return DropdownMenuItem<String>(
                            value: c["code"],
                            child: Text("${c["flag"]} ${c["code"]}"),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedCode = v!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Champ numéro
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Numéro de téléphone",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // EMAIL
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Adresse email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                SizedBox(height: h * 0.03),

                // BUTTON REGISTER
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Créer le compte",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.02),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Déjà un compte ?"),
                    TextButton(
                      onPressed: () => context.go('/auth'),
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
