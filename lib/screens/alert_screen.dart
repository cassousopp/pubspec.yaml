import 'package:flutter/material.dart';
import 'package:nexus_app/widgets/nexus_scaffold.dart';
import 'package:nexus_app/utils/supabase_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  List<Map<String, dynamic>> allPhotos = [];
  Set<String> hiddenPhotos = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadHiddenAndPhotos();
  }

  Future<void> _loadHiddenAndPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    hiddenPhotos = Set<String>.from(prefs.getStringList('hidden_photos') ?? []);
    await loadPhotos();
  }

  Future<void> loadPhotos() async {
    try {
      debugPrint('🔄 Chargement des photos depuis le bucket: photos');
      final storagePhotos = await SupabaseStorageHelper.getPhotosFromBucket();

      if (mounted) {
        setState(() {
          // On ne garde que les photos qui ne sont pas dans la liste des photos masquées
          allPhotos = storagePhotos.where((p) => !hiddenPhotos.contains(p['name'])).toList();
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des photos: $e');
      if (mounted) {
        setState(() {
          allPhotos = [];
          loading = false;
        });
      }
    }
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
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  ),
                ),
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

  Future<void> _hidePhoto(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    hiddenPhotos.add(fileName);
    await prefs.setStringList('hidden_photos', hiddenPhotos.toList());
    
    if (mounted) {
      setState(() {
        allPhotos.removeWhere((p) => p['name'] == fileName);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo supprimée")),
      );
    }
  }

  void _confirmHide(String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("Supprimer la photo ?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Êtes-vous sûr de vouloir supprimer cette photo ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _hidePhoto(fileName);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NexusScaffold(
      title: Text(
        "Photos",
        style: TextStyle(
          fontSize: 24, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white : const Color(0xFF1A1A1A)
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : allPhotos.isEmpty
              ? const Center(child: Text("Aucune photo disponible"))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: allPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = allPhotos[index];
                    return _buildPhotoCard(photo);
                  },
                ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo) {
    final imageUrl = photo["url"] as String? ?? '';
    final fileName = photo["name"] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: imageUrl.isNotEmpty ? () => _showImagePreview(imageUrl) : null,
      onLongPress: () => _confirmHide(fileName),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFFFE4ED), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                )
              else
                const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              
              // Overlay Nom du fichier
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(180), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
