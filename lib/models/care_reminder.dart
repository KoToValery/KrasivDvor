import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'plant_instance.dart';

part 'care_reminder.g.dart';

@JsonSerializable()
@HiveType(typeId: 17)
class CareReminder extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String clientId;
  
  @HiveField(2)
  final String plantInstanceId;
  
  @HiveField(3)
  final CareType careType;
  
  @HiveField(4)
  final DateTime scheduledDate;
  
  @HiveField(5)
  final ReminderFrequency frequency;
  
  @HiveField(6)
  final String instructions;
  
  @HiveField(7)
  final bool isCompleted;
  
  @HiveField(8)
  final WeatherDependency weatherDependency;
  
  @HiveField(9)
  final DateTime? completedAt;
  
  @HiveField(10)
  final DateTime createdAt;

  CareReminder({
    required this.id,
    required this.clientId,
    required this.plantInstanceId,
    required this.careType,
    required this.scheduledDate,
    required this.frequency,
    required this.instructions,
    this.isCompleted = false,
    required this.weatherDependency,
    this.completedAt,
    required this.createdAt,
  });

  factory CareReminder.fromJson(Map<String, dynamic> json) => 
      _$CareReminderFromJson(json);
  Map<String, dynamic> toJson() => _$CareReminderToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 18)
class ReminderFrequency extends HiveObject {
  @HiveField(0)
  final int intervalDays;
  
  @HiveField(1)
  final FrequencyType type;
  
  @HiveField(2)
  final bool adjustForWeather;

  ReminderFrequency({
    required this.intervalDays,
    required this.type,
    this.adjustForWeather = false,
  });

  factory ReminderFrequency.fromJson(Map<String, dynamic> json) => 
      _$ReminderFrequencyFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderFrequencyToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 19)
class WeatherDependency extends HiveObject {
  @HiveField(0)
  final bool isWeatherDependent;
  
  @HiveField(1)
  final List<WeatherCondition> skipConditions;
  
  @HiveField(2)
  final int postponeDays;

  WeatherDependency({
    this.isWeatherDependent = false,
    required this.skipConditions,
    this.postponeDays = 1,
  });

  factory WeatherDependency.fromJson(Map<String, dynamic> json) => 
      _$WeatherDependencyFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDependencyToJson(this);
}

@HiveType(typeId: 32)
enum FrequencyType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  seasonal,
  @HiveField(4)
  yearly,
  @HiveField(5)
  asNeeded,
}

@HiveType(typeId: 33)
enum WeatherCondition {
  @HiveField(0)
  rain,
  @HiveField(1)
  snow,
  @HiveField(2)
  frost,
  @HiveField(3)
  highWind,
  @HiveField(4)
  extremeHeat,
  @HiveField(5)
  extremeCold,
}