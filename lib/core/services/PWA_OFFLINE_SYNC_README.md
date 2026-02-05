# PWA and Offline Sync Implementation

This document describes the PWA (Progressive Web App) and offline synchronization implementation for the Landscape Plant Catalog application.

## Overview

The application implements full PWA capabilities with offline support, including:
- Service worker for offline caching
- Install prompt for adding to home screen
- Background sync for offline changes
- Conflict resolution for data synchronization
- Online/offline status detection

## Architecture

### Service Worker (`web/flutter_service_worker.js`)

The custom service worker implements three caching strategies:

1. **Cache-First Strategy**: For app shell and images
   - Tries cache first, falls back to network
   - Caches successful network responses for future use

2. **Network-First Strategy**: For API requests
   - Tries network first, falls back to cache
   - Ensures fresh data when online

3. **Background Sync**: For offline data synchronization
   - Queues changes made while offline
   - Syncs automatically when connection is restored

### PWA Service (`lib/core/services/pwa_service.dart`)

Manages PWA-specific functionality:
- **Install Prompt**: Detects and shows install prompt
- **Update Detection**: Notifies when new version is available
- **Online/Offline Status**: Monitors connection status
- **Service Worker Communication**: Handles messages from service worker

### Offline Sync Service (`lib/core/services/offline_sync_service.dart`)

Manages offline data synchronization:
- **Change Queue**: Stores changes made while offline
- **Automatic Sync**: Syncs when connection is restored
- **Conflict Detection**: Identifies conflicts between local and server data
- **Conflict Resolution**: Allows user to choose which version to keep

## Usage

### For Service Developers

To add offline support to a service, use the `OfflineSyncMixin`:

```dart
import 'package:landscape_plant_catalog/core/services/offline_sync_mixin.dart';

class MyService with OfflineSyncMixin {
  Future<Plant> updatePlant(Plant plant) async {
    return executeWithOfflineSupport(
      onlineOperation: () async {
        // Normal API call
        return await apiService.updatePlant(plant);
      },
      offlineChange: updateOfflineChange(
        entityType: 'plant',
        entityId: plant.id,
        data: plant.toJson(),
      ),
      offlineResult: plant, // Return optimistic result
    );
  }
}
```

### For UI Developers

The following widgets are available for PWA features:

1. **PWAInstallPrompt**: Shows install prompt banner
2. **PWAUpdateBanner**: Shows update notification
3. **OfflineIndicator**: Shows offline status
4. **SyncProgressIndicator**: Shows sync progress

These are already integrated in `HomeScreen`.

### Conflict Resolution

When conflicts occur (local and server versions differ), users can:
1. Navigate to the Sync Conflicts screen
2. View all conflicts with details
3. Choose to keep local or server version
4. Conflicts are automatically resolved during sync

## Configuration

### Manifest (`web/manifest.json`)

The manifest defines PWA properties:
- App name and short name
- Theme colors
- Display mode (standalone)
- Icons (192x192 and 512x512)

### Icons

Place the following icons in `web/icons/`:
- `Icon-192.png`: 192x192px standard icon
- `Icon-512.png`: 512x512px standard icon
- `Icon-maskable-192.png`: 192x192px maskable icon
- `Icon-maskable-512.png`: 512x512px maskable icon

Use tools like https://www.pwabuilder.com/imageGenerator to generate icons.

## Caching Strategy

### Precached Assets
- App shell (index.html, main.dart.js)
- Manifest and icons
- Flutter framework files

### Runtime Cached
- API responses (network-first)
- Plant images (cache-first)
- User-generated content

### Cache Versioning
- Cache name includes version number
- Old caches are automatically cleaned up on activation

## Background Sync

### Automatic Sync
- Triggers when connection is restored
- Processes all queued changes
- Handles conflicts automatically when possible

### Manual Sync
Users can manually trigger sync:
```dart
await PWAService().triggerSync();
```

### Sync Progress
Monitor sync progress:
```dart
OfflineSyncService().syncProgressStream.listen((progress) {
  print('Sync: ${progress.completed}/${progress.total}');
});
```

## Conflict Resolution

### Conflict Detection
Conflicts occur when:
- Local change timestamp < server change timestamp
- Both versions have been modified

### Resolution Strategies
1. **Use Local**: Apply local changes, overwrite server
2. **Use Server**: Discard local changes, keep server version
3. **Merge**: (Future) Combine both versions intelligently

### Conflict Storage
Conflicts are stored in Hive box: `sync_conflicts`
- Persists across app restarts
- Can be viewed and resolved later

## Testing

### Testing Offline Mode
1. Open Chrome DevTools
2. Go to Network tab
3. Select "Offline" from throttling dropdown
4. Make changes in the app
5. Go back online
6. Verify changes sync automatically

### Testing Install Prompt
1. Open app in Chrome (desktop or mobile)
2. Wait for install prompt to appear
3. Click "Install" to add to home screen

### Testing Service Worker
1. Open Chrome DevTools
2. Go to Application tab
3. Select "Service Workers"
4. View registered service worker and cache storage

## Best Practices

### For Developers
1. Always use `OfflineSyncMixin` for data operations
2. Provide optimistic results for offline operations
3. Handle sync conflicts gracefully
4. Test both online and offline scenarios

### For Users
1. Install app to home screen for best experience
2. Check sync status before closing app
3. Resolve conflicts promptly
4. Keep app updated

## Troubleshooting

### Service Worker Not Registering
- Check browser console for errors
- Ensure HTTPS or localhost
- Clear browser cache and reload

### Sync Not Working
- Check online status indicator
- View pending changes in DevTools
- Check for JavaScript errors in console

### Conflicts Not Resolving
- Navigate to Sync Conflicts screen
- Manually resolve each conflict
- Contact support if issues persist

## Future Enhancements

1. **Smart Merge**: Intelligent conflict resolution
2. **Selective Sync**: Choose what to sync
3. **Compression**: Reduce cache size
4. **Analytics**: Track offline usage patterns
5. **Push Sync**: Server-initiated sync
