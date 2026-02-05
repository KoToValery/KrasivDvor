import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/models.dart';
import 'compatibility_engine.dart';

class PlantCatalogService {
  final ApiService _apiService;
  final StorageService _storageService;
  final CompatibilityEngine _compatibilityEngine;
  
  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const String _plantsCacheKey = 'plants_cache';

  PlantCatalogService(this._apiService, this._storageService, this._compatibilityEngine);

  /// Get plants by category with offline caching support
  Future<List<Plant>> getPlantsByCategory(PlantCategory category) async {
    try {
      // Try to get from API first
      final response = await _apiService.get('/plants?category=${category.name}');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      final plants = plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Cache the results
      await _cachePlants(plants);
      
      return plants;
    } catch (e) {
      // Fallback to cached data if API fails
      return _getCachedPlantsByCategory(category);
    }
  }

  /// Get a specific plant by ID
  Future<Plant?> getPlantById(String id) async {
    try {
      // Try API first
      final response = await _apiService.get('/plants/$id');
      final plantJson = response['data'];
      
      if (plantJson != null) {
        final plant = Plant.fromJson(plantJson as Map<String, dynamic>);
        // Cache individual plant
        await _storageService.storePlant(id, plant.toJson());
        return plant;
      }
      
      return null;
    } catch (e) {
      // Fallback to cached data
      final cachedData = _storageService.getPlant(id);
      return cachedData != null ? Plant.fromJson(cachedData) : null;
    }
  }

  /// Search plants with multiple criteria
  Future<List<Plant>> searchPlants(SearchCriteria criteria) async {
    try {
      final queryParams = _buildSearchQuery(criteria);
      final response = await _apiService.get('/plants/search?$queryParams');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      final plants = plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return plants;
    } catch (e) {
      // Fallback to cached search
      return _searchCachedPlants(criteria);
    }
  }

  /// Get compatible plants for a given plant
  Future<List<Plant>> getCompatiblePlants(String plantId) async {
    try {
      final response = await _apiService.get('/plants/$plantId/compatible');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      return plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to cached compatibility data or calculate compatibility
      return _getCompatiblePlantsOffline(plantId);
    }
  }

  /// Get compatible plants using the compatibility engine (offline-capable)
  Future<List<Plant>> getCompatiblePlantsWithAnalysis(
    String plantId, {
    double minCompatibilityScore = 0.6,
    int? maxResults,
  }) async {
    final targetPlant = await getPlantById(plantId);
    if (targetPlant == null) return [];
    
    final allPlants = await getAllPlants();
    final compatibilityResults = _compatibilityEngine.findCompatiblePlants(
      targetPlant,
      allPlants,
      minCompatibilityScore: minCompatibilityScore,
      maxResults: maxResults,
    );
    
    // Convert compatibility results back to plants
    final compatiblePlants = <Plant>[];
    for (final result in compatibilityResults) {
      final plant = allPlants.firstWhere(
        (p) => p.id == result.plant2Id,
        orElse: () => allPlants.firstWhere((p) => p.id == result.plant1Id),
      );
      compatiblePlants.add(plant);
    }
    
    return compatiblePlants;
  }

  /// Analyze compatibility between two specific plants
  Future<CompatibilityResult?> analyzeCompatibility(String plant1Id, String plant2Id) async {
    final plant1 = await getPlantById(plant1Id);
    final plant2 = await getPlantById(plant2Id);
    
    if (plant1 == null || plant2 == null) return null;
    
    return _compatibilityEngine.analyzeCompatibility(plant1, plant2);
  }

  /// Find plants that work well with multiple existing plants (for group plantings)
  Future<List<Plant>> findGroupCompatiblePlants(
    List<String> existingPlantIds, {
    double minAverageScore = 0.7,
  }) async {
    final existingPlants = <Plant>[];
    for (final id in existingPlantIds) {
      final plant = await getPlantById(id);
      if (plant != null) existingPlants.add(plant);
    }
    
    if (existingPlants.isEmpty) return [];
    
    final allPlants = await getAllPlants();
    return _compatibilityEngine.findGroupCompatiblePlants(
      existingPlants,
      allPlants,
      minAverageScore: minAverageScore,
    );
  }

