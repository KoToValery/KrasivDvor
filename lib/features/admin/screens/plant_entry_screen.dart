import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/plant.dart';
import '../../../models/client.dart';
import '../providers/admin_provider_new.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PlantEntryScreen extends StatefulWidget {
  final String clientId;

  const PlantEntryScreen({super.key, required this.clientId});

  @override
  State<PlantEntryScreen> createState() => _PlantEntryScreenState();
}

class _PlantEntryScreenState extends State<PlantEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  Plant? _selectedPlant;
  String? _selectedZone;
  int _quantity = 1;
  String? _notes;
  bool _isScanningQR = false;
  final MobileScannerController _qrController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPlants();
    });
  }

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавяне на растения'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _toggleQRScanner(),
            tooltip: 'Сканирай QR код',
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
                if (_isScanningQR) _buildQRScanner(),
                _buildPlantSelectionSection(adminProvider),
                const SizedBox(height: 16),
                _buildZoneSelectionSection(adminProvider),
                const SizedBox(height: 16),
                _buildQuantitySection(),
                const SizedBox(height: 16),
                _buildNotesSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                if (_selectedPlant != null) _buildPlantPreview(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _qrController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Text(
                          'Грешка: ${error.errorCode}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                  // Overlay to guide user
                  Container(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    margin: const EdgeInsets.all(50),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _toggleQRScanner(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Затвори'),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _qrController,
                    builder: (context, state, child) {
                      return TextButton(
                        onPressed: () => _qrController.toggleTorch(),
                        child: Text(
                          state.torchState == TorchState.on
                              ? 'Изключи светкавица'
                              : 'Включи светкавица',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantSelectionSection(AdminProvider adminProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Избор на растение',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SearchAnchor.bar(
              barHintText: 'Търсете растение...',
              suggestionsBuilder: (context, controller) {
                final query = controller.text.toLowerCase();
                final filteredPlants = adminProvider.plants
                    .where((plant) =>
                        plant.bulgarianName.toLowerCase().contains(query) ||
                        plant.latinName.toLowerCase().contains(query) ||
                        plant.bulgarianName.toLowerCase().contains(query))
                    .toList();

                return filteredPlants
                    .map((plant) => ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              plant.imageUrls.isNotEmpty
                                  ? plant.imageUrls[0]
                                  : '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.local_florist),
                              ),
                            ),
                          ),
                          title: Text(plant.bulgarianName),
                          subtitle: Text(plant.latinName),
                          trailing: Text('${plant.category}'),
                          onTap: () {
                            setState(() {
                              _selectedPlant = plant;
                            });
                            controller.closeView(plant.bulgarianName);
                          },
                        ))
                    .toList();
              },
            ),
            if (_selectedPlant != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedPlant!.imageUrls.isNotEmpty
                            ? _selectedPlant!.imageUrls[0]
                            : '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.local_florist, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlant!.bulgarianName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_selectedPlant!.latinName),
                          Text('Категория: ${_selectedPlant!.category}'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () => setState(() => _selectedPlant = null),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelectionSection(AdminProvider adminProvider) {
    Client? client;
    try {
      client = adminProvider.clients.firstWhere((c) => c.id == widget.clientId);
    } catch (_) {}

    final zones = client?.zones ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Избор на зона',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (zones.isEmpty)
              const Text('Няма налични зони. Създайте зони от мастър плана.')
            else
              DropdownButtonFormField<String>(
                value: _selectedZone,
                decoration: const InputDecoration(
                  labelText: 'Зона',
                  prefixIcon: Icon(Icons.layers),
                  border: OutlineInputBorder(),
                ),
                items: zones
                    .map((zone) => DropdownMenuItem(
                          value: zone.id,
                          child: Text(zone.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedZone = value),
                validator: (value) =>
                    value == null ? 'Моля изберете зона' : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Количество',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Бележки',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Допълнителни бележки',
                hintText:
                    'Например: специфични грижи, местоположение в зоната и т.н.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _notes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _canSubmit() ? _submitPlantEntry : null,
            icon: const Icon(Icons.save),
            label: const Text('Запази'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearForm,
            icon: const Icon(Icons.clear),
            label: const Text('Изчисти'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantPreview() {
    if (_selectedPlant == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Преглед',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedPlant!.imageUrls.isNotEmpty
                      ? _selectedPlant!.imageUrls[0]
                      : '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_florist, size: 30),
                  ),
                ),
              ),
              title: Text(_selectedPlant!.bulgarianName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedPlant!.latinName),
                  if (_selectedZone != null)
                    Text('Зона: ${_getZoneName(_selectedZone!)}'),
                  Text('Количество: $_quantity'),
                  if (_notes != null && _notes!.isNotEmpty)
                    Text('Бележки: $_notes'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _processQRCode(String code) {
    // QR code format: "plant_id:12345"
    final parts = code.split(':');
    if (parts.length == 2 && parts[0] == 'plant_id') {
      final plantId = parts[1];
      final adminProvider = context.read<AdminProvider>();
      Plant? plant;
      try {
        plant = adminProvider.plants.firstWhere((p) => p.id == plantId);
      } catch (e) {
        plant = null;
      }

      if (plant != null) {
        setState(() {
          _selectedPlant = plant;
          _isScanningQR = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Намерено растение: ${plant.bulgarianName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Растението не е намерено в каталога')),
        );
      }
    }
  }

  void _toggleQRScanner() {
    setState(() {
      _isScanningQR = !_isScanningQR;
    });
  }

  bool _canSubmit() {
    return _selectedPlant != null && _selectedZone != null && _quantity > 0;
  }

  void _submitPlantEntry() {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit()) return;

    final adminProvider = context.read<AdminProvider>();
    adminProvider
        .addPlantToZone(
      clientId: widget.clientId,
      plantId: _selectedPlant!.id,
      zoneId: _selectedZone!,
      quantity: _quantity,
      notes: _notes,
    )
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${adminProvider.plants.firstWhere((p) => p.id == _selectedPlant!.id).bulgarianName} добавено успешно!'),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _clearForm() {
    setState(() {
      _selectedPlant = null;
      _selectedZone = null;
      _quantity = 1;
      _notes = null;
      _isScanningQR = false;
    });
  }

  String _getZoneName(String zoneId) {
    final adminProvider = context.read<AdminProvider>();
    Client? client;
    try {
      client = adminProvider.clients.firstWhere((c) => c.id == widget.clientId);
    } catch (_) {}

    if (client == null) return 'Неизвестна зона';

    final zone = client.zones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => Zone.empty(),
    );
    return zone.name;
  }
}
