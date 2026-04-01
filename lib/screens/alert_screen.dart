import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  List<dynamic> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    // Récupération du module associé à l’utilisateur
    final device = await supabase
        .from("devices")
        .select()
        .eq("owner_id", user.id)
        .maybeSingle();

    if (device == null) {
      setState(() => loading = false);
      return;
    }

    // Récupération des alertes liées
    final res = await supabase
        .from("alerts")
        .select()
        .eq("device_id", device["device_id"])
        .order("created_at", ascending: false);

    setState(() {
      alerts = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Historique des alertes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : alerts.isEmpty
          ? const Center(
        child: Text(
          "Aucune alerte pour le moment",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, i) {
            final alert = alerts[i];

            return _alertCard(
              type: alert["type"] ?? "unknown",
              message: alert["message"] ?? "",
              date: alert["created_at"],
            );
          },
        ),
      ),
    );
  }

  // 🔥 Belle carte d'alerte
  Widget _alertCard({required String type, required String message, required String date}) {
    IconData icon = Icons.warning_amber_rounded;
    Color color = Colors.orange;

    if (type == "movement") {
      icon = Icons.directions_run;
      color = Colors.deepPurple;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          timeAgo(DateTime.parse(date)),
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

// Formatage du temps : "il y a 3 min"
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inSeconds < 60) return "il y a ${diff.inSeconds}s";
  if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
  if (diff.inHours < 24) return "il y a ${diff.inHours} h";
  return "il y a ${diff.inDays} jours";
}