  /// Analyze a combination of plants for garden design
  Future<PlantCombinationAnalysis?> analyzePlantCombination(List<String> plantIds) async {
    final plants = <Plant>[];
    for (final id in plantIds) {
      final plant = await getPlantById(id);
      if (plant != null) plants.add(plant);
    }
    
    if (plants.isEmpty) return null;
    
    return _compatibilityEngine.analyzePlantCombination(plants);
  }

  /// Get plants by multiple categories
  Future<List<Plant>> getPlantsByCategories(List<PlantCategory> categories) async {
    try {
      final categoryParams = categories.map((c) => c.name).join(',');
      final response = await _apiService.get('/plants?categories=${Uri.encodeComponent(categoryParams)}');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      final plants = plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Cache the results
      await _cachePlants(plants);
      
      return plants;
    } catch (e) {
      // Fallback to cached data
      return _getCachedPlantsByCategories(categories);
    }
  }

  /// Advanced search with sorting options
  Future<List<Plant>> searchPlantsAdvanced(
    SearchCriteria criteria, {
    PlantSortBy sortBy = PlantSortBy.name,
    bool ascending = true,
  }) async {
    try {
      final queryParams = _buildSearchQuery(criteria);
      final sortParam = 'sortBy=${sortBy.name}&ascending=$ascending';
      final fullQuery = queryParams.isEmpty ? sortParam : '$queryParams&$sortParam';
      
      final response = await _apiService.get('/plants/search?$fullQuery');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      final plants = plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return plants;
    } catch (e) {
      // Fallback to cached search with sorting
      final plants = _searchCachedPlants(criteria);
      return _sortPlants(plants, sortBy, ascending);
    }
  }

  /// Get plants suitable for specific conditions
  Future<List<Plant>> getPlantsForConditions({
    required LightRequirement lightCondition,
    required WaterRequirement waterCondition,
    SoilType? soilCondition,
    int? hardinessZone,
  }) async {
    final criteria = SearchCriteria(
      lightRequirement: lightCondition,
      waterRequirement: waterCondition,
      soilType: soilCondition,
      hardinessZone: hardinessZone,
    );
    
    return searchPlants(criteria);
  }

