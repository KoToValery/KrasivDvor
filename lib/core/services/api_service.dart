import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl =
      'https://api.landscapeplants.com'; // Replace with actual API URL
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Mock data storage for development
  static final Map<String, List<Map<String, dynamic>>> _mockData = {
    'clients': [],
    'plants': [],
    'zones': [],
  };

  // Public method to access mock data for development
  static List<Map<String, dynamic>> getMockClients() =>
      List.from(_mockData['clients'] ?? []);
  static List<Map<String, dynamic>> getMockPlants() =>
      List.from(_mockData['plants'] ?? []);
  static List<Map<String, dynamic>> getMockZones() =>
      List.from(_mockData['zones'] ?? []);

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();
  String? _authToken;
  String? _refreshToken;
  UserRole? _userRole;

  // Initialize mock data
  ApiService() {
    _initializeMockData();
  }

  // Authentication
  void setAuthToken(String token, {String? refreshToken, UserRole? role}) {
    _authToken = token;
    _refreshToken = refreshToken;
    _userRole = role;
  }

  void clearAuthToken() {
    _authToken = null;
    _refreshToken = null;
    _userRole = null;
  }

  bool get isAuthenticated => _authToken != null;
  UserRole? get userRole => _userRole;

  /// Authenticate user with credentials
  Future<AuthResult> authenticate(String username) async {
    // MOCK AUTHENTICATION FOR DEVELOPMENT
    if (username == 'admin') {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay
      final authResult = AuthResult(
        accessToken: 'mock_admin_token',
        refreshToken: 'mock_admin_refresh_token',
        userRole: UserRole.admin,
        user: {
          'id': 'admin_1',
          'username': 'admin',
          'name': 'Administrator',
        },
      );
      setAuthToken(authResult.accessToken,
          refreshToken: authResult.refreshToken, role: authResult.userRole);
      return authResult;
    }

    if (username == 'client') {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay
      final authResult = AuthResult(
        accessToken: 'mock_client_token',
        refreshToken: 'mock_client_refresh_token',
        userRole: UserRole.client,
        user: {
          'id': 'client_1',
          'username': 'client',
          'name': 'Test Client',
        },
      );
      setAuthToken(authResult.accessToken,
          refreshToken: authResult.refreshToken, role: authResult.userRole);
      return authResult;
    }

    // Test clients for development
    if (username == 'ivan') {
      await Future.delayed(const Duration(seconds: 1));
      final authResult = AuthResult(
        accessToken: 'mock_client_token_client_1',
        refreshToken: 'mock_client_refresh_token_client_1',
        userRole: UserRole.client,
        user: {
          'id': 'client_1',
          'username': 'ivan',
          'name': 'Иван Иванов',
        },
      );
      setAuthToken(authResult.accessToken,
          refreshToken: authResult.refreshToken, role: authResult.userRole);
      return authResult;
    }

    if (username == 'maria') {
      await Future.delayed(const Duration(seconds: 1));
      final authResult = AuthResult(
        accessToken: 'mock_client_token_client_2',
        refreshToken: 'mock_client_refresh_token_client_2',
        userRole: UserRole.client,
        user: {
          'id': 'client_2',
          'username': 'maria',
          'name': 'Мария Петрова',
        },
      );
      setAuthToken(authResult.accessToken,
          refreshToken: authResult.refreshToken, role: authResult.userRole);
      return authResult;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'username': username,
            }),
          )
          .timeout(timeout);

      final data = _handleResponse(response);

      final authResult = AuthResult.fromJson(data);
      setAuthToken(
        authResult.accessToken,
        refreshToken: authResult.refreshToken,
        role: authResult.userRole,
      );

      return authResult;
    } catch (e) {
      throw ApiException('Authentication failed: $e');
    }
  }

  /// Refresh authentication token
  Future<void> refreshAuthToken() async {
    if (_refreshToken == null) {
      throw ApiException('No refresh token available');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'refreshToken': _refreshToken,
            }),
          )
          .timeout(timeout);

      final data = _handleResponse(response);

      _authToken = data['accessToken'] as String;
      if (data['refreshToken'] != null) {
        _refreshToken = data['refreshToken'] as String;
      }
    } catch (e) {
      clearAuthToken();
      throw ApiException('Token refresh failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _client
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: _headers,
              body: json.encode({
                'refreshToken': _refreshToken,
              }),
            )
            .timeout(timeout);
      } catch (e) {
        // Ignore logout errors, clear tokens anyway
      }
    }

    clearAuthToken();
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET request with retry logic and token refresh
  Future<Map<String, dynamic>> get(String endpoint) async {
    // Check if this is a mock endpoint
    if (_isMockEndpoint(endpoint)) {
      return _handleMockGet(endpoint);
    }

    return _makeRequestWithRetry(() async {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    });
  }

  /// POST request with retry logic and token refresh
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    // Check if this is a mock endpoint
    if (_isMockEndpoint(endpoint)) {
      return _handleMockPost(endpoint, data);
    }

    return _makeRequestWithRetry(() async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    });
  }

  /// PUT request with retry logic and token refresh
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    // Check if this is a mock endpoint
    if (_isMockEndpoint(endpoint)) {
      return _handleMockPut(endpoint, data);
    }

    return _makeRequestWithRetry(() async {
      final response = await _client
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(timeout);

      return _handleResponse(response);
    });
  }

  /// DELETE request with retry logic and token refresh
  Future<Map<String, dynamic>> delete(String endpoint) async {
    // Check if this is a mock endpoint
    if (_isMockEndpoint(endpoint)) {
      return _handleMockDelete(endpoint);
    }

    return _makeRequestWithRetry(() async {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: _headers,
          )
          .timeout(timeout);

      return _handleResponse(response);
    });
  }

  /// File upload with progress tracking
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
    Function(int, int)? onProgress,
  }) async {
    return _makeRequestWithRetry(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add headers (excluding Content-Type as it's set automatically for multipart)
      final headers = Map<String, String>.from(_headers);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(timeout);

      // Track progress if callback provided
      if (onProgress != null) {
        final contentLength = streamedResponse.contentLength ?? 0;
        int received = 0;

        final responseBytes = <int>[];
        await for (final chunk in streamedResponse.stream) {
          responseBytes.addAll(chunk);
          received += chunk.length;
          onProgress(received, contentLength);
        }

        final response = http.Response.bytes(
          responseBytes,
          streamedResponse.statusCode,
          headers: streamedResponse.headers,
        );

        return _handleResponse(response);
      } else {
        final response = await http.Response.fromStream(streamedResponse);
        return _handleResponse(response);
      }
    });
  }

  /// Bulk upload multiple files
  Future<Map<String, dynamic>> uploadMultipleFiles(
    String endpoint,
    Map<String, String> filePaths, {
    Map<String, String>? additionalFields,
  }) async {
    return _makeRequestWithRetry(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add headers
      final headers = Map<String, String>.from(_headers);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add files
      for (final entry in filePaths.entries) {
        final file = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(file);
      }

      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    });
  }

  /// Make request with automatic retry and token refresh
  Future<Map<String, dynamic>> _makeRequestWithRetry(
    Future<Map<String, dynamic>> Function() requestFunction,
  ) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await requestFunction();
      } on ApiException catch (e) {
        // If unauthorized and we have a refresh token, try to refresh
        if (e.statusCode == 401 && _refreshToken != null && retryCount == 0) {
          try {
            await refreshAuthToken();
            retryCount++;
            continue;
          } catch (refreshError) {
            throw ApiException('Authentication failed: $refreshError');
          }
        }

        // If it's a network error and we haven't exceeded retries
        if (_isRetryableError(e) && retryCount < maxRetries - 1) {
          retryCount++;
          await Future.delayed(
              Duration(seconds: retryCount * 2)); // Exponential backoff
          continue;
        }

        rethrow;
      } catch (e) {
        // Handle other types of errors (network, timeout, etc.)
        if (retryCount < maxRetries - 1 && _isNetworkError(e)) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }

        throw ApiException('Network error: $e');
      }
    }

    throw ApiException('Max retries exceeded');
  }

  bool _isRetryableError(ApiException e) {
    // Retry on server errors (5xx) and some client errors
    return e.statusCode != null &&
        (e.statusCode! >= 500 ||
            e.statusCode == 408 || // Request Timeout
            e.statusCode == 429); // Too Many Requests
  }

  bool _isNetworkError(dynamic error) {
    return error is SocketException ||
        error is HttpException ||
        error.toString().contains('timeout') ||
        error.toString().contains('connection');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Invalid JSON response: $e');
      }
    } else {
      String errorMessage = 'HTTP $statusCode';
      Map<String, dynamic>? errorData;

      try {
        errorData = json.decode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        // Use default error message if JSON parsing fails
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      throw ApiException(errorMessage, statusCode, errorData);
    }
  }

  void dispose() {
    _client.close();
  }

  // Mock endpoint handlers
  bool _isMockEndpoint(String endpoint) {
    return endpoint.startsWith('/admin/') ||
        endpoint.startsWith('/plants') ||
        endpoint.startsWith('/clients');
  }

  Future<Map<String, dynamic>> _handleMockGet(String endpoint) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate network delay

    // Debug print to see what data we have
    print('DEBUG: Mock data plants count: ${_mockData['plants']?.length ?? 0}');
    print(
        'DEBUG: Mock data clients count: ${_mockData['clients']?.length ?? 0}');

    if (endpoint.startsWith('/admin/clients')) {
      if (endpoint.contains('/zones')) {
        // Get client zones
        final parts = endpoint.split('/');
        final clientId = parts[3];
        final zones = _mockData['zones']!
            .where((zone) => zone['clientId'] == clientId)
            .toList();
        return {'zones': zones};
      } else {
        // Get all clients
        return {'data': _mockData['clients']};
      }
    } else if (endpoint.startsWith('/admin/plants')) {
      return {'plants': _mockData['plants']};
    } else if (endpoint.startsWith('/plants')) {
      if (endpoint.contains('/search')) {
        // Search plants
        return {'data': _mockData['plants']};
      } else if (endpoint.contains('/compatible')) {
        // Get compatible plants
        return {'data': []};
      } else {
        // Get all plants
        print(
            'DEBUG: Returning all plants: ${_mockData['plants']?.length ?? 0} items');
        return {'data': _mockData['plants']};
      }
    } else if (endpoint.startsWith('/clients')) {
      // Get client data
      final parts = endpoint.split('/');
      if (parts.length > 2) {
        final clientId = parts[2];
        final client = _mockData['clients']!.firstWhere(
          (c) => c['id'] == clientId,
          orElse: () => {},
        );
        return {'data': client};
      }
      return {'data': _mockData['clients']};
    }

    throw ApiException('Endpoint not found: $endpoint', 404);
  }

  Future<Map<String, dynamic>> _handleMockPost(
      String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    if (endpoint == '/admin/clients') {
      // Create new client
      final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
      final clientData = {
        'id': clientId,
        'name': data['name'] ?? 'New Client',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'address': data['address'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'garden': {
          'id': 'garden_$clientId',
          'clientId': clientId,
          'zones': [],
          'plants': [],
          'masterPlan': null,
          'notes': [],
          'documents': [],
        },
      };

      _mockData['clients']!.add(clientData);

      // Also store in persistent storage
      await _storageService.storeGarden(clientId, clientData['garden']);

      return {'data': clientData, 'message': 'Client created successfully'};
    } else if (endpoint.startsWith('/admin/clients') &&
        endpoint.endsWith('/zones')) {
      // Create garden zone
      final parts = endpoint.split('/');
      final clientId = parts[3];
      final zoneId = 'zone_${DateTime.now().millisecondsSinceEpoch}';
      final zoneData = {
        'id': zoneId,
        'clientId': clientId,
        'name': data['name'],
        'description': data['description'],
        'createdAt': DateTime.now().toIso8601String(),
      };

      _mockData['zones']!.add(zoneData);
      return {'data': zoneData, 'message': 'Zone created successfully'};
    } else if (endpoint.startsWith('/admin/clients') &&
        endpoint.endsWith('/plants')) {
      // Assign plants to client
      return {
        'message': 'Plants assigned successfully',
        'data': {'success': true}
      };
    } else if (endpoint == '/admin/plants/bulk') {
      // Bulk import plants
      final plantsList = (data['plants'] as List).cast<Map<String, dynamic>>();
      for (final plant in plantsList) {
        final plantId = plant['id'] ??
            'plant_${DateTime.now().millisecondsSinceEpoch}_${plant['latinName'].hashCode}';
        final plantData = {
          ...plant,
          'id': plantId,
          'createdAt': DateTime.now().toIso8601String(),
        };
        _mockData['plants']!.add(plantData);
      }
      return {'message': '${plantsList.length} plants imported successfully'};
    } else if (endpoint.startsWith('/admin/plants')) {
      // Add plant to catalog
      final plantId = 'plant_${DateTime.now().millisecondsSinceEpoch}';
      final plantData = {
        'id': plantId,
        'name': data['name'] ?? 'New Plant',
        'latinName': data['latinName'] ?? '',
        'category': data['category'] ?? 'flowers',
        'createdAt': DateTime.now().toIso8601String(),
        ...data,
      };

      _mockData['plants']!.add(plantData);
      return {'data': plantData, 'message': 'Plant added successfully'};
    }

    throw ApiException('Endpoint not implemented: $endpoint', 501);
  }

  Future<Map<String, dynamic>> _handleMockPut(
      String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate network delay

    if (endpoint.startsWith('/admin/clients') && endpoint.contains('/zones/')) {
      // Update garden zone
      final parts = endpoint.split('/');
      final zoneId = parts[5];
      final index = _mockData['zones']!.indexWhere((z) => z['id'] == zoneId);

      if (index != -1) {
        _mockData['zones']![index] = {
          ..._mockData['zones']![index],
          'name': data['name'] ?? _mockData['zones']![index]['name'],
          'description':
              data['description'] ?? _mockData['zones']![index]['description'],
          'updatedAt': DateTime.now().toIso8601String(),
        };
        return {
          'data': _mockData['zones']![index],
          'message': 'Zone updated successfully'
        };
      }
    } else if (endpoint.startsWith('/plants/')) {
      // Update plant
      final parts = endpoint.split('/');
      final plantId = parts[2];
      final index = _mockData['plants']!.indexWhere((p) => p['id'] == plantId);

      if (index != -1) {
        _mockData['plants']![index] = {
          ..._mockData['plants']![index],
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        return {
          'data': _mockData['plants']![index],
          'message': 'Plant updated successfully'
        };
      }
    }

    throw ApiException('Endpoint not found or not implemented: $endpoint', 404);
  }

  Future<Map<String, dynamic>> _handleMockDelete(String endpoint) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate network delay

    if (endpoint.startsWith('/admin/clients') && endpoint.contains('/zones/')) {
      // Delete garden zone
      final parts = endpoint.split('/');
      final zoneId = parts[5];
      _mockData['zones']!.removeWhere((z) => z['id'] == zoneId);
      return {'message': 'Zone deleted successfully'};
    } else if (endpoint.startsWith('/plants/')) {
      // Delete plant
      final parts = endpoint.split('/');
      final plantId = parts[2];
      _mockData['plants']!.removeWhere((p) => p['id'] == plantId);
      return {'message': 'Plant deleted successfully'};
    }

    throw ApiException('Endpoint not found or not implemented: $endpoint', 404);
  }
}

