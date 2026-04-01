import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static const _kLastActiveAtMs = 'last_active_at_ms';

  static Future<void> markActiveNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastActiveAtMs, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> shouldForceReLogin({
    Duration inactivity = const Duration(days: 30),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastActiveAtMs);
    if (last == null) return false;

    final lastActive = DateTime.fromMillisecondsSinceEpoch(last);
    return DateTime.now().difference(lastActive) > inactivity;
  }

  static Future<void> enforceReLoginIfNeeded() async {
    final should = await shouldForceReLogin();
    if (!should) return;

    // Force reconnexion après inactivité prolongée.
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastActiveAtMs);
  }
}

