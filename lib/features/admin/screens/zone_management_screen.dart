import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider_new.dart';
import '../../../models/client.dart';

class ZoneManagementScreen extends StatefulWidget {
  final String clientId;
  final List<Zone> existingZones;

  const ZoneManagementScreen({
    super.key,
    required this.clientId,
    this.existingZones = const [],
  });

  @override
  State<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  late List<Zone> _zones;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _zones = List.from(widget.existingZones);
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = context.read<AdminProvider>();
      final zonesData = await adminProvider.getZones(widget.clientId);

      setState(() {
        _zones = zonesData
            .map((data) => Zone(
                  id: data['id'],
                  name: data['name'],
                  originalName: data['originalName'] ?? data['name'],
                  description: data['description'],
                  plants: (data['plants'] as List<dynamic>?)
                          ?.map((plant) => ZonePlant(
                                plantId: plant['plantId'],
                                plantName: plant['plantName'],
                                quantity: plant['quantity'],
                                plantedDate:
                                    DateTime.parse(plant['plantedDate']),
                                notes: plant['notes'],
                                careHistory: plant['careHistory'] ?? {},
                              ))
                          .toList() ??
                      [],
                  properties: data['properties'] ?? {},
                ))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при зареждане на зони: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление на зони'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadZones,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _zones.isEmpty
              ? _buildEmptyState()
              : _buildZonesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addZone,
        icon: const Icon(Icons.add),
        label: const Text('Добави зона'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Няма дефинирани зони',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавете зони за по-добра организация на градината',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addZone,
            icon: const Icon(Icons.add),
            label: const Text('Добави първа зона'),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getZoneColor(index),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              zone.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (zone.description != null) Text(zone.description!),
                const SizedBox(height: 4),
                Text(
                  '${zone.plants.length} растения',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editZone(zone),
                  tooltip: 'Редактирай',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteZone(zone),
                  tooltip: 'Изтрий',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addZone() {
    showDialog(
      context: context,
      builder: (context) => const ZoneDialog(),
    ).then((result) {
      if (result != null) {
        _createZone(result['name'], result['description']);
      }
    });
  }

  void _editZone(Zone zone) {
    showDialog(
      context: context,
      builder: (context) => ZoneDialog(
        initialName: zone.name,
        initialDescription: zone.description,
      ),
    ).then((result) {
      if (result != null) {
        _updateZone(zone.id, result['name'], result['description']);
      }
    });
  }

  Future<void> _createZone(String name, String? description) async {
    try {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.createZone(widget.clientId, name, description);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Зоната е създадена успешно'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadZones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при създаване на зона: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateZone(
      String zoneId, String name, String? description) async {
    try {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.updateZone(
          widget.clientId, zoneId, name, description);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Зоната е обновена успешно'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadZones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при обновяване на зона: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteZone(Zone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на зона'),
        content: Text(
          'Сигурни ли сте, че искате да изтриете зона "${zone.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отказ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminProvider = context.read<AdminProvider>();
      await adminProvider.deleteZone(widget.clientId, zone.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Зоната е изтрита успешно'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadZones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при изтриване на зона: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getZoneColor(int index) {
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

    return colors[index % colors.length];
  }
}

class ZoneDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;

  const ZoneDialog({
    super.key,
    this.initialName,
    this.initialDescription,
  });

  @override
  State<ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<ZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null ? 'Добави зона' : 'Редактирай зона',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Име на зона *',
                border: OutlineInputBorder(),
                hintText: 'напр. Предна градина, Задна градина',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Моля въведете име на зоната';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                hintText: 'Допълнителна информация за зоната',
              ),
              maxLines: 3,
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
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              });
            }
          },
          child: const Text('Запази'),
        ),
      ],
    );
  }
}
