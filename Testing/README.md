# Hockey Garmin Sensor Testing

This directory contains tools for testing the sensor implementation in the Hockey Garmin app.

## Prerequisites

- Python 3.7+ with standard libraries
- Garmin Connect IQ SDK installed
- Developer key (for signing apps)
- (Optional) Garmin FIT SDK for advanced testing

## Testing Workflow and File Relationships

This section explains how all the testing components work together and the recommended testing workflow.

### Files Overview and Relationships

```
Testing/
├── sensor_test.py                # Static code analyzer for Monkey C
├── test_simple_heartrate.py      # Core script for generating data and running tests
├── direct_sensor_test_runner.py  # Helper script used by test_simple_heartrate.py
├── run_sensor_test.sh            # Simple wrapper for direct testing
├── json_to_fit.py                # Converts JSON data to FIT format
├── run_fit_test.sh               # Complete test suite including FIT conversion
└── README.md                     # Documentation
```

#### File Dependencies

- `test_simple_heartrate.py` creates and uses `direct_sensor_test_runner.py`
- `run_sensor_test.sh` calls `test_simple_heartrate.py`
- `run_fit_test.sh` calls `run_sensor_test.sh` and `json_to_fit.py`
- `json_to_fit.py` depends on the output from `test_simple_heartrate.py`

### Testing Process Flow

The testing system follows this process flow:

1. **Static Analysis**: `sensor_test.py` validates your Monkey C code against best practices
2. **Data Generation**: `test_simple_heartrate.py` creates realistic sensor data
3. **Direct Testing**: `direct_sensor_test_runner.py` injects data into app and validates responses
4. **FIT Conversion**: `json_to_fit.py` transforms JSON data to Garmin FIT format
5. **Comprehensive Testing**: `run_fit_test.sh` combines steps 1-4 in a single command

### Recommended Testing Workflow

#### Basic Workflow (Most Common)

For regular sensor testing during development:

```bash
# One-step testing (recommended for most users)
./run_sensor_test.sh
```

This provides direct testing with clear pass/fail output and is sufficient for most development needs.

#### Complete Workflow (For Advanced Testing)

For comprehensive testing including FIT format:

```bash
# Install FIT SDK first
pip install fitparse

# Run complete test suite
./run_fit_test.sh
```

This performs direct testing and converts data to FIT format for use with Garmin devices and tools.

#### Custom Testing Scenarios

1. **Code Analysis Only**:
   ```bash
   python sensor_test.py ../source/SimpleHeartRateTest.mc
   ```

2. **Generate Test Data Without Testing**:
   ```bash
   python test_simple_heartrate.py --output custom_data.json
   ```

3. **Direct Testing with Custom Parameters**:
   ```bash
   python test_simple_heartrate.py --duration 120 --hr-min 80 --hr-max 190 --test-mode
   ```

4. **Convert Existing Data to FIT Format**:
   ```bash
   python json_to_fit.py --input custom_data.json --output custom_data.fit
   ```

### Data Flow Diagram

```
                 ┌─────────────────┐
                 │  sensor_test.py │
                 └─────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────┐
│         test_simple_heartrate.py        │◄───┐
└─────────────────────────────────────────┘    │
                │        │                      │
                │        └──────────────┐       │
                ▼                       ▼       │
┌─────────────────────┐    ┌─────────────────────┐
│sensor_test_data.json│    │direct_sensor_test.py│
└─────────────────────┘    └─────────────────────┘
        │                             ▲
        │       ┌───────────────┐     │
        │       │run_sensor_test│─────┘
        │       └───────────────┘
        ▼
┌─────────────────┐
│  json_to_fit.py │
└─────────────────┘
        │
        ▼
┌─────────────────────┐
│sensor_test_data.fit │
└─────────────────────┘
        ▲
        │
┌─────────────────┐
│ run_fit_test.sh │
└─────────────────┘
```

## Quick Reference

