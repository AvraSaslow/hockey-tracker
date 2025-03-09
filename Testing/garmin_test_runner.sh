#!/usr/bin/env bash
# Garmin Connect IQ Test Runner
# This script automates testing of Garmin Connect IQ apps from the command line
# without requiring the simulator UI.
#
# For sensor testing, the script can:
# 1. Use an existing sensor data JSON file specified with --sensor-data
# 2. Automatically generate sensor test data using test_simple_heartrate.py
# 3. Directly test sensor implementation without using the simulator
#
# NOTE: This script is maintained for legacy compatibility. For direct testing,
# use the run_sensor_test.sh script instead.

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
fi

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
DEVICE="fenix6"
ENTRY_CLASS="SimpleHeartRateTest"
VERBOSE=false
TEST_LOG=false
SENSOR_DATA=""
SDK_PATH="${GARMIN_SDK_DIR}"
LOG_DIR="./logs"
SENSOR_TEST_DURATION=60
DIRECT_TEST=true # Default to direct testing without simulator

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Print usage information
function print_usage() {
    echo -e "${CYAN}Garmin Connect IQ Test Runner${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE_ID   Set the target device (default: $DEVICE)"
    echo "  -s, --sdk PATH           Set the Garmin SDK path (default: auto-detected)"
    echo "  -e, --entry CLASS        Set the entry class (default: $ENTRY_CLASS)"
    echo "  -t, --test-log           Enable test logger and output test results"
    echo "  -v, --verbose            Show verbose build and test output"
    echo "  -f, --sensor-data FILE   Use specific sensor data file for testing"
    echo "  -n, --no-direct-test     Don't use direct testing (for legacy simulator support)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --device fenix6 --test-log"
    echo "  $0 --device fr955 --sensor-data custom_data.json"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift
            shift
            ;;
        -s|--sdk)
            SDK_PATH="$2"
            shift
            shift
            ;;
        -e|--entry)
            ENTRY_CLASS="$2"
            shift
            shift
            ;;
        -t|--test-log)
            TEST_LOG=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--sensor-data)
            SENSOR_DATA="$2"
            shift
            shift
            ;;
        -n|--no-direct-test)
            DIRECT_TEST=false
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

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Validate SDK path
if [ -z "$SDK_PATH" ] || [ ! -d "$SDK_PATH" ]; then
    echo -e "${RED}Error: Garmin SDK not found at $SDK_PATH${NC}"
    echo "Please set the correct SDK path with --sdk or set the GARMIN_SDK_DIR environment variable."
    exit 1
fi

# Print configuration
echo -e "${BLUE}Testing configuration:${NC}"
echo -e "- Device: ${CYAN}$DEVICE${NC}"
echo -e "- SDK path: ${CYAN}$SDK_PATH${NC}"
echo -e "- Entry class: ${CYAN}$ENTRY_CLASS${NC}"
echo -e "- Test logging: ${CYAN}$TEST_LOG${NC}"
echo -e "- Verbose mode: ${CYAN}$VERBOSE${NC}"
echo -e "- Direct testing: ${CYAN}$DIRECT_TEST${NC}"
if [ -n "$SENSOR_DATA" ]; then
    echo -e "- Sensor data: ${CYAN}$SENSOR_DATA${NC}"
fi
echo ""

# Function to run the sensor test analyzer
function run_sensor_test_analyzer() {
    local source_file="$1"
    
    if [ -f "$SCRIPT_DIR/sensor_test.py" ]; then
        echo -e "${BLUE}Running sensor implementation analysis on $source_file...${NC}"
        python "$SCRIPT_DIR/sensor_test.py" "$source_file"
        echo ""
    else
        echo -e "${YELLOW}Warning: sensor_test.py not found in $SCRIPT_DIR${NC}"
    fi
}

# Function to generate sensor test data if not provided
function setup_sensor_data() {
    # If sensor data file is provided, use it
    if [ -n "$SENSOR_DATA" ] && [ -f "$SENSOR_DATA" ]; then
        echo -e "${BLUE}Using provided sensor data: $SENSOR_DATA${NC}"
        return
    fi
    
    # Check if test_simple_heartrate.py exists
    if [ -f "$SCRIPT_DIR/test_simple_heartrate.py" ]; then
        echo -e "${BLUE}Generating sensor test data...${NC}"
        
        # Build command with appropriate options
        local cmd="python $SCRIPT_DIR/test_simple_heartrate.py"
        if [ "$DIRECT_TEST" = true ]; then
            cmd="$cmd --test-mode --device $DEVICE"
        fi
        
        # Execute the command
        $cmd
        
        # Set the SENSOR_DATA variable to the generated file
        SENSOR_DATA="$SCRIPT_DIR/sensor_test_data.json"
        echo -e "${GREEN}Sensor data generated at: $SENSOR_DATA${NC}"
    else
        echo -e "${YELLOW}Warning: test_simple_heartrate.py not found in $SCRIPT_DIR${NC}"
    fi
}

