#!/usr/bin/env bash
# Garmin Connect IQ Test Runner
# This script automates testing of Garmin Connect IQ apps from the command line
# without requiring the simulator UI.
#
# For sensor testing, the script can:
# 1. Use an existing sensor data JSON file specified with --sensor-data
# 2. Automatically generate sensor test data using test_simple_heartrate.py
# 3. Provide instructions for loading the sensor data in the simulator

set -e

# Helper functions
function list_dir() {
    local dir="$1"
    echo -e "${BLUE}Contents of directory: $dir${NC}"
    ls -la "$dir"
    echo ""
}

# Try to auto-detect SDK location if not set
if [ -z "$GARMIN_SDK_DIR" ]; then
    # Common SDK locations to check
    POSSIBLE_SDK_PATHS=(
        "/Users/Avra.Saslow/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.0-2025-03-04-7ae1ed1cb"
        "$HOME/connectiq-sdk"
        "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/current"
        "/Applications/Garmin/ConnectIQ/Sdks/current"
        "$HOME/garmin-connectiq-sdk"
        "$HOME/connectiq"
        "/opt/connectiq-sdk"
    )
    
    # Check each path and use the first one that exists
    for path in "${POSSIBLE_SDK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            GARMIN_SDK_DIR="$path"
            echo "Auto-detected Garmin SDK at: $GARMIN_SDK_DIR"
            break
        fi
    done
    
    # If still not found, use the default
    if [ -z "$GARMIN_SDK_DIR" ]; then
        GARMIN_SDK_DIR="$HOME/connectiq-sdk"
    fi
fi

# Configure paths
DEVICE_ID="${DEVICE_ID:-fenix6}"  # Default device to target
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/bin"

# Default to SimpleHeartRateTest
ENTRY_CLASS="SimpleHeartRateTest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
print_usage() {
    echo -e "${BLUE}Garmin Connect IQ Test Runner${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE_ID       Set the target device (default: $DEVICE_ID)"
    echo "  -s, --sdk PATH               Set the Garmin SDK path (default: $GARMIN_SDK_DIR)"
    echo "  -e, --entry CLASS            Set the entry class (default: $ENTRY_CLASS)"
    echo "  -t, --test-log               Enable test logger and output test results"
    echo "  --sensor-data FILE           Specify a JSON file with sensor data to use in testing"
    echo "  -v, --verbose                Show verbose build and test output"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --device fenix6 --test-log"
    echo "  $0 --device fenix6 --sensor-data sensor_test_data.json"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -s|--sdk)
            GARMIN_SDK_DIR="$2"
            shift 2
            ;;
        -e|--entry)
            ENTRY_CLASS="$2"
            shift 2
            ;;
        -t|--test-log)
            ENABLE_TEST_LOG=1
            shift
            ;;
        --sensor-data)
            SENSOR_DATA_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Verify SDK directory exists
if [ ! -d "$GARMIN_SDK_DIR" ]; then
    echo -e "${RED}Error: Garmin SDK directory not found at '$GARMIN_SDK_DIR'${NC}"
    echo -e "${YELLOW}Please do one of the following:${NC}"
    echo -e "  1. Install the SDK to one of these locations:"
    for path in "${POSSIBLE_SDK_PATHS[@]}"; do
        echo -e "     - $path"
    done
    echo -e "  2. Specify the SDK path: ${GREEN}--sdk /path/to/your/connectiq-sdk${NC}"
    echo -e "  3. Set the environment variable: ${GREEN}export GARMIN_SDK_DIR=/path/to/your/connectiq-sdk${NC}"
    echo -e "\nFor instructions on installing the Garmin Connect IQ SDK, visit:"
    echo -e "${BLUE}https://developer.garmin.com/connect-iq/sdk/${NC}"
    exit 1
fi

# Detect SDK bin directory 
MONKEYC="$GARMIN_SDK_DIR/bin/monkeyc"
MONKEYDO="$GARMIN_SDK_DIR/bin/monkeydo"

if [ ! -x "$MONKEYC" ]; then
    echo -e "${RED}Error: monkeyc compiler not found at '$MONKEYC'${NC}"
    exit 1
fi

if [ ! -x "$MONKEYDO" ]; then
    echo -e "${RED}Error: monkeydo runner not found at '$MONKEYDO'${NC}"
    exit 1
fi

