import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus_app/theme/app_theme.dart';
import 'package:nexus_app/widgets/nexus_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NexusScaffold extends StatelessWidget {
  const NexusScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = true,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: title,
        actions: actions,
      ),
      drawer: showDrawer ? _NexusDrawer() : null,
      body: NexusBackground(child: SafeArea(child: body)),
    );
  }
}

class _NexusDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    Widget item({
      required String label,
      required IconData icon,
      required String route,
    }) {
      final selected = location == route;
      return ListTile(
        leading: Icon(icon,
            color: selected ? AppTheme.secondary : Colors.black54),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.secondary : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      );
    }

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: NexusBackground(
        child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Hero(
              tag: 'logo',
              child: Image.asset("assets/images/logo_nexus.png", height: 70),
            ),
            const SizedBox(height: 24),
            item(label: "Tableau de bord", icon: Icons.dashboard_rounded, route: "/dashboard"),
            item(label: "Mon compte", icon: Icons.person_rounded, route: "/account"),
            item(label: "Appareils", icon: Icons.devices_rounded, route: "/devices"),
            item(label: "Paramètres", icon: Icons.settings_rounded, route: "/settings"),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                "Déconnexion",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }
}