# Function to build the app
function build_app() {
    echo -e "${BLUE}Building app for $DEVICE...${NC}"
    
    # Create the build command
    local build_cmd="$SDK_PATH/bin/monkeyc"
    build_cmd+=" -d $DEVICE"
    build_cmd+=" -f monkey.jungle"
    build_cmd+=" -o bin/$ENTRY_CLASS-$DEVICE.prg"
    build_cmd+=" -y developer_key"
    
    if [ "$TEST_LOG" = true ]; then
        build_cmd+=" -l 3" # Enable test logger
    fi
    
    # Execute the build command
    local log_file="$LOG_DIR/build_log_$(date +%Y%m%d_%H%M%S).txt"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}Executing: $build_cmd${NC}"
        $build_cmd | tee "$log_file"
    else
        echo -e "${CYAN}Building... check $log_file for details${NC}"
        $build_cmd > "$log_file" 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Build successful!${NC}"
    else
        echo -e "${RED}Build failed! Check $log_file for details${NC}"
        exit 1
    fi
}

# Function to run direct tests
function run_direct_tests() {
    echo -e "${BLUE}Running direct sensor tests for $DEVICE...${NC}"
    
    # If test_simple_heartrate.py exists, use it for direct testing
    if [ -f "$SCRIPT_DIR/test_simple_heartrate.py" ]; then
        if [ -n "$SENSOR_DATA" ]; then
            echo -e "${CYAN}Using existing sensor data: $SENSOR_DATA${NC}"
            python "$SCRIPT_DIR/test_simple_heartrate.py" --test-mode --device "$DEVICE" --output "$SENSOR_DATA"
        else
            echo -e "${CYAN}Generating new sensor data and running tests...${NC}"
            python "$SCRIPT_DIR/test_simple_heartrate.py" --test-mode --device "$DEVICE"
        fi
    else
        echo -e "${RED}Error: test_simple_heartrate.py not found in $SCRIPT_DIR${NC}"
        exit 1
    fi
}

# Function to run legacy simulator tests (only if --no-direct-test is specified)
function run_simulator_tests() {
    echo -e "${YELLOW}Warning: Running in legacy simulator mode. Direct testing is recommended.${NC}"
    echo -e "${BLUE}Running app in simulator for $DEVICE...${NC}"
    
    # Create the simulator command
    local sim_cmd="$SDK_PATH/bin/connectiq"
    sim_cmd+=" --transport console"
    sim_cmd+=" --device $DEVICE"
    sim_cmd+=" bin/$ENTRY_CLASS-$DEVICE.prg"
    
    if [ -n "$SENSOR_DATA" ] && [ -f "$SENSOR_DATA" ]; then
        echo -e "${CYAN}Using sensor data: $SENSOR_DATA${NC}"
        # Note: In legacy simulator mode, you need to manually load the sensor data
        echo -e "${YELLOW}Note: You'll need to manually load sensor data in the simulator GUI:${NC}"
        echo -e "${YELLOW}File -> Simulate -> Sensor Data -> Load $SENSOR_DATA${NC}"
    fi
    
    # Execute the simulator command
    local log_file="$LOG_DIR/sim_log_$(date +%Y%m%d_%H%M%S).txt"
    
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}Executing: $sim_cmd${NC}"
        $sim_cmd | tee "$log_file"
    else
        echo -e "${CYAN}Starting simulator... check $log_file for details${NC}"
        echo -e "${YELLOW}Press Ctrl+C after a few seconds to stop the simulator${NC}"
        $sim_cmd > "$log_file" 2>&1
    fi
    
    echo -e "${GREEN}Simulator run completed${NC}"
}

# Main execution flow
echo -e "${MAGENTA}Starting Hockey Garmin sensor test process...${NC}"
echo ""

# Analyze source code first
run_sensor_test_analyzer "$PROJECT_DIR/source/$ENTRY_CLASS.mc"

# Check for sensor data or generate it
setup_sensor_data

# Build the app
build_app

# Run the tests
if [ "$DIRECT_TEST" = true ]; then
    run_direct_tests
else
    run_simulator_tests
fi

echo ""
echo -e "${GREEN}Testing completed successfully!${NC}"
exit 0 