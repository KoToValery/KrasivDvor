import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider_new.dart';
import '../../../models/client.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, location, createdAt
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    // Load clients when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление на клиенти'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.clients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredClients = _filterClients(adminProvider.clients);

          if (filteredClients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Няма намерени клиенти',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Създайте нов клиентски профил',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(context, filteredClients),
              const SizedBox(height: 16),

              // Client List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return _ClientCard(
                      client: client,
                      onTap: () => _showClientDetails(client),
                      onEdit: () => _showEditClientDialog(client),
                      onDelete: () => _showDeleteConfirmation(client),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClientDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Нов клиент'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Client> clients) {
    final totalZones =
        clients.fold<int>(0, (sum, client) => sum + client.zones.length);
    final activeClients = clients.where((c) => c.masterPlanUrl != null).length;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              icon: Icons.people,
              title: 'Общо клиенти',
              value: clients.length.toString(),
              color: Colors.blue,
            ),
            _SummaryItem(
              icon: Icons.map,
              title: 'Общо зони',
              value: totalZones.toString(),
              color: Colors.green,
            ),
            _SummaryItem(
              icon: Icons.local_florist,
              title: 'Активни градини',
              value: activeClients.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  List<Client> _filterClients(List<Client> clients) {
    var filtered = clients;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        return client.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            client.location
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            client.username.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Active filter
    if (_showOnlyActive) {
      filtered =
          filtered.where((client) => client.masterPlanUrl != null).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'location':
          return a.location.compareTo(b.location);
        case 'createdAt':
          return b.createdAt.compareTo(a.createdAt);
        default: // name
          return a.fullName.compareTo(b.fullName);
      }
    });

    return filtered;
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Търсене на клиент'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Име, местоположение или потребителско име',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Изчисти'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _searchQuery = controller.text;
              });
            },
            child: const Text('Търси'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Филтриране и сортиране'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Сортиране по:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Име')),
                  DropdownMenuItem(
                      value: 'location', child: Text('Местоположение')),
                  DropdownMenuItem(
                      value: 'createdAt', child: Text('Дата на създаване')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Покажи само активни клиенти'),
                subtitle: const Text('Клиенти с качен мастър план'),
                value: _showOnlyActive,
                onChanged: (value) {
                  setState(() {
                    _showOnlyActive = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Затвори'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClientDialog() {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Създаване на нов клиент'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Име на градината *',
                  prefixIcon: Icon(Icons.park),
                  hintText: 'например: Градина "Рози"',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Моля въведете име на градината';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Местоположение на градината *',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'например: София, Бояна',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Моля въведете местоположение';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Уникален номер ще бъде генериран автоматично',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  fullNameController.text,
                  locationController.text,
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

  void _showEditClientDialog(Client client) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: client.fullName);
    final locationController = TextEditingController(text: client.location);
    final addressController = TextEditingController(text: client.address ?? '');
    final phoneController = TextEditingController(text: client.phone ?? '');
    final emailController = TextEditingController(text: client.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактиране на клиент'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Име на клиент *',
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
                    labelText: 'Местоположение на градината *',
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
                _updateClient(
                  client,
                  fullNameController.text,
                  locationController.text,
                  addressController.text,
                  phoneController.text,
                  emailController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Запази'),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(Client client) {
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
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text('Местоположение'),
                subtitle: Text(client.location),
              ),
              if (client.address != null)
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.green),
                  title: const Text('Адрес'),
                  subtitle: Text(client.address!),
                ),
              if (client.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.orange),
                  title: const Text('Телефон'),
                  subtitle: Text(client.phone!),
                ),
              if (client.email != null)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.purple),
                  title: const Text('Email'),
                  subtitle: Text(client.email!),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: const Text('Създаден на'),
                subtitle: Text(client.createdAt.toString().substring(0, 10)),
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.red),
                title: const Text('Брой зони'),
                subtitle: Text(client.zones.length.toString()),
              ),
              if (client.masterPlanUrl != null)
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.indigo),
                  title: const Text('Мастър план'),
                  subtitle: const Text('Качен'),
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
              // Navigate to client management with this client
              context.go('/admin-dashboard/clients/${client.id}');
            },
            child: const Text('Управление'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Потвърждение за изтриване'),
        content: Text(
            'Сигурни ли сте, че искате да изтриете клиента "${client.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClient(client);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );
  }

  void _createClient(
    String fullName,
    String location,
  ) async {
    final adminProvider = context.read<AdminProvider>();
    try {
      await adminProvider.createClient(
        fullName: fullName,
        location: location,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Клиентът е създаден успешно'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload clients to show the new one
      await adminProvider.loadClients();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при създаване: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateClient(
    Client client,
    String fullName,
    String location,
    String address,
    String phone,
    String email,
  ) async {
    final adminProvider = context.read<AdminProvider>();
    try {
      await adminProvider.updateClient(client.id, {
        'fullName': fullName,
        'location': location,
        'address': address.isNotEmpty ? address : null,
        'phone': phone.isNotEmpty ? phone : null,
        'email': email.isNotEmpty ? email : null,
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Клиентът е обновен успешно'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload clients to show the updated data
      await adminProvider.loadClients();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при обновяване: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteClient(Client client) {
    // Implement delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Клиент "${client.fullName}" беше изтрит')),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  client.fullName.substring(0, 1),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.map, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${client.zones.length} зони'),
                        const SizedBox(width: 16),
                        if (client.masterPlanUrl != null)
                          Icon(Icons.upload_file,
                              size: 16, color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'zones':
                      context.go('/admin-dashboard/clients/${client.id}/zones');
                      break;
                    case 'master_plan':
                      context.go(
                        '/admin-dashboard/clients/${client.id}/master-plan',
                        extra: client,
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Редактирай'),
                  ),
                  const PopupMenuItem(
                    value: 'zones',
                    child: Text('Управление на зони'),
                  ),
                  const PopupMenuItem(
                    value: 'master_plan',
                    child: Text('Качи мастър план'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Изтрий'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
