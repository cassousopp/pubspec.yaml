import 'package:flutter/material.dart';
import 'package:nexus_app/services/settings_service.dart';
import 'package:nexus_app/widgets/nexus_card.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool loading = true;
  bool pushEnabled = true;
  bool alertSoundEnabled = true;
  bool autoArmEnabled = true;
  bool batterySaverEnabled = false;
  int motionSensitivity = 1; // 0 low,1 medium,2 high
  String themeMode = 'dark';

  Map<String, dynamic>? device;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final vTheme = await SettingsService.getThemeMode();
    final vPush = await SettingsService.getPushNotificationsEnabled();
    final vSound = await SettingsService.getAlertSoundEnabled();
    final vAutoArm = await SettingsService.getAutoArmEnabled();
    final vBattery = await SettingsService.getBatterySaverEnabled();
    final vSens = await SettingsService.getMotionSensitivity();

    Map<String, dynamic>? dev;
    if (user != null) {
      dev = await supabase
          .from('devices')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    }

    if (!mounted) return;
    setState(() {
      themeMode = vTheme;
      pushEnabled = vPush;
      alertSoundEnabled = vSound;
      autoArmEnabled = vAutoArm;
      batterySaverEnabled = vBattery;
      motionSensitivity = vSens;
      device = dev;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NexusScaffold(
      title: const Text("Settings"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _deviceHeader(context),
                const SizedBox(height: 18),
                Text("Notifications",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                NexusCard(
                  child: _switchTile(
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFF2A1B22),
                    title: "Push Notifications",
                    subtitle: "Recevez les alertes sur votre appareil",
                    value: pushEnabled,
                    onChanged: (v) async {
                      setState(() => pushEnabled = v);
                      await SettingsService.setPushNotificationsEnabled(v);
                    },
                  ),
                ),
                NexusCard(
                  child: _switchTile(
                    icon: Icons.volume_up_rounded,
                    iconBg: const Color(0xFF241A2E),
                    title: "Alert Sound",
                    subtitle: "Son pour les alertes importantes",
                    value: alertSoundEnabled,
                    onChanged: (v) async {
                      setState(() => alertSoundEnabled = v);
                      await SettingsService.setAlertSoundEnabled(v);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text("Security",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                NexusCard(
                  child: _switchTile(
                    icon: Icons.shield_rounded,
                    iconBg: const Color(0xFF14241E),
                    title: "Auto-Arm",
                    subtitle: "Activer la protection automatiquement",
                    value: autoArmEnabled,
                    onChanged: (v) async {
                      setState(() => autoArmEnabled = v);
                      await SettingsService.setAutoArmEnabled(v);
                    },
                  ),
                ),
                NexusCard(
                  child: _segmentedSensitivity(context),
                ),
                const SizedBox(height: 18),
                Text("Appearance",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                NexusCard(
                  child: _themeTile(context),
                ),
                const SizedBox(height: 18),
                Text("Power",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                NexusCard(
                  child: _switchTile(
                    icon: Icons.battery_saver_rounded,
                    iconBg: const Color(0xFF2C2416),
                    title: "Battery Saver",
                    subtitle: "Réduire la consommation",
                    value: batterySaverEnabled,
                    onChanged: (v) async {
                      setState(() => batterySaverEnabled = v);
                      await SettingsService.setBatterySaverEnabled(v);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                NexusCard(
                  child: Column(
                    children: [
                      _linkTile(
                        icon: Icons.help_outline_rounded,
                        title: "Help & Support",
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _linkTile(
                        icon: Icons.privacy_tip_rounded,
                        title: "Privacy Policy",
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _linkTile(
                        icon: Icons.description_rounded,
                        title: "Terms of Service",
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ctaPill(context, "Manage your NEXUS settings"),
              ],
            ),
    );
  }

  Widget _deviceHeader(BuildContext context) {
    final deviceId = device?['device_id']?.toString() ?? '—';
    final battery = device?['battery']?.toString() ?? '—';
    const signal = "Excellent"; // pas de GPS/tracking demandé

    return NexusCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7ABF), Color(0xFFB08CFF)],
                  ),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NEXUS Pro",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text("Serial: $deviceId",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("v1.0.0",
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text("Up to date",
                      style: TextStyle(
                        color: Color(0xFF2EE59D),
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric("Battery", "$battery%"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric("Signal Strength", signal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _segmentedSensitivity(BuildContext context) {
    final labels = const ["Low", "Medium", "High"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1730),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Motion sensitivity",
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text("Ajuster le seuil de détection",
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                labels[motionSensitivity],
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text("Low")),
            ButtonSegment(value: 1, label: Text("Medium")),
            ButtonSegment(value: 2, label: Text("High")),
          ],
          selected: {motionSensitivity},
          onSelectionChanged: (s) async {
            final v = s.first;
            setState(() => motionSensitivity = v);
            await SettingsService.setMotionSensitivity(v);
          },
        ),
      ],
    );
  }

  Widget _themeTile(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1730),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.dark_mode_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Theme", style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text("Choisir le mode clair/sombre", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        DropdownButton<String>(
          value: themeMode,
          items: const [
            DropdownMenuItem(value: 'dark', child: Text("Dark")),
            DropdownMenuItem(value: 'light', child: Text("Light")),
            DropdownMenuItem(value: 'system', child: Text("System")),
          ],
          onChanged: (v) async {
            if (v == null) return;
            setState(() => themeMode = v);
            await SettingsService.setThemeMode(v);
          },
        ),
      ],
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _ctaPill(BuildContext context, String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

