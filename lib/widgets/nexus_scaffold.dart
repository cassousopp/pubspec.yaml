import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NexusScaffold extends StatelessWidget {
  const NexusScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: title,
        actions: actions,
        automaticallyImplyLeading: false, 
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1933) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.bar_chart_rounded, "Accueil", "/dashboard", location == "/dashboard"),
            _navItem(context, Icons.radio_button_checked_rounded, "Photos", "/photos", location == "/photos"),
            _navItem(context, Icons.menu_rounded, "Historique", "/history", location == "/history"),
            _navItem(context, Icons.person_outline_rounded, "Profil", "/account", location == "/account"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route, bool active) {
    final color = active ? const Color(0xFF6366F1) : Colors.grey.shade400;
    return GestureDetector(
      onTap: () {
        if (!active) {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
