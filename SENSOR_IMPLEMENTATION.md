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
- **Primary sensor for speed calculation** (especially critical for indoor rinks)
- **Motion pattern recognition** for hockey-specific movements

### GPS Sensor (Planned Implementation)
**Unit**: m/s for speed, decimal degrees for position

**Implementation (Planned)**:
```monkey
if (Position has :speed && Position.speed != null) {
    // GPS speed data available
    var gpsSpeed = Position.speed;
    System.println("GPS Speed: " + gpsSpeed + " m/s");
}
```

**Usage in Hockey Context**:
- Backup/secondary speed measurement
- Position tracking for outdoor rinks
- Validation of accelerometer-derived speed
- Long-term distance accumulation

## Sensor Fusion Strategy: Accelerometer-Primary with GPS Backup

### Why Accelerometer-Primary?
1. **Indoor Compatibility**: Most hockey is played indoors where GPS signals are weak or unavailable
2. **Higher Sample Rate**: Accelerometer data can be sampled at much higher frequencies (typically 25-100Hz) compared to GPS (typically 1Hz)
3. **Lower Battery Impact**: Accelerometer sensors consume significantly less power than continuous GPS tracking
4. **Low Latency**: Provides immediate feedback on movement changes without GPS acquisition delays
5. **Motion Pattern Recognition**: Can detect hockey-specific movements like stops, starts, and shot attempts

### Accelerometer Speed Calculation
Speed will be calculated from accelerometer data using the following steps:

1. **Preprocessing**:
   - Apply low-pass filter to remove high-frequency noise
   - Detect and correct for device orientation
   - Identify and remove gravity component

2. **Integration**:
   - First integration of acceleration yields velocity
   - Apply high-pass filter to combat drift
   - Reset integration when stationary periods detected
   - Implementation:
   ```monkey
   // Pseudocode for accelerometer speed calculation
   function calculateSpeedFromAccel(accelX, accelY, accelZ, deltaTime) {
       // Remove gravity and correct orientation
       var linearAccel = removeGravity(accelX, accelY, accelZ);
       
       // Integrate to get velocity
       _velocityX += linearAccel[0] * deltaTime;
       _velocityY += linearAccel[1] * deltaTime;
       _velocityZ += linearAccel[2] * deltaTime;
       
       // Apply high-pass filter to combat drift
       applyDriftCorrection();
       
       // Calculate speed magnitude
       return Math.sqrt(_velocityX*_velocityX + _velocityY*_velocityY + _velocityZ*_velocityZ);
   }
   ```

3. **Calibration**:
   - Use known hockey movement patterns to calibrate sensitivity
   - Periodic zero-velocity updates during detected rest periods
   - Adjustable sensitivity based on player position and style

## Kalman Filter Implementation for Sensor Fusion

The Hockey Tracker will implement a Kalman filter to optimally combine accelerometer and GPS data when available. The Kalman filter provides a mathematically sound way to fuse data from multiple sensors, accounting for the strengths and weaknesses of each sensor.

### Kalman Filter Design

1. **State Representation**:
   - State vector will include position, velocity, and acceleration
   - Position and velocity updated from both sensors
   - Acceleration primarily from accelerometer

2. **Sensor Weighting**:
   - Higher weight to accelerometer in indoor environments
   - Dynamically adjust weights based on GPS signal quality
   - Lower GPS weight when signal quality is poor (e.g., indoor rinks)
   - Implementation:
   ```monkey
   // Pseudocode for adaptive sensor weighting
   function updateSensorWeights(gpsAccuracy) {
       if (gpsAccuracy == null || gpsAccuracy > GPS_THRESHOLD_POOR) {
           // Poor GPS - rely almost entirely on accelerometer
           _kalmanConfig.accelWeight = 0.95;
           _kalmanConfig.gpsWeight = 0.05;
       } else if (gpsAccuracy > GPS_THRESHOLD_MODERATE) {
           // Moderate GPS - blend data but favor accelerometer
           _kalmanConfig.accelWeight = 0.75;
           _kalmanConfig.gpsWeight = 0.25;
       } else {
           // Good GPS - more balanced approach
           _kalmanConfig.accelWeight = 0.60;
           _kalmanConfig.gpsWeight = 0.40;
       }
   }
   ```

