import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/client_garden.dart';
import '../providers/garden_provider.dart';

/// Screen for viewing and managing garden documentation
class GardenDocumentationScreen extends StatefulWidget {
  final String clientId;

  const GardenDocumentationScreen({
    Key? key,
    required this.clientId,
  }) : super(key: key);

  @override
  State<GardenDocumentationScreen> createState() => _GardenDocumentationScreenState();
}

class _GardenDocumentationScreenState extends State<GardenDocumentationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocumentation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentation() async {
    final gardenProvider = context.read<GardenProvider>();
    await gardenProvider.loadGardenDocumentation(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документация'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Бележки', icon: Icon(Icons.note)),
            Tab(text: 'Документи', icon: Icon(Icons.folder)),
            Tab(text: 'Галерия', icon: Icon(Icons.photo_library)),
          ],
        ),
      ),
      body: Consumer<GardenProvider>(
        builder: (context, gardenProvider, child) {
          if (gardenProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _NotesTab(clientId: widget.clientId),
              _DocumentsTab(clientId: widget.clientId),
              _PhotoGalleryTab(clientId: widget.clientId),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добави'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Нова бележка'),
              onTap: () {
                Navigator.pop(context);
                _addNote();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Качи документ'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нова бележка'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Въведете текст...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Запази'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final gardenProvider = context.read<GardenProvider>();
      await gardenProvider.createNote(widget.clientId, controller.text);
    }
  }

  Future<void> _uploadDocument() async {
    final documentType = await showDialog<DocumentType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тип документ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Гаранция'),
              onTap: () => Navigator.pop(context, DocumentType.warranty),
            ),
            ListTile(
              title: const Text('Сертификат'),
              onTap: () => Navigator.pop(context, DocumentType.certificate),
            ),
            ListTile(
              title: const Text('Инструкции за грижи'),
              onTap: () => Navigator.pop(context, DocumentType.careInstructions),
            ),
            ListTile(
              title: const Text('Друго'),
              onTap: () => Navigator.pop(context, DocumentType.other),
            ),
          ],
        ),
      ),
    );

    if (documentType != null) {
      final gardenProvider = context.read<GardenProvider>();
      await gardenProvider.uploadDocument(widget.clientId, documentType);
    }
  }
}

class _NotesTab extends StatelessWidget {
  final String clientId;

  const _NotesTab({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final gardenProvider = context.watch<GardenProvider>();
    final notes = gardenProvider.gardenNotes;

    if (notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Няма бележки', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(note.content),
                if (note.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: note.photoUrls.length,
                      itemBuilder: (context, photoIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: note.photoUrls[photoIndex],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final String clientId;

  const _DocumentsTab({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final gardenProvider = context.watch<GardenProvider>();
    final documents = gardenProvider.gardenDocuments;

    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Няма документи', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_getDocumentIcon(document.type)),
            title: Text(document.name),
            subtitle: Text(
              '${_getDocumentTypeText(document.type)} • ${DateFormat('dd.MM.yyyy').format(document.uploadedAt)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                // Open document
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.warranty:
        return Icons.verified_user;
      case DocumentType.certificate:
        return Icons.card_membership;
      case DocumentType.careInstructions:
        return Icons.menu_book;
      case DocumentType.other:
        return Icons.description;
    }
  }

  String _getDocumentTypeText(DocumentType type) {
    switch (type) {
      case DocumentType.warranty:
        return 'Гаранция';
      case DocumentType.certificate:
        return 'Сертификат';
      case DocumentType.careInstructions:
        return 'Инструкции';
      case DocumentType.other:
        return 'Друго';
    }
  }
}

class _PhotoGalleryTab extends StatelessWidget {
  final String clientId;

  const _PhotoGalleryTab({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final gardenProvider = context.watch<GardenProvider>();
    final allPhotos = _getAllPhotos(gardenProvider);

    if (allPhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Няма снимки', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allPhotos.length,
      itemBuilder: (context, index) {
        final photoUrl = allPhotos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  List<String> _getAllPhotos(GardenProvider provider) {
    final photos = <String>[];
    
    // Add photos from notes
    for (final note in provider.gardenNotes) {
      photos.addAll(note.photoUrls);
    }
    
    // Add progress photos from plant instances
    for (final plant in provider.plantingHistory) {
      photos.addAll(plant.progressPhotos);
    }
    
    return photos;
  }
}
