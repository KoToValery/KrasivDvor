# Requirements Document

## Introduction

Система за каталогизиране на растения и управление на градини, предназначена за ландшафтни архитекти и техните клиенти. Приложението служи като B2B2C платформа, където ландшафтните екипи създават профили за клиентите си с попълнена информация за засадените растения.

## Glossary

- **Plant_Catalog**: Централна база данни с всички видове растения
- **QR_System**: Система за генериране и сканиране на QR кодове за растения
- **Compatibility_Engine**: Алгоритъм за определяне на съвместимост между растения
- **Client_Garden**: Персонален профил на клиент с неговите засадени растения
- **Landscape_Team**: Ландшафтни архитекти и екипи, които управляват системата
- **Care_Reminder_System**: Система за автоматични напомняния за грижи
- **Admin_Panel**: Административен интерфейс за ландшафтните екипи

## Requirements

### Requirement 1: Plant Catalog Management

**User Story:** Като ландшафтен архитект, искам да имам достъп до пълен каталог на растения, за да мога да избирам подходящи видове за проектите си.

#### Acceptance Criteria

1. THE Plant_Catalog SHALL store plants organized in categories (trees, shrubs, flowers, grasses, climbers, aquatic plants)
2. WHEN a plant is added to the catalog, THE Plant_Catalog SHALL require Latin name, Bulgarian name, and basic characteristics
3. THE Plant_Catalog SHALL store multiple photos for each plant (leaf, flower, full view, winter appearance)
4. THE Plant_Catalog SHALL store care requirements (light, water, soil, maintenance schedule)
5. THE Plant_Catalog SHALL store plant specifications (height, width, hardiness zone, bloom season, growth rate)
6. THE Plant_Catalog SHALL store compatibility information and toxicity warnings

### Requirement 2: QR Code System

**User Story:** Като клиент, искам да мога да сканирам QR код на растение, за да получа пълна информация за него.

#### Acceptance Criteria

1. WHEN a plant is added to the catalog, THE QR_System SHALL generate a unique QR code
2. WHEN a QR code is scanned, THE QR_System SHALL display complete plant information
3. WHEN scanning a QR code, THE QR_System SHALL provide option to add plant to "My Garden"
4. THE QR_System SHALL allow sharing plant information with clients

### Requirement 3: Plant Compatibility System

**User Story:** Като ландшафтен архитект, искам да знам кои растения се комбинират добре заедно, за да създавам хармонични композици.

#### Acceptance Criteria

1. THE Compatibility_Engine SHALL analyze plant compatibility based on light requirements
2. THE Compatibility_Engine SHALL analyze plant compatibility based on water needs
3. THE Compatibility_Engine SHALL consider color harmony, height levels, and seasonal variety
4. WHEN viewing a plant, THE Compatibility_Engine SHALL suggest compatible plants
5. THE Compatibility_Engine SHALL provide visualization of plant combinations

### Requirement 4: Client Garden Profiles

**User Story:** Като клиент, искам да имам персонален профил с информация за растенията в моята градина.

#### Acceptance Criteria

1. THE Landscape_Team SHALL create client profiles with unique login credentials
2. WHEN a client profile is created, THE Client_Garden SHALL include pre-populated plants from the project
3. THE Client_Garden SHALL display visual garden map with zones
4. THE Client_Garden SHALL maintain planting history with dates and photos
5. THE Client_Garden SHALL allow clients to add personal notes and photos
6. THE Client_Garden SHALL store documentation (warranties, certificates, care instructions)

### Requirement 5: Care Reminder System

**User Story:** Като клиент, искам да получавам напомняния за грижи за растенията в градината си.

#### Acceptance Criteria

1. THE Care_Reminder_System SHALL generate automatic watering reminders based on plant type
2. THE Care_Reminder_System SHALL adjust reminders based on season and weather data
3. THE Care_Reminder_System SHALL consider plant age (newly planted vs established)
4. THE Care_Reminder_System SHALL send reminders for fertilizing, pruning, and seasonal care
5. WHEN weather conditions change, THE Care_Reminder_System SHALL modify reminder frequency
6. THE Care_Reminder_System SHALL allow users to postpone or mark reminders as completed

### Requirement 6: Administrative Management

**User Story:** Като ландшафтен екип, искам да управлявам клиентски профили и каталога на растения.

#### Acceptance Criteria

1. THE Admin_Panel SHALL allow creation of new client profiles
2. THE Admin_Panel SHALL support importing projects and assigning plants to clients
3. THE Admin_Panel SHALL generate QR code labels for plant identification
4. THE Admin_Panel SHALL allow easy addition and editing of catalog plants
5. THE Admin_Panel SHALL support bulk import of plant data from Excel/CSV files
6. THE Admin_Panel SHALL enable mass upload of plant photos and categorization

### Requirement 7: Garden Zone Management

**User Story:** Като ландшафтен архитект, искам да създавам зонирани планове на градини за по-добра организация.

#### Acceptance Criteria

1. THE Admin_Panel SHALL support uploading garden master plans as JPG or PDF files
2. WHEN uploading a master plan, THE Admin_Panel SHALL allow defining numbered zones with legends
3. THE Admin_Panel SHALL allow renaming zones according to project needs
4. THE Client_Garden SHALL display the master plan with interactive zones
5. WHEN viewing zones, THE Client_Garden SHALL show plants assigned to each specific zone

### Requirement 8: Plant Search and Discovery

**User Story:** Като потребител, искам да търся растения по различни критерии, за да намеря подходящи видове.

#### Acceptance Criteria

1. THE Plant_Catalog SHALL provide search functionality by name, category, and characteristics
2. THE Plant_Catalog SHALL allow filtering by care requirements (light, water, maintenance)
3. THE Plant_Catalog SHALL support filtering by plant specifications (size, bloom time, hardiness)
4. WHEN searching plants, THE Plant_Catalog SHALL display results with key information and photos
5. THE Plant_Catalog SHALL provide advanced search combining multiple criteria