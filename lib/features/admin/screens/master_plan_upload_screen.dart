import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:image/image.dart' as img;
import '../providers/admin_provider_new.dart';
import '../../../models/client.dart';

class MasterPlanUploadScreen extends StatefulWidget {
  final Client? client;

  const MasterPlanUploadScreen({super.key, this.client});

  @override
  State<MasterPlanUploadScreen> createState() => _MasterPlanUploadScreenState();
}

class _MasterPlanUploadScreenState extends State<MasterPlanUploadScreen> {
  File? _selectedFile;
  String? _fileName;
  String _fileType = '';
  List<Zone> _zones = [];
  final Map<String, TextEditingController> _zoneNameControllers = {};
  final Map<String, TextEditingController> _zoneDescriptionControllers = {};
  bool _isUploading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.client != null && widget.client!.zones.isNotEmpty) {
      _zones = List.from(widget.client!.zones);
      for (var zone in _zones) {
        _zoneNameControllers[zone.id] = TextEditingController(text: zone.name);
        _zoneDescriptionControllers[zone.id] = TextEditingController(
          text: zone.properties['description'] ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _zoneNameControllers.values) {
      controller.dispose();
    }
    for (var controller in _zoneDescriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client != null
            ? 'Мастър план за ${widget.client!.fullName}'
            : 'Качване на мастър план'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Назад', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _handleStepContinue,
        onStepCancel: _handleStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Напред'),
                  ),
                if (_currentStep == 2)
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadMasterPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Качи мастър план'),
                  ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Назад'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Избор на файл'),
            subtitle: const Text('Изберете JPG или PDF файл'),
            content: _buildFileSelectionStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Преглед на файла'),
            subtitle: const Text('Прегледайте и потвърдете файла'),
            content: _buildFilePreviewStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Управление на зони'),
            subtitle: const Text('Дефинирайте и именувайте зоните'),
            content: _buildZoneManagementStep(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectionStep() {
    return Column(
      children: [
        Card(
          elevation: 4,
          child: InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle
                        : Icons.cloud_upload,
                    size: 64,
                    color:
                        _selectedFile != null ? Colors.green : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile != null
                        ? 'Избран файл: $_fileName'
                        : 'Изберете JPG или PDF файл',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Поддържани формати: JPG, JPEG, PNG, PDF',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedFile != null)
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.refresh),
            label: const Text('Избери друг файл'),
          ),
      ],
    );
  }

  Widget _buildFilePreviewStep() {
    if (_selectedFile == null) {
      return const Center(child: Text('Няма избран файл'));
    }

    return Column(
      children: [
        Card(
          elevation: 4,
          child: Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildFilePreview(),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('Файл: $_fileName'),
          subtitle: Text('Тип: ${_fileType.toUpperCase()}'),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    if (_fileType == 'pdf') {
      return PDFView(
        filePath: _selectedFile!.path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
      );
    } else {
      return Image.file(
        _selectedFile!,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildZoneManagementStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Зони в градината',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _addZone,
              icon: const Icon(Icons.add),
              label: const Text('Добави зона'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_zones.isEmpty)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Все още няма зони',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавете зони, за да организирате растенията',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._zones.map((zone) => _buildZoneCard(zone)).toList(),
      ],
    );
  }

  Widget _buildZoneCard(Zone zone) {
    final nameController =
        _zoneNameControllers[zone.id] ?? TextEditingController();
    final descriptionController =
        _zoneDescriptionControllers[zone.id] ?? TextEditingController();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Име на зона',
                      prefixIcon: Icon(Icons.map),
                    ),
                    onChanged: (value) {
                      zone.name = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeZone(zone),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (незадължително)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              onChanged: (value) {
                zone.properties['description'] = value;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_florist, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${zone.plants.length} растения'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editZonePlants(zone),
                  icon: const Icon(Icons.edit),
                  label: const Text('Управление на растения'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileType = result.files.single.extension?.toLowerCase() ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Грешка при избиране на файл: $e')),
      );
    }
  }

  void _addZone() {
    setState(() {
      final newZone = Zone(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Зона ${_zones.length + 1}',
        originalName: 'Зона ${_zones.length + 1}',
        description: '',
        plants: [],
        properties: {},
      );
      _zones.add(newZone);
      _zoneNameControllers[newZone.id] =
          TextEditingController(text: newZone.name);
      _zoneDescriptionControllers[newZone.id] = TextEditingController();
    });
  }

  void _removeZone(Zone zone) {
    setState(() {
      _zones.remove(zone);
      _zoneNameControllers[zone.id]?.dispose();
      _zoneDescriptionControllers[zone.id]?.dispose();
      _zoneNameControllers.remove(zone.id);
      _zoneDescriptionControllers.remove(zone.id);
    });
  }

  void _editZonePlants(Zone zone) {
    // Navigate to plant management for this zone
    context.push('/admin-dashboard/plants', extra: {
      'client': widget.client,
      'zone': zone,
    });
  }

  void _handleStepContinue() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Моля изберете файл')),
        );
        return;
      }
      setState(() {
        _currentStep++;
      });
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _uploadMasterPlan() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Моля изберете файл')),
      );
      return;
    }

    if (widget.client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Няма избран клиент')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final zonesData = _zones
          .map((zone) => <String, dynamic>{
                'id': zone.id,
                'name': zone.name,
                'description': zone.properties['description'] ?? '',
              })
          .toList();

      await context.read<AdminProvider>().uploadMasterPlan(
            widget.client!.id,
            _selectedFile!.path,
            zonesData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Мастър планът беше качен успешно')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грешка при качване: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
