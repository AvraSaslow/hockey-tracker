# Hockey Tracker - Garmin App Documentation

## Project Overview
Hockey Tracker is a Garmin watch application designed specifically for hockey players. The app aims to provide tracking, timing, and analysis features for both game situations and training sessions.

## Current Project Status
**Current Phase: Phase 1 - Project Setup and Basic Structure**

### Completed Tasks:
1. ✅ Updated App Manifest
   - Added target Garmin devices suitable for hockey players
   - Set required permissions for sensors, storage, etc.
   - Updated app name to "Hockey Tracker"
   - Updated entry point to "HockeyTracker"
   - Added language support for major hockey-playing regions

2. ✅ Updated Main Application File
   - Created HockeyTracker.mc with proper class name
   - Added sensor integration for heart rate and accelerometer
   - Implemented sensor event handling with appropriate units:
     - Heart Rate: beats per minute (bpm)
     - Accelerometer: millig-units for x,y,z axes

### Pending Tasks:
1. ⬜ Create Hockey-Themed Resources
   - Replace generic launcher icon with hockey-themed icon
   - Create hockey-related graphics (puck, stick, rink, etc.)
   - Update string resources with hockey terminology

2. ⬜ Define Core App Features
   - Game Timer implementation
   - Stat Tracking structure
   - Fitness Metrics integration
   - Training Mode foundation

## Sensor Implementation
The app is configured to use the following sensors in accordance with the [Garmin Developer Documentation](https://developer.garmin.com/connect-iq/core-topics/sensors/):

| Sensor | Unit | Usage in App |
|--------|------|-------------|
| Heart Rate | Beats per minute (bpm) | Track exertion during gameplay and recovery |
| Accelerometer | Millig-units (mg) for x,y,z axes | Track movement intensity, potentially identify skating patterns |

Additional sensors that may be added in future phases:
- Barometer (pressure in millibars)
- Temperature (degrees Celsius)
- Ambient Light (lux)

## Project Structure
```
hockey-garmin/
├── manifest.xml            # Application manifest with device support, permissions
├── monkey.jungle           # Build configuration
├── resources/              # UI and localization resources
│   ├── drawables/          # Images and icons
│   ├── layouts/            # UI layout definitions
│   ├── menus/              # Menu definitions
│   └── strings/            # Localized text
└── source/                 # Application code
    ├── HockeyTracker.mc    # Main application class
    ├── hockey-garminDelegate.mc   # Input handling
    ├── hockey-garminMenuDelegate.mc  # Menu handling
    └── hockey-garminView.mc     # UI view definition
```

## Future Development Plan

### Phase 2: Core UI Development (Next Up)
- Implement Main Menu
- Create Game Mode View
- Create Training Mode View
- Create Statistics View

### Phase 3: Data Management and Logic
- Implement Game Data Storage
- Implement Training Data Management
- Implement Settings

### Phase 4: Sensor Integration and Advanced Features
- Complete Heart Rate Monitoring features
- Enhance Accelerometer integration
- Add Notifications and Alerts
- Consider Voice Feedback

### Phase 5: Polish and Optimization
- Refine UI
- Optimize performance and battery usage
- Create testing suite
- Complete documentation

## Development Log

### 2023-03-07
- Initial project template created

### [Current Date]
- Updated manifest.xml with target devices, permissions, and languages
- Updated app name to "Hockey Tracker"
- Created HockeyTracker.mc with sensor integration
- Created initial project documentation 