# Device verification
DEVICES_XML="$GARMIN_SDK_DIR/devices.xml"
if [ ! -f "$DEVICES_XML" ]; then
    echo -e "${YELLOW}Warning: devices.xml not found at '$DEVICES_XML'${NC}"
    echo "Cannot verify device ID. Proceeding anyway..."
else
    if ! grep -q "id=\"$DEVICE_ID\"" "$DEVICES_XML"; then
        echo -e "${YELLOW}Warning: Device ID '$DEVICE_ID' not found in devices.xml${NC}"
        echo "Available devices include:"
        grep -o 'id="[^"]*"' "$DEVICES_XML" | cut -d'"' -f2 | sort | uniq | head -n 10
        echo "... and more"
        echo ""
        echo -e "${YELLOW}Proceeding with the specified device ID anyway...${NC}"
    fi
fi

# Build the app
echo -e "${BLUE}Building app with entry class '$ENTRY_CLASS' for device '$DEVICE_ID'...${NC}"

BUILD_PRG="$OUTPUT_DIR/$ENTRY_CLASS.prg"

# Add test logger if requested
TEST_LOG_ARGS=""
if [ -n "$ENABLE_TEST_LOG" ]; then
    TEST_LOG_ARGS="-t"
    echo -e "${BLUE}Test logging enabled${NC}"
fi

# Set verbosity
VERBOSITY=""
if [ -n "$VERBOSE" ]; then
    VERBOSITY="-v"
fi

# Look for developer key
DEVELOPER_KEY=""
if [ -f "$PROJECT_DIR/developer_key" ]; then
    DEVELOPER_KEY="$PROJECT_DIR/developer_key"
    echo -e "${BLUE}Using developer key from $DEVELOPER_KEY${NC}"
fi

# Set up build logging early
BUILD_LOG_DIR="$SCRIPT_DIR/build_logs"
mkdir -p "$BUILD_LOG_DIR"
BUILD_LOG_FILE="$BUILD_LOG_DIR/build_$(date +%Y%m%d_%H%M%S).log"
echo -e "${BLUE}Logging build output to: $BUILD_LOG_FILE${NC}"

# Start logging to the file
exec > >(tee -a "$BUILD_LOG_FILE") 2>&1
echo "===== Garmin Connect IQ Build Log ====="
echo "Date: $(date)"
echo "Entry Class: $ENTRY_CLASS"
echo "Device: $DEVICE_ID"
echo "SDK Path: $GARMIN_SDK_DIR"
echo "Current Directory: $(pwd)"
echo "Script Directory: $SCRIPT_DIR"
echo "Project Directory: $PROJECT_DIR"
echo "======================================="

# Compile the app
echo -e "${BLUE}Compiling...${NC}"
if [ -n "$VERBOSE" ]; then
    set -x
fi

# Make output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run from project directory for correct paths
cd "$PROJECT_DIR"

"$MONKEYC" \
    -o "$BUILD_PRG" \
    -d "$DEVICE_ID" \
    -f "monkey.jungle" \
    -y "$DEVELOPER_KEY" \
    $TEST_LOG_ARGS \
    $VERBOSITY

if [ -n "$VERBOSE" ]; then
    set +x
fi

# Check if compilation succeeded
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully built $BUILD_PRG${NC}"

