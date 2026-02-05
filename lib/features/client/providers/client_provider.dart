import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../models/client.dart';
import '../../../models/plant.dart';
import '../../../core/models/notification.dart';

class ClientProvider extends ChangeNotifier {
  Client? _currentClient;
  List<Zone> _zones = [];
  List<Plant> _plants = [];
  List<AppNotification> _notifications = [];
  String? _weatherCondition;
  double? _temperature;
  bool _isLoading = false;
  String? _error;

  // Getters
  Client? get currentClient => _currentClient;
  List<Zone> get zones => _zones;
  List<Plant> get plants => _plants;
  List<AppNotification> get notifications => _notifications;
  String? get weatherCondition => _weatherCondition;
  double? get temperature => _temperature;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load client data
  Future<void> loadClientData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate loading from local storage
      await Future.delayed(const Duration(seconds: 1));

      // Load client data from Hive
      final clientBox = Hive.box<Client>('clients');

      // Auto-seed if empty (Demo mode)
      if (clientBox.isEmpty) {
        final client1 = Client(
          id: 'client_1',
          username: 'ivan',
          fullName: 'Иван Иванов',
          location: 'София, кв. Бояна',
          address: 'ул. Секвоя 15',
          phone: '0888123456',
          email: 'ivan@example.com',
          createdAt: DateTime.now(),
          zones: [],
          zoneIds: [],
          contacts: [],
          preferences: {
            'notificationsEnabled': true,
            'reminderFrequency': 'daily',
            'language': 'bg',
          },
        );

        final client2 = Client(
          id: 'client_2',
          username: 'maria',
          fullName: 'Мария Петрова',
          location: 'Пловдив, Стария град',
          address: 'ул. Съборна 5',
          phone: '0888654321',
          email: 'maria@example.com',
          createdAt: DateTime.now(),
          zones: [],
          zoneIds: [],
          contacts: [],
          preferences: {
            'notificationsEnabled': true,
            'reminderFrequency': 'daily',
            'language': 'bg',
          },
        );

        await clientBox.put(client1.id, client1);
        await clientBox.put(client2.id, client2);
      }

      if (clientBox.isNotEmpty) {
        _currentClient = clientBox.getAt(0); // Get first client for demo

        // Load weather based on location
        if (_currentClient != null) {
          await _loadWeather(_currentClient!.location);
        }
      }

      // Load zones for this client
      final zoneBox = Hive.box<Zone>('zones');
      _zones = zoneBox.values
          .where((zone) => _currentClient?.zoneIds.contains(zone.id) ?? false)
          .toList();

      // Load plants for this client
      final plantBox = Hive.box<Plant>('catalog_plants');
      _plants = plantBox.values.toList();

      // Load notifications
      final notificationBox = Hive.box<AppNotification>('notifications');
      _notifications = notificationBox.values
          .where((notification) => notification.clientId == _currentClient?.id)
          .toList();
    } catch (e) {
      _error = 'Грешка при зареждане на данни: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update zone name
  Future<void> updateZoneName(String zoneId, String newName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final zoneIndex = _zones.indexWhere((zone) => zone.id == zoneId);
      if (zoneIndex != -1) {
        // Create new zone with updated name using copyWith
        final updatedZone = _zones[zoneIndex].copyWith(name: newName);
        _zones[zoneIndex] = updatedZone;

        // Update in Hive zones box
        final zoneBox = Hive.box<Zone>('zones');
        await zoneBox.put(zoneId, updatedZone);

        // Also update Client if exists
        if (_currentClient != null) {
          List<Zone> clientZones = List.from(_currentClient!.zones);
          final clientZoneIndex = clientZones.indexWhere((z) => z.id == zoneId);
          if (clientZoneIndex != -1) {
            clientZones[clientZoneIndex] = updatedZone;

            final updatedClient = _currentClient!.copyWith(zones: clientZones);
            _currentClient = updatedClient;

            final clientBox = Hive.box<Client>('clients');
            await clientBox.put(updatedClient.id, updatedClient);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'Грешка при актуализиране на зоната: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // Toggle notification (mark as completed/uncompleted)
  Future<void> toggleNotification(String notificationId, bool completed) async {
    try {
      final notificationIndex =
          _notifications.indexWhere((n) => n.id == notificationId);
      if (notificationIndex != -1) {
        final updatedNotification = _notifications[notificationIndex].copyWith(
          isCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
        );
        _notifications[notificationIndex] = updatedNotification;

        // Update in Hive
        final notificationBox = Hive.box<AppNotification>('notifications');
        await notificationBox.put(notificationId, updatedNotification);

        notifyListeners();
      }
    } catch (e) {
      _error = 'Грешка при актуализиране на нотификацията: $e';
      notifyListeners();
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    bool? wateringEnabled,
    bool? fertilizingEnabled,
    bool? pruningEnabled,
    int? wateringReminderDays,
    int? fertilizingReminderDays,
    int? pruningReminderDays,
  }) async {
    try {
      if (_currentClient != null) {
        // Create new client with updated settings using copyWith
        final updatedClient = _currentClient!.copyWith(
          wateringNotificationsEnabled: wateringEnabled,
          fertilizingNotificationsEnabled: fertilizingEnabled,
          pruningNotificationsEnabled: pruningEnabled,
          wateringReminderDays: wateringReminderDays,
          fertilizingReminderDays: fertilizingReminderDays,
          pruningReminderDays: pruningReminderDays,
        );

        _currentClient = updatedClient;

        // Update in Hive
        final clientBox = Hive.box<Client>('clients');
        await clientBox.put(updatedClient.id, updatedClient);

        notifyListeners();
      }
    } catch (e) {
      _error = 'Грешка при актуализиране на настройките: $e';
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notificationIndex =
          _notifications.indexWhere((n) => n.id == notificationId);
      if (notificationIndex != -1) {
        final updatedNotification =
            _notifications[notificationIndex].copyWith(isRead: true);
        _notifications[notificationIndex] = updatedNotification;

        // Update in Hive
        final notificationBox = Hive.box<AppNotification>('notifications');
        await notificationBox.put(notificationId, updatedNotification);

        notifyListeners();
      }
    } catch (e) {
      _error = 'Грешка при маркиране на нотификацията: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadClientData();
  }

  Future<void> _loadWeather(String location) async {
    // Mock weather service
    await Future.delayed(const Duration(milliseconds: 500));

    // Simple deterministic mock based on location string length
    if (location.length % 2 == 0) {
      _weatherCondition = 'Слънчево';
      _temperature = 24.5;
    } else {
      _weatherCondition = 'Облачно';
      _temperature = 18.0;
    }

    // Check if location contains specific keywords
    final loc = location.toLowerCase();
    if (loc.contains('софия') || loc.contains('sofia')) {
      _weatherCondition = 'Променлива облачност';
      _temperature = 21.0;
    } else if (loc.contains('варна') ||
        loc.contains('varna') ||
        loc.contains('море')) {
      _weatherCondition = 'Слънчево и ветровито';
      _temperature = 26.0;
    } else if (loc.contains('планина') || loc.contains('mountain')) {
      _weatherCondition = 'Дъждовно';
      _temperature = 15.0;
    }
  }
}
