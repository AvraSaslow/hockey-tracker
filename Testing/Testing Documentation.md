# Hockey Garmin App Testing

This document explains how to test the sensor implementation in the Hockey Garmin app without relying solely on the Garmin Connect IQ Simulator.

## Testing Tools

We've created several tools in this Testing directory to help verify the sensor implementation:

1. **sensor_test.py** - A static code analyzer that checks whether the sensor implementation follows best practices
2. **sensor_simulator.py** - A dynamic tester that simulates sensor data and predicts how the app would handle it
3. **garmin_test_runner.sh** - A shell script that automates testing with the Garmin SDK tools

These tools allow you to verify your sensor implementation from different angles:
- Static analysis checks for proper API usage and best practices
- Dynamic simulation tests with realistic sensor data
- Command-line testing using the actual SDK tools

## Prerequisites

- Python 3.7+ with standard libraries
- Garmin Connect IQ SDK installed
- Developer key (for signing apps)

## 1. Static Code Analysis with sensor_test.py

This tool analyzes your Monkey C code to ensure it follows best practices for sensor implementation.

### Usage

```bash
cd Testing
python sensor_test.py ../source/SimpleHeartRateTest.mc
```

### What It Checks

- Proper sensor registration/unregistration
- Correct sensor data access patterns with appropriate null checks
- Error handling with try/catch blocks
- Battery optimization best practices
- UI updates after sensor data processing

### Example Output

The tool will generate a report showing which checks passed and which failed, with line numbers and suggestions for improvement.

## 2. Sensor Simulation with sensor_simulator.py

This tool simulates how your code would behave with real sensor data by analyzing the sensor callback and options.

### Usage

```bash
cd Testing
python sensor_simulator.py ../source/SimpleHeartRateTest.mc
```

### What It Simulates

- Different movement patterns (random, walking, hockey-specific)
- Heart rate variations
- Accelerometer data in three axes
- Data processing success rate
- Potential runtime errors

### Example Output

The tool provides a report on how your implementation would handle different movement patterns and identifies potential issues.

## 3. Command-line Testing with garmin_test_runner.sh

This script automates the process of building and testing your app using the official SDK tools.

### Usage

```bash
cd Testing
chmod +x garmin_test_runner.sh
./garmin_test_runner.sh --device fenix6 --test-log
```

### Options

- `-d, --device DEVICE_ID` - Set the target device (default: fenix6)
- `-s, --sdk PATH` - Set the Garmin SDK path (default: $HOME/connectiq-sdk)
- `-e, --entry CLASS` - Set the entry class (default: SimpleHeartRateTest)
- `-t, --test-log` - Enable test logger and output test results
- `-v, --verbose` - Show verbose build and test output
- `-h, --help` - Show the help message

### What It Does

1. Builds your app with the specified parameters
2. Runs it in the simulator for a short time
3. Captures and analyzes logs for sensor data
4. Automatically runs the sensor_test.py and sensor_simulator.py if they exist

## Troubleshooting

### Common Issues

1. **"SDK not found"**: Set the correct SDK path with `--sdk` or set the `GARMIN_SDK_DIR` environment variable.

2. **"Device ID not found"**: Ensure you're using a valid device ID from the Garmin device list.

3. **"No sensor data detected"**: This could indicate an issue with the sensor implementation or simulator configuration.

4. **Test failure in sensor_test.py**: Check the specific error messages and fix the issues in your code according to the recommendations.

## Correcting Sensor Implementation Issues

If the tests reveal issues with your sensor implementation, here are the common fixes:

1. **Proper registration**:
   ```monkey
   try {
       Sensor.registerSensorDataListener(method(:onSensorData), options);
   } catch (e) {
       System.println("Error registering sensors: " + e.getErrorMessage());
   }
   ```

2. **Proper unregistration**:
   ```monkey
   try {
       Sensor.unregisterSensorDataListener();
   } catch (e) {
       System.println("Error unregistering sensors: " + e.getErrorMessage());
   }
   ```

3. **Correct sensor data access**:
   ```monkey
   if (sensorData has :heartRate && sensorData.heartRate != null) {
       // Now it's safe to use sensorData.heartRate
   }
   ```

4. **UI updates**:
   ```monkey
   // After processing sensor data
   WatchUi.requestUpdate();
   ```

## Integration with CI/CD

These testing tools can be integrated into a CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    - name: Install Garmin SDK
      run: |
        # Install Garmin SDK (varies based on your setup)
    - name: Run static analysis
      run: python Testing/sensor_test.py source/SimpleHeartRateTest.mc
    - name: Run sensor simulation
      run: python Testing/sensor_simulator.py source/SimpleHeartRateTest.mc
```

## Further Reading

For more information on sensor implementation in Garmin Connect IQ, see:
- [Garmin Developer Documentation - Sensors](https://developer.garmin.com/connect-iq/core-topics/sensors/)
- [Sensor Implementation Guide](../SENSOR_IMPLEMENTATION.md) in this repository 