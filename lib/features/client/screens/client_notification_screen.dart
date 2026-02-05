import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification.dart';
import '../providers/client_provider.dart';

class ClientNotificationScreen extends StatefulWidget {
  const ClientNotificationScreen({super.key});

  @override
  State<ClientNotificationScreen> createState() => _ClientNotificationScreenState();
}

class _ClientNotificationScreenState extends State<ClientNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClientData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Нотификации'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showNotificationSettings(),
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = clientProvider.notifications;
          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              if (unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Имате $unreadCount непрочетени нотификации',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _markAllAsRead(clientProvider),
                        child: Text(
                          'Маркирай всички',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(notifications, clientProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Няма налични нотификации',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ще получавате нотификации за грижи за вашите растения',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications, ClientProvider clientProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, clientProvider);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, ClientProvider clientProvider) {
    final isOverdue = notification.dueDate.isBefore(DateTime.now()) && !notification.isCompleted;
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Card(
      elevation: notification.isRead ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification, clientProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isOverdue ? Colors.red : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(notification.dueDate),
                          style: TextStyle(
                            color: isOverdue ? Colors.red : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Text(
                            'ПРЕСРОЧНО',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.zoneName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Зона: ${notification.zoneName}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'watering':
        return Icons.water_drop;
      case 'fertilizing':
        return Icons.grass;
      case 'pruning':
        return Icons.content_cut;
      case 'pest_control':
        return Icons.bug_report;
      case 'seasonal':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'watering':
        return Colors.blue;
      case 'fertilizing':
        return Colors.green;
      case 'pruning':
        return Colors.orange;
      case 'pest_control':
        return Colors.red;
      case 'seasonal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Сега';
      } else if (difference.inHours > 0) {
        return 'След ${difference.inHours} ч.';
      } else {
        return 'Преди ${difference.inHours.abs()} ч.';
      }
    } else if (difference.inDays == 1) {
      return 'Утре';
    } else if (difference.inDays == -1) {
      return 'Вчера';
    } else if (difference.inDays > 0) {
      return 'След ${difference.inDays} дни';
    } else {
      return 'Преди ${difference.inDays.abs()} дни';
    }
  }

  void _handleNotificationTap(AppNotification notification, ClientProvider clientProvider) {
    if (!notification.isRead) {
      clientProvider.markNotificationAsRead(notification.id);
    }
    
    // Navigate to relevant screen based on notification type
    switch (notification.type) {
      case 'watering':
      case 'fertilizing':
      case 'pruning':
        context.push('/client/plants');
        break;
      case 'pest_control':
        context.push('/client/plants');
        break;
      default:
        // Stay on current screen
        break;
    }
  }

  void _markAllAsRead(ClientProvider clientProvider) {
    for (final notification in clientProvider.notifications.where((n) => !n.isRead)) {
      clientProvider.markNotificationAsRead(notification.id);
    }
  }

  void _showNotificationSettings() {
    final clientProvider = context.read<ClientProvider>();
    final client = clientProvider.currentClient;
    
    if (client == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Настройки на нотификации'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationSettingTile(
                  title: 'Напомняния за поливане',
                  subtitle: 'Получавайте напомняния кога да поливате растенията',
                  value: client.wateringNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      clientProvider.updateNotificationSettings(
                        wateringEnabled: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildNotificationSettingTile(
                  title: 'Напомняния за торене',
                  subtitle: 'Получавайте напомняния кога да торите растенията',
                  value: client.fertilizingNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      clientProvider.updateNotificationSettings(
                        fertilizingEnabled: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildNotificationSettingTile(
                  title: 'Напомняния за подрязване',
                  subtitle: 'Получавайте напомняния кога да подрязвате растенията',
                  value: client.pruningNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      clientProvider.updateNotificationSettings(
                        pruningEnabled: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Честота на напомнянията:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReminderSetting(
                  title: 'Поливане',
                  days: client.wateringReminderDays,
                  onChanged: (value) {
                    clientProvider.updateNotificationSettings(
                      wateringReminderDays: value,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildReminderSetting(
                  title: 'Торене',
                  days: client.fertilizingReminderDays,
                  onChanged: (value) {
                    clientProvider.updateNotificationSettings(
                      fertilizingReminderDays: value,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildReminderSetting(
                  title: 'Подрязване',
                  days: client.pruningReminderDays,
                  onChanged: (value) {
                    clientProvider.updateNotificationSettings(
                      pruningReminderDays: value,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Затвори'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildReminderSetting({
    required String title,
    required int days,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        DropdownButton<int>(
          value: days,
          items: [
            const DropdownMenuItem(value: 1, child: Text('Всеки ден')),
            const DropdownMenuItem(value: 3, child: Text('На 3 дни')),
            const DropdownMenuItem(value: 7, child: Text('Седмично')),
            const DropdownMenuItem(value: 14, child: Text('На 2 седмици')),
            const DropdownMenuItem(value: 30, child: Text('Месечно')),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }
}