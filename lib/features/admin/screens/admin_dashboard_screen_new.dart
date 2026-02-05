import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider_new.dart';
import '../../../models/client.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadClients();
      context.read<AdminProvider>().loadPlants();
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
            tooltip: 'Изход',
            onPressed: () async {
              final adminProvider = context.read<AdminProvider>();
              await adminProvider.logout();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildQuickStats(context, adminProvider),
                const SizedBox(height: 24),

                // Main Actions Grid
                _buildMainActionsGrid(context),
                const SizedBox(height: 24),

                // Recent Clients
                _buildRecentClientsSection(context, adminProvider),
              ],
            ),
          );
        },
      ),
      // Floating Action Button for quick client creation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClientDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Нов клиент'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AdminProvider adminProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Бърза статистика',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  title: 'Общо клиенти',
                  value: adminProvider.clients.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Активни градини',
                  value: adminProvider.clients
                      .where((client) => client.masterPlanUrl != null)
                      .length
                      .toString(),
                  icon: Icons.local_florist,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Растения в каталог',
                  value: adminProvider.plants.length.toString(),
                  icon: Icons.grass,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Основни действия',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _AdminCard(
              title: 'Управление на клиенти',
              subtitle: 'Създайте и управлявайте клиентски профили',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => context.go('/admin-dashboard/clients'),
            ),
            _AdminCard(
              title: 'Управление на растения',
              subtitle: 'Добавяйте и редактирайте растения в каталога',
              icon: Icons.local_florist,
              color: Colors.green,
              onTap: () => context.go('/admin-dashboard/plants'),
            ),
            _AdminCard(
              title: 'Качване на мастър план',
              subtitle: 'Качете генплан със зони за клиент',
              icon: Icons.upload_file,
              color: Colors.orange,
              onTap: () => context.go('/admin-dashboard/clients'),
            ),
            _AdminCard(
              title: 'Управление на зони',
              subtitle: 'Преименувайте и организирайте зоните',
              icon: Icons.map,
              color: Colors.purple,
              onTap: () => context.go('/admin-dashboard/clients'),
            ),
            _AdminCard(
              title: 'QR етикети',
              subtitle: 'Генерирайте QR кодове за растения',
              icon: Icons.qr_code,
              color: Colors.teal,
              onTap: () => context.go('/admin-dashboard/qr-labels'),
            ),
            _AdminCard(
              title: 'Добавяне на растения',
              subtitle: 'Добавете нови растения към каталога',
              icon: Icons.add_circle,
              color: Colors.red,
              onTap: () => _showAddPlantDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentClientsSection(
      BuildContext context, AdminProvider adminProvider) {
    final recentClients = adminProvider.clients.take(5).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Скорошни клиенти',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/admin-dashboard/clients'),
                  child: const Text('Всички'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentClients.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Все още няма клиенти'),
                ),
              )
            else
              Column(
                children: recentClients
                    .map((client) => _ClientListItem(
                          client: client,
                          onTap: () => _showClientDetails(context, client),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateClientDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final locationController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Създаване на нов клиент'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Име на клиент',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Моля въведете име';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Местоположение на градината',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Моля въведете местоположение';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Адрес (незадължително)',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон (незадължително)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (незадължително)',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _createClient(
                  context,
                  fullNameController.text,
                  locationController.text,
                  addressController.text,
                  phoneController.text,
                  emailController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Създай'),
          ),
        ],
      ),
    );
  }

  void _createClient(
    BuildContext context,
    String fullName,
    String location,
    String address,
    String phone,
    String email,
  ) {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.createClient(
      fullName: fullName,
      location: location,
      address: address,
      phone: phone,
      email: email,
    );
  }

  void _showClientDetails(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Местоположение'),
                subtitle: Text(client.location),
              ),
              if (client.address != null)
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Адрес'),
                  subtitle: Text(client.address!),
                ),
              if (client.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Телефон'),
                  subtitle: Text(client.phone!),
                ),
              if (client.email != null)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(client.email!),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Създаден на'),
                subtitle: Text(client.createdAt.toString().substring(0, 10)),
              ),
              ListTile(
                leading: const Icon(Icons.local_florist),
                title: const Text('Брой зони'),
                subtitle: Text(client.zones.length.toString()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Затвори'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to client management with this client selected
              context.go('/admin-dashboard/clients', extra: client);
            },
            child: const Text('Управление'),
          ),
        ],
      ),
    );
  }

  void _showAddPlantDialog(BuildContext context) {
    // This would open the plant management screen
    context.go('/admin-dashboard/plants');
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientListItem extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientListItem({
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            client.fullName.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(client.fullName),
        subtitle: Text(client.location),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${client.zones.length} зони'),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
