// lib/main.dart
import 'package:flutter/material.dart';
import 'package:nexus_app/screens/alert_history_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://theghvwkzakcwtehrdya.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZWdodndremFrY3d0ZWhyZHlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0MzYzOTksImV4cCI6MjA3OTAxMjM5OX0.U_TOsAkRDUZSVp_VAU3w8bJVtCLOgdAIiKp1-Y08X8A',
  );
  
  // Initialize notification service
  await AlertNotificationService().initialize();

  // Force reconnexion si inactivité > 30 jours
  await SessionService.enforceReLoginIfNeeded();
  
  runApp(const NexusApp());
}

final _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuthed = Supabase.instance.client.auth.currentUser != null;
    const protected = {
      '/pairing',
      '/dashboard',
      '/alerts',
      '/account',
      '/devices',
      '/settings',
    };
    final isProtected = protected.contains(state.matchedLocation);
    if (isProtected && !isAuthed) return '/auth';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/pairing',
      builder: (context, state) => const PairingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/devices',
      builder: (context, state) => const DevicesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthLoginUser(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const AuthSignupUser(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertHistoryScreen(),
    ),

  ],

);



class NexusApp extends StatefulWidget {
  const NexusApp({super.key});

  @override
  State<NexusApp> createState() => _NexusAppState();
}

class _NexusAppState extends State<NexusApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Premier marquage "actif" au lancement
    SessionService.markActiveNow();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await SettingsService.getThemeMode();
    if (!mounted) return;
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.markActiveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NEXUS',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
    );
  }
}
