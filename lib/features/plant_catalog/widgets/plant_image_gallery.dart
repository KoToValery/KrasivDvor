import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlantImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final String plantName;
  final double height;
  final bool showThumbnails;
  final bool enableZoom;

  const PlantImageGallery({
    super.key,
    required this.imageUrls,
    required this.plantName,
    this.height = 300,
    this.showThumbnails = true,
    this.enableZoom = true,
  });

  @override
  State<PlantImageGallery> createState() => _PlantImageGalleryState();
}

class _PlantImageGalleryState extends State<PlantImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _buildPlaceholder();
    }

    return Column(
      children: [
        // Main image carousel
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, index) {
                  return _buildMainImage(widget.imageUrls[index], index);
                },
              ),
              // Navigation arrows (only show if more than one image)
              if (widget.imageUrls.length > 1) ...[
                _buildNavigationArrow(Icons.chevron_left, () {
                  if (_currentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }, Alignment.centerLeft),
                _buildNavigationArrow(Icons.chevron_right, () {
                  if (_currentIndex < widget.imageUrls.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }, Alignment.centerRight),
              ],
              // Page indicator
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildPageIndicator(),
                ),
              // Fullscreen button
              Positioned(
                top: 16,
                right: 16,
                child: _buildFullscreenButton(),
              ),
            ],
          ),
        ),
        // Thumbnail strip
        if (widget.showThumbnails && widget.imageUrls.length > 1) ...[
          const SizedBox(height: 16),
          _buildThumbnailStrip(),
        ],
      ],
    );
  }

  Widget _buildMainImage(String imageUrl, int index) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.enableZoom
            ? InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: _buildCachedImage(imageUrl),
              )
            : _buildCachedImage(imageUrl),
      ),
    );
  }

  Widget _buildCachedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Изображението не може да бъде заредено',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      // Enable memory caching
      memCacheWidth: 800,
      memCacheHeight: 600,
      // Enable disk caching
      cacheKey: imageUrl,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Няма налични изображения',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow(IconData icon, VoidCallback onPressed, Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.imageUrls.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.fullscreen, color: Colors.white),
        onPressed: () => _showFullscreenGallery(),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.local_florist,
                      size: 24,
                      color: Colors.grey[400],
                    ),
                  ),
                  // Smaller cache size for thumbnails
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullscreenGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageGallery(
          imageUrls: widget.imageUrls,
          initialIndex: _currentIndex,
          plantName: widget.plantName,
        ),
      ),
    );
  }
}

class FullscreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String plantName;

  const FullscreenImageGallery({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.plantName,
  });

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.plantName} (${_currentIndex + 1}/${widget.imageUrls.length})',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareImage(),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Изображението не може да бъде заредено',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // High quality for fullscreen
                    memCacheWidth: 1200,
                    memCacheHeight: 1200,
                  ),
                ),
              );
            },
          ),
          // Page indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _shareImage() {
    // TODO: Implement image sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Споделянето на изображения ще бъде имплементирано'),
        backgroundColor: Colors.white,
      ),
    );
  }
}

// Image category types for better organization
enum PlantImageCategory {
  fullView,
  leaf,
  flower,
  fruit,
  bark,
  winter,
}

class CategorizedPlantImageGallery extends StatefulWidget {
  final Map<PlantImageCategory, List<String>> categorizedImages;
  final String plantName;
  final double height;

  const CategorizedPlantImageGallery({
    super.key,
    required this.categorizedImages,
    required this.plantName,
    this.height = 300,
  });

  @override
  State<CategorizedPlantImageGallery> createState() => _CategorizedPlantImageGalleryState();
}

class _CategorizedPlantImageGalleryState extends State<CategorizedPlantImageGallery>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<PlantImageCategory> _availableCategories;

  @override
  void initState() {
    super.initState();
    _availableCategories = widget.categorizedImages.keys
        .where((category) => widget.categorizedImages[category]!.isNotEmpty)
        .toList();
    _tabController = TabController(length: _availableCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_availableCategories.isEmpty) {
      return PlantImageGallery(
        imageUrls: const [],
        plantName: widget.plantName,
        height: widget.height,
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _availableCategories.map((category) => Tab(
            text: _getCategoryDisplayName(category),
          )).toList(),
        ),
        SizedBox(
          height: widget.height + 100, // Extra space for thumbnails
          child: TabBarView(
            controller: _tabController,
            children: _availableCategories.map((category) {
              final images = widget.categorizedImages[category]!;
              return PlantImageGallery(
                imageUrls: images,
                plantName: '${widget.plantName} - ${_getCategoryDisplayName(category)}',
                height: widget.height,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(PlantImageCategory category) {
    switch (category) {
      case PlantImageCategory.fullView:
        return 'Общ вид';
      case PlantImageCategory.leaf:
        return 'Листа';
      case PlantImageCategory.flower:
        return 'Цветове';
      case PlantImageCategory.fruit:
        return 'Плодове';
      case PlantImageCategory.bark:
        return 'Кора';
      case PlantImageCategory.winter:
        return 'Зимен вид';
    }
  }
}