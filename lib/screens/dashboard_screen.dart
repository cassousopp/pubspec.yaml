import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/services/alert_notification_service.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? device;
  Map<String, dynamic>? lastAlert;
  bool loading = true;
  bool isMonitoring = true;
  int totalAlerts = 0;

  @override
  void initState() {
    super.initState();
    loadDevice();
  }

  Future<void> loadDevice() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }

    final res = await supabase
        .from("devices")
        .select("*, profiles:owner_id(username)")
        .eq("owner_id", user.id)
        .maybeSingle();

    if (res != null) {
      device = res;
      final alert = await supabase
          .from("alerts")
          .select()
          .eq("device_id", device!["device_id"])
          .order("created_at", ascending: false)
          .limit(1)
          .maybeSingle();

      // Charger le nombre total d'alertes
      final allAlerts = await supabase
          .from("alerts")
          .select()
          .eq("device_id", device!["device_id"]);

      lastAlert = alert;
      totalAlerts = allAlerts.length;

      _setupRealtimeListeners(device!["device_id"]);
      AlertNotificationService().listenToAlerts(device!["device_id"]);
    }

    if (mounted) setState(() => loading = false);
  }

  void _setupRealtimeListeners(String deviceId) {
    final supabase = Supabase.instance.client;
    supabase.channel('dashboard_updates').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'devices',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'device_id', value: deviceId),
      callback: (payload) {
        if (mounted && isMonitoring) loadDevice();
      },
    ).subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final username = (device?['profiles']?['username'] ?? "User").toString();
    final initials = username.isNotEmpty ? username[0].toUpperCase() : "U";

    return NexusScaffold(
      title: GestureDetector(
        onTap: loadDevice,
        child: Row(
          children: [
            Image.asset("assets/images/logo_nexus.png", height: 120),
            const SizedBox(width: 12),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => context.go('/account'),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF3F0FF),
              child: Text(initials, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        )
      ],
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: loadDevice,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildSurveillanceCard(),
                    const SizedBox(height: 20),
                    if (lastAlert != null && isMonitoring) _buildAlertNotificationCard(),
                    const SizedBox(height: 20),
                    _buildRealStatsRow(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSurveillanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mode surveillance",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Switch(
                value: isMonitoring,
                onChanged: (v) {
                  setState(() => isMonitoring = v);
                  if (v) loadDevice();
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMonitoring ? "Active" : "Désactivé",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              const Text(
                "Connecté",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertNotificationCard() {
    if (lastAlert == null) return const SizedBox.shrink();
    
    final alertName = lastAlert!["message"] ?? "Alerte détectée";
    final deviceName = device?['device_name'] ?? "Module";
    final DateTime date = DateTime.parse(lastAlert!["created_at"]);
    final imageUrl = lastAlert!["picture_url"] ?? lastAlert!["image_url"];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFE4ED), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D8D), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Dernière alerte", style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      timeAgo(date),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alertName,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFF3F0FF),
                  child: imageUrl != null 
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Image.asset("assets/images/nexus_roue.png", fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton(
                    onPressed: () => context.push('/alert-detail', extra: {...lastAlert!, 'device_name': deviceName}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Row(
                      children: [
                        Text("Voir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealStatsRow() {
    final int batteryLevel = int.tryParse(device?["battery"]?.toString() ?? "0") ?? 0;
    final Color batteryColor = batteryLevel <= 30 ? Colors.redAccent : Colors.greenAccent;

    return Row(
      children: [
        // Alerts Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Alertes", style: TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(totalAlerts.toString(), style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w900, fontSize: 32)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD1E1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD81B60), size: 24),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Battery Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Batterie", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
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
                  ],
                ),
                const SizedBox(height: 8),
                Text("$batteryLevel%", style: TextStyle(color: batteryColor, fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return "il y a un instant";
  if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
  if (diff.inHours < 24) return "il y a ${diff.inHours} h";
  return "il y a ${diff.inDays} j";
}
