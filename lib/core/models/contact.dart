import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: 46)
class CoreContact {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // architect, gardener, contractor, supplier

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String role;

  @HiveField(4)
  final String? phone;

  @HiveField(5)
  final String? email;

  @HiveField(6)
  final String? address;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  CoreContact({
    required this.id,
    required this.type,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoreContact.fromJson(Map<String, dynamic> json) {
    return CoreContact(
      id: json['id'] ?? '',
      type: json['type'] ?? 'architect',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CoreContact copyWith({
    String? id,
    String? type,
    String? name,
    String? role,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoreContact(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CoreContact.empty() {
    return CoreContact(
      id: '',
      type: 'architect',
      name: '',
      role: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}