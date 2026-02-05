import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'plant_instance.g.dart';

@JsonSerializable()
@HiveType(typeId: 15)
class PlantInstance extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String plantId;
  
  @HiveField(2)
  final String? zoneId;
  
  @HiveField(3)
  final DateTime plantedDate;
  
  @HiveField(4)
  final PlantSize plantedSize;
  
  @HiveField(5)
  final PlantStatus status;
  
  @HiveField(6)
  final List<String> progressPhotos;
  
  @HiveField(7)
  final List<CareRecord> careHistory;
  
  @HiveField(8)
  final String? notes;

  PlantInstance({
    required this.id,
    required this.plantId,
    this.zoneId,
    required this.plantedDate,
    required this.plantedSize,
    required this.status,
    required this.progressPhotos,
    required this.careHistory,
    this.notes,
  });

  factory PlantInstance.fromJson(Map<String, dynamic> json) => 
      _$PlantInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$PlantInstanceToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 16)
class CareRecord extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final CareType careType;
  
  @HiveField(2)
  final DateTime performedAt;
  
  @HiveField(3)
  final String? notes;
  
  @HiveField(4)
  final List<String> photoUrls;

  CareRecord({
    required this.id,
    required this.careType,
    required this.performedAt,
    this.notes,
    required this.photoUrls,
  });

  factory CareRecord.fromJson(Map<String, dynamic> json) => 
      _$CareRecordFromJson(json);
  Map<String, dynamic> toJson() => _$CareRecordToJson(this);
}

@HiveType(typeId: 29)
enum PlantSize {
  @HiveField(0)
  seedling,
  @HiveField(1)
  small,
  @HiveField(2)
  medium,
  @HiveField(3)
  large,
  @HiveField(4)
  mature,
}

@HiveType(typeId: 30)
enum PlantStatus {
  @HiveField(0)
  planted,
  @HiveField(1)
  establishing,
  @HiveField(2)
  healthy,
  @HiveField(3)
  stressed,
  @HiveField(4)
  diseased,
  @HiveField(5)
  dead,
  @HiveField(6)
  removed,
}

@HiveType(typeId: 31)
enum CareType {
  @HiveField(0)
  watering,
  @HiveField(1)
  fertilizing,
  @HiveField(2)
  pruning,
  @HiveField(3)
  weeding,
  @HiveField(4)
  mulching,
  @HiveField(5)
  pestControl,
  @HiveField(6)
  diseaseControl,
  @HiveField(7)
  other,
}