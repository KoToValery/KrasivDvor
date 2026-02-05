import 'package:hive/hive.dart';
import '../../../models/client_garden.dart';
import '../../../models/plant_instance.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class GardenService {
  final ApiService _apiService;
  final StorageService _storageService;
  static const String _gardenBoxName = 'gardens';
  static const String _plantInstanceBoxName = 'plant_instances';

  GardenService(this._apiService, this._storageService);

  /// Get client garden by client ID
  Future<ClientGarden> getClientGarden(String clientId) async {
    try {
      // Try to get from cache first
      final box = await Hive.openBox<ClientGarden>(_gardenBoxName);
      
      // Fetch from API
      final response = await _apiService.get('/gardens/$clientId');
      final garden = ClientGarden.fromJson(response);
      
      // Update cache
      await box.put(clientId, garden);
      
      return garden;
    } catch (e) {
      // If API fails, try to return cached data
      final box = await Hive.openBox<ClientGarden>(_gardenBoxName);
      final cachedGarden = box.get(clientId);
      
      if (cachedGarden != null) {
        return cachedGarden;
      }
      
      throw Exception('Failed to get client garden: $e');
    }
  }

  /// Add plant to client garden
  Future<PlantInstance> addPlantToGarden(
    String clientId,
    PlantInstance plant,
  ) async {
    try {
      final response = await _apiService.post(
        '/gardens/$clientId/plants',
        plant.toJson(),
      );
      
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await _cachePlantInstance(plantInstance);
      
      return plantInstance;
    } catch (e) {
      throw Exception('Failed to add plant to garden: $e');
    }
  }

  /// Get all plants in a client's garden
  Future<List<PlantInstance>> getGardenPlants(String clientId) async {
    try {
      final response = await _apiService.get('/gardens/$clientId/plants');
      final plantsData = response['plants'] as List;
      
      final plants = plantsData
          .map((json) => PlantInstance.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update cache
      final box = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
      for (final plant in plants) {
        await box.put(plant.id, plant);
      }
      
      return plants;
    } catch (e) {
      // Try to return cached data
      final box = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
      final cachedPlants = box.values.toList();
      
      if (cachedPlants.isNotEmpty) {
        return cachedPlants;
      }
      
      throw Exception('Failed to get garden plants: $e');
    }
  }

  /// Update plant instance status
  Future<PlantInstance> updatePlantStatus(
    String plantInstanceId,
    PlantStatus status,
  ) async {
    try {
      final response = await _apiService.put(
        '/plant-instances/$plantInstanceId/status',
        {'status': status.name},
      );
      
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await _cachePlantInstance(plantInstance);
      
      return plantInstance;
    } catch (e) {
      throw Exception('Failed to update plant status: $e');
    }
  }

  /// Add note to garden
  Future<GardenNote> addGardenNote(String clientId, GardenNote note) async {
    try {
      final response = await _apiService.post(
        '/gardens/$clientId/notes',
        note.toJson(),
      );
      
      return GardenNote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add garden note: $e');
    }
  }

  /// Get plants by zone
  Future<List<PlantInstance>> getPlantsByZone(
    String clientId,
    String zoneId,
  ) async {
    try {
      final response = await _apiService.get(
        '/gardens/$clientId/zones/$zoneId/plants',
      );
      
      final plantsData = response['plants'] as List;
      return plantsData
          .map((json) => PlantInstance.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get plants by zone: $e');
    }
  }

  /// Create or update garden zone
  Future<GardenZone> saveGardenZone(
    String clientId,
    GardenZone zone,
  ) async {
    try {
      final response = await _apiService.post(
        '/gardens/$clientId/zones',
        zone.toJson(),
      );
      
      return GardenZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save garden zone: $e');
    }
  }

  /// Delete garden zone
  Future<void> deleteGardenZone(String clientId, String zoneId) async {
    try {
      await _apiService.delete('/gardens/$clientId/zones/$zoneId');
    } catch (e) {
      throw Exception('Failed to delete garden zone: $e');
    }
  }

  /// Assign plant to zone
  Future<PlantInstance> assignPlantToZone(
    String plantInstanceId,
    String zoneId,
  ) async {
    try {
      final response = await _apiService.put(
        '/plant-instances/$plantInstanceId/zone',
        {'zoneId': zoneId},
      );
      
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await _cachePlantInstance(plantInstance);
      
      return plantInstance;
    } catch (e) {
      throw Exception('Failed to assign plant to zone: $e');
    }
  }

  /// Add care record to plant instance
  Future<CareRecord> addCareRecord(
    String plantInstanceId,
    CareRecord careRecord,
  ) async {
    try {
      final response = await _apiService.post(
        '/plant-instances/$plantInstanceId/care-records',
        careRecord.toJson(),
      );
      
      return CareRecord.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add care record: $e');
    }
  }

  /// Get plant instance by ID
  Future<PlantInstance> getPlantInstance(String plantInstanceId) async {
    try {
      // Try cache first
      final box = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
      
      // Fetch from API
      final response = await _apiService.get('/plant-instances/$plantInstanceId');
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await box.put(plantInstanceId, plantInstance);
      
      return plantInstance;
    } catch (e) {
      // Try cached data
      final box = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
      final cached = box.get(plantInstanceId);
      
      if (cached != null) {
        return cached;
      }
      
      throw Exception('Failed to get plant instance: $e');
    }
  }

  /// Update plant instance
  Future<PlantInstance> updatePlantInstance(PlantInstance plant) async {
    try {
      final response = await _apiService.put(
        '/plant-instances/${plant.id}',
        plant.toJson(),
      );
      
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await _cachePlantInstance(plantInstance);
      
      return plantInstance;
    } catch (e) {
      throw Exception('Failed to update plant instance: $e');
    }
  }

  /// Add progress photo to plant instance
  Future<PlantInstance> addProgressPhoto(
    String plantInstanceId,
    String photoUrl,
  ) async {
    try {
      final response = await _apiService.post(
        '/plant-instances/$plantInstanceId/photos',
        {'photoUrl': photoUrl},
      );
      
      final plantInstance = PlantInstance.fromJson(response);
      
      // Update cache
      await _cachePlantInstance(plantInstance);
      
      return plantInstance;
    } catch (e) {
      throw Exception('Failed to add progress photo: $e');
    }
  }

  /// Cache plant instance locally
  Future<void> _cachePlantInstance(PlantInstance plant) async {
    final box = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
    await box.put(plant.id, plant);
  }

  /// Upload photo for progress tracking
  Future<String> uploadProgressPhoto(String plantInstanceId, String filePath) async {
    try {
      // Upload photo to storage service
      final photoUrl = await _storageService.uploadFile(filePath, 'progress_photos');
      
      // Add photo to plant instance
      await addProgressPhoto(plantInstanceId, photoUrl);
      
      return photoUrl;
    } catch (e) {
      throw Exception('Failed to upload progress photo: $e');
    }
  }

  /// Upload document to garden
  Future<GardenDocument> uploadGardenDocument(
    String clientId,
    String filePath,
    String fileName,
    DocumentType type,
  ) async {
    try {
      // Upload document to storage service
      final fileUrl = await _storageService.uploadFile(filePath, 'garden_documents');
      
      final document = GardenDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        fileUrl: fileUrl,
        type: type,
        uploadedAt: DateTime.now(),
      );
      
      final response = await _apiService.post(
        '/gardens/$clientId/documents',
        document.toJson(),
      );
      
      return GardenDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload garden document: $e');
    }
  }

  /// Create garden note with optional photos
  Future<GardenNote> createGardenNote(
    String clientId,
    String content,
    List<String>? photoFilePaths,
  ) async {
    try {
      // Upload photos if provided
      final photoUrls = <String>[];
      if (photoFilePaths != null && photoFilePaths.isNotEmpty) {
        for (final filePath in photoFilePaths) {
          final photoUrl = await _storageService.uploadFile(filePath, 'garden_notes');
          photoUrls.add(photoUrl);
        }
      }
      
      final note = GardenNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        createdAt: DateTime.now(),
        photoUrls: photoUrls,
      );
      
      return await addGardenNote(clientId, note);
    } catch (e) {
      throw Exception('Failed to create garden note: $e');
    }
  }

  /// Get all garden notes for a client
  Future<List<GardenNote>> getGardenNotes(String clientId) async {
    try {
      final response = await _apiService.get('/gardens/$clientId/notes');
      final notesData = response['notes'] as List;
      
      return notesData
          .map((json) => GardenNote.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get garden notes: $e');
    }
  }

  /// Get all garden documents for a client
  Future<List<GardenDocument>> getGardenDocuments(String clientId) async {
    try {
      final response = await _apiService.get('/gardens/$clientId/documents');
      final documentsData = response['documents'] as List;
      
      return documentsData
          .map((json) => GardenDocument.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get garden documents: $e');
    }
  }

  /// Delete garden note
  Future<void> deleteGardenNote(String clientId, String noteId) async {
    try {
      await _apiService.delete('/gardens/$clientId/notes/$noteId');
    } catch (e) {
      throw Exception('Failed to delete garden note: $e');
    }
  }

  /// Delete garden document
  Future<void> deleteGardenDocument(String clientId, String documentId) async {
    try {
      await _apiService.delete('/gardens/$clientId/documents/$documentId');
    } catch (e) {
      throw Exception('Failed to delete garden document: $e');
    }
  }

  /// Get planting history for a client garden
  Future<List<PlantInstance>> getPlantingHistory(String clientId) async {
    try {
      final plants = await getGardenPlants(clientId);
      
      // Sort by planted date (newest first)
      plants.sort((a, b) => b.plantedDate.compareTo(a.plantedDate));
      
      return plants;
    } catch (e) {
      throw Exception('Failed to get planting history: $e');
    }
  }

  /// Get all zones for a client garden
  Future<List<GardenZone>> getGardenZones(String clientId) async {
    try {
      final response = await _apiService.get('/gardens/$clientId/zones');
      final zonesData = response['zones'] as List;
      
      return zonesData
          .map((json) => GardenZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get garden zones: $e');
    }
  }

  /// Rename garden zone
  Future<GardenZone> renameGardenZone(
    String clientId,
    String zoneId,
    String newName,
  ) async {
    try {
      final response = await _apiService.put(
        '/gardens/$clientId/zones/$zoneId',
        {'name': newName},
      );
      
      return GardenZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to rename garden zone: $e');
    }
  }

  /// Clear all cached garden data
  Future<void> clearCache() async {
    final gardenBox = await Hive.openBox<ClientGarden>(_gardenBoxName);
    final plantBox = await Hive.openBox<PlantInstance>(_plantInstanceBoxName);
    
    await gardenBox.clear();
    await plantBox.clear();
  }
}
