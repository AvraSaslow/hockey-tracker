# Sensor Implementation Guide for Hockey Tracker

This document outlines how sensors are implemented in the Hockey Tracker app according to the [Garmin Sensor Documentation](https://developer.garmin.com/connect-iq/core-topics/sensors/).

## Implemented Sensors

### Heart Rate Sensor
**Unit**: Beats per minute (bpm)

**Implementation**:
```monkey
if (sensorData has :heartRate && sensorData.heartRate != null) {
    // Heart rate data available (beats per minute)
    var heartRate = sensorData.heartRate;
    System.println("Heart Rate: " + heartRate + " bpm");
}
```

**Usage in Hockey Context**:
- Track player exertion during shifts
- Monitor recovery during bench time
- Calculate intensity zones during play
- Provide post-game recovery insights

### Accelerometer Sensor
**Unit**: Millig-units (mg) for x, y, z axes

**Implementation**:
```monkey
if (sensorData has :accelerometer && sensorData.accelerometer != null) {
    // Accelerometer data available (in millig-units as x,y,z)
    var accel = sensorData.accelerometer;
    System.println("Accelerometer: x=" + accel[0] + ", y=" + accel[1] + ", z=" + accel[2] + " mg");
}
```

**Usage in Hockey Context**:
- Detect skating intensity
- Identify stopping/starting patterns
- Potentially recognize shot motions
- Track overall movement exertion

## Testing in Simulator

The Garmin simulator can simulate sensor data for testing. To test sensor implementation:

1. Run the app in the simulator
2. Use the Sensor tab in the simulator
3. For Heart Rate:
   - Set values between 60-200 bpm for testing different intensities
   - Test transitions between zones
4. For Accelerometer:
   - Test different values for x, y, z axes
   - Simulate changes that would represent skating, stopping, etc.

## Planned Future Sensor Implementations

### Temperature Sensor
**Unit**: Degrees Celsius (°C)
**Purpose**: Track environmental conditions, especially for outdoor rinks

### Barometer/Altitude Sensor
**Unit**: Millibars (mb) / Meters (m)
**Purpose**: Track altitude for games at different elevations, which can affect player stamina

## Best Practices for Sensor Implementation

1. **Battery Optimization**:
   - Only register sensors when needed
   - Unregister listeners in onStop()
   - Consider sampling rate requirements

2. **Data Processing**:
   - Filter noisy sensor data
   - Use appropriate thresholds for hockey-specific movements
   - Consider rolling averages for more stable readings

3. **Error Handling**:
   - Always check if sensor data is available
   - Handle null values gracefully
   - Provide fallbacks when sensors are unavailable

## How Hockey Tracker Processes Sensor Data

1. **Data Collection Phase**:
   - Raw sensor data is collected via the onSensorData callback
   - Data is preliminarily filtered for null values

2. **Processing Phase** (to be implemented):
   - Heart rate data will be categorized into effort zones
   - Accelerometer data will be analyzed for movement patterns
   - Combined sensor data will generate game/training insights

3. **Visualization Phase** (to be implemented):
   - Real-time display of current heart rate
   - Post-session graphs and analysis
   - Period-by-period exertion tracking

## Simulator-Specific Notes

When testing in the simulator, note that:
- Some sensor behaviors may differ from actual devices
- The simulator allows setting specific values that might be unrealistic
- Test extreme values to ensure the app handles them gracefully
- Not all sensors available on devices can be simulated 