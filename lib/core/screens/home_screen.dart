import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/pwa_install_prompt.dart';
import '../widgets/pwa_update_banner.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/sync_progress_indicator.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;

  const HomeScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show offline indicator when offline (web only)
          if (kIsWeb) const OfflineIndicator(),
          // Show sync progress (web only)
          if (kIsWeb) const SyncProgressIndicator(),
          // Show update banner when update is available (web only)
          if (kIsWeb) const PWAUpdateBanner(),
          // Main content
          Expanded(child: child),
          // Show install prompt at bottom (web only)
          if (kIsWeb) const PWAInstallPrompt(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'Каталог',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.park),
            label: 'Градина',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Напомняния',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Скенер',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/garden')) {
      return 1;
    }
    if (location.startsWith('/reminders')) {
      return 2;
    }
    if (location.startsWith('/scanner')) {
      return 3;
    }
    return 0; // Default to catalog
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/garden');
        break;
      case 2:
        GoRouter.of(context).go('/reminders');
        break;
      case 3:
        GoRouter.of(context).go('/scanner');
        break;
    }
  }
}