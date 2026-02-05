# Garden Zone Management Widgets

This directory contains widgets for managing and displaying garden zones.

## Interactive Zone Display

The `InteractiveZoneDisplay` widget provides an interactive visualization of garden zones overlaid on a master plan image.

### Features

- **Visual Zone Overlay**: Displays numbered zones on top of the master plan image
- **Interactive Selection**: Click zones to select and view details
- **Zone Legend**: Shows all zones with color coding and plant counts
- **Hover Effects**: Visual feedback when hovering over zones
- **Selected Zone Details**: Displays detailed information about the selected zone

### Usage

```dart
InteractiveZoneDisplay(
  masterPlan: garden.masterPlan!,
  zones: garden.zones,
  plants: garden.plants,
  onZoneTap: (zone) {
    // Handle zone selection
    print('Selected zone: ${zone.name}');
  },
  isInteractive: true, // Enable/disable interaction
)
```

### Properties

- `masterPlan` (required): The garden master plan with image URL
- `zones` (required): List of garden zones to display
- `plants` (required): List of plant instances for counting plants per zone
- `onZoneTap`: Callback when a zone is tapped
- `isInteractive`: Enable/disable zone interaction (default: true)

## Zone Management

Zones can be managed through the admin panel using the `ZoneManagementScreen`.

### Admin Features

- Create new zones with name and description
- Edit existing zone information
- Delete zones
- View plant count per zone
- Color-coded zone visualization

### Zone Properties

Each zone has:
- **ID**: Unique identifier
- **Name**: Display name (e.g., "Front Garden", "Back Yard")
- **Description**: Optional detailed description
- **Plant Instance IDs**: List of plants assigned to this zone

## Integration

The zone system integrates with:

1. **Master Plan Upload**: Zones can be defined when uploading a master plan
2. **Plant Assignment**: Plants can be assigned to specific zones
3. **Garden Overview**: Interactive zone display in client garden view
4. **Admin Panel**: Full zone management capabilities

## API Endpoints

The zone system uses the following API endpoints:

- `POST /admin/clients/:clientId/zones` - Create zones
- `GET /gardens/:clientId/zones` - Get all zones
- `PUT /gardens/:clientId/zones/:zoneId` - Update zone
- `DELETE /gardens/:clientId/zones/:zoneId` - Delete zone
- `GET /gardens/:clientId/zones/:zoneId/plants` - Get plants in zone
- `PUT /plant-instances/:plantInstanceId/zone` - Assign plant to zone
