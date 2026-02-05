import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../../../core/services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  AdminProvider(this._adminService);

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  UserRole? _userRole;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _userRole == UserRole.admin || _userRole == UserRole.landscapeTeam;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.login(email, password);
      
      if (result.userRole == UserRole.admin || result.userRole == UserRole.landscapeTeam) {
        _isAuthenticated = true;
        _userRole = result.userRole;
        _currentUser = result.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Нямате администраторски права';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _adminService.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      _isAuthenticated = false;
      _userRole = null;
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createClient(Map<String, dynamic> clientData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = await _adminService.createClientProfile(clientData);
      _isLoading = false;
      notifyListeners();
      return client;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> addPlant(Map<String, dynamic> plantData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.addPlantToCatalog(plantData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignPlantsToClient(String clientId, List<String> plantIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.assignPlantsToClient(clientId, plantIds);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadMasterPlan(
    String clientId,
    String filePath,
    List<Map<String, String>> zones,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.uploadGardenMasterPlan(clientId, filePath, zones);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createZone(
    String clientId,
    String zoneName,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.createGardenZone(clientId, zoneName, description);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateZone(
    String clientId,
    String zoneId,
    String zoneName,
    String? description,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateGardenZone(clientId, zoneId, zoneName, description);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteZone(String clientId, String zoneId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteGardenZone(clientId, zoneId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getZones(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _adminService.getClientZones(clientId);
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}