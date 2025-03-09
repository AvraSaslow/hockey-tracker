#!/bin/bash
# Run full sensor tests including JSON and FIT format conversion
#
# This script runs the direct sensor tests and also converts
# the test data to FIT format for advanced analysis.

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}Hockey Garmin Full Test Suite${NC}"
echo -e "${BLUE}=============================${NC}\n"

# Check if fitparse is installed
if python -c "import fitparse" &>/dev/null; then
    FITPARSE_INSTALLED=true
    echo -e "${GREEN}Garmin FIT SDK (fitparse) is installed.${NC}"
else
    FITPARSE_INSTALLED=false
    echo -e "${YELLOW}Garmin FIT SDK (fitparse) is not installed.${NC}"
    echo -e "To enable FIT file conversion, install it with:"
    echo -e "${CYAN}pip install fitparse${NC}"
    echo -e "Learn more at: https://developer.garmin.com/fit/overview/\n"
fi

# Step 1: Run the sensor tests
echo -e "${BLUE}Step 1: Running direct sensor tests...${NC}\n"
./run_sensor_test.sh

TEST_RESULT=$?
if [ $TEST_RESULT -ne 0 ]; then
    echo -e "\n${RED}Sensor tests failed. Stopping the test suite.${NC}"
    exit 1
fi

echo -e "\n${BLUE}Step 2: Converting sensor data to FIT format...${NC}\n"

# Generate or use existing sensor data
if [ -f "sensor_test_data.json" ]; then
    # Convert to FIT format
    if [ "$FITPARSE_INSTALLED" = true ]; then
        python json_to_fit.py --input sensor_test_data.json --output sensor_test_data.fit
        FIT_RESULT=$?
        
        if [ $FIT_RESULT -eq 0 ]; then
            echo -e "\n${GREEN}✅ FIT conversion completed successfully!${NC}"
            echo -e "You can now use the FIT file with Garmin tools like:"
            echo -e "- Garmin Connect IQ SDK"
            echo -e "- Garmin Connect Web Tool"
            echo -e "- FIT File Tools"
            echo -e "\nFIT file location: ${CYAN}$SCRIPT_DIR/sensor_test_data.fit${NC}"
        else
            echo -e "\n${RED}❌ FIT conversion failed.${NC}"
            echo -e "Please check the error messages above."
        fi
    else
        echo -e "${YELLOW}Skipping FIT conversion (fitparse not installed).${NC}"
        echo -e "Install fitparse to enable this feature."
    fi
else
    echo -e "${RED}No sensor test data found.${NC}"
    echo -e "Please run the sensor tests first to generate data."
fi

echo -e "\n${BLUE}Test suite completed.${NC}" 