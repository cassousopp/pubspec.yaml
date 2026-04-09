import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseStorageHelper {
  // URL de base Supabase
  static const String supabaseUrl = 'https://theghvwkzakcwtehrdya.supabase.co';
  static const String bucketName = 'photos';

  static String getPublicPhotoUrl(String? fileName) {
    if (fileName == null || fileName.isEmpty) return '';
    
    // Générer l'URL publique du fichier
    return '$supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
  }

  /// Récupérer tous les fichiers du bucket photos
  static Future<List<Map<String, dynamic>>> getPhotosFromBucket() async {
    try {
      final client = Supabase.instance.client;
      print('📸 Tentative de chargement du bucket: $bucketName');
      
      // Récupérer les fichiers du bucket (racine)
      final files = await client.storage.from(bucketName).list(
        path: '',
        searchOptions: const SearchOptions(
          limit: 100,
          sortBy: SortBy(column: 'created_at', order: 'desc'),
        ),
      );
      print('📸 Files trouvés: ${files.length}');
      
      final photoFiles = files
          .where((f) => !f.name.startsWith('.') && (
                       f.name.toLowerCase().endsWith('.jpg') ||
                       f.name.toLowerCase().endsWith('.jpeg') ||
                       f.name.toLowerCase().endsWith('.png')))
          .toList();
      
      print('📸 Photos filtrées: ${photoFiles.length}');
      
      // Transformer en liste avec URLs
      return photoFiles.map((f) {
        // Correction robuste pour les dates qui peuvent être String ou DateTime
        DateTime parseDate(dynamic d) {
          if (d == null) return DateTime.now();
          if (d is DateTime) return d;
          return DateTime.tryParse(d.toString()) ?? DateTime.now();
        }

        final date = parseDate(f.createdAt ?? f.updatedAt);
        
        return {
          'name': f.name,
          'url': getPublicPhotoUrl(f.name),
          'id': f.name,
          'created_at': date.toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur Storage: $e');
      return [];
    }
  }

  static Future<String?> uploadPhotoToStorage(String fileName, Uint8List fileBytes) async {
    try {
      final client = Supabase.instance.client;
      await client.storage.from(bucketName).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return getPublicPhotoUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deletePhotoFromStorage(String fileName) async {
    try {
      final client = Supabase.instance.client;
      await client.storage.from(bucketName).remove([fileName]);
    } catch (e) {
      // Silencieusement échouer
    }
  }
}
