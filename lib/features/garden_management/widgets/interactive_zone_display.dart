import 'package:flutter/material.dart';
import '../../../models/client_garden.dart';
import '../../../models/plant_instance.dart';

/// Interactive widget for displaying garden zones on top of master plan
class InteractiveZoneDisplay extends StatefulWidget {
  final GardenMasterPlan masterPlan;
  final List<GardenZone> zones;
  final List<PlantInstance> plants;
  final Function(GardenZone)? onZoneTap;
  final bool isInteractive;

  const InteractiveZoneDisplay({
    super.key,
    required this.masterPlan,
    required this.zones,
    required this.plants,
    this.onZoneTap,
    this.isInteractive = true,
  });

  @override
  State<InteractiveZoneDisplay> createState() => _InteractiveZoneDisplayState();
}

class _InteractiveZoneDisplayState extends State<InteractiveZoneDisplay> {
  String? _selectedZoneId;
  String? _hoveredZoneId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'План на градината',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_selectedZoneId != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedZoneId = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Изчисти избора'),
                  ),
              ],
            ),
          ),
          // Master plan image with zone overlay
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Background master plan image
                Positioned.fill(
                  child: Image.network(
                    widget.masterPlan.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 64),
                        ),
                      );
                    },
                  ),
                ),
                // Zone overlays
                if (widget.isInteractive)
                  ...widget.zones.map((zone) => _buildZoneOverlay(zone)),
              ],
            ),
          ),
          // Zone legend
          if (widget.zones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Легенда на зоните',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: widget.zones.map((zone) {
                      final plantCount = _getPlantCountForZone(zone.id);
                      final isSelected = _selectedZoneId == zone.id;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedZoneId = isSelected ? null : zone.id;
                          });
                          if (widget.onZoneTap != null) {
                            widget.onZoneTap!(zone);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getZoneColor(zone.id).withValues(alpha: 0.3)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getZoneColor(zone.id),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getZoneColor(zone.id),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$plantCount растения',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          // Selected zone details
          if (_selectedZoneId != null)
            _buildSelectedZoneDetails(),
        ],
      ),
    );
  }

  Widget _buildZoneOverlay(GardenZone zone) {
    final isSelected = _selectedZoneId == zone.id;
    final isHovered = _hoveredZoneId == zone.id;
    final zoneIndex = widget.zones.indexOf(zone);
    
    // Calculate position based on zone index (simple grid layout)
    // In a real implementation, zones would have actual coordinates
    final columns = 3;
    final row = zoneIndex ~/ columns;
    final col = zoneIndex % columns;
    
    return Positioned(
      left: (col * 33.33) + 5,
      top: (row * 33.33) + 5,
      width: 28,
      height: 28,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.isInteractive) {
            setState(() {
              _hoveredZoneId = zone.id;
            });
          }
        },
        onExit: (_) {
          if (widget.isInteractive) {
            setState(() {
              _hoveredZoneId = null;
            });
          }
        },
        child: GestureDetector(
          onTap: () {
            if (widget.isInteractive) {
              setState(() {
                _selectedZoneId = isSelected ? null : zone.id;
              });
              if (widget.onZoneTap != null) {
                widget.onZoneTap!(zone);
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _getZoneColor(zone.id).withValues(
                alpha: isSelected ? 0.6 : (isHovered ? 0.4 : 0.3),
              ),
              border: Border.all(
                color: _getZoneColor(zone.id),
                width: isSelected ? 3 : (isHovered ? 2 : 1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${zoneIndex + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSelected ? 16 : 14,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedZoneDetails() {
    final zone = widget.zones.firstWhere((z) => z.id == _selectedZoneId);
    final zonePlants = widget.plants
        .where((p) => p.zoneId == zone.id)
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getZoneColor(zone.id).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getZoneColor(zone.id),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getZoneColor(zone.id),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.zones.indexOf(zone) + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (zone.description != null)
                      Text(
                        zone.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Растения в зоната: ${zonePlants.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (zonePlants.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...zonePlants.take(3).map((plant) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_florist, size: 16),
                  const SizedBox(width: 8),
                  Text(plant.plantId),
                ],
              ),
            )),
            if (zonePlants.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... и още ${zonePlants.length - 3}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }

  int _getPlantCountForZone(String zoneId) {
    return widget.plants.where((p) => p.zoneId == zoneId).length;
  }

  Color _getZoneColor(String zoneId) {
    // Generate consistent color based on zone ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    
    final index = zoneId.hashCode.abs() % colors.length;
    return colors[index];
  }
}
