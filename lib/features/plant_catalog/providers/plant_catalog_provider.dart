import 'package:flutter/foundation.dart';
import '../../../models/models.dart';
import '../services/plant_catalog_service.dart';

class PlantCatalogProvider extends ChangeNotifier {
  final PlantCatalogService _plantCatalogService;

  PlantCatalogProvider(this._plantCatalogService);

  List<Plant> _plants = [];
  bool _isLoading = false;
  String? _error;

  List<Plant> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all plants from the catalog
  Future<void> loadAllPlants() async {
    _setLoading(true);
    try {
      print('DEBUG: PlantCatalogProvider.loadAllPlants() called');
      _plants = await _plantCatalogService.getAllPlants();
      print('DEBUG: Loaded ${_plants.length} plants');
      _error = null;
    } catch (e) {
      print('DEBUG: Error loading plants: $e');
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load plants by specific category
  Future<void> loadPlantsByCategory(PlantCategory category) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsByCategory(category);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Search plants by name (both Latin and Bulgarian)
  Future<void> searchPlants(String query) async {
    _setLoading(true);
    try {
      final criteria = SearchCriteria(name: query);
      _plants = await _plantCatalogService.searchPlants(criteria);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Search plants with advanced criteria
  Future<void> searchPlantsWithCriteria(SearchCriteria criteria) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.searchPlants(criteria);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants by multiple categories
  Future<void> loadPlantsByCategories(List<PlantCategory> categories) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsByCategories(categories);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants suitable for specific conditions
  Future<void> loadPlantsForConditions({
    required LightRequirement lightCondition,
    required WaterRequirement waterCondition,
    SoilType? soilCondition,
    int? hardinessZone,
  }) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsForConditions(
        lightCondition: lightCondition,
        waterCondition: waterCondition,
        soilCondition: soilCondition,
        hardinessZone: hardinessZone,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants by size range
  Future<void> loadPlantsBySize({
    int? minHeight,
    int? maxHeight,
    int? minWidth,
    int? maxWidth,
  }) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsBySize(
        minHeight: minHeight,
        maxHeight: maxHeight,
        minWidth: minWidth,
        maxWidth: maxWidth,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants by bloom season
  Future<void> loadPlantsByBloomSeason(List<Season> seasons) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsByBloomSeason(seasons);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants by care requirements
  Future<void> loadPlantsByCareRequirements({
    WaterRequirement? waterRequirement,
    LightRequirement? lightRequirement,
    GrowthRate? growthRate,
  }) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsByCareRequirements(
        waterRequirement: waterRequirement,
        lightRequirement: lightRequirement,
        growthRate: growthRate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get plants by price category
  Future<void> loadPlantsByPriceCategory(PriceCategory priceCategory) async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getPlantsByPriceCategory(priceCategory);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get safe plants (low toxicity)
  Future<void> loadSafePlants() async {
    _setLoading(true);
    try {
      _plants = await _plantCatalogService.getSafePlants();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _plants = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific plant by ID
  Future<Plant?> getPlantById(String id) async {
    try {
      return await _plantCatalogService.getPlantById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get compatible plants for a given plant
  Future<List<Plant>> getCompatiblePlants(String plantId) async {
    try {
      return await _plantCatalogService.getCompatiblePlants(plantId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Cache plants for offline use
  Future<void> cachePlantsOffline() async {
    try {
      await _plantCatalogService.cachePlantsOffline();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Check if cached data is valid
  bool isCacheValid() {
    return _plantCatalogService.isCacheValid();
  }

  /// Clear current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh current data
  Future<void> refresh() async {
    if (_plants.isEmpty) {
      await loadAllPlants();
    } else {
      // Reload with current state - this is a simplified approach
      // In a real app, you might want to track the current filter state
      await loadAllPlants();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}