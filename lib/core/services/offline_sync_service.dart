import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'pwa_service.dart';

/// Service for managing offline data synchronization
/// Handles queuing offline changes and syncing when connection is restored
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final _pwaService = PWAService();
  final _syncController = StreamController<SyncProgress>.broadcast();
  
  Stream<SyncProgress> get syncProgressStream => _syncController.stream;
  
  bool _isSyncing = false;
  late Box<Map<dynamic, dynamic>> _pendingChangesBox;
  late Box<Map<dynamic, dynamic>> _conflictsBox;

  /// Initialize offline sync service
  Future<void> init() async {
    // Open Hive boxes for pending changes and conflicts
    _pendingChangesBox = await Hive.openBox('pending_changes');
    _conflictsBox = await Hive.openBox('sync_conflicts');

    // Listen to online status changes
    _pwaService.onlineStatusStream.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        // Automatically sync when coming online
        syncPendingChanges();
      }
    });

    // Listen to sync status from service worker
    _pwaService.syncStatusStream.listen((status) {
      if (status == SyncStatus.syncing) {
        syncPendingChanges();
      }
    });
  }

  /// Queue a change for offline sync
  Future<void> queueChange(OfflineChange change) async {
    final changeData = change.toMap();
    await _pendingChangesBox.add(changeData);
    
    if (kDebugMode) {
      print('[OfflineSync] Queued change: ${change.type} - ${change.entityType}');
    }

    // Try to sync immediately if online
    if (_pwaService.isOnline && !_isSyncing) {
      syncPendingChanges();
    }
  }

  /// Get all pending changes
  Future<List<OfflineChange>> getPendingChanges() async {
    final changes = <OfflineChange>[];
    for (var i = 0; i < _pendingChangesBox.length; i++) {
      final changeData = _pendingChangesBox.getAt(i);
      if (changeData != null) {
        changes.add(OfflineChange.fromMap(Map<String, dynamic>.from(changeData)));
      }
    }
    return changes;
  }

  /// Sync all pending changes
  Future<void> syncPendingChanges() async {
    if (_isSyncing || !_pwaService.isOnline) {
      return;
    }

    _isSyncing = true;
    _syncController.add(SyncProgress(
      status: SyncProgressStatus.syncing,
      total: _pendingChangesBox.length,
      completed: 0,
    ));

    try {
      final changes = await getPendingChanges();
      int completed = 0;

      for (var i = 0; i < changes.length; i++) {
        final change = changes[i];
        
        try {
          // Apply the change
          final result = await _applyChange(change);
          
          if (result.success) {
            // Remove from pending changes
            await _pendingChangesBox.deleteAt(i);
            completed++;
            
            _syncController.add(SyncProgress(
              status: SyncProgressStatus.syncing,
              total: changes.length,
              completed: completed,
            ));
          } else if (result.hasConflict) {
            // Store conflict for manual resolution
            await _storeConflict(change, result.serverData);
            await _pendingChangesBox.deleteAt(i);
            completed++;
          }
        } catch (e) {
          if (kDebugMode) {
            print('[OfflineSync] Error syncing change: $e');
          }
          // Keep the change in queue for retry
        }
      }

      _syncController.add(SyncProgress(
        status: SyncProgressStatus.completed,
        total: changes.length,
        completed: completed,
      ));

      if (kDebugMode) {
        print('[OfflineSync] Sync completed: $completed/${changes.length}');
      }
    } catch (e) {
      _syncController.add(SyncProgress(
        status: SyncProgressStatus.failed,
        error: e.toString(),
      ));
      
      if (kDebugMode) {
        print('[OfflineSync] Sync failed: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Apply a single change to the server
  Future<SyncResult> _applyChange(OfflineChange change) async {
    // This is a placeholder - actual implementation would call the appropriate service
    // based on the entity type and change type
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 100));
      
      // In real implementation, this would:
      // 1. Call the appropriate API endpoint
      // 2. Check for conflicts (compare timestamps)
      // 3. Return success or conflict information
      
      return SyncResult(success: true);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Store a conflict for manual resolution
  Future<void> _storeConflict(OfflineChange localChange, Map<String, dynamic>? serverData) async {
    final conflict = {
      'localChange': localChange.toMap(),
      'serverData': serverData,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _conflictsBox.add(conflict);
    
    if (kDebugMode) {
      print('[OfflineSync] Conflict stored: ${localChange.entityType} ${localChange.entityId}');
    }
  }

  /// Get all unresolved conflicts
  Future<List<SyncConflict>> getConflicts() async {
    final conflicts = <SyncConflict>[];
    for (var i = 0; i < _conflictsBox.length; i++) {
      final conflictData = _conflictsBox.getAt(i);
      if (conflictData != null) {
        conflicts.add(SyncConflict.fromMap(Map<String, dynamic>.from(conflictData)));
      }
    }
    return conflicts;
  }

  /// Resolve a conflict by choosing local or server version
  Future<void> resolveConflict(int conflictIndex, ConflictResolution resolution) async {
    final conflictData = _conflictsBox.getAt(conflictIndex);
    if (conflictData == null) return;

    final conflict = SyncConflict.fromMap(Map<String, dynamic>.from(conflictData));

    if (resolution == ConflictResolution.useLocal) {
      // Re-queue the local change with force flag
      await queueChange(conflict.localChange.copyWith(forceUpdate: true));
    } else if (resolution == ConflictResolution.useServer) {
      // Server version is already applied, just remove conflict
    }

    // Remove the conflict
    await _conflictsBox.deleteAt(conflictIndex);
    
    if (kDebugMode) {
      print('[OfflineSync] Conflict resolved: $resolution');
    }
  }

  /// Clear all pending changes (use with caution)
  Future<void> clearPendingChanges() async {
    await _pendingChangesBox.clear();
  }

  /// Clear all conflicts
  Future<void> clearConflicts() async {
    await _conflictsBox.clear();
  }

  /// Dispose resources
  void dispose() {
    _syncController.close();
  }
}

/// Represents a change made while offline
class OfflineChange {
  final String id;
  final ChangeType type;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool forceUpdate;

  OfflineChange({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.timestamp,
    this.forceUpdate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'forceUpdate': forceUpdate,
    };
  }

  factory OfflineChange.fromMap(Map<String, dynamic> map) {
    return OfflineChange(
      id: map['id'] as String,
      type: ChangeType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ChangeType.update,
      ),
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
      forceUpdate: map['forceUpdate'] as bool? ?? false,
    );
  }

  OfflineChange copyWith({
    String? id,
    ChangeType? type,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? forceUpdate,
  }) {
    return OfflineChange(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      forceUpdate: forceUpdate ?? this.forceUpdate,
    );
  }
}

/// Type of change
enum ChangeType {
  create,
  update,
  delete,
}

/// Result of syncing a change
class SyncResult {
  final bool success;
  final bool hasConflict;
  final Map<String, dynamic>? serverData;
  final String? error;

  SyncResult({
    required this.success,
    this.hasConflict = false,
    this.serverData,
    this.error,
  });
}

/// Represents a sync conflict
class SyncConflict {
  final OfflineChange localChange;
  final Map<String, dynamic>? serverData;
  final DateTime timestamp;

  SyncConflict({
    required this.localChange,
    this.serverData,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'localChange': localChange.toMap(),
      'serverData': serverData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      localChange: OfflineChange.fromMap(
        Map<String, dynamic>.from(map['localChange'] as Map),
      ),
      serverData: map['serverData'] != null
          ? Map<String, dynamic>.from(map['serverData'] as Map)
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// Conflict resolution strategy
enum ConflictResolution {
  useLocal,
  useServer,
  merge,
}

/// Sync progress information
class SyncProgress {
  final SyncProgressStatus status;
  final int total;
  final int completed;
  final String? error;

  SyncProgress({
    required this.status,
    this.total = 0,
    this.completed = 0,
    this.error,
  });

  double get progress => total > 0 ? completed / total : 0.0;
}

/// Sync progress status
enum SyncProgressStatus {
  idle,
  syncing,
  completed,
  failed,
}
