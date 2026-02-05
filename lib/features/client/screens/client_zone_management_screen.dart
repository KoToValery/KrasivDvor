import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/client.dart';
import '../providers/client_provider.dart';

class ClientZoneManagementScreen extends StatefulWidget {
  const ClientZoneManagementScreen({super.key});

  @override
  State<ClientZoneManagementScreen> createState() => _ClientZoneManagementScreenState();
}

class _ClientZoneManagementScreenState extends State<ClientZoneManagementScreen> {
  final _zoneNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление на зони'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          if (clientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final zones = clientProvider.zones;
          
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.landscape,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Все още няма създадени зони',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Вашият ландшафтен архитект ще създаде зоните за вашата градина',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              return _buildZoneCard(zone, clientProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildZoneCard(Zone zone, ClientProvider clientProvider) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showZoneDetails(zone),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${zone.plants.length} растения',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showRenameDialog(zone, clientProvider),
                    tooltip: 'Преименувай зоната',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (zone.plants.isNotEmpty) ...[
                Text(
                  'Растения в зоната:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...zone.plants.take(3).map((zonePlant) => _buildPlantItem(zonePlant)),
                if (zone.plants.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton(
                      onPressed: () => _showZoneDetails(zone),
                      child: Text('Виж всички ${zone.plants.length} растения'),
                    ),
                  ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Все още няма добавени растения в тази зона',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantItem(dynamic zonePlant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.local_florist,
            size: 16,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${zonePlant.plantName} (${zonePlant.quantity} бр.)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(Zone zone, ClientProvider clientProvider) {
    _zoneNameController.text = zone.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Преименувай зоната'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _zoneNameController,
            decoration: const InputDecoration(
              labelText: 'Име на зоната',
              hintText: 'Въведете ново име на зоната',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Моля, въведете име на зоната';
              }
              if (value.trim().length < 2) {
                return 'Името трябва да е поне 2 символа';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _renameZone(zone.id, clientProvider);
                context.pop();
              }
            },
            child: const Text('Запази'),
          ),
        ],
      ),
    );
  }

  void _renameZone(String zoneId, ClientProvider clientProvider) async {
    final newName = _zoneNameController.text.trim();
    
    try {
      await clientProvider.updateZoneName(zoneId, newName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Зоната е преименувана успешно!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка при преименуване: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showZoneDetails(Zone zone) {
    context.push('/client/zone/${zone.id}');
  }
}