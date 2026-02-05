import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 6)
class AppNotification {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final String type; // watering, fertilizing, pruning, pest_control, seasonal

  @HiveField(5)
  final DateTime dueDate;

  @HiveField(6)
  final bool isRead;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime? completedAt;

  @HiveField(9)
  final String? zoneName;

  @HiveField(10)
  final String? plantName;

  @HiveField(11)
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.clientId,
    required this.title,
    required this.message,
    required this.type,
    required this.dueDate,
    this.isRead = false,
    this.isCompleted = false,
    this.completedAt,
    this.zoneName,
    this.plantName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({
    String? id,
    String? clientId,
    String? title,
    String? message,
    String? type,
    DateTime? dueDate,
    bool? isRead,
    bool? isCompleted,
    DateTime? completedAt,
    String? zoneName,
    String? plantName,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isRead: isRead ?? this.isRead,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      zoneName: zoneName ?? this.zoneName,
      plantName: plantName ?? this.plantName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'title': title,
      'message': message,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'isRead': isRead,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'zoneName': zoneName,
      'plantName': plantName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      clientId: json['clientId'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      dueDate: DateTime.parse(json['dueDate']),
      isRead: json['isRead'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      zoneName: json['zoneName'],
      plantName: json['plantName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}