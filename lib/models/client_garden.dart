import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'plant_instance.dart';

part 'client_garden.g.dart';

@JsonSerializable()
@HiveType(typeId: 9)
class ClientGarden extends HiveObject {
  @HiveField(0)
  final String clientId;
  
  @HiveField(1)
  final ClientProfile profile;
  
  @HiveField(2)
  final GardenMasterPlan? masterPlan;
  
  @HiveField(3)
  final List<GardenZone> zones;
  
  @HiveField(4)
  final List<PlantInstance> plants;
  
  @HiveField(5)
  final List<GardenNote> notes;
  
  @HiveField(6)
  final List<GardenDocument> documents;

  ClientGarden({
    required this.clientId,
    required this.profile,
    this.masterPlan,
    required this.zones,
    required this.plants,
    required this.notes,
    required this.documents,
  });

  factory ClientGarden.fromJson(Map<String, dynamic> json) => 
      _$ClientGardenFromJson(json);
  Map<String, dynamic> toJson() => _$ClientGardenToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 10)
class ClientProfile extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? phone;
  
  @HiveField(4)
  final String address;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final String createdBy; // landscape team member ID

  ClientProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.address,
    required this.createdAt,
    required this.createdBy,
  });

  factory ClientProfile.fromJson(Map<String, dynamic> json) => 
      _$ClientProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ClientProfileToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 11)
class GardenMasterPlan extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String imageUrl;
  
  @HiveField(2)
  final String fileName;
  
  @HiveField(3)
  final DateTime uploadedAt;

  GardenMasterPlan({
    required this.id,
    required this.imageUrl,
    required this.fileName,
    required this.uploadedAt,
  });

  factory GardenMasterPlan.fromJson(Map<String, dynamic> json) => 
      _$GardenMasterPlanFromJson(json);
  Map<String, dynamic> toJson() => _$GardenMasterPlanToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 12)
class GardenZone extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final List<String> plantInstanceIds;

  GardenZone({
    required this.id,
    required this.name,
    this.description,
    required this.plantInstanceIds,
  });

  factory GardenZone.fromJson(Map<String, dynamic> json) => 
      _$GardenZoneFromJson(json);
  Map<String, dynamic> toJson() => _$GardenZoneToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 13)
class GardenNote extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String content;
  
  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3)
  final List<String> photoUrls;

  GardenNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.photoUrls,
  });

  factory GardenNote.fromJson(Map<String, dynamic> json) => 
      _$GardenNoteFromJson(json);
  Map<String, dynamic> toJson() => _$GardenNoteToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 14)
class GardenDocument extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String fileUrl;
  
  @HiveField(3)
  final DocumentType type;
  
  @HiveField(4)
  final DateTime uploadedAt;

  GardenDocument({
    required this.id,
    required this.name,
    required this.fileUrl,
    required this.type,
    required this.uploadedAt,
  });

  factory GardenDocument.fromJson(Map<String, dynamic> json) => 
      _$GardenDocumentFromJson(json);
  Map<String, dynamic> toJson() => _$GardenDocumentToJson(this);
}

@HiveType(typeId: 28)
enum DocumentType {
  @HiveField(0)
  warranty,
  @HiveField(1)
  certificate,
  @HiveField(2)
  careInstructions,
  @HiveField(3)
  other,
}