import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AdminService {
  final ApiService _apiService;
  final StorageService _storageService;

  AdminService(this._apiService, this._storageService);

  Future<AuthResult> login(String username) async {
    final result = await _apiService.authenticate(username);

    // Store auth token for persistence
    await _storageService.setString('auth_token', result.accessToken);
    if (result.refreshToken != null) {
      await _storageService.setString('refresh_token', result.refreshToken!);
    }
    await _storageService.setString('user_role', result.userRole.name);

    return result;
  }

  Future<void> logout() async {
    await _apiService.logout();

    // Clear stored auth data
    await _storageService.remove('auth_token');
    await _storageService.remove('refresh_token');
    await _storageService.remove('user_role');
  }

  Future<Map<String, dynamic>> createClientProfile(
      Map<String, dynamic> profile) async {
    final response = await _apiService.post('/admin/clients', profile);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> addPlantToCatalog(Map<String, dynamic> plant) async {
    await _apiService.post('/admin/plants', plant);
  }

  Future<void> updatePlantInCatalog(
      String plantId, Map<String, dynamic> plant) async {
    await _apiService.put('/plants/$plantId', plant);
  }

  Future<void> deletePlantFromCatalog(String plantId) async {
    await _apiService.delete('/plants/$plantId');
  }

  Future<void> bulkImportPlants(List<Map<String, dynamic>> plants) async {
    await _apiService.post('/admin/plants/bulk', {'plants': plants});
  }

  Future<void> uploadGardenMasterPlan(
    String clientId,
    String planFile,
    List<Map<String, dynamic>>? zones,
  ) async {
    // Upload the master plan file
    await _apiService.uploadFile(
      '/admin/clients/$clientId/master-plan',
      planFile,
      'masterPlan',
    );

    // If zones are provided, create them
    if (zones != null && zones.isNotEmpty) {
      await _apiService.post(
        '/admin/clients/$clientId/zones',
        {'zones': zones},
      );
    }
  }

  Future<void> assignPlantsToClient(
      String clientId, List<String> plantIds) async {
    await _apiService.post('/admin/clients/$clientId/plants', {
      'plantIds': plantIds,
    });
  }

  Future<void> createGardenZone(
    String clientId,
    String zoneName,
    String? description,
  ) async {
    await _apiService.post('/admin/clients/$clientId/zones', {
      'name': zoneName,
      'description': description,
    });
  }

  Future<void> updateGardenZone(
    String clientId,
    String zoneId,
    String zoneName,
    String? description,
  ) async {
    await _apiService.put('/admin/clients/$clientId/zones/$zoneId', {
      'name': zoneName,
      'description': description,
    });
  }

  Future<void> deleteGardenZone(String clientId, String zoneId) async {
    await _apiService.delete('/admin/clients/$clientId/zones/$zoneId');
  }

  Future<List<Map<String, dynamic>>> getClientZones(String clientId) async {
    final response = await _apiService.get('/admin/clients/$clientId/zones');
    return List<Map<String, dynamic>>.from(response['zones'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllClients() async {
    final response = await _apiService.get('/admin/clients');
    return List<Map<String, dynamic>>.from(response['clients'] ?? []);
  }

  Future<Map<String, dynamic>> updateClientProfile(
      String clientId, Map<String, dynamic> updates) async {
    final response = await _apiService.put('/admin/clients/$clientId', updates);
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllPlants() async {
    final response = await _apiService.get('/admin/plants');
    return List<Map<String, dynamic>>.from(response['plants'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    final response = await _apiService.get('/admin/contacts');
    return List<Map<String, dynamic>>.from(response['contacts'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllZones() async {
    final response = await _apiService.get('/admin/zones');
    return List<Map<String, dynamic>>.from(response['zones'] ?? []);
  }

  Future<Map<String, dynamic>> addPlantToZone(
      String clientId, String zoneId, String plantId, int quantity) async {
    final response = await _apiService
        .post('/admin/clients/$clientId/zones/$zoneId/plants', {
      'plantId': plantId,
      'quantity': quantity,
    });
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addContact(
      Map<String, dynamic> contactData) async {
    final response = await _apiService.post('/admin/contacts', contactData);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateContact(
      String contactId, Map<String, dynamic> contactData) async {
    final response =
        await _apiService.put('/admin/contacts/$contactId', contactData);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteContact(String contactId) async {
    await _apiService.delete('/admin/contacts/$contactId');
  }
}
