import 'package:flutter/material.dart';
import '../services/pwa_service.dart';

/// Widget that shows PWA update notification
class PWAUpdateBanner extends StatefulWidget {
  const PWAUpdateBanner({super.key});

  @override
  State<PWAUpdateBanner> createState() => _PWAUpdateBannerState();
}

class _PWAUpdateBannerState extends State<PWAUpdateBanner> {
  final _pwaService = PWAService();
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _pwaService.updateAvailableStream.listen((isAvailable) {
      if (mounted) {
        setState(() {
          _showBanner = isAvailable;
        });
      }
    });
    
    // Check initial state
    _showBanner = _pwaService.isUpdateAvailable;
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      leading: Icon(
        Icons.system_update,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      content: Text(
        'Налична е нова версия на приложението',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showBanner = false;
            });
          },
          child: const Text('По-късно'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _pwaService.updateServiceWorker();
          },
          child: const Text('Обнови'),
        ),
      ],
    );
  }
}
