# Hockey Garmin App

A Garmin Connect IQ application designed for hockey players to track performance metrics during games and practices.

## Features

- Heart rate monitoring and zone analysis for hockey-specific metrics
- Accelerometer data for skating intensity and movement patterns
- Period/shift tracking
- Performance analytics
- Battery-optimized sensor implementation

## Project Structure

- `source/` - Application source code
- `resources/` - Application resources and UI assets
- `Testing/` - Tools for sensor testing and validation
- `bin/` - Compiled application binaries

## Development

### Prerequisites

- Garmin Connect IQ SDK
- Developer key (for signing apps)
- Python 3.7+ for testing tools

### Building the App

```bash
# Build for fenix6
monkeyc -d fenix6 -f monkey.jungle -o bin/HockeyGarmin.prg -y developer_key
```

## Testing

The project uses a direct sensor testing approach that doesn't require the Garmin Connect IQ Simulator:

```bash
# Run sensor tests
cd Testing
./run_sensor_test.sh

# Analyze sensor implementation code
cd Testing
python sensor_test.py ../source/SimpleHeartRateTest.mc
```

### Testing Features

- Direct sensor data injection without simulator
- Realistic hockey-specific motion patterns
- Heart rate zone simulation
- Accelerometer data for skating patterns
- Automated test validation

## Documentation

- [Project Documentation](PROJECT_DOCUMENTATION.md) - Overall project details
- [Development Roadmap](DEVELOPMENT_ROADMAP.md) - Future plans and milestones
- [Sensor Implementation Guide](SENSOR_IMPLEMENTATION.md) - Sensor technical details
- [Testing Documentation](Testing/README.md) - Detailed testing information

## License

[Specify your license information here] 