```bash
# Generate test data and run direct sensor tests without simulator
./test_simple_heartrate.py --test-mode --device fenix6

# Run the static code analyzer
./sensor_test.py ../source/SimpleHeartRateTest.mc

# Simple testing script (recommended approach)
./run_sensor_test.sh

# Full test suite including FIT format conversion
./run_fit_test.sh
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

### 3. run_sensor_test.sh - Simple Test Runner

This script provides a user-friendly interface for running sensor tests without the simulator.

#### Usage
```bash
cd Testing
chmod +x run_sensor_test.sh
./run_sensor_test.sh
```

#### What It Does
- Automatically detects if you have existing sensor data
- Runs direct tests against your sensor implementation
- Shows clear success/failure indicators with color-coded output
- Provides detailed test results for debugging
- No simulator required - faster and more reliable testing

#### Benefits
- Simple, one-command execution
- Clear, readable output with success/failure status
- Handles both data generation and testing
- Integrates seamlessly with CI/CD pipelines

### 4. json_to_fit.py - JSON to FIT Format Converter

This tool converts the JSON sensor data to Garmin FIT format, which can be used for advanced analysis and with Garmin devices.

#### Usage
```bash
cd Testing
python json_to_fit.py --input sensor_test_data.json --output sensor_test_data.fit
```

#### Command Line Options
```
--input FILE     Input JSON file (default: sensor_test_data.json)
--output FILE    Output FIT file (default: sensor_test_data.fit)
--help           Show help message and exit
```

#### Requirements
To use this tool, you need to install the Garmin FIT SDK:
```bash
pip install fitparse
```

#### What It Does
- Converts JSON-formatted sensor data to Garmin FIT format
- Maintains timestamps and relationships between data points
- Creates properly structured FIT files compatible with Garmin tools
- Generates a JSON representation of the FIT data structure for reference

### 5. run_fit_test.sh - Complete Test Suite

This script runs the full test suite, including direct testing and FIT format conversion.

#### Usage
```bash
cd Testing
chmod +x run_fit_test.sh
./run_fit_test.sh
```

#### What It Does
- Runs the direct sensor tests
- Checks if the Garmin FIT SDK is installed
- Converts the test data to FIT format if possible
- Provides clear feedback on each step of the process
- Generates both JSON and FIT files for comprehensive testing

## Garmin FIT SDK Integration

We've integrated the [Garmin FIT SDK](https://developer.garmin.com/fit/overview/) to provide advanced testing capabilities using Flexible and Interoperable Data Transfer (FIT) files.

### How Our FIT Integration Works

Our testing tools automatically convert JSON sensor data to FIT format:

1. First, realistic sensor data is generated or loaded from existing files
2. The data is used for direct testing of the sensor implementation
3. The json_to_fit.py tool converts this data to FIT format
4. The resulting FIT file can be used with Garmin devices and analysis tools

### Using FIT Files for Advanced Testing

The FIT files generated by our tools can be used for:

1. **Device Testing**: Load the FIT files onto Garmin devices for real-world testing
2. **Data Analysis**: Use Garmin Connect or other FIT-compatible tools to analyze sensor patterns
3. **Algorithm Development**: Test sensor fusion algorithms with standardized data
4. **Performance Benchmarking**: Compare app performance with standard FIT test files

### Getting Started with FIT

1. Install the required library:
   ```bash
   pip install fitparse
   ```

2. Run the complete test suite:
   ```bash
   ./run_fit_test.sh
   ```

3. Examine the generated FIT files with Garmin tools or third-party FIT file viewers

For more details on the FIT file format, see the [Garmin FIT SDK Documentation](https://developer.garmin.com/fit/overview/).

## Troubleshooting

### Common Issues

1. **"SDK not found"**: Set the correct SDK path with `--sdk` or set the `GARMIN_SDK_DIR` environment variable.

2. **"Device ID not found"**: Ensure you're using a valid device ID from the Garmin device list.

3. **"No sensor data detected"**: This could indicate an issue with the sensor implementation or test configuration.

4. **Test failure in sensor_test.py**: Check the specific error messages and fix the issues in your code according to the recommendations.

5. **"fitparse library not found"**: Install the fitparse library:
   ```bash
   pip install fitparse
   ```

6. **"Error creating FIT file"**: This could indicate problems with the JSON data structure or incompatible timestamps. Check that your JSON data follows the expected format.

7. **"Error loading JSON file"**: Ensure the JSON file exists and contains valid JSON data. Try regenerating the data with:
   ```bash
   python test_simple_heartrate.py
   ```

### Debugging Steps

If you encounter issues with the testing suite:

1. **Verify your environment**:
   ```bash
   # Check Python version
   python --version  # Should be 3.7+
   
   # Check fitparse installation (for FIT conversion)
   python -c "import fitparse; print(fitparse.__version__)"
   ```

2. **Run tests with verbose output**:
   ```bash
   python test_simple_heartrate.py --test-mode --verbose
   ```

3. **Examine generated files**:
   ```bash
   # Check JSON file
   cat sensor_test_data.json | head -20
   
   # Check FIT JSON representation
   cat sensor_test_data.fit.json | head -20
   ```

4. **Generate small test dataset**:
   ```bash
   python test_simple_heartrate.py --duration 5 --output small_test.json
   ```

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

These testing tools can be integrated into CI/CD pipelines for automated testing. The command-line nature of all tools makes them suitable for continuous integration workflows, allowing for automated sensor testing on each code commit or pull request.

## Further Reading

- [Garmin Developer Documentation - Sensors](https://developer.garmin.com/connect-iq/core-topics/sensors/)
- [Garmin FIT SDK Documentation](https://developer.garmin.com/fit/overview/)
- [Sensor Implementation Guide](../SENSOR_IMPLEMENTATION.md) in this repository 