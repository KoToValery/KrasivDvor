import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'services/service_locator.dart';
import '../features/plant_catalog/providers/plant_catalog_provider.dart';
import '../features/garden_management/providers/garden_provider.dart';
import '../features/care_reminders/providers/care_reminder_provider.dart';
import '../features/admin/providers/admin_provider_new.dart';
import '../features/client/providers/client_provider.dart';

class LandscapePlantCatalogApp extends StatelessWidget {
  const LandscapePlantCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlantCatalogProvider(
            ServiceLocator.plantCatalogService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GardenProvider(
            ServiceLocator.gardenService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CareReminderProvider(
            ServiceLocator.careReminderService,
            ServiceLocator.notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            ServiceLocator.adminService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ClientProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Landscape Plant Catalog',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
