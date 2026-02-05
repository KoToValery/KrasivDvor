import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/client.dart';
import '../providers/admin_provider_new.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({super.key, required this.clientId});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детайли за клиент'),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          Client? client;
          try {
            client = adminProvider.clients.firstWhere(
              (c) => c.id == widget.clientId,
            );
          } catch (e) {
            client = null;
          }

          if (client == null) {
            return const Center(child: Text('Клиентът не е намерен'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              client.fullName.isNotEmpty
                                  ? client.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                const SizedBox(height: 4),
                                Text(client.location,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (client.phone != null && client.phone!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 8),
                          Text(client.phone!)
                        ]),
                      ],
                      if (client.email != null && client.email!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.email, size: 16),
                          const SizedBox(width: 8),
                          Text(client.email!)
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Управление на градината',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildActionTile(
                context,
                'Зони на градината',
                'Управление на зони и растения',
                Icons.map,
                () => context.pushNamed('admin-zones',
                    pathParameters: {'clientId': client!.id}),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                'Мастър план',
                'Качване и преглед на план',
                Icons.image,
                () => context.pushNamed('admin-master-plan',
                    pathParameters: {'clientId': client!.id}, extra: client),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                context,
                'Растения',
                'Добавяне и редакция на растения',
                Icons.local_florist,
                () => context.pushNamed('admin-plant-entry',
                    pathParameters: {'clientId': client!.id}),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
