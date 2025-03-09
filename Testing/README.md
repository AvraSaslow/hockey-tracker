# Hockey Garmin Sensor Testing

This directory contains tools for testing the sensor implementation in the Hockey Garmin app.

## Prerequisites

- Python 3.7+ with standard libraries
- Garmin Connect IQ SDK installed
- Developer key (for signing apps)
- (Optional) Garmin FIT SDK for advanced testing

## Quick Reference

```bash
# Generate test data and run direct sensor tests without simulator
./test_simple_heartrate.py --test-mode --device fenix6

# Run the static code analyzer
./sensor_test.py ../source/SimpleHeartRateTest.mc

# Automated testing with SDK
./garmin_test_runner.sh --device fenix6 --test-log
```

## Tools Overview

### 1. sensor_test.py - Static Code Analysis

This tool analyzes your Monkey C code to ensure it follows best practices for sensor implementation.

#### Usage
```bash
cd Testing
python sensor_test.py ../source/SimpleHeartRateTest.mc
```

#### What It Checks
- Proper sensor registration/unregistration
- Correct sensor data access patterns with appropriate null checks
- Error handling with try/catch blocks
- Battery optimization best practices
- UI updates after sensor data processing

#### Output
Generates `sensor_implementation_report.txt` with analysis results.

### 2. test_simple_heartrate.py - Direct Sensor Testing

This tool provides direct sensor testing functionality without requiring the Garmin Connect IQ Simulator. It can generate realistic sensor data and directly test the sensor implementation.

#### Usage
```bash
cd Testing
python test_simple_heartrate.py [options]
```

#### Command Line Options
```
--duration SECONDS     Test duration in seconds (default: 60)
--hr-min VALUE         Minimum heart rate in bpm (default: 60)
--hr-max VALUE         Maximum heart rate in bpm (default: 180)
--output FILE          Output file name (default: sensor_test_data.json)
--test-mode            Run in test mode (direct testing without simulator)
--device ID            Target device ID when in test mode (default: fenix6)
--help                 Show help message and exit
```

#### Examples
Generate 2 minutes of test data and run direct sensor tests:
```bash
python test_simple_heartrate.py --duration 120 --hr-min 80 --hr-max 190 --test-mode
```

Specify a different device for testing:
```bash
python test_simple_heartrate.py --test-mode --device fenix7
```

Generate only test data without running tests:
```bash
python test_simple_heartrate.py --output my_custom_data.json
```

#### How Direct Testing Works
The tool performs these steps when running in test mode:

1. Generates realistic heart rate and accelerometer data based on the specified parameters
2. Creates a test environment with configuration file
3. Launches a direct sensor test runner that:
   - Simulates connecting to the target device
   - Injects the generated sensor data directly to the app
   - Collects and validates responses from the app
   - Provides real-time feedback on sensor data processing

#### Data Format
The generated JSON file contains structured sensor data:
```json
{
  "description": "Hockey player sensor simulation",
  "heart_rate": [
    { "timestamp": 0.0, "value": 75 },
    { "timestamp": 1.0, "value": 76 },
    ...
  ],
  "accelerometer": [
    { "timestamp": 0.0, "x": 0.123, "y": 0.456, "z": 1.234 },
    { "timestamp": 0.1, "x": 0.124, "y": 0.458, "z": 1.232 },
    ...
  ]
}
```

### 3. garmin_test_runner.sh - Automated Testing

This script automates the process of building and testing your app using the official SDK tools.

#### Usage
```bash
cd Testing
chmod +x garmin_test_runner.sh
./garmin_test_runner.sh --device fenix6 --test-log
```

#### Options
- `-d, --device DEVICE_ID` - Set the target device (default: fenix6)
- `-s, --sdk PATH` - Set the Garmin SDK path (default: auto-detected)
- `-e, --entry CLASS` - Set the entry class (default: SimpleHeartRateTest)
- `-t, --test-log` - Enable test logger and output test results
- `-v, --verbose` - Show verbose build and test output
- `-h, --help` - Show the help message

#### What It Does
1. Builds your app with the specified parameters
2. Runs tests directly without requiring the simulator
3. Captures and analyzes logs for sensor data
4. Automatically runs the sensor_test.py and test_simple_heartrate.py if they exist

## Garmin FIT SDK Integration

The [Garmin FIT SDK](https://developer.garmin.com/fit/overview/) provides tools for working with Flexible and Interoperable Data Transfer (FIT) files.

### Using FIT with Our Testing Tools

You can extend your testing by converting the JSON data from test_simple_heartrate.py to FIT format:

1. Download the [Garmin FIT SDK](https://developer.garmin.com/fit/download/)
2. Use the Python examples in the SDK to convert JSON to FIT format
3. Test with both direct testing and FIT files

The [FIT SDK Python examples](https://developer.garmin.com/fit/example-projects/python/) show how to:
- Parse FIT files
- Create new FIT files
- Convert data formats
- Work with specific message types

## Troubleshooting

### Common Issues

1. **"SDK not found"**: Set the correct SDK path with `--sdk` or set the `GARMIN_SDK_DIR` environment variable.

2. **"Device ID not found"**: Ensure you're using a valid device ID from the Garmin device list.

3. **"No sensor data detected"**: This could indicate an issue with the sensor implementation or test configuration.

4. **Test failure in sensor_test.py**: Check the specific error messages and fix the issues in your code according to the recommendations.

## Sensor Implementation Best Practices

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

## Python Best Practices

When extending our testing tools or working with Garmin FIT data, follow these best practices:

1. **Use proper Python typing** - Annotate function parameters and return types for clarity
2. **Follow Python's style guide (PEP 8)** - Use consistent naming and formatting
3. **Handle exceptions gracefully** - Especially when working with files and external APIs
4. **Document your code well** - Include docstrings and comments for complex logic
5. **Test on actual devices** - Whenever possible, verify behavior on real Garmin hardware

## CI/CD Integration

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
    - name: Install dependencies
      run: pip install -r requirements.txt
    - name: Run static analysis
      run: python Testing/sensor_test.py source/SimpleHeartRateTest.mc
    - name: Generate test data and run direct tests
      run: python Testing/test_simple_heartrate.py --test-mode
```

## Further Reading

- [Garmin Developer Documentation - Sensors](https://developer.garmin.com/connect-iq/core-topics/sensors/)
- [Garmin FIT SDK Documentation](https://developer.garmin.com/fit/overview/)
- [Sensor Implementation Guide](../SENSOR_IMPLEMENTATION.md) in this repository 