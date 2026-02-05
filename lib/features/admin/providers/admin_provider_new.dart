import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/admin_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/service_locator.dart';
import '../../../models/client.dart';
import '../../../models/plant.dart';
import '../../../models/plant_instance.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  AdminProvider(this._adminService);

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  UserRole? _userRole;
  Map<String, dynamic>? _currentUser;
  List<Client> _clients = [];
  List<Plant> _plants = [];
  List<Contact> _contacts = [];
  List<Zone> _zones = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin =>
      _userRole == UserRole.admin || _userRole == UserRole.landscapeTeam;
  Map<String, dynamic>? get currentUser => _currentUser;
  List<Client> get clients => _clients;
  List<Plant> get plants => _plants;
  List<Contact> get contacts => _contacts;
  List<Zone> get zones => _zones;

  Future<bool> login(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminService.login(username);

      if (result.userRole == UserRole.admin ||
          result.userRole == UserRole.landscapeTeam) {
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
      _clients = [];
      notifyListeners();
    }
  }

  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = Hive.box<Client>('clients');

      // Initialize default clients if box is empty
      if (box.isEmpty) {
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

        await box.put(client1.id, client1);
        await box.put(client2.id, client2);
      }

      _clients = box.values.toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createClient({
    required String fullName,
    required String location,
    String? address,
    String? phone,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final clientData = {
        'fullName': fullName,
        'location': location,
        'address': address,
        'phone': phone,
        'email': email,
        'username': _generateUsername(fullName),
        'createdAt': DateTime.now().toIso8601String(),
        'zones': [],
        'contacts': [],
        'preferences': {
          'notificationsEnabled': true,
          'reminderFrequency': 'daily',
          'language': 'bg',
        },
      };

      final newClientData = await _adminService.createClientProfile(clientData);
      final newClient = Client.fromJson(newClientData);
      _clients.add(newClient);
      await _saveClientToHive(newClient);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateClient(
      String clientId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updateClientProfile(clientId, updates);

      // Update local client
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final updatedClient = Client.fromJson({
          ..._clients[clientIndex].toJson(),
          ...updates,
        });
        _clients[clientIndex] = updatedClient;
        await _saveClientToHive(updatedClient);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadPlants({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from Hive first if not forced
      if (!forceRefresh && Hive.isBoxOpen('catalog_plants')) {
        final box = Hive.box<Plant>('catalog_plants');
        if (box.isNotEmpty) {
          _plants = box.values.toList();
          _isLoading = false;
          notifyListeners();
          // We could return here, but maybe we want to fetch in background?
          // For now, return to show data immediately.
          return;
        }
      }

      // If forced or empty, fetch from API
      final plantsData = await _adminService.getAllPlants();
      _plants = plantsData.map((data) => Plant.fromJson(data)).toList();

      // Save to Hive
      if (Hive.isBoxOpen('catalog_plants')) {
        final box = Hive.box<Plant>('catalog_plants');
        await box.clear();
        for (var plant in _plants) {
          await box.put(plant.id, plant);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try Hive first
      if (Hive.isBoxOpen('contacts')) {
        final box = Hive.box<Contact>('contacts');
        if (box.isNotEmpty) {
          _contacts = box.values.toList();
          _isLoading = false;
          notifyListeners();
        }
      }

      if (_contacts.isEmpty) {
        final contactsData = await _adminService.getAllContacts();
        _contacts = contactsData.map((data) => Contact.fromJson(data)).toList();

        // Save to Hive
        if (Hive.isBoxOpen('contacts')) {
          final box = Hive.box<Contact>('contacts');
          await box.clear();
          for (var contact in _contacts) {
            await box.put(contact.id, contact);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlantToCatalog(Map<String, dynamic> plantData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.addPlantToCatalog(plantData);

      // The service might not return the created plant with ID,
      // but if we generated ID in service or locally, we need it.
      // Assuming plantData has ID or we generate one for local

      // Reload plants to include the new one from server
      // Or manually add to local list and Hive

      // Let's reload for consistency with backend if possible,
      // but for offline support we should add manually.

      // If plantData doesn't have ID, we can't save to Hive properly as ID key.
      // We should probably rely on reloadPlants() which now saves to Hive.
      await loadPlants();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlantInCatalog(
      String plantId, Map<String, dynamic> plantData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.updatePlantInCatalog(plantId, plantData);
      await loadPlants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlantFromCatalog(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deletePlantFromCatalog(plantId);
      await loadPlants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> importPlantsFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        _isLoading = true;
        notifyListeners();

        final file = result.files.single;
        String content;
        if (kIsWeb) {
          content = utf8.decode(file.bytes!);
        } else {
          content = await File(file.path!).readAsString();
        }

        final List<dynamic> jsonList = jsonDecode(content);
        final List<Map<String, dynamic>> plants =
            jsonList.cast<Map<String, dynamic>>();

        await _adminService.bulkImportPlants(plants);
        await loadPlants();

        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadZones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final zonesData = await _adminService.getAllZones();
      _zones = zonesData.map((data) => Zone.fromJson(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Zone> getAllZones() {
    return _zones;
  }

  Future<void> addPlantToZone({
    required String clientId,
    required String zoneId,
    required String plantId,
    required int quantity,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.addPlantToZone(clientId, zoneId, plantId, quantity);

      // Update local state
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final zoneIndex =
            _clients[clientIndex].zones.indexWhere((z) => z.id == zoneId);
        if (zoneIndex != -1) {
          final plant = _plants.firstWhere((p) => p.id == plantId,
              orElse: () => Plant.empty());
          if (plant.id.isNotEmpty) {
            final zonePlant = ZonePlant(
              plantId: plantId,
              plantName: plant.bulgarianName,
              quantity: quantity,
              plantedDate: DateTime.now(),
              notes: notes,
              careHistory: {},
            );

            // Create new zone with added plant
            Zone currentZone = _clients[clientIndex].zones[zoneIndex];
            List<ZonePlant> newPlants = List.from(currentZone.plants)
              ..add(zonePlant);
            Zone updatedZone = currentZone.copyWith(plants: newPlants);

            await _saveZoneToHive(updatedZone);

            // Update client with new zone list
            List<Zone> newZones = List.from(_clients[clientIndex].zones);
            newZones[zoneIndex] = updatedZone;

            Client updatedClient =
                _clients[clientIndex].copyWith(zones: newZones);
            _clients[clientIndex] = updatedClient;
            await _saveClientToHive(updatedClient);

            // Generate reminders based on plant's care requirements
            try {
              final plantInstance = PlantInstance(
                id: '${zoneId}_${plantId}_${DateTime.now().millisecondsSinceEpoch}',
                plantId: plantId,
                zoneId: zoneId,
                plantedDate: DateTime.now(),
                plantedSize: PlantSize.medium, // Default assumption
                status: PlantStatus.healthy,
                progressPhotos: [],
                careHistory: [],
                notes: notes,
              );

              await ServiceLocator.careReminderService
                  .generateRemindersForPlant(
                clientId,
                plantInstance,
                plant,
              );
            } catch (e) {
              print('Error generating reminders: $e');
              // Don't fail the whole operation if reminders fail
            }
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact({
    required String type,
    required String name,
    required String role,
    String? phone,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contactData = {
        'type': type,
        'name': name,
        'role': role,
        'phone': phone,
        'email': email,
        'address': address,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final newContactData = await _adminService.addContact(contactData);

      // If service returns the created contact with ID
      // But AdminService.addContact returns Map<String, dynamic>
      // Let's assume it returns what we sent plus ID.

      // If the service is mocked, it might return mocked data.
      // If we are strictly offline first for now or syncing:

      // We need to construct Contact object.
      // Assuming newContactData has 'id'.

      // If we are in "mock" mode or "offline" mode, we might need to generate ID.
      final contactId = newContactData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final contactType = ContactType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
          orElse: () => ContactType.other);

      final newContact = Contact(
        id: contactId,
        name: name,
        type: contactType,
        phone: phone ?? '',
        email: email,
        role: role,
        isPrimary: false, // Default
      );

      _contacts.add(newContact);
      await _saveContactToHive(newContact);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateContact(
    Contact contact, {
    required String type,
    required String name,
    required String role,
    String? phone,
    String? email,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final contactData = {
        'type': type,
        'name': name,
        'role': role,
        'phone': phone,
        'email': email,
        'address': address,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _adminService.updateContact(contact.id, contactData);

      // Update local contact
      final contactIndex = _contacts.indexWhere((c) => c.id == contact.id);
      if (contactIndex != -1) {
        final updatedContact = Contact(
          id: contact.id,
          name: name,
          type: ContactType.values.firstWhere(
              (e) => e.toString().split('.').last == type,
              orElse: () => ContactType.other),
          phone: phone ?? '',
          email: email,
          role: role,
          isPrimary: contact.isPrimary,
        );
        _contacts[contactIndex] = updatedContact;
        await _saveContactToHive(updatedContact);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteContact(Contact contact) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.deleteContact(contact.id);

      // Remove from local list
      _contacts.removeWhere((c) => c.id == contact.id);
      await _deleteContactFromHive(contact.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadMasterPlan(
    String clientId,
    String planFile,
    List<Map<String, dynamic>>? zones,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.uploadGardenMasterPlan(clientId, planFile, zones);

      // Update local client
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        Client client = _clients[clientIndex];

        // Update master plan URL
        // In a real app, we'd get the URL from the service response.
        // For local/offline, we use the file path.
        client = client.copyWith(masterPlanUrl: planFile);

        // If zones were added/updated
        if (zones != null) {
          List<Zone> currentZones = List.from(client.zones);
          List<String> currentZoneIds = List.from(client.zoneIds);

          for (var zoneData in zones) {
            final zoneId = zoneData['id'];
            final zoneName = zoneData['name'];
            final zoneDesc = zoneData['description'];

            final zoneIndex = currentZones.indexWhere((z) => z.id == zoneId);
            if (zoneIndex != -1) {
              // Update existing zone
              currentZones[zoneIndex] = currentZones[zoneIndex].copyWith(
                name: zoneName,
                description: zoneDesc,
                properties: {
                  ...currentZones[zoneIndex].properties,
                  'description': zoneDesc,
                },
              );
              await _saveZoneToHive(currentZones[zoneIndex]);
            } else {
              // New zone
              final newZone = Zone(
                id: zoneId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: zoneName,
                originalName: zoneName,
                description: zoneDesc ?? '',
                plants: [],
                properties: {'description': zoneDesc},
              );
              currentZones.add(newZone);
              currentZoneIds.add(newZone.id);
              await _saveZoneToHive(newZone);
            }
          }
          client =
              client.copyWith(zones: currentZones, zoneIds: currentZoneIds);
        }

        _clients[clientIndex] = client;
        await _saveClientToHive(client);
      }

      _isLoading = false;
      notifyListeners();
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

      // Update local client
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final newZone = Zone(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: zoneName,
          originalName: zoneName,
          description: description ?? '',
          plants: [],
          properties: {},
        );

        Client client = _clients[clientIndex];
        List<Zone> newZones = List.from(client.zones)..add(newZone);
        List<String> newZoneIds = List.from(client.zoneIds)..add(newZone.id);

        Client updatedClient =
            client.copyWith(zones: newZones, zoneIds: newZoneIds);
        _clients[clientIndex] = updatedClient;

        await _saveZoneToHive(newZone);
        await _saveClientToHive(updatedClient);
      }

      _isLoading = false;
      notifyListeners();
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
      await _adminService.updateGardenZone(
          clientId, zoneId, zoneName, description);

      // Update local client
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        final zoneIndex =
            _clients[clientIndex].zones.indexWhere((z) => z.id == zoneId);
        if (zoneIndex != -1) {
          Zone currentZone = _clients[clientIndex].zones[zoneIndex];
          Zone updatedZone = currentZone.copyWith(name: zoneName);

          if (description != null) {
            updatedZone = updatedZone.copyWith(
              description: description,
              properties: {
                ...updatedZone.properties,
                'description': description,
              },
            );
          }

          // Update client
          List<Zone> newZones = List.from(_clients[clientIndex].zones);
          newZones[zoneIndex] = updatedZone;

          Client updatedClient =
              _clients[clientIndex].copyWith(zones: newZones);
          _clients[clientIndex] = updatedClient;

          await _saveZoneToHive(updatedZone);
          await _saveClientToHive(updatedClient);
        }
      }

      _isLoading = false;
      notifyListeners();
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

      // Update local client
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        Client client = _clients[clientIndex];
        List<Zone> newZones = List.from(client.zones)
          ..removeWhere((z) => z.id == zoneId);
        List<String> newZoneIds = List.from(client.zoneIds)..remove(zoneId);

        Client updatedClient =
            client.copyWith(zones: newZones, zoneIds: newZoneIds);
        _clients[clientIndex] = updatedClient;

        await _deleteZoneFromHive(zoneId);
        await _saveClientToHive(updatedClient);
      }

      _isLoading = false;
      notifyListeners();
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

  Future<void> _saveClientToHive(Client client) async {
    final box = Hive.box<Client>('clients');
    await box.put(client.id, client);
  }

  Future<void> _saveZoneToHive(Zone zone) async {
    final box = Hive.box<Zone>('zones');
    await box.put(zone.id, zone);
  }

  Future<void> _deleteZoneFromHive(String zoneId) async {
    final box = Hive.box<Zone>('zones');
    await box.delete(zoneId);
  }

  Future<void> _saveContactToHive(Contact contact) async {
    if (Hive.isBoxOpen('contacts')) {
      final box = Hive.box<Contact>('contacts');
      await box.put(contact.id, contact);
    }
  }

  Future<void> _deleteContactFromHive(String contactId) async {
    if (Hive.isBoxOpen('contacts')) {
      final box = Hive.box<Contact>('contacts');
      await box.delete(contactId);
    }
  }

  String _generateUsername(String fullName) {
    final nameParts = fullName.toLowerCase().split(' ');
    final baseUsername = nameParts.join('.');
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$baseUsername.$timestamp';
  }
}