/// Authentication result model
class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final UserRole userRole;
  final Map<String, dynamic> user;

  AuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.userRole,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      userRole: UserRole.values.firstWhere(
        (role) => role.name == json['userRole'],
        orElse: () => UserRole.client,
      ),
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

/// User roles in the system
enum UserRole {
  admin,
  landscapeTeam,
  client,
}

/// API Exception with enhanced error information
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  ApiException(this.message, [this.statusCode, this.errorData]);

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

// Initialize mock data with comprehensive test data
void _initializeMockData() {
  // Initialize plants data
  if (ApiService._mockData['plants']!.isEmpty) {
    ApiService._mockData['plants']!.addAll([
      // Trees
      {
        'id': 'plant_1',
        'latinName': 'Acer platanoides',
        'bulgarianName': 'Клен остролистен',
        'category': 'trees',
        'imageUrls': [
          'https://example.com/maple1.jpg',
          'https://example.com/maple2.jpg'
        ],
        'characteristics': {
          'description':
              'Голямо дърво с красиви листа, достига до 25 метра височина',
          'lightRequirement': 'fullSun',
          'waterRequirement': 'moderate',
          'preferredSoil': 'loam',
          'hardinessZone': 5,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 7,
            'instructions': 'Поливай дълбоко веднъж седмично'
          },
          'fertilizing': {
            'frequencyDays': 180,
            'instructions': 'Пролетно и есенно торене'
          },
          'pruning': {
            'seasons': ['winter'],
            'instructions': 'Зимна стрижка за форма'
          },
          'seasonalCare': [
            {'season': 'spring', 'instructions': 'Проверка за болести'},
            {'season': 'autumn', 'instructions': 'Събиране на листа'}
          ],
        },
        'specifications': {
          'maxHeightCm': 2500,
          'maxWidthCm': 1500,
          'bloomSeason': ['spring'],
          'growthRate': 'moderate',
        },
        'compatiblePlantIds': ['plant_3', 'plant_5'],
        'toxicity': {'level': 'none', 'warning': null},
        'priceCategory': 'premium',
        'qrCode': 'qr_plant_1',
      },
      {
        'id': 'plant_2',
        'latinName': 'Quercus robur',
        'bulgarianName': 'Бял дъб',
        'category': 'trees',
        'imageUrls': ['https://example.com/oak1.jpg'],
        'characteristics': {
          'description': 'Мощно дърво с дълъг живот, достига до 40 метра',
          'lightRequirement': 'fullSun',
          'waterRequirement': 'low',
          'preferredSoil': 'clay',
          'hardinessZone': 4,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 14,
            'instructions': 'Минимален полив след засаждане'
          },
          'fertilizing': {
            'frequencyDays': 365,
            'instructions': 'Ежегодно торене'
          },
          'pruning': {
            'seasons': ['winter'],
            'instructions': 'Минимална стрижка'
          },
          'seasonalCare': [
            {'season': 'spring', 'instructions': 'Проверка за жълти листа'}
          ],
        },
        'specifications': {
          'maxHeightCm': 4000,
          'maxWidthCm': 2000,
          'bloomSeason': ['spring'],
          'growthRate': 'slow',
        },
        'compatiblePlantIds': ['plant_4', 'plant_6'],
        'toxicity': {'level': 'none', 'warning': null},
        'priceCategory': 'premium',
        'qrCode': 'qr_plant_2',
      },
      // Shrubs
      {
        'id': 'plant_3',
        'latinName': 'Rhododendron ponticum',
        'bulgarianName': 'Рододендрон',
        'category': 'shrubs',
        'imageUrls': [
          'https://example.com/rhodo1.jpg',
          'https://example.com/rhodo2.jpg'
        ],
        'characteristics': {
          'description': 'Цветущ храст с красиви розови цветове',
          'lightRequirement': 'partialShade',
          'waterRequirement': 'high',
          'preferredSoil': 'peat',
          'hardinessZone': 6,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 3,
            'instructions': 'Редовен полив, предпочита влажна почва'
          },
          'fertilizing': {
            'frequencyDays': 90,
            'instructions': 'Киселинно торене през пролетта'
          },
          'pruning': {
            'seasons': ['spring'],
            'instructions': 'Стрижка след цъфтене'
          },
          'seasonalCare': [
            {'season': 'winter', 'instructions': 'Защита от студ'},
            {
              'season': 'summer',
              'instructions': 'Мулчиране за запазване на влага'
            }
          ],
        },
        'specifications': {
          'maxHeightCm': 150,
          'maxWidthCm': 120,
          'bloomSeason': ['spring'],
          'growthRate': 'moderate',
        },
        'compatiblePlantIds': ['plant_1', 'plant_5'],
        'toxicity': {'level': 'moderate', 'warning': 'Листата са токсични'},
        'priceCategory': 'standard',
        'qrCode': 'qr_plant_3',
      },
      {
        'id': 'plant_4',
        'latinName': 'Berberis thunbergii',
        'bulgarianName': 'Берберис',
        'category': 'shrubs',
        'imageUrls': ['https://example.com/berberis1.jpg'],
        'characteristics': {
          'description': 'Шипест храст с ярко червени листа есента',
          'lightRequirement': 'fullSun',
          'waterRequirement': 'low',
          'preferredSoil': 'sand',
          'hardinessZone': 4,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 10,
            'instructions': 'Минимален полив след установяване'
          },
          'fertilizing': {
            'frequencyDays': 180,
            'instructions': 'Пролетно торене'
          },
          'pruning': {
            'seasons': ['spring'],
            'instructions': 'Формираща стрижка'
          },
          'seasonalCare': [],
        },
        'specifications': {
          'maxHeightCm': 120,
          'maxWidthCm': 100,
          'bloomSeason': ['spring'],
          'growthRate': 'fast',
        },
        'compatiblePlantIds': ['plant_2', 'plant_6'],
        'toxicity': {'level': 'mild', 'warning': 'Ягодите са леко токсични'},
        'priceCategory': 'budget',
        'qrCode': 'qr_plant_4',
      },
      // Flowers
      {
        'id': 'plant_5',
        'latinName': 'Rosa damascena',
        'bulgarianName': 'Роза дамаска',
        'category': 'flowers',
        'imageUrls': [
          'https://example.com/rose1.jpg',
          'https://example.com/rose2.jpg'
        ],
        'characteristics': {
          'description':
              'Ароматна роза с красиви цветове, идеална за ароматни градини',
          'lightRequirement': 'fullSun',
          'waterRequirement': 'moderate',
          'preferredSoil': 'loam',
          'hardinessZone': 5,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 3,
            'instructions': 'Поливай регулярно, избягвай мокри листа'
          },
          'fertilizing': {
            'frequencyDays': 30,
            'instructions': 'Пролетно и лятно торене'
          },
          'pruning': {
            'seasons': ['spring'],
            'instructions': 'Пролетна стрижка за нов растеж'
          },
          'seasonalCare': [
            {'season': 'autumn', 'instructions': 'Подготовка за зима'},
            {'season': 'winter', 'instructions': 'Защита от студ'}
          ],
        },
        'specifications': {
          'maxHeightCm': 150,
          'maxWidthCm': 100,
          'bloomSeason': ['spring', 'summer'],
          'growthRate': 'moderate',
        },
        'compatiblePlantIds': ['plant_1', 'plant_3'],
        'toxicity': {'level': 'none', 'warning': null},
        'priceCategory': 'standard',
        'qrCode': 'qr_plant_5',
      },
      {
        'id': 'plant_6',
        'latinName': 'Lavandula angustifolia',
        'bulgarianName': 'Лавандула',
        'category': 'flowers',
        'imageUrls': ['https://example.com/lavender1.jpg'],
        'characteristics': {
          'description': 'Ароматен храст с лилави цветове, привлича пчели',
          'lightRequirement': 'fullSun',
          'waterRequirement': 'low',
          'preferredSoil': 'sand',
          'hardinessZone': 5,
        },
        'careRequirements': {
          'watering': {
            'frequencyDays': 7,
            'instructions': 'Минимален полив, толерира засушаване'
          },
          'fertilizing': {
            'frequencyDays': 60,
            'instructions': 'Пролетно торене с малки количества'
          },
          'pruning': {
            'seasons': ['autumn'],
            'instructions': 'Есенна стрижка след цъфтене'
          },
          'seasonalCare': [
            {'season': 'spring', 'instructions': 'Разредяване на храстите'}
          ],
        },
        'specifications': {
          'maxHeightCm': 60,
          'maxWidthCm': 40,
          'bloomSeason': ['summer'],
          'growthRate': 'slow',
        },
        'compatiblePlantIds': ['plant_2', 'plant_4'],
        'toxicity': {'level': 'none', 'warning': null},
        'priceCategory': 'budget',
        'qrCode': 'qr_plant_6',
      },
    ]);
  }

  // Initialize clients with garden data
  if (ApiService._mockData['clients']!.isEmpty) {
    ApiService._mockData['clients']!.addAll([
      {
        'id': 'client_1',
        'name': 'Иван Иванов',
        'email': 'ivan.ivanov@example.com',
        'phone': '+359 888 123 456',
        'address': 'ул. Цариградско шосе 123, София',
        'createdAt': '2024-01-15T10:30:00Z',
        'garden': {
          'id': 'garden_client_1',
          'clientId': 'client_1',
          'zones': [
            {
              'id': 'zone_1_1',
              'name': 'Предна част',
              'description': 'Основен вход и пътеки',
              'plantIds': ['plant_5', 'plant_6'],
              'coordinates': {'x': 10, 'y': 10, 'width': 300, 'height': 150}
            },
            {
              'id': 'zone_1_2',
              'name': 'Страничен двор',
              'description': 'Зона за по-големи растения',
              'plantIds': ['plant_1'],
              'coordinates': {'x': 320, 'y': 10, 'width': 250, 'height': 200}
            },
            {
              'id': 'zone_1_3',
              'name': 'Задна част',
              'description': 'Зеленчукова градина',
              'plantIds': [],
              'coordinates': {'x': 10, 'y': 170, 'width': 300, 'height': 180}
            }
          ],
          'plants': [
            {
              'id': 'instance_1_1',
              'plantId': 'plant_5',
              'zoneId': 'zone_1_1',
              'datePlanted': '2024-03-15',
              'status': 'established',
              'notes': 'Засадена пролетта, много добре се развива',
              'photos': ['https://example.com/rose_garden1.jpg']
            },
            {
              'id': 'instance_1_2',
              'plantId': 'plant_6',
              'zoneId': 'zone_1_1',
              'datePlanted': '2024-03-15',
              'status': 'established',
              'notes': 'Перфектно цъфти през лятото',
              'photos': ['https://example.com/lavender_garden1.jpg']
            },
            {
              'id': 'instance_1_3',
              'plantId': 'plant_1',
              'zoneId': 'zone_1_2',
              'datePlanted': '2023-11-10',
              'status': 'established',
              'notes': 'Млад клен, добре се адаптира',
              'photos': ['https://example.com/maple_garden1.jpg']
            }
          ],
          'masterPlan': {
            'url': 'https://example.com/masterplan_client1.pdf',
            'uploadedAt': '2024-01-20T09:00:00Z',
            'zonesLegend': [
              {'number': 1, 'name': 'Предна част', 'color': '#FF6B6B'},
              {'number': 2, 'name': 'Страничен двор', 'color': '#4ECDC4'},
              {'number': 3, 'name': 'Задна част', 'color': '#45B7D1'}
            ]
          },
          'notes': [
            {
              'id': 'note_1_1',
              'content': 'Редовен полив 3 пъти седмично през лятото',
              'createdAt': '2024-03-20T14:30:00Z',
              'createdBy': 'admin'
            },
            {
              'id': 'note_1_2',
              'content': 'Добави още лавандула в зона 1',
              'createdAt': '2024-04-05T10:15:00Z',
              'createdBy': 'client'
            }
          ],
          'documents': [
            {
              'id': 'doc_1_1',
              'name': 'Гаранция за растенията',
              'type': 'warranty',
              'url': 'https://example.com/warranty_client1.pdf',
              'uploadedAt': '2024-01-20T09:30:00Z'
            }
          ]
        }
      },
      {
        'id': 'client_2',
        'name': 'Мария Петрова',
        'email': 'maria.petrova@example.com',
        'phone': '+359 888 987 654',
        'address': 'бул. Александър Малинов 45, София',
        'createdAt': '2024-01-20T14:15:00Z',
        'garden': {
          'id': 'garden_client_2',
          'clientId': 'client_2',
          'zones': [
            {
              'id': 'zone_2_1',
              'name': 'Главна алея',
              'description': 'Централна пътека с декоративни храсти',
              'plantIds': ['plant_3', 'plant_4'],
              'coordinates': {'x': 50, 'y': 50, 'width': 400, 'height': 100}
            },
            {
              'id': 'zone_2_2',
              'name': 'Сенчеста зона',
              'description': 'За растения, които предпочитат сянка',
              'plantIds': ['plant_2'],
              'coordinates': {'x': 50, 'y': 160, 'width': 200, 'height': 150}
            },
            {
              'id': 'zone_2_3',
              'name': 'Слънчева тераса',
              'description': 'Открито пространство за слънцелюбиви растения',
              'plantIds': ['plant_5'],
              'coordinates': {'x': 260, 'y': 160, 'width': 190, 'height': 150}
            }
          ],
          'plants': [
            {
              'id': 'instance_2_1',
              'plantId': 'plant_3',
              'zoneId': 'zone_2_1',
              'datePlanted': '2024-02-28',
              'status': 'newlyPlanted',
              'notes': 'Насадени преди месец, нуждае се от допълнителен полив',
              'photos': []
            },
            {
              'id': 'instance_2_2',
              'plantId': 'plant_4',
              'zoneId': 'zone_2_1',
              'datePlanted': '2024-02-28',
              'status': 'newlyPlanted',
              'notes': 'Много добре се развиват',
              'photos': []
            },
            {
              'id': 'instance_2_3',
              'plantId': 'plant_2',
              'zoneId': 'zone_2_2',
              'datePlanted': '2023-10-15',
              'status': 'established',
              'notes': 'Здрав дъб, изисква минимална грижа',
              'photos': ['https://example.com/oak_garden1.jpg']
            },
            {
              'id': 'instance_2_4',
              'plantId': 'plant_5',
              'zoneId': 'zone_2_3',
              'datePlanted': '2024-04-10',
              'status': 'newlyPlanted',
              'notes': 'Нови рози, нуждае се от внимателно наблюдение',
              'photos': []
            }
          ],
          'masterPlan': {
            'url': 'https://example.com/masterplan_client2.pdf',
            'uploadedAt': '2024-01-25T11:00:00Z',
            'zonesLegend': [
              {'number': 1, 'name': 'Главна алея', 'color': '#96CEB4'},
              {'number': 2, 'name': 'Сенчеста зона', 'color': '#FFEAA7'},
              {'number': 3, 'name': 'Слънчева тераса', 'color': '#DDA0DD'}
            ]
          },
          'notes': [
            {
              'id': 'note_2_1',
              'content': 'Клиентът иска да добави още рододендрони',
              'createdAt': '2024-03-10T16:45:00Z',
              'createdBy': 'admin'
            }
          ],
          'documents': [
            {
              'id': 'doc_2_1',
              'name': 'Проектна документация',
              'type': 'project',
              'url': 'https://example.com/project_client2.pdf',
              'uploadedAt': '2024-01-25T11:30:00Z'
            }
          ]
        }
      }
    ]);
  }
}
