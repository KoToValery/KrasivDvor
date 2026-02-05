import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider_new.dart';
import 'client_management_screen.dart';
import 'master_plan_upload_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Административен панел'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/welcome'),
            tooltip: 'Изход',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Overview
                _buildDashboardOverview(context, adminProvider),
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),
                
                // Recent Activity
                _buildRecentActivity(context, adminProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context, AdminProvider adminProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общ преглед',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Клиенти',
                  adminProvider.clients.length.toString(),
                  Icons.people,
                  Colors.blue,
                  context,
                ),
                _buildStatCard(
                  'Растения',
                  adminProvider.plants.length.toString(),
                  Icons.local_florist,
                  Colors.green,
                  context,
                ),
                _buildStatCard(
                  'Зони',
                  _calculateTotalZones(adminProvider).toString(),
                  Icons.layers,
                  Colors.orange,
                  context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Бързи действия',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickActionButton(
                  context,
                  'Управление на клиенти',
                  Icons.people,
                  Colors.blue,
                  () => context.pushNamed('admin-clients'),
                ),
                _buildQuickActionButton(
                  context,
                  'Качване на генплан',
                  Icons.upload_file,
                  Colors.green,
                  () => context.pushNamed('admin-master-plan'),
                ),
                _buildQuickActionButton(
                  context,
                  'Добавяне на растения',
                  Icons.add_photo_alternate,
                  Colors.purple,
                  () => context.pushNamed('admin-plants'),
                ),
                _buildQuickActionButton(
                  context,
                  'Управление на зони',
                  Icons.layers,
                  Colors.orange,
                  () => context.pushNamed('admin-clients'), // Zones are accessed via clients
                ),
                _buildQuickActionButton(
                  context,
                  'QR Кодове',
                  Icons.qr_code,
                  Colors.teal,
                  () => context.pushNamed('admin-qr-labels'),
                ),
                _buildQuickActionButton(
                  context,
                  'Контакти',
                  Icons.contacts,
                  Colors.indigo,
                  () => context.pushNamed('admin-clients'), // Contacts are client specific
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, AdminProvider adminProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Последна активност',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (adminProvider.clients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Все още няма активност'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminProvider.clients.length > 5 ? 5 : adminProvider.clients.length,
                itemBuilder: (context, index) {
                  final client = adminProvider.clients[adminProvider.clients.length - 1 - index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        client.fullName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(client.fullName),
                    subtitle: Text('${client.location} • ${client.createdAt.day}/${client.createdAt.month}/${client.createdAt.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editClient(context, client),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _editClient(BuildContext context, client) {
    // Navigate to client management screen with the specific client selected
    context.push('/admin/clients', extra: client);
  }

  int _calculateTotalZones(AdminProvider adminProvider) {
    int totalZones = 0;
    for (final client in adminProvider.clients) {
      totalZones += client.zones?.length ?? 0;
    }
    return totalZones;
  }
}