3. **Process Model**:
   - Account for hockey-specific movement patterns
   - Include rapid acceleration/deceleration common in hockey
   - Higher process noise during active play, lower during rest

4. **Implementation Strategy**:
   - A simplified Kalman filter to conserve battery and computational resources
   - Optimize for hockey's specific movement patterns
   - Adaptive filter parameters based on detected activity
   - Implementation:
   ```monkey
   // Pseudocode for simplified Kalman filter update
   function updateKalmanFilter(accelSpeed, gpsSpeed, deltaTime) {
       // Prediction step
       _predictedState = _previousState + _previousVelocity * deltaTime;
       _predictedVelocity = _previousVelocity;
       
       // Update step - when GPS data is available
       if (gpsSpeed != null) {
           updateSensorWeights(gpsAccuracy);
           
           // Calculate Kalman gain based on sensor weights
           var kalmanGain = calculateKalmanGain();
           
           // Update state with weighted combination
           _currentState = _predictedState + kalmanGain * (gpsSpeed - _predictedState);
           _currentVelocity = _predictedVelocity + kalmanGain * ((gpsSpeed - _predictedState)/deltaTime);
       } else {
           // No GPS, rely entirely on accelerometer prediction
           _currentState = _predictedState;
           _currentVelocity = accelSpeed;
       }
       
       // Store states for next iteration
       _previousState = _currentState;
       _previousVelocity = _currentVelocity;
       
       return _currentVelocity; // Return the estimated speed
   }
   ```

### Planned Testing Framework

1. **Controlled Environment Testing**:
   - Walking/running tests with known speeds
   - Comparison with professional speed measurement equipment
   - Validation against GPS in optimal conditions

2. **Hockey-Specific Tests**:
   - Simulated hockey movements (stops, starts, direction changes)
   - On-ice testing with different playing styles
   - Comparison of accelerometer-only vs. GPS-only vs. Kalman filter fusion

3. **Performance Metrics**:
   - Speed accuracy compared to reference sources
   - System responsiveness to sudden movement changes
   - Battery impact of different sensor configurations
   - Drift measurement over extended sessions

## Best Practices for Sensor Implementation

1. **Battery Optimization**:
   - Only register sensors when needed
   - Unregister listeners in onStop()
   - Consider sampling rate requirements
   - Adaptive sensor usage based on activity intensity

2. **Data Processing**:
   - Filter noisy sensor data
   - Use appropriate thresholds for hockey-specific movements
   - Consider rolling averages for more stable readings
   - Implement zero-velocity updates during stationary periods

3. **Error Handling**:
   - Always check if sensor data is available
   - Handle null values gracefully
   - Provide fallbacks when sensors are unavailable
   - Detect and discard physically impossible readings

## How Hockey Tracker Processes Sensor Data

1. **Data Collection Phase**:
   - Raw sensor data is collected via the onSensorData callback
   - Data is preliminarily filtered for null values
   - Sampling rates optimized for hockey movements

2. **Processing Phase** (to be implemented):
   - Heart rate data will be categorized into effort zones
   - Accelerometer data will be analyzed for movement patterns and speed
   - GPS data will be used to calibrate and validate accelerometer-derived speed
   - Kalman filter will fuse sensor data for optimal accuracy
   - Combined sensor data will generate game/training insights

3. **Visualization Phase** (to be implemented):
   - Real-time display of current heart rate and speed
   - Post-session graphs and analysis
   - Period-by-period exertion tracking
   - Shift-based performance metrics

## Direct Testing Notes

For testing sensor implementations without using the simulator:

- Our testing tools directly inject sensor data into the app for comprehensive testing
- Custom sensor data can be generated with realistic hockey-specific patterns
- The direct testing approach supports continuous integration/continuous deployment
- Testing can be performed against multiple device profiles simultaneously
- Edge cases can be simulated to verify app robustness
- Performance metrics can be collected during testing to evaluate efficiency

To run direct tests, use the tools in the Testing directory:
```bash
cd Testing
./test_simple_heartrate.py --test-mode --device fenix6
```

See the Testing/README.md file for more detailed information on the testing tools and options. 