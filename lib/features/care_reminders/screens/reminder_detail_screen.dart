import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/care_reminder.dart';
import '../../../models/plant_instance.dart';
import '../providers/care_reminder_provider.dart';

class ReminderDetailScreen extends StatelessWidget {
  final CareReminder reminder;
  final String clientId;

  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = reminder.scheduledDate.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детайли на напомнянето'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Care type header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getCareTypeIcon(reminder.careType),
                      size: 48,
                      color: isOverdue ? Colors.red : Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCareTypeLabel(reminder.careType),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          if (isOverdue)
                            const Text(
                              'Просрочено',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scheduled date and time
            _buildInfoSection(
              context,
              'Планирана дата и час',
              DateFormat('d MMMM yyyy, HH:mm', 'bg').format(reminder.scheduledDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),

            // Instructions
            _buildInfoSection(
              context,
              'Инструкции',
              reminder.instructions,
              Icons.description,
            ),
            const SizedBox(height: 16),

            // Frequency
            _buildInfoSection(
              context,
              'Честота',
              _getFrequencyLabel(reminder.frequency),
              Icons.repeat,
            ),
            const SizedBox(height: 16),

            // Weather dependency
            if (reminder.weatherDependency.isWeatherDependent) ...[
              _buildInfoSection(
                context,
                'Зависимост от времето',
                _getWeatherDependencyLabel(reminder.weatherDependency),
                Icons.wb_sunny,
              ),
              const SizedBox(height: 16),
            ],

            // Created date
            _buildInfoSection(
              context,
              'Създадено на',
              DateFormat('d MMMM yyyy, HH:mm', 'bg').format(reminder.createdAt),
              Icons.info_outline,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPostponeDialog(context),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Отложи'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeReminder(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Завърши'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
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

  String _getFrequencyLabel(ReminderFrequency frequency) {
    final typeLabel = _getFrequencyTypeLabel(frequency.type);
    final adjustLabel = frequency.adjustForWeather ? ' (коригира се според времето)' : '';
    return '$typeLabel - на всеки ${frequency.intervalDays} дни$adjustLabel';
  }

  String _getFrequencyTypeLabel(FrequencyType type) {
    switch (type) {
      case FrequencyType.daily:
        return 'Ежедневно';
      case FrequencyType.weekly:
        return 'Седмично';
      case FrequencyType.monthly:
        return 'Месечно';
      case FrequencyType.seasonal:
        return 'Сезонно';
      case FrequencyType.yearly:
        return 'Годишно';
      case FrequencyType.asNeeded:
        return 'При нужда';
    }
  }

  String _getWeatherDependencyLabel(WeatherDependency dependency) {
    if (!dependency.isWeatherDependent) {
      return 'Не зависи от времето';
    }

    final conditions = dependency.skipConditions
        .map((c) => _getWeatherConditionLabel(c))
        .join(', ');
    
    return 'Отлага се при: $conditions (с ${dependency.postponeDays} дни)';
  }

  String _getWeatherConditionLabel(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.rain:
        return 'дъжд';
      case WeatherCondition.snow:
        return 'сняг';
      case WeatherCondition.frost:
        return 'мраз';
      case WeatherCondition.highWind:
        return 'силен вятър';
      case WeatherCondition.extremeHeat:
        return 'екстремна жега';
      case WeatherCondition.extremeCold:
        return 'екстремен студ';
    }
  }

  void _showPostponeDialog(BuildContext context) {
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
                _postponeReminder(context, const Duration(hours: 1));
              },
            ),
            ListTile(
              title: const Text('3 часа'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, const Duration(hours: 3));
              },
            ),
            ListTile(
              title: const Text('1 ден'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, const Duration(days: 1));
              },
            ),
            ListTile(
              title: const Text('3 дни'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, const Duration(days: 3));
              },
            ),
            ListTile(
              title: const Text('1 седмица'),
              onTap: () {
                Navigator.pop(context);
                _postponeReminder(context, const Duration(days: 7));
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

  void _postponeReminder(BuildContext context, Duration delay) {
    context.read<CareReminderProvider>().postponeReminder(reminder.id, delay);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Напомнянето е отложено'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _completeReminder(BuildContext context) {
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
              
              Navigator.pop(context);
              
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
