import 'package:flutter/foundation.dart';
import '../../../models/client_garden.dart';
import '../../../models/plant_instance.dart';
import '../services/garden_service.dart';

class GardenProvider extends ChangeNotifier {
  final GardenService _gardenService;

  GardenProvider(this._gardenService);

  ClientGarden? _garden;
  List<PlantInstance> _gardenPlants = [];
  PlantInstance? _selectedPlantInstance;
  List<PlantInstance> _plantingHistory = [];
  List<GardenNote> _gardenNotes = [];
  List<GardenDocument> _gardenDocuments = [];
  bool _isLoading = false;
  String? _error;

  ClientGarden? get garden => _garden;
  List<PlantInstance> get gardenPlants => _gardenPlants;
  PlantInstance? get selectedPlantInstance => _selectedPlantInstance;
  List<PlantInstance> get plantingHistory => _plantingHistory;
  List<GardenNote> get gardenNotes => _gardenNotes;
  List<GardenDocument> get gardenDocuments => _gardenDocuments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load client garden
  Future<void> loadGarden(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _garden = await _gardenService.getClientGarden(clientId);
      _gardenPlants = _garden?.plants ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load garden plants
  Future<void> loadGardenPlants(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gardenPlants = await _gardenService.getGardenPlants(clientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load plant instance details
  Future<void> loadPlantInstance(String plantInstanceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedPlantInstance = await _gardenService.getPlantInstance(plantInstanceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update plant status
  Future<void> updatePlantStatus(String plantInstanceId, PlantStatus status) async {
    try {
      final updatedPlant = await _gardenService.updatePlantStatus(plantInstanceId, status);
      
      // Update in list
      final index = _gardenPlants.indexWhere((p) => p.id == plantInstanceId);
      if (index != -1) {
        _gardenPlants[index] = updatedPlant;
      }
      
      // Update selected if it's the same plant
      if (_selectedPlantInstance?.id == plantInstanceId) {
        _selectedPlantInstance = updatedPlant;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add care record
  Future<void> addCareRecord(String plantInstanceId, CareRecord careRecord) async {
    try {
      await _gardenService.addCareRecord(plantInstanceId, careRecord);
      
      // Reload plant instance to get updated care history
      await loadPlantInstance(plantInstanceId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add progress photo
  Future<void> addProgressPhoto(String plantInstanceId, String photoUrl) async {
    try {
      final updatedPlant = await _gardenService.addProgressPhoto(plantInstanceId, photoUrl);
      
      // Update selected plant
      if (_selectedPlantInstance?.id == plantInstanceId) {
        _selectedPlantInstance = updatedPlant;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get plants by zone
  Future<List<PlantInstance>> getPlantsByZone(String clientId, String zoneId) async {
    try {
      return await _gardenService.getPlantsByZone(clientId, zoneId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load planting history
  Future<void> loadPlantingHistory(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plantingHistory = await _gardenService.getPlantingHistory(clientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load garden documentation (notes and documents)
  Future<void> loadGardenDocumentation(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gardenNotes = await _gardenService.getGardenNotes(clientId);
      _gardenDocuments = await _gardenService.getGardenDocuments(clientId);
      _plantingHistory = await _gardenService.getPlantingHistory(clientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create garden note
  Future<void> createNote(String clientId, String content) async {
    try {
      final note = await _gardenService.createGardenNote(
        clientId,
        content,
        null,
      );
      _gardenNotes.insert(0, note);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Upload document
  Future<void> uploadDocument(String clientId, DocumentType type) async {
    try {
      // This would be implemented with actual file picker
      // For now, just a placeholder
      _error = 'Document upload not yet implemented';
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete garden note
  Future<void> deleteNote(String clientId, String noteId) async {
    try {
      await _gardenService.deleteGardenNote(clientId, noteId);
      _gardenNotes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete garden document
  Future<void> deleteDocument(String clientId, String documentId) async {
    try {
      await _gardenService.deleteGardenDocument(clientId, documentId);
      _gardenDocuments.removeWhere((doc) => doc.id == documentId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}