# Generate or use sensor test data
if [ -n "$SENSOR_DATA_FILE" ]; then
    echo -e "${BLUE}Looking for sensor data file: $SENSOR_DATA_FILE${NC}"
    
    # First try directly with the provided path
    if [ -f "$SENSOR_DATA_FILE" ]; then
        SENSOR_DATA="$SENSOR_DATA_FILE"
        echo -e "${GREEN}Found sensor data file at $SENSOR_DATA${NC}"
    # Next try relative to the Testing directory
    elif [ -f "$SCRIPT_DIR/$SENSOR_DATA_FILE" ]; then
        SENSOR_DATA="$SCRIPT_DIR/$SENSOR_DATA_FILE"
        echo -e "${GREEN}Found sensor data file at $SENSOR_DATA${NC}"
    # Next try relative to the project root
    elif [ -f "$PROJECT_DIR/$SENSOR_DATA_FILE" ]; then
        SENSOR_DATA="$PROJECT_DIR/$SENSOR_DATA_FILE"
        echo -e "${GREEN}Found sensor data file at $SENSOR_DATA${NC}"
    # If all else fails, perform a search
    else
        echo -e "${YELLOW}Sensor data file not found in expected locations, searching...${NC}"
        
        # Current directory
        echo -e "${BLUE}Contents of current directory ($(pwd)):${NC}"
        ls -la
        
        # Testing directory
        echo -e "${BLUE}Contents of Testing directory ($SCRIPT_DIR):${NC}"
        ls -la "$SCRIPT_DIR"
        
        # Try to find the file anywhere under the project directory
        echo -e "${BLUE}Searching for the file in the project:${NC}"
        FOUND_FILES=$(find "$PROJECT_DIR" -name "$SENSOR_DATA_FILE" 2>/dev/null)
        
        if [ -n "$FOUND_FILES" ]; then
            # Use the first found file
            SENSOR_DATA=$(echo "$FOUND_FILES" | head -n1)
            echo -e "${GREEN}Found sensor data file at: $SENSOR_DATA${NC}"
        else
            echo -e "${RED}Error: Sensor data file '$SENSOR_DATA_FILE' not found${NC}"
            echo "Checked locations:"
            echo "  - $SENSOR_DATA_FILE"
            echo "  - $SCRIPT_DIR/$SENSOR_DATA_FILE"
            echo "  - $PROJECT_DIR/$SENSOR_DATA_FILE"
            
            # Try to generate the file as a fallback
            if [ -f "$SCRIPT_DIR/test_simple_heartrate.py" ]; then
                echo -e "${YELLOW}Attempting to generate sensor data as fallback...${NC}"
                cd "$SCRIPT_DIR"
                python test_simple_heartrate.py
                
                if [ -f "$SCRIPT_DIR/sensor_test_data.json" ]; then
                    SENSOR_DATA="$SCRIPT_DIR/sensor_test_data.json"
                    echo -e "${GREEN}Successfully generated sensor data at: $SENSOR_DATA${NC}"
                else
                    echo -e "${RED}Failed to generate sensor data file${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}No fallback method available. Exiting.${NC}"
                exit 1
            fi
        fi
    fi
else
    # No sensor data file specified, generate one
    if [ -f "$SCRIPT_DIR/test_simple_heartrate.py" ]; then
        echo -e "${BLUE}Generating sensor test data...${NC}"
        # Show current directory for debugging
        echo -e "${BLUE}Current directory: $(pwd)${NC}"
        cd "$SCRIPT_DIR"
        echo -e "${BLUE}Changed to directory: $(pwd)${NC}"
        
        # List files before running
        echo -e "${BLUE}Files before running test_simple_heartrate.py:${NC}"
        ls -la
        
        # Run the script
        python test_simple_heartrate.py
        
        # List files after running
        echo -e "${BLUE}Files after running test_simple_heartrate.py:${NC}"
        ls -la
        
        # Set the sensor data path and verify it exists
        SENSOR_DATA="$SCRIPT_DIR/sensor_test_data.json"
        
        if [ -f "$SENSOR_DATA" ]; then
            echo -e "${GREEN}Successfully generated sensor data at: $SENSOR_DATA${NC}"
            # Show the first few lines of the file
            echo -e "${BLUE}First 10 lines of generated file:${NC}"
            head -n 10 "$SENSOR_DATA"
        else
            echo -e "${RED}Failed to generate sensor data at $SENSOR_DATA${NC}"
            # Create a simple fallback
            echo -e "${YELLOW}Creating minimal test file...${NC}"
            echo '{
                "description": "Minimal test data",
                "heart_rate": [{"timestamp": 0, "value": 70}],
                "accelerometer": [{"timestamp": 0, "x": 0, "y": 0, "z": 1}]
            }' > "$SENSOR_DATA"
            
            if [ -f "$SENSOR_DATA" ]; then
                echo -e "${GREEN}Created minimal test data at: $SENSOR_DATA${NC}"
            else
                echo -e "${RED}Failed to create even the minimal test data. Check permissions.${NC}"
                exit 1
            fi
        fi
        
        cd "$PROJECT_DIR"
    else
        echo -e "${YELLOW}Warning: test_simple_heartrate.py not found at $SCRIPT_DIR/test_simple_heartrate.py${NC}"
        echo "Proceeding without sensor data simulation."
        SENSOR_DATA=""
    fi
fi

# Log the final sensor data path if we have one
if [ -n "$SENSOR_DATA" ]; then
    echo -e "${GREEN}Using sensor data from: $SENSOR_DATA${NC}"
    echo "Sensor Data: $SENSOR_DATA" # For the log