  /// Get plants by size range
  Future<List<Plant>> getPlantsBySize({
    int? minHeight,
    int? maxHeight,
    int? minWidth,
    int? maxWidth,
  }) async {
    final criteria = SearchCriteria(
      minHeight: minHeight,
      maxHeight: maxHeight,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
    
    return searchPlants(criteria);
  }

  /// Get plants by bloom season
  Future<List<Plant>> getPlantsByBloomSeason(List<Season> seasons) async {
    final criteria = SearchCriteria(bloomSeason: seasons);
    return searchPlants(criteria);
  }

  /// Get plants by care requirements
  Future<List<Plant>> getPlantsByCareRequirements({
    WaterRequirement? waterRequirement,
    LightRequirement? lightRequirement,
    GrowthRate? growthRate,
  }) async {
    final criteria = SearchCriteria(
      waterRequirement: waterRequirement,
      lightRequirement: lightRequirement,
      growthRate: growthRate,
    );
    
    return searchPlants(criteria);
  }

  /// Get plants by price category
  Future<List<Plant>> getPlantsByPriceCategory(PriceCategory priceCategory) async {
    final criteria = SearchCriteria(priceCategory: priceCategory);
    return searchPlants(criteria);
  }

  /// Get plants with low toxicity (safe for families with children/pets)
  Future<List<Plant>> getSafePlants() async {
    final criteria = SearchCriteria(maxToxicityLevel: ToxicityLevel.mild);
    return searchPlants(criteria);
  }

  /// Get all plants (for full catalog)
  Future<List<Plant>> getAllPlants() async {
    try {
      final response = await _apiService.get('/plants');
      final List<dynamic> plantsJson = response['data'] ?? [];
      
      final plants = plantsJson
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Cache all plants
      await _cachePlants(plants);
      
      return plants;
    } catch (e) {
      // Return all cached plants
      return _getAllCachedPlants();
    }
  }

  /// Add a new plant (admin functionality)
  Future<Plant> addPlant(Plant plant) async {
    final response = await _apiService.post('/plants', plant.toJson());
    final createdPlant = Plant.fromJson(response['data'] as Map<String, dynamic>);
    
    // Update cache
    await _storageService.storePlant(createdPlant.id, createdPlant.toJson());
    
    return createdPlant;
  }

  /// Update an existing plant (admin functionality)
  Future<Plant> updatePlant(Plant plant) async {
    final response = await _apiService.put('/plants/${plant.id}', plant.toJson());
    final updatedPlant = Plant.fromJson(response['data'] as Map<String, dynamic>);
    
    // Update cache
    await _storageService.storePlant(updatedPlant.id, updatedPlant.toJson());
    
    return updatedPlant;
  }

  /// Delete a plant (admin functionality)
  Future<void> deletePlant(String plantId) async {
    await _apiService.delete('/plants/$plantId');
    
    // Remove from cache
    await _storageService.remove('plant_$plantId');
  }

  /// Cache plants offline for better performance
  Future<void> cachePlantsOffline() async {
    try {
      final plants = await getAllPlants();
      await _cachePlants(plants);
      await _storageService.setCacheTimestamp(_plantsCacheKey);
    } catch (e) {
      throw Exception('Failed to cache plants offline: $e');
    }
  }

  /// Check if cached data is still valid
  bool isCacheValid() {
    return _storageService.isCacheValid(_plantsCacheKey, _cacheMaxAge);
  }

  // Private helper methods

  Future<void> _cachePlants(List<Plant> plants) async {
    final plantsMap = <String, Map<String, dynamic>>{};
    for (final plant in plants) {
      plantsMap[plant.id] = plant.toJson();
    }
    await _storageService.storePlants(plantsMap);
  }

  List<Plant> _getCachedPlantsByCategory(PlantCategory category) {
    final allCachedPlants = _getAllCachedPlants();
    return allCachedPlants.where((plant) => plant.category == category).toList();
  }

  List<Plant> _getAllCachedPlants() {
    final cachedPlantsData = _storageService.getAllPlants();
    return cachedPlantsData.values
        .map((json) => Plant.fromJson(json))
        .toList();
  }

  List<Plant> _searchCachedPlants(SearchCriteria criteria) {
    final allPlants = _getAllCachedPlants();
    
    return allPlants.where((plant) {
      // Name search (both Latin and Bulgarian names)
      if (criteria.name != null && criteria.name!.isNotEmpty) {
        final searchTerm = criteria.name!.toLowerCase();
        if (!plant.latinName.toLowerCase().contains(searchTerm) &&
            !plant.bulgarianName.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      // Category filter
      if (criteria.category != null && plant.category != criteria.category) {
        return false;
      }
      
      // Light requirement filter
      if (criteria.lightRequirement != null && 
          plant.characteristics.lightRequirement != criteria.lightRequirement) {
        return false;
      }
      
      // Water requirement filter
      if (criteria.waterRequirement != null && 
          plant.characteristics.waterRequirement != criteria.waterRequirement) {
        return false;
      }
      
      // Height filters
      if (criteria.maxHeight != null && 
          plant.specifications.maxHeightCm > criteria.maxHeight!) {
        return false;
      }
      
      if (criteria.minHeight != null && 
          plant.specifications.maxHeightCm < criteria.minHeight!) {
        return false;
      }
      
      // Width filters
      if (criteria.maxWidth != null && 
          plant.specifications.maxWidthCm > criteria.maxWidth!) {
        return false;
      }
      
      if (criteria.minWidth != null && 
          plant.specifications.maxWidthCm < criteria.minWidth!) {
        return false;
      }
      
      // Hardiness zone filter
      if (criteria.hardinessZone != null && 
          plant.characteristics.hardinessZone != criteria.hardinessZone) {
        return false;
      }
      
      // Bloom season filter
      if (criteria.bloomSeason != null && criteria.bloomSeason!.isNotEmpty) {
        final hasMatchingSeason = criteria.bloomSeason!.any(
          (season) => plant.specifications.bloomSeason.contains(season)
        );
        if (!hasMatchingSeason) {
          return false;
        }
      }
      
      // Growth rate filter
      if (criteria.growthRate != null && 
          plant.specifications.growthRate != criteria.growthRate) {
        return false;
      }
      
      // Soil type filter
      if (criteria.soilType != null && 
          plant.characteristics.preferredSoil != criteria.soilType) {
        return false;
      }
      
      // Toxicity level filter (max allowed toxicity)
      if (criteria.maxToxicityLevel != null) {
        final toxicityLevels = [
          ToxicityLevel.none,
          ToxicityLevel.mild,
          ToxicityLevel.moderate,
          ToxicityLevel.severe,
        ];
        final plantToxicityIndex = toxicityLevels.indexOf(plant.toxicity.level);
        final maxToxicityIndex = toxicityLevels.indexOf(criteria.maxToxicityLevel!);
        if (plantToxicityIndex > maxToxicityIndex) {
          return false;
        }
      }
      
      // Price category filter
      if (criteria.priceCategory != null && 
          plant.priceCategory != criteria.priceCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<Plant> _getCachedCompatiblePlants(String plantId) {
    final plant = _storageService.getPlant(plantId);
    if (plant == null) return [];
    
    final plantObj = Plant.fromJson(plant);
    final allPlants = _getAllCachedPlants();
    
    return allPlants
        .where((p) => plantObj.compatiblePlantIds.contains(p.id))
        .toList();
  }

  /// Fallback method for getting compatible plants offline using compatibility engine
  Future<List<Plant>> _getCompatiblePlantsOffline(String plantId) async {
    final cachedPlants = _getCachedCompatiblePlants(plantId);
    if (cachedPlants.isNotEmpty) {
      return cachedPlants;
    }
    
    // Use compatibility engine as fallback
    return getCompatiblePlantsWithAnalysis(plantId);
  }

  List<Plant> _getCachedPlantsByCategories(List<PlantCategory> categories) {
    final allCachedPlants = _getAllCachedPlants();
    return allCachedPlants.where((plant) => categories.contains(plant.category)).toList();
  }

  List<Plant> _sortPlants(List<Plant> plants, PlantSortBy sortBy, bool ascending) {
    plants.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case PlantSortBy.name:
          comparison = a.bulgarianName.compareTo(b.bulgarianName);
          break;
        case PlantSortBy.latinName:
          comparison = a.latinName.compareTo(b.latinName);
          break;
        case PlantSortBy.category:
          comparison = a.category.name.compareTo(b.category.name);
          break;
        case PlantSortBy.height:
          comparison = a.specifications.maxHeightCm.compareTo(b.specifications.maxHeightCm);
          break;
        case PlantSortBy.width:
          comparison = a.specifications.maxWidthCm.compareTo(b.specifications.maxWidthCm);
          break;
        case PlantSortBy.growthRate:
          final growthRateOrder = [GrowthRate.slow, GrowthRate.moderate, GrowthRate.fast];
          final aIndex = growthRateOrder.indexOf(a.specifications.growthRate);
          final bIndex = growthRateOrder.indexOf(b.specifications.growthRate);
          comparison = aIndex.compareTo(bIndex);
          break;
        case PlantSortBy.priceCategory:
          final priceOrder = [PriceCategory.budget, PriceCategory.standard, PriceCategory.premium];
          final aIndex = priceOrder.indexOf(a.priceCategory);
          final bIndex = priceOrder.indexOf(b.priceCategory);
          comparison = aIndex.compareTo(bIndex);
          break;
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return plants;
  }

  String _buildSearchQuery(SearchCriteria criteria) {
    final params = <String>[];
    
    if (criteria.name != null && criteria.name!.isNotEmpty) {
      params.add('name=${Uri.encodeComponent(criteria.name!)}');
    }
    
    if (criteria.category != null) {
      params.add('category=${criteria.category!.name}');
    }
    
    if (criteria.lightRequirement != null) {
      params.add('light=${criteria.lightRequirement!.name}');
    }
    
    if (criteria.waterRequirement != null) {
      params.add('water=${criteria.waterRequirement!.name}');
    }
    
    if (criteria.maxHeight != null) {
      params.add('maxHeight=${criteria.maxHeight}');
    }
    
    if (criteria.minHeight != null) {
      params.add('minHeight=${criteria.minHeight}');
    }
    
    if (criteria.maxWidth != null) {
      params.add('maxWidth=${criteria.maxWidth}');
    }
    
    if (criteria.minWidth != null) {
      params.add('minWidth=${criteria.minWidth}');
    }
    
    if (criteria.hardinessZone != null) {
      params.add('zone=${criteria.hardinessZone}');
    }
    
    if (criteria.bloomSeason != null && criteria.bloomSeason!.isNotEmpty) {
      final seasons = criteria.bloomSeason!.map((s) => s.name).join(',');
      params.add('bloomSeason=${Uri.encodeComponent(seasons)}');
    }
    
    if (criteria.growthRate != null) {
      params.add('growthRate=${criteria.growthRate!.name}');
    }
    
    if (criteria.soilType != null) {
      params.add('soilType=${criteria.soilType!.name}');
    }
    
    if (criteria.maxToxicityLevel != null) {
      params.add('maxToxicity=${criteria.maxToxicityLevel!.name}');
    }
    
    if (criteria.priceCategory != null) {
      params.add('priceCategory=${criteria.priceCategory!.name}');
    }
    
    return params.join('&');
  }
}

/// Search criteria class for plant filtering
class SearchCriteria {
  final String? name;
  final PlantCategory? category;
  final LightRequirement? lightRequirement;
  final WaterRequirement? waterRequirement;
  final int? maxHeight;
  final int? minHeight;
  final int? maxWidth;
  final int? minWidth;
  final int? hardinessZone;
  final List<Season>? bloomSeason;
  final GrowthRate? growthRate;
  final SoilType? soilType;
  final ToxicityLevel? maxToxicityLevel;
  final PriceCategory? priceCategory;

  SearchCriteria({
    this.name,
    this.category,
    this.lightRequirement,
    this.waterRequirement,
    this.maxHeight,
    this.minHeight,
    this.maxWidth,
    this.minWidth,
    this.hardinessZone,
    this.bloomSeason,
    this.growthRate,
    this.soilType,
    this.maxToxicityLevel,
    this.priceCategory,
  });

  /// Create a copy with updated values
  SearchCriteria copyWith({
    String? name,
    PlantCategory? category,
    LightRequirement? lightRequirement,
    WaterRequirement? waterRequirement,
    int? maxHeight,
    int? minHeight,
    int? maxWidth,
    int? minWidth,
    int? hardinessZone,
    List<Season>? bloomSeason,
    GrowthRate? growthRate,
    SoilType? soilType,
    ToxicityLevel? maxToxicityLevel,
    PriceCategory? priceCategory,
  }) {
    return SearchCriteria(
      name: name ?? this.name,
      category: category ?? this.category,
      lightRequirement: lightRequirement ?? this.lightRequirement,
      waterRequirement: waterRequirement ?? this.waterRequirement,
      maxHeight: maxHeight ?? this.maxHeight,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      minWidth: minWidth ?? this.minWidth,
      hardinessZone: hardinessZone ?? this.hardinessZone,
      bloomSeason: bloomSeason ?? this.bloomSeason,
      growthRate: growthRate ?? this.growthRate,
      soilType: soilType ?? this.soilType,
      maxToxicityLevel: maxToxicityLevel ?? this.maxToxicityLevel,
      priceCategory: priceCategory ?? this.priceCategory,
    );
  }

  /// Check if any search criteria is set
  bool get hasFilters {
    return name != null ||
        category != null ||
        lightRequirement != null ||
        waterRequirement != null ||
        maxHeight != null ||
        minHeight != null ||
        maxWidth != null ||
        minWidth != null ||
        hardinessZone != null ||
        bloomSeason != null ||
        growthRate != null ||
        soilType != null ||
        maxToxicityLevel != null ||
        priceCategory != null;
  }
}

/// Sorting options for plant search results
enum PlantSortBy {
  name,
  latinName,
  category,
  height,
  width,
  growthRate,
  priceCategory,
}