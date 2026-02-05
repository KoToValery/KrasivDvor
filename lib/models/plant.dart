import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'plant.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class Plant extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String latinName;

  @HiveField(2)
  final String bulgarianName;

  @HiveField(3)
  final PlantCategory category;

  @HiveField(4)
  @JsonKey(defaultValue: [])
  final List<String> imageUrls;

  @HiveField(5)
  final PlantCharacteristics characteristics;

  @HiveField(6)
  final CareRequirements careRequirements;

  @HiveField(7)
  final PlantSpecifications specifications;

  @HiveField(8)
  @JsonKey(defaultValue: [])
  final List<String> compatiblePlantIds;

  @HiveField(9)
  final ToxicityInfo toxicity;

  @HiveField(10)
  final PriceCategory priceCategory;

  @HiveField(11)
  final String qrCode;

  Plant({
    required this.id,
    required this.latinName,
    required this.bulgarianName,
    required this.category,
    required this.imageUrls,
    required this.characteristics,
    required this.careRequirements,
    required this.specifications,
    required this.compatiblePlantIds,
    required this.toxicity,
    required this.priceCategory,
    required this.qrCode,
  });

  factory Plant.fromJson(Map<String, dynamic> json) => _$PlantFromJson(json);
  Map<String, dynamic> toJson() => _$PlantToJson(this);

  static Plant empty() {
    return Plant(
      id: '',
      latinName: '',
      bulgarianName: '',
      category: PlantCategory.shrubs,
      imageUrls: [],
      characteristics: PlantCharacteristics(
        description: '',
        lightRequirement: LightRequirement.fullSun,
        waterRequirement: WaterRequirement.moderate,
        preferredSoil: SoilType.loam,
        hardinessZone: 6,
      ),
      careRequirements: CareRequirements(
        watering: WateringSchedule(
          frequencyDays: 7,
          instructions: '',
          weatherDependent: false,
        ),
        fertilizing: FertilizingSchedule(
          frequencyDays: 30,
          instructions: '',
          seasons: [],
          fertilizerType: '',
        ),
        pruning: PruningSchedule(
          seasons: [],
          instructions: '',
          frequencyDays: 90,
        ),
        seasonalCare: [],
        winterizing: WinterizingSchedule(
          needed: false,
          startMonth: 10,
          instructions: '',
        ),
      ),
      specifications: PlantSpecifications(
        maxHeightCm: 0,
        maxWidthCm: 0,
        bloomSeason: [],
        growthRate: GrowthRate.moderate,
      ),
      compatiblePlantIds: [],
      toxicity: ToxicityInfo(
        level: ToxicityLevel.none,
      ),
      priceCategory: PriceCategory.standard,
      qrCode: '',
    );
  }
}

@JsonSerializable()
@HiveType(typeId: 1)
class PlantCharacteristics extends HiveObject {
  @HiveField(0)
  final String description;

  @HiveField(1)
  final LightRequirement lightRequirement;

  @HiveField(2)
  final WaterRequirement waterRequirement;

  @HiveField(3)
  final SoilType preferredSoil;

  @HiveField(4)
  final int hardinessZone;

  PlantCharacteristics({
    required this.description,
    required this.lightRequirement,
    required this.waterRequirement,
    required this.preferredSoil,
    required this.hardinessZone,
  });

  factory PlantCharacteristics.fromJson(Map<String, dynamic> json) =>
      _$PlantCharacteristicsFromJson(json);
  Map<String, dynamic> toJson() => _$PlantCharacteristicsToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 2)
class CareRequirements extends HiveObject {
  @HiveField(0)
  final WateringSchedule watering;

  @HiveField(1)
  final FertilizingSchedule fertilizing;

  @HiveField(2)
  final PruningSchedule pruning;

  @HiveField(3)
  final List<SeasonalCare> seasonalCare;

  @HiveField(4)
  final WinterizingSchedule? winterizing;

  CareRequirements({
    required this.watering,
    required this.fertilizing,
    required this.pruning,
    required this.seasonalCare,
    this.winterizing,
  });

  factory CareRequirements.fromJson(Map<String, dynamic> json) =>
      _$CareRequirementsFromJson(json);
  Map<String, dynamic> toJson() => _$CareRequirementsToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 48)
class PlantSpecifications extends HiveObject {
  @HiveField(0)
  final int maxHeightCm;

  @HiveField(1)
  final int maxWidthCm;

  @HiveField(2)
  @JsonKey(defaultValue: [])
  final List<Season> bloomSeason;

  @HiveField(3)
  final GrowthRate growthRate;

  PlantSpecifications({
    required this.maxHeightCm,
    required this.maxWidthCm,
    this.bloomSeason = const [],
    required this.growthRate,
  });