fi

# Run the app in the simulator
echo -e "${BLUE}Running in simulator...${NC}"
if [ -n "$VERBOSE" ]; then
    set -x
fi

# Create a temporary file for logs
LOG_FILE=$(mktemp)

# Run with a timeout to capture logs - if we have sensor data, add it to simulator
if [ -n "$SENSOR_DATA" ] && [ -f "$SENSOR_DATA" ]; then
    echo -e "${GREEN}Simulating with sensor data from $SENSOR_DATA${NC}"
    echo -e "${YELLOW}Note: To properly use the sensor data in the simulator:${NC}"
    echo -e "${YELLOW}1. The simulator will start automatically${NC}"
    echo -e "${YELLOW}2. In the simulator, go to File -> Simulate -> Sensor Data${NC}"
    echo -e "${YELLOW}3. Browse to the file: $SENSOR_DATA${NC}"
    echo -e "${YELLOW}4. The sensor data will be loaded and used in the app${NC}"
fi

# Run with a timeout to capture some logs and then exit
if command -v timeout >/dev/null 2>&1; then
    # If timeout command is available, use it
    timeout 10s "$MONKEYDO" "$BUILD_PRG" "$DEVICE_ID" > "$LOG_FILE" 2>&1 &
else
    # If timeout is not available (e.g., on macOS by default)
    echo -e "${YELLOW}Note: 'timeout' command not found, using alternative method${NC}"
    "$MONKEYDO" "$BUILD_PRG" "$DEVICE_ID" > "$LOG_FILE" 2>&1 &
    # Set a manual timeout with sleep
    sleep 10
fi
PID=$!

# Progress animation
echo -n "Collecting logs"
for i in {1..10}; do
    echo -n "."
    sleep 1
    # Check if process is still running
    if ! kill -0 $PID 2>/dev/null; then
        break
    fi
done
echo ""

# Kill the process if it's still running
if kill -0 $PID 2>/dev/null; then
    kill $PID
fi

if [ -n "$VERBOSE" ]; then
    set +x
fi

# Display collected logs
echo -e "${BLUE}Simulator output:${NC}"
cat "$LOG_FILE"

# Check for sensor-related logs
if grep -q "Sensor" "$LOG_FILE"; then
    echo -e "${GREEN}Sensor data detected in logs!${NC}"
    SENSOR_LINES=$(grep -i "sensor\|heart\|accel" "$LOG_FILE")
    echo -e "${BLUE}Sensor-related log entries:${NC}"
    echo "$SENSOR_LINES"
else
    echo -e "${YELLOW}No sensor data detected in logs.${NC}"
fi

# Clean up
rm "$LOG_FILE"

echo -e "${GREEN}Test completed${NC}"

# Run the additional sensor validation script if it exists
if [ -f "$SCRIPT_DIR/sensor_test.py" ]; then
    echo -e "${BLUE}Running sensor implementation validation...${NC}"
    python "$SCRIPT_DIR/sensor_test.py" "$PROJECT_DIR/source/$ENTRY_CLASS.mc"
fi

# Run the sensor simulator if it exists
if [ -f "$SCRIPT_DIR/sensor_simulator.py" ]; then
    echo -e "${BLUE}Running sensor simulator...${NC}"
    
    # Check if we have a valid sensor data file to use
    if [ -n "$SENSOR_DATA" ] && [ -f "$SENSOR_DATA" ]; then
        # Get the absolute path of the sensor data file
        SENSOR_DATA_ABS=$(realpath "$SENSOR_DATA")
        echo -e "${GREEN}Using sensor data from: $SENSOR_DATA_ABS${NC}"
        
        # Change to the script directory and run the simulator
        cd "$SCRIPT_DIR"
        python sensor_simulator.py "$PROJECT_DIR/source/$ENTRY_CLASS.mc" --sensor-data "$SENSOR_DATA_ABS"
    else
        echo -e "${YELLOW}No valid sensor data file found for simulation.${NC}"
        echo -e "${YELLOW}Running sensor_simulator.py without custom data.${NC}"
        
        # Change to the script directory and run the simulator without sensor data
        cd "$SCRIPT_DIR"
        python sensor_simulator.py "$PROJECT_DIR/source/$ENTRY_CLASS.mc"
    fi
fi

echo -e "${GREEN}All tests completed${NC}" 