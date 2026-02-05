import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRLabelGenerationScreen extends StatefulWidget {
  const QRLabelGenerationScreen({super.key});

  @override
  State<QRLabelGenerationScreen> createState() => _QRLabelGenerationScreenState();
}

class _QRLabelGenerationScreenState extends State<QRLabelGenerationScreen> {
  final List<Map<String, dynamic>> _plants = [];
  final List<String> _selectedPlantIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load plants from API
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генериране на QR етикети'),
        actions: [
          if (_selectedPlantIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Принтирай избраните',
              onPressed: _handlePrint,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plants.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Няма налични растения',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Избрани: ${_selectedPlantIds.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_selectedPlantIds.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPlantIds.clear();
                                });
                              },
                              child: const Text('Изчисти избора'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _plants.length,
                        itemBuilder: (context, index) {
                          final plant = _plants[index];
                          final plantId = plant['id'] as String;
                          final isSelected = _selectedPlantIds.contains(plantId);

                          return Card(
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue[50] : null,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPlantIds.remove(plantId);
                                  } else {
                                    _selectedPlantIds.add(plantId);
                                  }
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  QrImageView(
                                    data: plant['qrCode'] ?? plantId,
                                    version: QrVersions.auto,
                                    size: 120,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      plant['bulgarianName'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      plant['latinName'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
      floatingActionButton: _selectedPlantIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _handlePrint,
              icon: const Icon(Icons.print),
              label: Text('Принтирай (${_selectedPlantIds.length})'),
            )
          : null,
    );
  }

  Future<void> _handlePrint() async {
    // Show print preview dialog
    showDialog(
      context: context,
      builder: (context) => PrintPreviewDialog(
        plantIds: _selectedPlantIds,
        plants: _plants.where((p) => _selectedPlantIds.contains(p['id'])).toList(),
      ),
    );
  }
}

class PrintPreviewDialog extends StatelessWidget {
  final List<String> plantIds;
  final List<Map<String, dynamic>> plants;

  const PrintPreviewDialog({
    super.key,
    required this.plantIds,
    required this.plants,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Преглед за печат'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: plants.map((plant) {
                    return Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: plant['qrCode'] ?? plant['id'],
                            version: QrVersions.auto,
                            size: 150,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plant['bulgarianName'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            plant['latinName'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Затвори'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement actual printing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Функцията за печат ще бъде имплементирана'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Принтирай'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
