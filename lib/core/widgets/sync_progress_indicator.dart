import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

/// Widget that shows sync progress
class SyncProgressIndicator extends StatefulWidget {
  const SyncProgressIndicator({super.key});

  @override
  State<SyncProgressIndicator> createState() => _SyncProgressIndicatorState();
}

class _SyncProgressIndicatorState extends State<SyncProgressIndicator> {
  final _syncService = OfflineSyncService();
  SyncProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _syncService.syncProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
        
        // Clear progress after completion
        if (progress.status == SyncProgressStatus.completed ||
            progress.status == SyncProgressStatus.failed) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _currentProgress = null;
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProgress == null ||
        _currentProgress!.status == SyncProgressStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _getBackgroundColor(),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMessage(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_currentProgress!.status == SyncProgressStatus.syncing &&
                    _currentProgress!.total > 0) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _currentProgress!.progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_currentProgress!.status) {
      case SyncProgressStatus.syncing:
        return Colors.blue.shade700;
      case SyncProgressStatus.completed:
        return Colors.green.shade700;
      case SyncProgressStatus.failed:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildIcon() {
    switch (_currentProgress!.status) {
      case SyncProgressStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncProgressStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.white, size: 20);
      case SyncProgressStatus.failed:
        return const Icon(Icons.error, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.sync, color: Colors.white, size: 20);
    }
  }

  String _getMessage() {
    switch (_currentProgress!.status) {
      case SyncProgressStatus.syncing:
        if (_currentProgress!.total > 0) {
          return 'Синхронизиране: ${_currentProgress!.completed}/${_currentProgress!.total}';
        }
        return 'Синхронизиране на данни...';
      case SyncProgressStatus.completed:
        return 'Синхронизацията завърши успешно';
      case SyncProgressStatus.failed:
        return 'Грешка при синхронизация: ${_currentProgress!.error ?? "Неизвестна грешка"}';
      default:
        return '';
    }
  }
}
