import 'package:flutter/material.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool loading = true;
  Map<String, dynamic>? device;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final res = await supabase
        .from('devices')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();

    setState(() {
      device = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NexusScaffold(
      title: const Text("Appareils"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: device == null
                  ? const Text("Aucun module associé pour le moment.")
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Module: ${device!['device_id'] ?? '-'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text("Statut: ${device!['status'] ?? '-'}"),
                            const SizedBox(height: 8),
                            Text("Batterie: ${device!['battery'] ?? '?'}%"),
                          ],
                        ),
                      ),
                    ),
            ),
    );
  }
}

