import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/app.dart';
import 'core/services/service_locator.dart';
import 'core/services/pwa_service.dart';
import 'core/services/offline_sync_service.dart';
import 'models/care_reminder.dart';
import 'models/plant_instance.dart';
import 'models/plant.dart';
import 'models/client.dart';
import 'core/models/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive Adapters
  if (!Hive.isAdapterRegistered(17))
    Hive.registerAdapter(CareReminderAdapter());
  if (!Hive.isAdapterRegistered(18))
    Hive.registerAdapter(ReminderFrequencyAdapter());
  if (!Hive.isAdapterRegistered(19))
    Hive.registerAdapter(WeatherDependencyAdapter());
  if (!Hive.isAdapterRegistered(32))
    Hive.registerAdapter(FrequencyTypeAdapter());
  if (!Hive.isAdapterRegistered(33))
    Hive.registerAdapter(WeatherConditionAdapter());
  if (!Hive.isAdapterRegistered(31)) Hive.registerAdapter(CareTypeAdapter());

  // Register new adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PlantAdapter());
  if (!Hive.isAdapterRegistered(1))
    Hive.registerAdapter(PlantCharacteristicsAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(CareRequirementsAdapter());
  if (!Hive.isAdapterRegistered(3))
    Hive.registerAdapter(PlantSpecificationsAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ToxicityInfoAdapter());
  if (!Hive.isAdapterRegistered(5))
    Hive.registerAdapter(WateringScheduleAdapter());
  if (!Hive.isAdapterRegistered(45))
    Hive.registerAdapter(FertilizingScheduleAdapter());
  if (!Hive.isAdapterRegistered(7))
    Hive.registerAdapter(PruningScheduleAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(SeasonalCareAdapter());
  if (!Hive.isAdapterRegistered(9))
    Hive.registerAdapter(WinterizingScheduleAdapter());
  if (!Hive.isAdapterRegistered(20))
    Hive.registerAdapter(PlantCategoryAdapter());
  if (!Hive.isAdapterRegistered(21))
    Hive.registerAdapter(LightRequirementAdapter());
  if (!Hive.isAdapterRegistered(22))
    Hive.registerAdapter(WaterRequirementAdapter());
  if (!Hive.isAdapterRegistered(23)) Hive.registerAdapter(SoilTypeAdapter());
  if (!Hive.isAdapterRegistered(24)) Hive.registerAdapter(SeasonAdapter());
  if (!Hive.isAdapterRegistered(25)) Hive.registerAdapter(GrowthRateAdapter());
  if (!Hive.isAdapterRegistered(26))
    Hive.registerAdapter(ToxicityLevelAdapter());
  if (!Hive.isAdapterRegistered(27))
    Hive.registerAdapter(PriceCategoryAdapter());
  if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(ClientAdapter());
  if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(ZoneAdapter());
  if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(ZonePlantAdapter());
  if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(ContactAdapter());
  if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(ContactTypeAdapter());
  if (!Hive.isAdapterRegistered(6))
    Hive.registerAdapter(AppNotificationAdapter());

  // Initialize Firebase for push notifications
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Initialize service locator
  await ServiceLocator.init();

  // Initialize PWA service for web
  if (kIsWeb) {
    await PWAService().init();
    await OfflineSyncService().init();
  }

  runApp(const LandscapePlantCatalogApp());
}
