import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Service for managing PWA-specific functionality
/// Handles install prompts, service worker communication, and offline status
class PWAService {
  static final PWAService _instance = PWAService._internal();
  factory PWAService() => _instance;
  PWAService._internal();

  final _installPromptController = StreamController<bool>.broadcast();
  final _updateAvailableController = StreamController<bool>.broadcast();
  final _onlineStatusController = StreamController<bool>.broadcast();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  Stream<bool> get installPromptStream => _installPromptController.stream;
  Stream<bool> get updateAvailableStream => _updateAvailableController.stream;
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  bool _isInstallable = false;
  bool _isOnline = true;
  bool _isUpdateAvailable = false;
  js.JsObject? _deferredPrompt;

  bool get isInstallable => _isInstallable;
  bool get isOnline => _isOnline;
  bool get isUpdateAvailable => _isUpdateAvailable;

  /// Initialize PWA service
  Future<void> init() async {
    if (kIsWeb) {
      _setupInstallPromptListener();
      _setupOnlineStatusListener();
      _setupServiceWorkerListener();
      _checkOnlineStatus();
    }
  }

  /// Setup listener for install prompt
  void _setupInstallPromptListener() {
    // Check if deferredPrompt is available
    try {
      if (js.context.hasProperty('deferredPrompt')) {
        _deferredPrompt = js.context['deferredPrompt'];
        _isInstallable = true;
        _installPromptController.add(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PWA] Error checking deferred prompt: $e');
      }
    }

    // Listen for future install prompts
    html.window.addEventListener('beforeinstallprompt', (event) {
      event.preventDefault();
      try {
        _deferredPrompt = js.JsObject.fromBrowserObject(event);
        _isInstallable = true;
        _installPromptController.add(true);
        // Store in window for later use
        js.context['deferredPrompt'] = _deferredPrompt;
      } catch (e) {
        if (kDebugMode) {
          print('[PWA] Error storing deferred prompt: $e');
        }
      }
    });

    // Listen for app installed event
    html.window.addEventListener('appinstalled', (event) {
      _isInstallable = false;
      _deferredPrompt = null;
      _installPromptController.add(false);
      if (kDebugMode) {
        print('[PWA] App installed successfully');
      }
    });
  }

  /// Setup listener for online/offline status
  void _setupOnlineStatusListener() {
    html.window.addEventListener('online', (event) {
      _isOnline = true;
      _onlineStatusController.add(true);
      if (kDebugMode) {
        print('[PWA] Connection restored');
      }
      // Trigger background sync when coming online
      _triggerBackgroundSync();
    });

    html.window.addEventListener('offline', (event) {
      _isOnline = false;
      _onlineStatusController.add(false);
      if (kDebugMode) {
        print('[PWA] Connection lost');
      }
    });
  }

  /// Setup listener for service worker messages
  void _setupServiceWorkerListener() {
    if (html.window.navigator.serviceWorker != null) {
      html.window.navigator.serviceWorker!.addEventListener('message', (event) {
        final messageEvent = event as html.MessageEvent;
        final data = messageEvent.data;
        
        if (data is Map) {
          final type = data['type'];
          
          switch (type) {
            case 'UPDATE_AVAILABLE':
              _isUpdateAvailable = true;
              _updateAvailableController.add(true);
              if (kDebugMode) {
                print('[PWA] Update available');
              }
              break;
            case 'SYNC_STARTED':
              _syncStatusController.add(SyncStatus.syncing);
              if (kDebugMode) {
                print('[PWA] Sync started');
              }
              break;
            case 'SYNC_COMPLETED':
              _syncStatusController.add(SyncStatus.completed);
              if (kDebugMode) {
                print('[PWA] Sync completed');
              }
              break;
            case 'SYNC_FAILED':
              _syncStatusController.add(SyncStatus.failed);
              if (kDebugMode) {
                print('[PWA] Sync failed: ${data['error']}');
              }
              break;
          }
        }
      });
    }
  }

  /// Check current online status
  void _checkOnlineStatus() {
    _isOnline = html.window.navigator.onLine ?? true;
    _onlineStatusController.add(_isOnline);
  }

  /// Show install prompt to user
  Future<bool> showInstallPrompt() async {
    if (!kIsWeb || !_isInstallable || _deferredPrompt == null) {
      return false;
    }

    try {
      // Trigger the install prompt
      _deferredPrompt!.callMethod('prompt', []);
      
      // Wait for user choice
      final userChoice = await _deferredPrompt!.callMethod('userChoice', []);
      
      if (userChoice != null && userChoice['outcome'] == 'accepted') {
        if (kDebugMode) {
          print('[PWA] User accepted install prompt');
        }
        _isInstallable = false;
        _deferredPrompt = null;
        _installPromptController.add(false);
        return true;
      } else {
        if (kDebugMode) {
          print('[PWA] User dismissed install prompt');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PWA] Error showing install prompt: $e');
      }
    }
    
    return false;
  }

  /// Trigger service worker update
  Future<void> updateServiceWorker() async {
    if (!kIsWeb) return;

    try {
      final registration = await html.window.navigator.serviceWorker?.getRegistration();
      if (registration != null) {
        await registration.update();
        
        // Tell the new service worker to skip waiting
        final waiting = registration.waiting;
        if (waiting != null) {
          waiting.postMessage({'type': 'SKIP_WAITING'});
        }
        
        // Reload the page to activate new service worker
        html.window.location.reload();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PWA] Error updating service worker: $e');
      }
    }
  }

  /// Trigger background sync
  Future<void> _triggerBackgroundSync() async {
    if (!kIsWeb) return;

    try {
      final registration = await html.window.navigator.serviceWorker?.ready;
      if (registration != null) {
        // Request background sync
        await registration.sync?.register('sync-offline-data');
        if (kDebugMode) {
          print('[PWA] Background sync registered');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PWA] Error triggering background sync: $e');
      }
    }
  }

  /// Manually trigger sync
  Future<void> triggerSync() async {
    _syncStatusController.add(SyncStatus.syncing);
    await _triggerBackgroundSync();
  }

  /// Cache specific URLs for offline access
  Future<void> cacheUrls(List<String> urls) async {
    if (!kIsWeb) return;

    try {
      final controller = html.window.navigator.serviceWorker?.controller;
      if (controller != null) {
        controller.postMessage({
          'type': 'CACHE_URLS',
          'urls': urls,
        });
        if (kDebugMode) {
          print('[PWA] Caching ${urls.length} URLs');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PWA] Error caching URLs: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _installPromptController.close();
    _updateAvailableController.close();
    _onlineStatusController.close();
    _syncStatusController.close();
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}
