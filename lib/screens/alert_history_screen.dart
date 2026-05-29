import 'package:flutter/material.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  List<Map<String, dynamic>> allAlerts = [];
  List<Map<String, dynamic>> filteredAlerts = [];
  bool loading = true;
  DateTime? selectedDate;

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

      if (mounted) {
        setState(() {
          allAlerts = List<Map<String, dynamic>>.from(res);
          filteredAlerts = allAlerts;
          loading = false;
        });
      }
    } else {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        filteredAlerts = allAlerts.where((alert) {
          final alertDate = DateTime.parse(alert["created_at"]);
          return alertDate.year == picked.year &&
                 alertDate.month == picked.month &&
                 alertDate.day == picked.day;
        }).toList();
      });
    }
  }

  void _resetFilter() {
    setState(() {
      selectedDate = null;
      filteredAlerts = allAlerts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NexusScaffold(
      title: const Text(
        "Historique",
        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: loadHistory,
              color: const Color(0xFF6366F1),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F2),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null 
                                      ? "Trier par date" 
                                      : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}",
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (selectedDate != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              onPressed: _resetFilter,
                              icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredAlerts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F7F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      selectedDate == null 
                                        ? "Aucun événement détecté" 
                                        : "Aucune alerte pour cette date",
                                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = filteredAlerts[index];
                              final date = DateTime.parse(alert["created_at"]);
                              return _buildHistoryItem(alert, date);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> alert, DateTime date) {
    final message = alert["message"] ?? "Événement détecté";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFE4ED), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD81B60), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
