import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/care_reminder.dart';
import '../../../models/plant_instance.dart';
import '../../../models/plant.dart';
import '../../../core/services/api_service.dart';

class CareReminderService {
  final ApiService _apiService;
  final Box<CareReminder> _reminderBox;
  static const String _weatherApiKey = 'YOUR_OPENWEATHERMAP_API_KEY'; // Replace with actual key
  static const String _weatherApiUrl = 'https://api.openweathermap.org/data/2.5';

  CareReminderService(this._apiService, this._reminderBox);

  /// Get active reminders for a client
  Future<List<CareReminder>> getActiveReminders(String clientId) async {
    try {
      final response = await _apiService.get('/reminders?clientId=$clientId&active=true');
      final List<dynamic> remindersJson = response['reminders'] ?? [];
      
      final reminders = remindersJson
          .map((json) => CareReminder.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Cache reminders locally
      for (final reminder in reminders) {
        await _reminderBox.put(reminder.id, reminder);
      }
      
      return reminders;
    } catch (e) {
      // Fallback to cached data if offline
      return _reminderBox.values
          .where((r) => r.clientId == clientId && !r.isCompleted)
          .toList();
    }
  }

  /// Schedule a new care reminder
  Future<CareReminder> scheduleReminder(CareReminder reminder) async {
    try {
      final response = await _apiService.post('/reminders', reminder.toJson());
      final createdReminder = CareReminder.fromJson(response);
      
      // Cache locally
      await _reminderBox.put(createdReminder.id, createdReminder);
      
      return createdReminder;
    } catch (e) {
      // Cache locally for later sync
      await _reminderBox.put(reminder.id, reminder);
      return reminder;
    }
  }

  /// Mark reminder as completed
  Future<void> markReminderComplete(String reminderId) async {
    try {
      await _apiService.put('/reminders/$reminderId/complete', {
        'completedAt': DateTime.now().toIso8601String(),
      });
      
      // Update local cache
      final reminder = _reminderBox.get(reminderId);
      if (reminder != null) {
        final updated = CareReminder(
          id: reminder.id,
          clientId: reminder.clientId,
          plantInstanceId: reminder.plantInstanceId,
          careType: reminder.careType,
          scheduledDate: reminder.scheduledDate,
          frequency: reminder.frequency,
          instructions: reminder.instructions,
          isCompleted: true,
          weatherDependency: reminder.weatherDependency,
          completedAt: DateTime.now(),
          createdAt: reminder.createdAt,
        );
        await _reminderBox.put(reminderId, updated);
      }
    } catch (e) {
      throw Exception('Failed to mark reminder complete: $e');
    }
  }

  /// Postpone a reminder by specified duration
  Future<void> postponeReminder(String reminderId, Duration delay) async {
    try {
      final reminder = _reminderBox.get(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }
      
      final newScheduledDate = reminder.scheduledDate.add(delay);
      
      await _apiService.put('/reminders/$reminderId/postpone', {
        'scheduledDate': newScheduledDate.toIso8601String(),
      });
      
      // Update local cache
      final updated = CareReminder(
        id: reminder.id,
        clientId: reminder.clientId,
        plantInstanceId: reminder.plantInstanceId,
        careType: reminder.careType,
        scheduledDate: newScheduledDate,
        frequency: reminder.frequency,
        instructions: reminder.instructions,
        isCompleted: reminder.isCompleted,
        weatherDependency: reminder.weatherDependency,
        completedAt: reminder.completedAt,
        createdAt: reminder.createdAt,
      );
      await _reminderBox.put(reminderId, updated);
    } catch (e) {
      throw Exception('Failed to postpone reminder: $e');
    }
  }

  /// Update reminders based on current weather conditions
  Future<void> updateRemindersForWeather(String clientId, double latitude, double longitude) async {
    try {
      // Fetch current weather
      final weather = await _fetchWeatherData(latitude, longitude);
      
      // Get active reminders for client
      final reminders = await getActiveReminders(clientId);
      
      // Process weather-dependent reminders
      for (final reminder in reminders) {
        if (reminder.weatherDependency.isWeatherDependent) {
          final shouldPostpone = _shouldPostponeForWeather(
            reminder.weatherDependency,
            weather,
          );
          
          if (shouldPostpone) {
            await postponeReminder(
              reminder.id,
              Duration(days: reminder.weatherDependency.postponeDays),
            );
          }
        }
      }
    } catch (e) {
      // Log error but don't throw - weather updates are non-critical
      print('Failed to update reminders for weather: $e');
    }
  }

  /// Generate automatic reminders for a plant instance
  Future<List<CareReminder>> generateRemindersForPlant(
    String clientId,
    PlantInstance plantInstance,
    Plant plant,
  ) async {
    final reminders = <CareReminder>[];
    final now = DateTime.now();
    
    // Determine if plant is newly planted (less than 3 months)
    final isNewlyPlanted = now.difference(plantInstance.plantedDate).inDays < 90;
    
    // Watering reminder
    final wateringReminder = _createWateringReminder(
      clientId,
      plantInstance,
      plant,
      isNewlyPlanted,
    );
    reminders.add(wateringReminder);
    
    // Fertilizing reminder
    final fertilizingReminder = _createFertilizingReminder(
      clientId,
      plantInstance,
      plant,
    );
    reminders.add(fertilizingReminder);
    
    // Pruning reminder (seasonal)
    final pruningReminder = _createPruningReminder(
      clientId,
      plantInstance,
      plant,
    );
    reminders.add(pruningReminder);
    
    // Schedule all reminders
    final scheduledReminders = <CareReminder>[];
    for (final reminder in reminders) {
      try {
        final scheduled = await scheduleReminder(reminder);
        scheduledReminders.add(scheduled);
      } catch (e) {
        print('Failed to schedule reminder: $e');
      }
    }
    
    return scheduledReminders;
  }

  /// Create watering reminder based on plant requirements and age
  CareReminder _createWateringReminder(
    String clientId,
    PlantInstance plantInstance,
    Plant plant,
    bool isNewlyPlanted,
  ) {
    int intervalDays = plant.careRequirements.watering.frequencyDays;
    if (isNewlyPlanted) {
      intervalDays = (intervalDays * 0.7).round();
      if (intervalDays < 1) intervalDays = 1;
    }

    final season = _getCurrentSeason();
    if (season == Season.summer) {
      intervalDays = (intervalDays * 0.7).round();
      if (intervalDays < 1) intervalDays = 1;
    } else if (season == Season.winter) {
      intervalDays = (intervalDays * 1.3).round();
    }
    
    return CareReminder(
      id: '${plantInstance.id}_watering_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      plantInstanceId: plantInstance.id,
      careType: CareType.watering,
      scheduledDate: DateTime.now().add(Duration(days: intervalDays)),
      frequency: ReminderFrequency(
        intervalDays: intervalDays,
        type: FrequencyType.asNeeded,
        adjustForWeather: true,
      ),
      instructions: isNewlyPlanted
          ? 'Поливайте новозасаденото растение редовно. Проверете дали почвата е влажна на 5-10 см дълбочина.'
          : 'Поливайте растението според нуждите му. Проверете почвата преди поливане.',
      isCompleted: false,
      weatherDependency: WeatherDependency(
        isWeatherDependent: true,
        skipConditions: [WeatherCondition.rain, WeatherCondition.snow],
        postponeDays: 2,
      ),
      createdAt: DateTime.now(),
    );
  }

  /// Create fertilizing reminder based on plant type
  CareReminder _createFertilizingReminder(
    String clientId,
    PlantInstance plantInstance,
    Plant plant,
  ) {
    int intervalDays = plant.careRequirements.fertilizing.frequencyDays;
    if (intervalDays <= 0) {
      switch (plant.specifications.growthRate) {
        case GrowthRate.slow:
          intervalDays = 60;
          break;
        case GrowthRate.moderate:
          intervalDays = 45;
          break;
        case GrowthRate.fast:
          intervalDays = 30;
          break;
      }
    }

    final fertilizerType = plant.careRequirements.fertilizing.fertilizerType;
    final instructions =
        plant.careRequirements.fertilizing.instructions.isNotEmpty
            ? plant.careRequirements.fertilizing.instructions
            : 'Приложете подходящ тор за ${plant.bulgarianName}. Следвайте инструкциите на производителя.';
    final fertilizerText = (fertilizerType != null &&
            fertilizerType.trim().isNotEmpty)
        ? 'Тор: ${fertilizerType.trim()}. '
        : '';
    return CareReminder(
      id: '${plantInstance.id}_fertilizing_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      plantInstanceId: plantInstance.id,
      careType: CareType.fertilizing,
      scheduledDate: DateTime.now().add(Duration(days: intervalDays)),
      frequency: ReminderFrequency(
        intervalDays: intervalDays,
        type: FrequencyType.monthly,
        adjustForWeather: false,
      ),
      instructions: '$fertilizerText$instructions',
      isCompleted: false,
      weatherDependency: WeatherDependency(
        isWeatherDependent: false,
        skipConditions: [],
        postponeDays: 0,
      ),
      createdAt: DateTime.now(),
    );
  }

  /// Create pruning reminder based on plant type and season
  CareReminder _createPruningReminder(
    String clientId,
    PlantInstance plantInstance,
    Plant plant,
  ) {
    final configuredInterval = plant.careRequirements.pruning.frequencyDays;
    final intervalDays = (configuredInterval != null && configuredInterval > 0)
        ? configuredInterval
        : 90;
    final scheduledDate = (configuredInterval != null && configuredInterval > 0)
        ? DateTime.now().add(Duration(days: intervalDays))
        : _getNextPruningDate(plant);
    final instructions = plant.careRequirements.pruning.instructions.isNotEmpty
        ? plant.careRequirements.pruning.instructions
        : 'Подрежете ${plant.bulgarianName} за поддържане на форма и здраве. Премахнете мъртви или болни клони.';
    return CareReminder(
      id: '${plantInstance.id}_pruning_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      plantInstanceId: plantInstance.id,
      careType: CareType.pruning,
      scheduledDate: scheduledDate,
      frequency: ReminderFrequency(
        intervalDays: intervalDays,
        type: FrequencyType.seasonal,
        adjustForWeather: false,
      ),
      instructions: instructions,
      isCompleted: false,
      weatherDependency: WeatherDependency(
        isWeatherDependent: true,
        skipConditions: [WeatherCondition.frost, WeatherCondition.extremeCold],
        postponeDays: 7,
      ),
      createdAt: DateTime.now(),
    );
  }

  /// Fetch weather data from OpenWeatherMap API
  Future<WeatherData> _fetchWeatherData(double latitude, double longitude) async {
    final url = '$_weatherApiUrl/weather?lat=$latitude&lon=$longitude&appid=$_weatherApiKey&units=metric';
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return WeatherData.fromJson(data);
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }

  /// Determine if reminder should be postponed based on weather
  bool _shouldPostponeForWeather(
    WeatherDependency dependency,
    WeatherData weather,
  ) {
    for (final condition in dependency.skipConditions) {
      switch (condition) {
        case WeatherCondition.rain:
          if (weather.isRaining) return true;
          break;
        case WeatherCondition.snow:
          if (weather.isSnowing) return true;
          break;
        case WeatherCondition.frost:
          if (weather.temperature < 0) return true;
          break;
        case WeatherCondition.highWind:
          if (weather.windSpeed > 15) return true;
          break;
        case WeatherCondition.extremeHeat:
          if (weather.temperature > 35) return true;
          break;
        case WeatherCondition.extremeCold:
          if (weather.temperature < -5) return true;
          break;
      }
    }
    return false;
  }

  /// Get current season based on date
  Season _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  /// Get next pruning date based on plant type
  DateTime _getNextPruningDate(Plant plant) {
    final now = DateTime.now();
    final season = _getCurrentSeason();
    
    // Most pruning happens in late winter/early spring
    if (season == Season.winter || season == Season.spring) {
      return DateTime(now.year, 3, 15); // Mid-March
    } else {
      return DateTime(now.year + 1, 3, 15); // Next year
    }
  }
}

/// Weather data model
class WeatherData {
  final double temperature;
  final double windSpeed;
  final bool isRaining;
  final bool isSnowing;
  final String description;

  WeatherData({
    required this.temperature,
    required this.windSpeed,
    required this.isRaining,
    required this.isSnowing,
    required this.description,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final weatherMain = weather['main'] as String;
    
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      windSpeed: (wind['speed'] as num).toDouble(),
      isRaining: weatherMain.toLowerCase().contains('rain'),
      isSnowing: weatherMain.toLowerCase().contains('snow'),
      description: weather['description'] as String,
    );
  }
}

/// Season enum
enum Season {
  spring,
  summer,
  autumn,
  winter,
}
