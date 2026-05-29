// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nexus_app/firebase_options.dart';
import 'package:nexus_app/screens/alert_detail_screen.dart';
import 'package:nexus_app/screens/alert_history_screen.dart';
import 'package:nexus_app/screens/alert_screen.dart'; // Pour l'onglet Photos
import 'package:nexus_app/screens/auth/auth_login_user.dart';
import 'package:nexus_app/screens/auth/auth_signup_user.dart';
import 'package:nexus_app/screens/account_screen.dart';
import 'package:nexus_app/screens/dashboard_screen.dart';
import 'package:nexus_app/screens/devices_screen.dart';
import 'package:nexus_app/screens/settings_screen.dart';
import 'package:nexus_app/screens/tutorial_screen.dart';
import 'package:nexus_app/services/alert_notification_service.dart';
import 'package:nexus_app/services/session_service.dart';
import 'package:nexus_app/services/settings_service.dart';
import 'package:nexus_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/pairing_screen.dart';

// Classe pour gérer le thème globalement
class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final mode = await SettingsService.getThemeMode();
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    await SettingsService.setThemeMode(mode);
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }
}

final themeManager = ThemeManager();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.markActiveNow();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: 'https://theghvwkzakcwtehrdya.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZWdodndremFrY3d0ZWhyZHlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MzYzOTksImV4cCI6MjA3OTAxMjM5OX0.U_TOsAkRDUZSVp_VAU3w8bJVtCLOgdAIiKp1-Y08X8A',
  );
  
  await AlertNotificationService().initialize();
  await SessionService.enforceReLoginIfNeeded();
  await themeManager.loadTheme();
  SessionService.markActiveNow();
  
  runApp(const NexusApp());
}

final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuthed = Supabase.instance.client.auth.currentUser != null;
    const protected = {
      '/pairing',
      '/dashboard',
      '/photos',
      '/history',
      '/account',
      '/devices',
      '/settings',
      '/alert-detail',
    };
    final isProtected = protected.contains(state.matchedLocation);
    if (isProtected && !isAuthed) return '/auth';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash', builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login', builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/pairing', builder: (context, state) => const PairingScreen(),
    ),
    GoRoute(
      path: '/dashboard', builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/account', builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/devices', builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/settings', builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auth', builder: (context, state) => const AuthLoginUser(),
    ),
    GoRoute(
      path: '/signup', builder: (context, state) => const AuthSignupUser(),
    ),
    GoRoute(
      path: '/tutorial', builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/photos', builder: (context, state) => const AlertScreen(),
    ),
    GoRoute(
      path: '/history', builder: (context, state) => const AlertHistoryScreen(),
    ),
    GoRoute(
      path: '/alert-detail', builder: (context, state) => const AlertDetailScreen(),
    ),
  ],
);

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'NexusApp',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeManager.themeMode,
        );
      },
    );
  }
}
