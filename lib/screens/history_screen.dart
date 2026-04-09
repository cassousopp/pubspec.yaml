import 'package:flutter/material.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final device = await supabase
        .from("devices")
        .select()
        .eq("owner_id", user.id)
        .maybeSingle();

    if (device != null) {
      final res = await supabase
          .from("alerts")
          .select()
          .eq("device_id", device["device_id"])
          .order("created_at", ascending: false);

      setState(() {
        alerts = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NexusScaffold(
      title: Text(
        "Historique",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : alerts.isEmpty
              ? const Center(child: Text("Aucun événement détecté"))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButton<String>(
                          value: "date",
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const [
                            DropdownMenuItem(value: "date", child: Text("Trier par date", style: TextStyle(fontWeight: FontWeight.w600))),
                          ],
                          onChanged: (v) {},
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: alerts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          final date = DateTime.parse(alert["created_at"]);
                          return _buildHistoryItem(alert, date);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> alert, DateTime date) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.circle, color: Color(0xFF6366F1), size: 12),
      ),
      title: const Text(
        "Événement détecté",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      subtitle: Text(
        "${date.day}/${date.month.toString().padLeft(2, '0')} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }
}
