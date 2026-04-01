import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/services/alert_notification_service.dart';
import 'package:nexus_app/theme/app_theme.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? vehicleImageUrl;
  Map<String, dynamic>? device;
  Map<String, dynamic>? lastAlert;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDevice();
  }

  Future<void> loadDevice() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          device = null;
          lastAlert = null;
          loading = false;
        });
      }
      return;
    }

    // Initial fetch
    final res = await supabase
        .from("devices")
        .select("*, profiles:owner_id(username)")
        .eq("owner_id", user.id)
        .maybeSingle();

    if (res != null) {
      device = res;
      _updateImageUrl();

      final alert = await supabase
          .from("alerts")
          .select()
          .eq("device_id", device!["device_id"])
          .order("created_at", ascending: false)
          .limit(1)
          .maybeSingle();

      lastAlert = alert;
      
      // Setup Realtime listeners for live updates
      _setupRealtimeListeners(device!["device_id"]);
      AlertNotificationService().listenToAlerts(device!["device_id"]);
    }

    if (mounted) setState(() => loading = false);
  }

  void _updateImageUrl() {
    if (device == null) return;
    vehicleImageUrl = device?["picture_url"] ??
        device?["image_url"] ??
        device?["last_image_url"] ??
        device?["photo_url"] ??
        device?["lastImageUrl"];
  }

  void _setupRealtimeListeners(String deviceId) {
    final supabase = Supabase.instance.client;

    // Écouter les mises à jour du véhicule (batterie, statut, etc.)
    supabase
        .channel('device_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'devices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                device = {...?device, ...payload.newRecord};
                _updateImageUrl();
              });
            }
          },
        )
        .subscribe();

    // Écouter les nouvelles alertes pour mettre à jour la dernière activité
    supabase
        .channel('alert_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                lastAlert = payload.newRecord;
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    AlertNotificationService().stopListening();
    Supabase.instance.client.removeAllChannels();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NexusScaffold(
      title: Image.asset("assets/images/logo_nexus.png", height: 60),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppTheme.primary),
          onPressed: () => context.go('/alerts'),
        ),
      ],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: loadDevice,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleHeader(),
            const SizedBox(height: 24),
            
            Text("Statut du système", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (device != null) _buildStatusCard(),
            const SizedBox(height: 16),
            
            if (device != null) _buildBatteryWifiRow(),
            const SizedBox(height: 16),
            
            if (lastAlert != null) ...[
              Text("Dernière activité", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildLastAlertCard(),
              const SizedBox(height: 16),
            ],
            
            if (vehicleImageUrl != null && vehicleImageUrl!.isNotEmpty) _buildLastImageCard(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Image.asset('assets/images/nexus_roue.png',
                    fit: BoxFit.contain),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent
                    ],
                  ),
                ),
                child: const Text(
                  "Mon véhicule connecté",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = device!["status"] ?? "Indisponible";
    final isSecure = status.toLowerCase().contains("sécurisé") || status.toLowerCase().contains("ok");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSecure 
            ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
            : [const Color(0xFFFF5252), const Color(0xFFFF8A80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isSecure ? Colors.green : Colors.red)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(isSecure ? Icons.shield_rounded : Icons.warning_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
                Text(
                  isSecure ? "Votre véhicule est protégé" : "Attention requise",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryWifiRow() {
    return Row(
      children: [
        Expanded(
          child: _modernInfoCard(
            icon: Icons.battery_charging_full_rounded,
            iconColor: const Color(0xFF00C853),
            title: "Batterie",
            value: "${device!["battery"] ?? "?"}%",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _modernInfoCard(
            icon: Icons.wifi_tethering_rounded,
            iconColor: AppTheme.primary,
            title: "Signal",
            value: "Excellent", 
          ),
        ),
      ],
    );
  }

  Widget _modernInfoCard({required IconData icon, required Color iconColor, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLastAlertCard() {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.history_toggle_off_rounded, color: Colors.orange),
        ),
        title: Text(lastAlert!["message"] ?? "Alerte détectée", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(timeAgo(DateTime.parse(lastAlert!["created_at"]))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => context.go('/alerts'),
      ),
    );
  }

  Widget _buildLastImageCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Dernière capture", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImagePreview(vehicleImageUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              vehicleImageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 40),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return "À l'instant";
  if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
  if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
  return "Il y a ${diff.inDays} j";
}
