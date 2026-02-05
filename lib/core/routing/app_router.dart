import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/plant_catalog/screens/plant_catalog_screen.dart';
import '../../features/plant_catalog/screens/plant_detail_screen.dart';
import '../../features/garden_management/screens/garden_overview_screen.dart';
import '../../features/garden_management/screens/plant_instance_detail_screen.dart';
import '../../features/care_reminders/screens/care_reminders_screen.dart';
import '../../features/qr_scanner/screens/qr_scanner_screen.dart';
import '../../features/qr_scanner/screens/qr_display_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen_new.dart';
import '../../features/admin/screens/client_management_screen.dart';
import '../../features/admin/screens/plant_management_screen.dart';
import '../../features/admin/screens/master_plan_upload_screen.dart';
import '../../features/admin/screens/zone_management_screen.dart';
import '../../features/admin/screens/client_details_screen.dart';
import '../../features/admin/screens/plant_entry_screen.dart';
import '../../features/admin/screens/qr_label_generation_screen.dart';
import '../../features/admin/providers/admin_provider_new.dart';
import '../../models/client.dart';
import '../../models/plant.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/client_login_screen.dart';
import '../../features/client/screens/client_dashboard_screen.dart';
import '../../features/client/screens/client_zone_management_screen.dart';
import '../../features/client/screens/client_notification_screen.dart';
import '../services/service_locator.dart';
import '../services/api_service.dart';
import '../services/client_auth_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Welcome Screen
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Admin Authentication
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Client Authentication
      GoRoute(
        path: '/client/login',
        name: 'client-login',
        builder: (context, state) => const ClientLoginScreen(),
      ),

      GoRoute(
        path: '/admin',
        name: 'admin-alias',
        redirect: (context, state) => '/admin-dashboard',
      ),

      GoRoute(
        path: '/client-dashboard',
        name: 'client-dashboard-alias',
        redirect: (context, state) => '/client/dashboard',
      ),

      GoRoute(
        path: '/demo',
        name: 'demo',
        redirect: (context, state) => '/',
      ),

      // Main navigation with bottom navigation bar
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          // Plant Catalog
          GoRoute(
            path: '/',
            name: 'catalog',
            builder: (context, state) => const PlantCatalogScreen(),
            routes: [
              GoRoute(
                path: 'plant/:plantId',
                name: 'plant-detail',
                builder: (context, state) => PlantDetailScreen(
                  plantId: state.pathParameters['plantId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'qr',
                    name: 'plant-qr',
                    builder: (context, state) {
                      final plant = state.extra as Plant;
                      return QRDisplayScreen(plant: plant);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Garden Management
          GoRoute(
            path: '/garden',
            name: 'garden',
            builder: (context, state) {
              // Get client ID from query params or use default
              final clientId =
                  state.uri.queryParameters['clientId'] ?? 'default';
              return GardenOverviewScreen(clientId: clientId);
            },
            routes: [
              GoRoute(
                path: 'plant/:plantInstanceId',
                name: 'plant-instance-detail',
                builder: (context, state) => PlantInstanceDetailScreen(
                  plantInstanceId: state.pathParameters['plantInstanceId']!,
                ),
              ),
            ],
          ),

          // Care Reminders
          GoRoute(
            path: '/reminders',
            name: 'reminders',
            builder: (context, state) {
              // Get client ID from query params or use default
              final clientId =
                  state.uri.queryParameters['clientId'] ?? 'default';
              return CareRemindersScreen(clientId: clientId);
            },
          ),

          // QR Scanner
          GoRoute(
            path: '/scanner',
            name: 'scanner',
            builder: (context, state) => const QRScannerScreen(),
          ),
        ],
      ),

      // Client Dashboard (protected routes)
      GoRoute(
        path: '/client/dashboard',
        name: 'client-dashboard',
        builder: (context, state) => const ClientDashboardScreen(),
        redirect: (context, state) {
          // Check if client is authenticated
          final clientAuthService =
              ClientAuthService(ServiceLocator.apiService);
          if (!clientAuthService.isAuthenticated) {
            return '/client/login';
          }
          return null;
        },
        routes: [
          // Client Plant Catalog
          GoRoute(
            path: 'catalog',
            name: 'client-catalog',
            builder: (context, state) => const PlantCatalogScreen(),
            routes: [
              GoRoute(
                path: 'plant/:plantId',
                name: 'client-plant-detail',
                builder: (context, state) => PlantDetailScreen(
                  plantId: state.pathParameters['plantId']!,
                ),
              ),
            ],
          ),

          // Client Garden Management
          GoRoute(
            path: 'garden',
            name: 'client-garden',
            builder: (context, state) {
              final clientAuthService =
                  ClientAuthService(ServiceLocator.apiService);
              return GardenOverviewScreen(
                  clientId: clientAuthService.currentClientId ?? 'default');
            },
            routes: [
              GoRoute(
                path: 'plant/:plantInstanceId',
                name: 'client-plant-instance-detail',
                builder: (context, state) => PlantInstanceDetailScreen(
                  plantInstanceId: state.pathParameters['plantInstanceId']!,
                ),
              ),
            ],
          ),

          // Client Care Reminders
          GoRoute(
            path: 'reminders',
            name: 'client-reminders',
            builder: (context, state) {
              final clientAuthService =
                  ClientAuthService(ServiceLocator.apiService);
              return CareRemindersScreen(
                  clientId: clientAuthService.currentClientId ?? 'default');
            },
          ),

          // Client QR Scanner
          GoRoute(
            path: 'scanner',
            name: 'client-scanner',
            builder: (context, state) => const QRScannerScreen(),
          ),

          // Client Zones
          GoRoute(
            path: 'zones',
            name: 'client-zones',
            builder: (context, state) => const ClientZoneManagementScreen(),
          ),

          // Client Notifications
          GoRoute(
            path: 'notifications',
            name: 'client-notifications',
            builder: (context, state) => const ClientNotificationScreen(),
          ),

          // Client Settings
          GoRoute(
            path: 'settings',
            name: 'client-settings',
            builder: (context, state) => const ClientNotificationScreen(),
          ),

          // Client Progress
          GoRoute(
            path: 'progress',
            name: 'client-progress',
            builder: (context, state) => const ClientNotificationScreen(),
          ),
        ],
      ),

      // Admin Panel (separate from main navigation)
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
        redirect: (context, state) {
          // Check if user is authenticated as admin
          final apiService = ServiceLocator.apiService;
          if (!apiService.isAuthenticated) {
            return '/admin/login';
          }
          if (apiService.userRole != UserRole.admin &&
              apiService.userRole != UserRole.landscapeTeam) {
            return '/admin/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'clients',
            name: 'admin-clients',
            builder: (context, state) => const ClientManagementScreen(),
            routes: [
              GoRoute(
                path: ':clientId',
                name: 'admin-client-details',
                builder: (context, state) => ClientDetailsScreen(
                  clientId: state.pathParameters['clientId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'zones',
                    name: 'admin-zones',
                    builder: (context, state) => ZoneManagementScreen(
                      clientId: state.pathParameters['clientId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'plant-entry',
                    name: 'admin-plant-entry',
                    builder: (context, state) => PlantEntryScreen(
                      clientId: state.pathParameters['clientId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'master-plan',
                    name: 'admin-master-plan',
                    builder: (context, state) {
                      Client? client = state.extra as Client?;
                      if (client == null) {
                        final clientId = state.pathParameters['clientId'];
                        if (clientId != null) {
                          try {
                            final provider = Provider.of<AdminProvider>(context,
                                listen: false);
                            client = provider.clients
                                .firstWhere((c) => c.id == clientId);
                          } catch (_) {}
                        }
                      }
                      return MasterPlanUploadScreen(client: client);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'plants',
            name: 'admin-plants',
            builder: (context, state) => const PlantManagementScreen(),
          ),
          GoRoute(
            path: 'qr-labels',
            name: 'admin-qr-labels',
            builder: (context, state) => const QRLabelGenerationScreen(),
          ),
        ],
      ),
    ],
  );
}
