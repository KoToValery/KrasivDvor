import 'package:flutter/material.dart';
import '../services/pwa_service.dart';

/// Widget that shows PWA install prompt
class PWAInstallPrompt extends StatefulWidget {
  const PWAInstallPrompt({super.key});

  @override
  State<PWAInstallPrompt> createState() => _PWAInstallPromptState();
}

class _PWAInstallPromptState extends State<PWAInstallPrompt> {
  final _pwaService = PWAService();
  bool _showPrompt = false;

  @override
  void initState() {
    super.initState();
    _pwaService.installPromptStream.listen((isInstallable) {
      if (mounted) {
        setState(() {
          _showPrompt = isInstallable;
        });
      }
    });
    
    // Check initial state
    _showPrompt = _pwaService.isInstallable;
  }

  @override
  Widget build(BuildContext context) {
    if (!_showPrompt) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.install_mobile,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Инсталирайте приложението',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Добавете към началния екран за бърз достъп',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _showPrompt = false;
              });
            },
            child: const Text('По-късно'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final installed = await _pwaService.showInstallPrompt();
              if (installed && mounted) {
                setState(() {
                  _showPrompt = false;
                });
              }
            },
            child: const Text('Инсталирай'),
          ),
        ],
      ),
    );
  }
}
