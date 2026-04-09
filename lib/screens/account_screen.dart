import 'package:flutter/material.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:nexus_app/theme/app_theme.dart';
import 'package:nexus_app/services/settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/main.dart' show themeManager;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? device;
  Map<String, dynamic>? lastAlert;
  bool loading = true;
  String currentTheme = 'dark';
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    loadAccountData();
  }

  Future<void> loadAccountData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final theme = await SettingsService.getThemeMode();
    final notifs = await SettingsService.getPushNotificationsEnabled();

    if (user == null) return;

    try {
      final profileRes = await supabase
          .from("profiles")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      final deviceRes = await supabase
          .from("devices")
          .select()
          .eq("owner_id", user.id)
          .maybeSingle();

      if (deviceRes != null) {
        final alertRes = await supabase
            .from("alerts")
            .select()
            .eq("device_id", deviceRes["device_id"])
            .order("created_at", ascending: false)
            .limit(1)
            .maybeSingle();
        
        lastAlert = alertRes;
      }

      if (mounted) {
        setState(() {
          profile = profileRes;
          device = deviceRes;
          currentTheme = theme;
          notificationsEnabled = notifs;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateTheme(String mode) async {
    await themeManager.setTheme(mode);
    if (mounted) {
      setState(() => currentTheme = mode);
    }
  }

  Future<void> _updateNotifications(bool enabled) async {
    await SettingsService.setPushNotificationsEnabled(enabled);
    if (mounted) {
      setState(() => notificationsEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1933) : Colors.white;
    final sectionBg = isDark ? const Color(0xFF222146) : const Color(0xFFF7F7F2);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return NexusScaffold(
      title: const Text("Profil"),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: loadAccountData,
              color: AppTheme.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: sectionBg,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            child: Text(
                              (profile?['username'] ?? "U").toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['username'] ?? "Utilisateur",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  profile?['email'] ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Module Section
                    _buildSectionLabel("Module associé"),
                    const SizedBox(height: 16),
                    
                    // Row for Battery and Signal
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard("Batterie", _buildBatteryIndicator(), isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInfoCard("Signal", _buildSignalIndicator(), isDark)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Apparence Section
                    _buildSectionLabel("Apparence"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Thème",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _updateTheme('light'),
                                      child: _buildThemeButton("Clair", currentTheme == 'light', isDark),
                                    ),
                                    GestureDetector(
                                      onTap: () => _updateTheme('dark'),
                                      child: _buildThemeButton("Sombre", currentTheme == 'dark', isDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 32, color: isDark ? Colors.white10 : null),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Notifications",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                              ),
                              Switch(
                                value: notificationsEnabled,
                                onChanged: (v) => _updateNotifications(v),
                                activeThumbColor: AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // Support Section
                    _buildSectionLabel("Support & Légal"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile("Help & Support", Icons.help_outline_rounded, textColor),
                          Divider(height: 0, thickness: 1, color: isDark ? Colors.white10 : null),
                          _buildMenuTile("Privacy Policy", Icons.privacy_tip_outlined, textColor),
                          Divider(height: 0, thickness: 1, color: isDark ? Colors.white10 : null),
                          _buildMenuTile("Terms of Service", Icons.description_outlined, textColor),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Logout Button
                  OutlinedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      // ignore: use_build_context_synchronously
                      if (mounted) context.go('/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFFEBEE)),
                      backgroundColor: const Color(0xFFFFEBEE).withValues(alpha: 0.3),
                    ),
                    child: const Text("Déconnexion"),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      "Version 1.0.0 (Build 1)",
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoCard(String label, Widget content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222146) : const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    final int batteryLevel = int.tryParse(device?["battery"]?.toString() ?? "0") ?? 0;
    final Color batteryColor = batteryLevel <= 30 ? Colors.redAccent : Colors.greenAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: batteryColor.withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                flex: batteryLevel,
                child: Container(
                  decoration: BoxDecoration(
                    color: batteryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                flex: 100 - batteryLevel,
                child: const SizedBox(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text("$batteryLevel%", style: TextStyle(color: batteryColor, fontWeight: FontWeight.w900, fontSize: 16)),
      ],
    );
  }

  Widget _buildSignalIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSignalBar(height: 8, active: true),
            const SizedBox(width: 2),
            _buildSignalBar(height: 12, active: true),
            const SizedBox(width: 2),
            _buildSignalBar(height: 16, active: true),
            const SizedBox(width: 2),
            _buildSignalBar(height: 20, active: true),
          ],
        ),
        const SizedBox(height: 8),
        const Text("Fort", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900, fontSize: 16)),
      ],
    );
  }

  Widget _buildSignalBar({required double height, required bool active}) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1) : const Color(0xFF6366F1).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }


  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeButton(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, Color textColor) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      onTap: () => _handleMenuAction(title),
    );
  }

  void _handleMenuAction(String title) {
    switch (title) {
      case "Help & Support":
        _showHelpDialog();
        break;
      case "Privacy Policy":
        _showPrivacyDialog();
        break;
      case "Terms of Service":
        _showTermsDialog();
        break;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aide & Support"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Besoin d'aide?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text("• Consulter la FAQ: nexusapp.com/faq"),
              Text("• Email: support@nexusapp.com"),
              Text("• Téléphone: +33 1 XX XX XX XX"),
              SizedBox(height: 16),
              Text(
                "Signaler un problème",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text("Décrivez votre problème dans un email à support@nexusapp.com"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Politique de Confidentialité"),
        content: const SingleChildScrollView(
          child: Text(
            "NEXUS respecte votre vie privée.\n\n"
            "• Vos données personnelles sont sécurisées sur nos serveurs chiffrés\n"
            "• Nous ne partageons jamais vos données avec des tiers\n"
            "• Vous avez le droit d'accès et de suppression de vos données\n"
            "• Déclaration CNIL: N° XXXXX\n\n"
            "Pour plus d'informations: privacy@nexusapp.com",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conditions d'Utilisation"),
        content: const SingleChildScrollView(
          child: Text(
            "Conditions d'utilisation de NEXUS\n\n"
            "1. ACCEPTATION DES CONDITIONS\n"
            "En utilisant NEXUS, vous acceptez ces conditions.\n\n"
            "2. USAGE AUTORISÉ\n"
            "Vous vous engagez à utiliser l'application de manière légale et responsable.\n\n"
            "3. PROPRIÉTÉ INTELLECTUELLE\n"
            "Tous les contenus sont la propriété de NEXUS.\n\n"
            "4. LIMITATION DE RESPONSABILITÉ\n"
            "NEXUS ne peut être tenu responsable de dommages indirects.\n\n"
            "5. MODIFICATION DES CONDITIONS\n"
            "Ces conditions peuvent être modifiées à tout moment.",
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }
}
