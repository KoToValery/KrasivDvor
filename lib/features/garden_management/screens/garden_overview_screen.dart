import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/client_garden.dart';
import '../../../models/plant_instance.dart';
import '../../../models/plant.dart';
import '../../../core/services/service_locator.dart';
import '../../../features/plant_catalog/services/plant_catalog_service.dart';
import '../providers/garden_provider.dart';
import '../widgets/interactive_zone_display.dart';
import 'plant_instance_detail_screen.dart';

class GardenOverviewScreen extends StatefulWidget {
  final String clientId;

  const GardenOverviewScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<GardenOverviewScreen> createState() => _GardenOverviewScreenState();
}

class _GardenOverviewScreenState extends State<GardenOverviewScreen> {
  String? _selectedZoneId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GardenProvider>().loadGarden(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моята градина'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GardenProvider>().loadGarden(widget.clientId);
            },
          ),
        ],
      ),
      body: Consumer<GardenProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Грешка: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadGarden(widget.clientId);
                    },
                    child: const Text('Опитай отново'),
                  ),
                ],
              ),
            );
          }

          final garden = provider.garden;
          if (garden == null) {
            return const Center(
              child: Text('Градината не е намерена'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Garden master plan with interactive zones
                if (garden.masterPlan != null)
                  InteractiveZoneDisplay(
                    masterPlan: garden.masterPlan!,
                    zones: garden.zones,
                    plants: garden.plants,
                    onZoneTap: (zone) {
                      setState(() {
                        _selectedZoneId = _selectedZoneId == zone.id ? null : zone.id;
                      });
                    },
                  ),
                
                // Zones section (simplified)
                if (garden.zones.isNotEmpty && garden.masterPlan == null)
                  _buildZonesSection(garden),
                
                // Plants list section
                _buildPlantsSection(garden),
                
                // Notes section
                if (garden.notes.isNotEmpty)
                  _buildNotesSection(garden),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildZonesSection(ClientGarden garden) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Зони',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: garden.zones.length,
              itemBuilder: (context, index) {
                final zone = garden.zones[index];
                final isSelected = _selectedZoneId == zone.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedZoneId = isSelected ? null : zone.id;
                    });
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.landscape,
                          size: 32,
                          color: isSelected ? Colors.green : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          zone.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green[900] : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (zone.description != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              zone.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          '${zone.plantInstanceIds.length} растения',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsSection(ClientGarden garden) {
    final plants = _selectedZoneId == null
        ? garden.plants
        : garden.plants.where((p) => p.zoneId == _selectedZoneId).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_florist, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  _selectedZoneId == null
                      ? 'Всички растения (${plants.length})'
                      : 'Растения в зоната (${plants.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          if (plants.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Няма растения в тази зона'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plants.length,
              itemBuilder: (context, index) {
                return _buildPlantInstanceTile(plants[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlantInstanceTile(PlantInstance plantInstance) {
    return FutureBuilder<Plant?>(
      future: ServiceLocator.instance.get<PlantCatalogService>().getPlantById(plantInstance.plantId),
      builder: (context, snapshot) {
        final plant = snapshot.data;
        
        return ListTile(
          leading: plant?.imageUrls.isNotEmpty == true
              ? CircleAvatar(
                  backgroundImage: NetworkImage(plant!.imageUrls.first),
                )
              : const CircleAvatar(
                  child: Icon(Icons.local_florist),
                ),
          title: Text(plant?.bulgarianName ?? 'Зареждане...'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plant?.latinName ?? ''),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildStatusChip(plantInstance.status),
                  const SizedBox(width: 8),
                  Text(
                    'Засадено: ${_formatDate(plantInstance.plantedDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlantInstanceDetailScreen(
                  plantInstanceId: plantInstance.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(PlantStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case PlantStatus.planted:
        color = Colors.blue;
        label = 'Засадено';
        break;
      case PlantStatus.establishing:
        color = Colors.orange;
        label = 'Установява се';
        break;
      case PlantStatus.healthy:
        color = Colors.green;
        label = 'Здраво';
        break;
      case PlantStatus.stressed:
        color = Colors.amber;
        label = 'Стресирано';
        break;
      case PlantStatus.diseased:
        color = Colors.red;
        label = 'Болно';
        break;
      case PlantStatus.dead:
        color = Colors.grey;
        label = 'Мъртво';
        break;
      case PlantStatus.removed:
        color = Colors.black54;
        label = 'Премахнато';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotesSection(ClientGarden garden) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.note, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Бележки (${garden.notes.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: garden.notes.length > 3 ? 3 : garden.notes.length,
            itemBuilder: (context, index) {
              final note = garden.notes[index];
              return ListTile(
                leading: const Icon(Icons.note_outlined),
                title: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatDate(note.createdAt)),
              );
            },
          ),
          if (garden.notes.length > 3)
            TextButton(
              onPressed: () {
                // Navigate to full notes list
              },
              child: const Text('Виж всички бележки'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}