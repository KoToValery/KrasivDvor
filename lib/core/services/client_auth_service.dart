import 'api_service.dart';

class ClientAuthService {
  final ApiService _apiService;
  String? _currentClientId;

  ClientAuthService(this._apiService);

  Future<AuthResult> login(String username) async {
    print('DEBUG: ClientAuthService.login called with username: $username');
    
    // Mock client authentication for development
    final mockClients = [
      {
        'username': 'ivan',
        'id': 'client_1',
        'name': 'Иван Иванов'
      },
      {
        'username': 'maria',
        'id': 'client_2',
        'name': 'Мария Петрова'
      }
    ];

    print('DEBUG: Checking credentials against ${mockClients.length} mock clients');
    
    final client = mockClients.firstWhere(
      (c) => c['username']?.toLowerCase() == username.toLowerCase(),
      orElse: () => {},
    );

    print('DEBUG: Found client: ${client.isEmpty ? 'NONE' : client['name']}');

    if (client.isEmpty) {
      print('DEBUG: Authentication failed - invalid username');
      throw Exception('Невалидно потребителско име');
    }

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    final authResult = AuthResult(
      accessToken: 'mock_client_token_${client['id']}',
      refreshToken: 'mock_client_refresh_token_${client['id']}',
      userRole: UserRole.client,
      user: {
        'id': client['id'],
        'username': client['username'],
        'name': client['name'],
      },
    );

    print('DEBUG: Setting auth token and storing client ID: ${client['id']}');
    
    _apiService.setAuthToken(
      authResult.accessToken, 
      refreshToken: authResult.refreshToken, 
      role: authResult.userRole
    );
    
    _currentClientId = client['id'] as String;
    
    print('DEBUG: Authentication successful, currentClientId: $_currentClientId');
    
    return authResult;
  }

  Future<void> logout() async {
    _apiService.clearAuthToken();
    _currentClientId = null;
  }

  bool get isAuthenticated => _apiService.isAuthenticated;
  UserRole? get userRole => _apiService.userRole;
  String? get currentClientId => _currentClientId;
}