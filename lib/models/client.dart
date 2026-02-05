import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'client.g.dart';

@JsonSerializable()
@HiveType(typeId: 30)
class Client extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String location;

  @HiveField(4)
  final String? address;

  @HiveField(5)
  final String? phone;

  @HiveField(6)
  final String? email;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? masterPlanUrl;

  @HiveField(9)
  final List<Zone> zones;

  @HiveField(10)
  final List<Contact> contacts;

  @HiveField(11)
  final Map<String, dynamic> preferences;

  @HiveField(12)
  final bool wateringNotificationsEnabled;

  @HiveField(13)
  final bool fertilizingNotificationsEnabled;

  @HiveField(14)
  final bool pruningNotificationsEnabled;

  @HiveField(15)
  final int wateringReminderDays;

  @HiveField(16)
  final int fertilizingReminderDays;

  @HiveField(17)
  final int pruningReminderDays;

  @HiveField(18)
  final List<String> zoneIds;

  Client({
    required this.id,
    required this.username,
    required this.fullName,
    required this.location,
    this.address,
    this.phone,
    this.email,
    required this.createdAt,
    this.masterPlanUrl,
    required this.zones,
    required this.contacts,
    required this.preferences,
    this.wateringNotificationsEnabled = true,
    this.fertilizingNotificationsEnabled = true,
    this.pruningNotificationsEnabled = true,
    this.wateringReminderDays = 3,
    this.fertilizingReminderDays = 14,
    this.pruningReminderDays = 30,
    required this.zoneIds,
  });

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);

  Client copyWith({
    String? id,
    String? username,
    String? fullName,
    String? location,
    String? address,
    String? phone,
    String? email,
    DateTime? createdAt,
    String? masterPlanUrl,
    List<Zone>? zones,
    List<Contact>? contacts,
    Map<String, dynamic>? preferences,
    bool? wateringNotificationsEnabled,
    bool? fertilizingNotificationsEnabled,
    bool? pruningNotificationsEnabled,
    int? wateringReminderDays,
    int? fertilizingReminderDays,
    int? pruningReminderDays,
    List<String>? zoneIds,
  }) {
    return Client(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      masterPlanUrl: masterPlanUrl ?? this.masterPlanUrl,
      zones: zones ?? this.zones,
      contacts: contacts ?? this.contacts,
      preferences: preferences ?? this.preferences,
      wateringNotificationsEnabled:
          wateringNotificationsEnabled ?? this.wateringNotificationsEnabled,
      fertilizingNotificationsEnabled: fertilizingNotificationsEnabled ??
          this.fertilizingNotificationsEnabled,
      pruningNotificationsEnabled:
          pruningNotificationsEnabled ?? this.pruningNotificationsEnabled,
      wateringReminderDays: wateringReminderDays ?? this.wateringReminderDays,
      fertilizingReminderDays:
          fertilizingReminderDays ?? this.fertilizingReminderDays,
      pruningReminderDays: pruningReminderDays ?? this.pruningReminderDays,
      zoneIds: zoneIds ?? this.zoneIds,
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 41)
class Zone extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String originalName;

  @HiveField(3)
  String description;

  @HiveField(4)
  final List<ZonePlant> plants;

  @HiveField(5)
  final Map<String, dynamic> properties;

  Zone({
    required this.id,
    required this.name,
    required this.originalName,
    required this.description,
    required this.plants,
    required this.properties,
  });

  factory Zone.empty() {
    return Zone(
      id: '',
      name: '',
      originalName: '',
      description: '',
      plants: [],
      properties: {},
    );
  }

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);
  Map<String, dynamic> toJson() => _$ZoneToJson(this);

  Zone copyWith({
    String? id,
    String? name,
    String? originalName,
    String? description,
    List<ZonePlant>? plants,
    Map<String, dynamic>? properties,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      description: description ?? this.description,
      plants: plants ?? this.plants,
      properties: properties ?? this.properties,
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 42)
class ZonePlant extends HiveObject {
  @HiveField(0)
  final String plantId;

  @HiveField(1)
  final String plantName;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final DateTime plantedDate;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final Map<String, dynamic> careHistory;

  ZonePlant({
    required this.plantId,
    required this.plantName,
    required this.quantity,
    required this.plantedDate,
    this.notes,
    required this.careHistory,
  });

  factory ZonePlant.fromJson(Map<String, dynamic> json) =>
      _$ZonePlantFromJson(json);
  Map<String, dynamic> toJson() => _$ZonePlantToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 43)
class Contact extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ContactType type;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String? email;

  @HiveField(5)
  final String? role;

  @HiveField(6)
  final bool isPrimary;

  Contact({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    this.email,
    this.role,
    required this.isPrimary,
  });

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);
}

@HiveType(typeId: 44)
enum ContactType {
  @HiveField(0)
  landscapeArchitect,

  @HiveField(1)
  gardener,

  @HiveField(2)
  maintenance,

  @HiveField(3)
  emergency,

  @HiveField(4)
  other,
}
