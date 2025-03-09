#!/bin/bash
# Simple script to run sensor tests with clear output
#
# This is the preferred method for testing the Hockey Garmin app's
# sensor implementation. It uses direct testing without requiring
# the simulator, which is faster and more reliable.

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Hockey Garmin Sensor Test Runner${NC}"
echo -e "=====================================\n"

# Create test_outputs directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/test_outputs"

# Check if sensor_test_data.json exists
if [ -f "$SCRIPT_DIR/test_outputs/sensor_test_data.json" ]; then
  echo -e "${GREEN}Found existing sensor data at:${NC}"
  echo -e "  $SCRIPT_DIR/test_outputs/sensor_test_data.json"
  echo -e "${YELLOW}Using existing sensor data for testing...${NC}\n"
  
  # Run the test with existing data
  python generate_data.py --test-mode --device fenix6 --input "$SCRIPT_DIR/test_outputs/sensor_test_data.json"
  
  TEST_RESULT=$?
  if [ $TEST_RESULT -eq 0 ]; then
    echo -e "\n${GREEN}✅ Test completed successfully!${NC}"
    echo -e "The sensor implementation is working as expected."
  else
    echo -e "\n${RED}❌ Test failed with error code $TEST_RESULT${NC}"
    echo -e "Please check the error messages above."
  fi
else
  echo -e "${YELLOW}No existing sensor data found.${NC}"
  echo -e "Generating new test data and running tests...\n"
  
  # Generate new data and run test - output will go to test_outputs directory
  python generate_data.py --test-mode --device fenix6
  
  TEST_RESULT=$?
  if [ $TEST_RESULT -eq 0 ]; then
    echo -e "\n${GREEN}✅ Test completed successfully!${NC}"
    echo -e "The sensor implementation is working as expected."
  else
    echo -e "\n${RED}❌ Test failed with error code $TEST_RESULT${NC}"
    echo -e "Please check the error messages above."
  fi
fi

echo -e "\n${BLUE}Test run completed.${NC}"

# Clean up temporary test run folder
if [ -d "$SCRIPT_DIR/test_outputs/test_run" ]; then
  echo -e "\n${YELLOW}Cleaning up temporary test files...${NC}"
  rm -rf "$SCRIPT_DIR/test_outputs/test_run"
fi

echo -e "${GREEN}All test files are stored in: $SCRIPT_DIR/test_outputs/${NC}" 