import 'package:flutter/foundation.dart';
import 'offline_sync_service.dart';
import 'pwa_service.dart';

/// Mixin for services that need offline sync capabilities
mixin OfflineSyncMixin {
  final _syncService = OfflineSyncService();
  final _pwaService = PWAService();

  /// Execute an operation with offline support
  /// If online, executes immediately. If offline, queues for later sync.
  Future<T> executeWithOfflineSupport<T>({
    required Future<T> Function() onlineOperation,
    required OfflineChange offlineChange,
    required T offlineResult,
  }) async {
    if (_pwaService.isOnline) {
      try {
        // Try to execute online
        return await onlineOperation();
      } catch (e) {
        if (kDebugMode) {
          print('[OfflineSync] Online operation failed, queuing: $e');
        }
        // If online operation fails, queue for later
        await _syncService.queueChange(offlineChange);
        return offlineResult;
      }
    } else {
      // Queue for later sync
      await _syncService.queueChange(offlineChange);
      if (kDebugMode) {
        print('[OfflineSync] Offline, queuing change: ${offlineChange.entityType}');
      }
      return offlineResult;
    }
  }

  /// Create an offline change for a create operation
  OfflineChange createOfflineChange({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) {
    return OfflineChange(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      type: ChangeType.create,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  /// Create an offline change for an update operation
  OfflineChange updateOfflineChange({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) {
    return OfflineChange(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      type: ChangeType.update,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  /// Create an offline change for a delete operation
  OfflineChange deleteOfflineChange({
    required String entityType,
    required String entityId,
  }) {
    return OfflineChange(
      id: '${DateTime.now().millisecondsSinceEpoch}_$entityId',
      type: ChangeType.delete,
      entityType: entityType,
      entityId: entityId,
      data: {},
      timestamp: DateTime.now(),
    );
  }
}