  factory PlantSpecifications.fromJson(Map<String, dynamic> json) =>
      _$PlantSpecificationsFromJson(json);
  Map<String, dynamic> toJson() => _$PlantSpecificationsToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 4)
class ToxicityInfo extends HiveObject {
  @HiveField(0)
  final ToxicityLevel level;

  @HiveField(1)
  final String? warning;

  ToxicityInfo({
    required this.level,
    this.warning,
  });

  factory ToxicityInfo.fromJson(Map<String, dynamic> json) =>
      _$ToxicityInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ToxicityInfoToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 5)
class WateringSchedule extends HiveObject {
  @HiveField(0)
  final int frequencyDays;

  @HiveField(1)
  final String instructions;

  @HiveField(2)
  @JsonKey(defaultValue: false)
  final bool weatherDependent;

  WateringSchedule({
    required this.frequencyDays,
    required this.instructions,
    this.weatherDependent = false,
  });

  factory WateringSchedule.fromJson(Map<String, dynamic> json) =>
      _$WateringScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$WateringScheduleToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 45)
class FertilizingSchedule extends HiveObject {
  @HiveField(0)
  final int frequencyDays;

  @HiveField(1)
  final String instructions;

  @HiveField(2)
  final List<Season> seasons;

  @HiveField(3)
  final String? fertilizerType;

  FertilizingSchedule({
    required this.frequencyDays,
    required this.instructions,
    required this.seasons,
    this.fertilizerType,
  });

  factory FertilizingSchedule.fromJson(Map<String, dynamic> json) =>
      _$FertilizingScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$FertilizingScheduleToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 7)
class PruningSchedule extends HiveObject {
  @HiveField(0)
  final List<Season> seasons;

  @HiveField(1)
  final String instructions;

  @HiveField(2)
  final int? frequencyDays;

  PruningSchedule({
    required this.seasons,
    required this.instructions,
    this.frequencyDays,
  });

  factory PruningSchedule.fromJson(Map<String, dynamic> json) =>
      _$PruningScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$PruningScheduleToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 8)
class SeasonalCare extends HiveObject {
  @HiveField(0)
  final Season season;

  @HiveField(1)
  final String instructions;

  SeasonalCare({
    required this.season,
    required this.instructions,
  });

  factory SeasonalCare.fromJson(Map<String, dynamic> json) =>
      _$SeasonalCareFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonalCareToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 47)
class WinterizingSchedule extends HiveObject {
  @HiveField(0)
  @JsonKey(defaultValue: false)
  final bool needed;

  @HiveField(1)
  final int startMonth;

  @HiveField(2)
  final String instructions;

  WinterizingSchedule({
    this.needed = false,
    required this.startMonth,
    required this.instructions,
  });

  factory WinterizingSchedule.fromJson(Map<String, dynamic> json) =>
      _$WinterizingScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$WinterizingScheduleToJson(this);
}

// Enums
@HiveType(typeId: 20)
enum PlantCategory {
  @HiveField(0)
  trees,
  @HiveField(1)
  shrubs,
  @HiveField(2)
  flowers,
  @HiveField(3)
  grasses,
  @HiveField(4)
  climbers,
  @HiveField(5)
  aquatic,
}

@HiveType(typeId: 21)
enum LightRequirement {
  @HiveField(0)
  fullSun,
  @HiveField(1)
  partialSun,
  @HiveField(2)
  partialShade,
  @HiveField(3)
  fullShade,
}

@HiveType(typeId: 22)
enum WaterRequirement {
  @HiveField(0)
  low,
  @HiveField(1)
  moderate,
  @HiveField(2)
  high,
}

@HiveType(typeId: 23)
enum SoilType {
  @HiveField(0)
  clay,
  @HiveField(1)
  loam,
  @HiveField(2)
  sand,
  @HiveField(3)
  chalk,
  @HiveField(4)
  peat,
}

@HiveType(typeId: 24)
enum Season {
  @HiveField(0)
  spring,
  @HiveField(1)
  summer,
  @HiveField(2)
  autumn,
  @HiveField(3)
  winter,
}

@HiveType(typeId: 25)
enum GrowthRate {
  @HiveField(0)
  slow,
  @HiveField(1)
  moderate,
  @HiveField(2)
  fast,
}

@HiveType(typeId: 26)
enum ToxicityLevel {
  @HiveField(0)
  none,
  @HiveField(1)
  mild,
  @HiveField(2)
  moderate,
  @HiveField(3)
  severe,
}

@HiveType(typeId: 27)
enum PriceCategory {
  @HiveField(0)
  budget,
  @HiveField(1)
  standard,
  @HiveField(2)
  premium,
}
