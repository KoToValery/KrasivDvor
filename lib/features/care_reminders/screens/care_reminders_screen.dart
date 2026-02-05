import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/care_reminder.dart';
import '../../../models/plant_instance.dart';
import '../providers/care_reminder_provider.dart';
import 'reminder_detail_screen.dart';

class CareRemindersScreen extends StatefulWidget {
  final String clientId;
  
  const CareRemindersScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<CareRemindersScreen> createState() => _CareRemindersScreenState();
}

class _CareRemindersScreenState extends State<CareRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CareReminderProvider>().loadReminders(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напомняния за грижи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CareReminderProvider>().loadReminders(widget.clientId);
            },
          ),
        ],
      ),
      body: Consumer<CareReminderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Грешка: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadReminders(widget.clientId);
                    },
                    child: const Text('Опитай отново'),
                  ),
                ],
              ),
            );
          }

          if (provider.reminders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Няма активни напомняния',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group reminders by date
          final groupedReminders = _groupRemindersByDate(provider.reminders);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedReminders.length,
            itemBuilder: (context, index) {
              final entry = groupedReminders.entries.elementAt(index);
              final date = entry.key;
              final reminders = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatDateHeader(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...reminders.map((reminder) => _buildReminderCard(context, reminder)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, CareReminder reminder) {
    final isOverdue = reminder.scheduledDate.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReminderDetailScreen(
                reminder: reminder,
                clientId: widget.clientId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCareTypeIcon(reminder.careType),
                    color: isOverdue ? Colors.red : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCareTypeLabel(reminder.careType),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(reminder.scheduledDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    const Chip(
                      label: Text('Просрочено'),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reminder.instructions,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPostponeDialog(context, reminder),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Отложи'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _completeReminder(context, reminder),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Завърши'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<CareReminder>> _groupRemindersByDate(List<CareReminder> reminders) {
    final grouped = <DateTime, List<CareReminder>>{};
    
    for (final reminder in reminders) {
      final date = DateTime(
        reminder.scheduledDate.year,
        reminder.scheduledDate.month,
        reminder.scheduledDate.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(reminder);
    }
    
    // Sort by date
    final sortedKeys = grouped.keys.toList()..sort();
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date == today) {
      return 'Днес';
    } else if (date == tomorrow) {
      return 'Утре';
    } else if (date.isBefore(today)) {
      return 'Просрочени';
    } else {
      return DateFormat('d MMMM, EEEE', 'bg').format(date);
    }
  }

  IconData _getCareTypeIcon(CareType careType) {
    switch (careType) {
      case CareType.watering:
        return Icons.water_drop;
      case CareType.fertilizing:
        return Icons.grass;
      case CareType.pruning:
        return Icons.content_cut;
      case CareType.weeding:
        return Icons.cleaning_services;
      case CareType.mulching:
        return Icons.layers;
      case CareType.pestControl:
        return Icons.bug_report;
      case CareType.diseaseControl:
        return Icons.medical_services;
      case CareType.other:
        return Icons.more_horiz;
    }
  }

  String _getCareTypeLabel(CareType careType) {
    switch (careType) {
      case CareType.watering:
        return 'Поливане';
      case CareType.fertilizing:
        return 'Торене';
      case CareType.pruning:
        return 'Подрязване';
      case CareType.weeding:
        return 'Плевене';
      case CareType.mulching:
        return 'Мулчиране';
      case CareType.pestControl:
        return 'Контрол на вредители';
      case CareType.diseaseControl:
        return 'Контрол на болести';
      case CareType.other:
        return 'Други грижи';
    }
  }

  void _showPostponeDialog(BuildContext context, CareReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отложи напомнянето'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1 час'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, reminder, const Duration(hours: 1));
              },
            ),
            ListTile(
              title: const Text('3 часа'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, reminder, const Duration(hours: 3));
              },
            ),
            ListTile(
              title: const Text('1 ден'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, reminder, const Duration(days: 1));
              },
            ),
            ListTile(
              title: const Text('3 дни'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, reminder, const Duration(days: 3));
              },
            ),
            ListTile(
              title: const Text('1 седмица'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, reminder, const Duration(days: 7));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
        ],
      ),
    );
  }

  void _postponeReminder(BuildContext context, CareReminder reminder, Duration delay) {
    context.read<CareReminderProvider>().postponeReminder(reminder.id, delay);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Напомнянето е отложено'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _completeReminder(BuildContext context, CareReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завърши грижата'),
        content: const Text('Сигурни ли сте, че сте завършили тази грижа?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CareReminderProvider>().completeReminder(reminder.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Грижата е завършена'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Завърши'),
          ),
        ],
      ),
    );
  }
}