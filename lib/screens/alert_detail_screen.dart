import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  String? _imageUrl;
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLatestImage());
  }

  Future<void> _fetchLatestImage() async {
    try {
      final supabase = Supabase.instance.client;
      final alert = GoRouterState.of(context).extra as Map<String, dynamic>?;
      
      if (alert != null) {
        String? candidateUrl = alert["picture_url"] ?? alert["image_url"] ?? alert["last_image_url"];
        
        if (candidateUrl == null && alert["device_id"] != null) {
          final devRes = await supabase.from("devices").select().eq("device_id", alert["device_id"]).maybeSingle();
          if (devRes != null) {
            candidateUrl = devRes["picture_url"] ?? devRes["image_url"] ?? devRes["last_image_url"];
          }
        }

        if (candidateUrl != null && candidateUrl.isNotEmpty) {
          if (mounted) {
            setState(() {
              _imageUrl = candidateUrl;
              _loadingImage = false;
            });
            return;
          }
        }
      }

      final List<FileObject> files = await supabase.storage.from('photos').list(
        path: '',
        searchOptions: const SearchOptions(
          sortBy: SortBy(column: 'created_at', order: 'desc'),
          limit: 1,
        ),
      );

      if (files.isNotEmpty) {
        final String publicUrl = supabase.storage.from('photos').getPublicUrl(files.first.name);
        if (mounted) {
          setState(() {
            _imageUrl = publicUrl;
            _loadingImage = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingImage = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
              ),
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

  @override
  Widget build(BuildContext context) {
    final alert = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (alert == null) {
      return const NexusScaffold(title: Text("Détail"), body: Center(child: Text("Alerte introuvable")));
    }

    final date = DateTime.parse(alert["created_at"]);

    return NexusScaffold(
      title: Text(
        "Alerte",
        style: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white : const Color(0xFF1A1A1A)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: (_imageUrl != null) ? () => _showImagePreview(context, _imageUrl!) : null,
              child: Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _loadingImage 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : (_imageUrl != null)
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        )
                      : _buildFallbackImage(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoItem("Événement", alert["message"] ?? "Alerte détectée", isDark),
                      _infoItem("Module", alert["device_name"] ?? "MOD1", isDark),
                    ],
                  ),
                  const Divider(height: 32, color: Colors.black12),
                  Row(
                    children: [
                      _infoItem("Date", "${date.day}/${date.month}/${date.year}", isDark),
                      _infoItem("Heure", "${date.hour}:${date.minute.toString().padLeft(2, '0')}", isDark),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      minimumSize: const Size(0, 65),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('tel:17');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D8D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 65),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 8,
                      shadowColor: const Color(0xFFFF4D8D).withValues(alpha: 0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk_rounded, size: 22),
                        SizedBox(width: 8),
                        Text("SOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Opacity(
          opacity: 0.3,
          child: Image.asset('assets/images/nexus_roue.png', width: 120),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
