#!/usr/bin/env python3
"""
Garmin Connect IQ Sensor Implementation Validator

This script analyzes a Connect IQ app's sensor implementation and verifies it against 
the official Garmin Connect IQ SDK documentation. It checks for:
1. Proper sensor registration/unregistration
2. Correct sensor data access patterns
3. Error handling
4. Battery optimization best practices

Usage:
    python sensor_test.py <path_to_mc_file>

Example:
    python sensor_test.py ../source/SimpleHeartRateTest.mc
"""

__version__ = '1.1.0'

import sys
import os
import re
import json
import argparse
from dataclasses import dataclass
from typing import List, Dict, Optional, Set, Tuple

# Get script directory for relative path resolution
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

# Color codes for terminal output
class TermColors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

@dataclass
class SensorCheck:
    name: str
    description: str
    regex_pattern: str
    is_critical: bool = True
    
    def __post_init__(self):
        self.regex = re.compile(self.regex_pattern, re.MULTILINE | re.DOTALL)

@dataclass
class CheckResult:
    check: SensorCheck
    passed: bool
    matches: List[str]
    line_numbers: List[int]
    
    def get_status_str(self) -> str:
        if self.passed:
            return f"{TermColors.OKGREEN}PASS{TermColors.ENDC}"
        elif self.check.is_critical:
            return f"{TermColors.FAIL}FAIL{TermColors.ENDC}"
        else:
            return f"{TermColors.WARNING}WARN{TermColors.ENDC}"

# Define checks for sensor implementation
SENSOR_CHECKS = [
    # Registration checks
    SensorCheck(
        name="sensor_registration",
        description="Checks if sensors are properly registered",
        regex_pattern=r'Sensor\.registerSensorDataListener\s*\([\s\S]*?\)',
    ),
    SensorCheck(
        name="sensor_unregistration",
        description="Checks if sensors are properly unregistered",
        regex_pattern=r'Sensor\.unregisterSensorDataListener\s*\(\s*\)',
    ),
    SensorCheck(
        name="registration_in_onshow",
        description="Checks if sensor registration happens in onShow method",
        regex_pattern=r'function\s+onShow\s*\(\s*\)[\s\S]*?Sensor\.registerSensorDataListener',
    ),
    SensorCheck(
        name="unregistration_in_onhide",
        description="Checks if sensor unregistration happens in onHide method",
        regex_pattern=r'function\s+onHide\s*\(\s*\)\s*\{[^}]*Sensor\.unregisterSensorDataListener',
    ),
    
    # Heart rate sensor checks
    SensorCheck(
        name="heart_rate_enabled",
        description="Checks if heart rate sensor is enabled in options",
        regex_pattern=r':heartRate\s*=>\s*\{\s*:enabled\s*=>\s*true',
    ),
    SensorCheck(
        name="heart_rate_access",
        description="Checks if heart rate data is properly accessed",
        regex_pattern=r'(sensorData\s+has\s+:heartRate.*sensorData\.heartRate\s*!=\s*null)|(sensorData\.heartRate\s*!=\s*null.*sensorData\s+has\s+:heartRate)',
    ),
    
    # Accelerometer sensor checks
    SensorCheck(
        name="accelerometer_enabled",
        description="Checks if accelerometer sensor is enabled in options",
        regex_pattern=r':accelerometer\s*=>\s*\{\s*:enabled\s*=>\s*true',
    ),
    SensorCheck(
        name="accelerometer_access",
        description="Checks if accelerometer data is properly accessed",
        regex_pattern=r'(sensorData\s+has\s+:accelerometer.*sensorData\.accelerometer\s*!=\s*null)|(sensorData\.accelerometer\s*!=\s*null.*sensorData\s+has\s+:accelerometer)',
    ),
    
    # Error handling checks
    SensorCheck(
        name="try_catch_registration",
        description="Checks if sensor registration is wrapped in try-catch",
        regex_pattern=r'try\s*\{[\s\S]*?Sensor\.registerSensorDataListener[\s\S]*?\}\s*catch',
    ),
    SensorCheck(
        name="try_catch_unregistration",
        description="Checks if sensor unregistration is wrapped in try-catch",
        regex_pattern=r'try\s*\{[^}]*Sensor\.unregisterSensorDataListener[^}]*\}\s*catch\s*\(',
    ),
    SensorCheck(
        name="sensor_data_null_check",
        description="Checks if there is null checking for sensor data",
        regex_pattern=r'sensorData\s*!=\s*null',
    ),
    
    # Best practices checks
    SensorCheck(
        name="sensor_period_set",
        description="Checks if sensor sampling period is set",
        regex_pattern=r':period\s*=>\s*\d+',
        is_critical=False,
    ),
    SensorCheck(
        name="ui_update_requested",
        description="Checks if UI update is requested after sensor data processing",
        regex_pattern=r'WatchUi\.requestUpdate\(\)',
        is_critical=False,
    ),
]

def find_line_numbers(content: str, match: str) -> List[int]:
    """Find the line numbers for a match in the content."""
    lines = content.split('\n')
    line_numbers = []
    
    # This is a simple implementation that looks for the start of the match
    # A more accurate implementation would need to handle multi-line matches
    for i, line in enumerate(lines):
        if match.strip().split('\n')[0] in line:
            line_numbers.append(i + 1)  # 1-indexed line numbers
            
    return line_numbers

def run_sensor_checks(file_path: str) -> List[CheckResult]:
    """Run all sensor checks on the given file."""
    try:
        # Handle absolute or relative paths
        if not os.path.isabs(file_path):
            # Check if the path exists relative to the current directory
            if not os.path.exists(file_path):
                # Try relative to project directory
                alt_path = os.path.join(PROJECT_DIR, file_path)
                if os.path.exists(alt_path):
                    file_path = alt_path
        
        with open(file_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"{TermColors.FAIL}Error: File {file_path} not found.{TermColors.ENDC}")
        sys.exit(1)
    except Exception as e:
        print(f"{TermColors.FAIL}Error reading file: {e}{TermColors.ENDC}")
        sys.exit(1)
        
    results = []
    
    for check in SENSOR_CHECKS:
        matches = check.regex.findall(content)
        passed = len(matches) > 0
        
        # Convert matches to strings if they are tuples (from regex groups)
        str_matches = []
        line_numbers = []
        for match in matches:
            if isinstance(match, tuple):
                # Use the first non-empty group
                match_str = next((m for m in match if m), "")
            else:
                match_str = match
                
            str_matches.append(match_str)
            line_numbers.extend(find_line_numbers(content, match_str))
            
        results.append(CheckResult(
            check=check,
            passed=passed,
            matches=str_matches,
            line_numbers=line_numbers,
        ))
        
    return results

def calculate_score(results: List[CheckResult]) -> Tuple[int, int, float]:
    """Calculate a score based on the check results."""
    total_checks = len(results)
    passed_checks = sum(1 for r in results if r.passed)
    critical_failures = sum(1 for r in results if not r.passed and r.check.is_critical)
    
    # Calculate percentage score with critical failures weighing more
    if total_checks == 0:
        return 0, critical_failures, 0.0
        
    score_percentage = (passed_checks / total_checks) * 100
    
    # Reduce score for critical failures
    if critical_failures > 0:
        score_percentage *= (1 - (critical_failures / total_checks) * 0.5)
        
    return passed_checks, critical_failures, score_percentage

def print_check_results(results: List[CheckResult], file_path: str):
    """Print the check results in a readable format."""
    passed_checks, critical_failures, score = calculate_score(results)
    total_checks = len(results)
    
    print(f"\n{TermColors.HEADER}===== Garmin Connect IQ Sensor Implementation Test ====={TermColors.ENDC}")
    print(f"File: {file_path}")
    print(f"Score: {score:.1f}% ({passed_checks}/{total_checks} checks passed)")
    
    if critical_failures > 0:
        print(f"{TermColors.FAIL}Critical Issues: {critical_failures} checks failed{TermColors.ENDC}")
    
    print("\n{:<30} {:<10} {:<15}".format("Check", "Status", "Line Numbers"))
    print("=" * 60)
    
    for result in results:
        line_nums = ", ".join(str(ln) for ln in result.line_numbers) if result.line_numbers else "N/A"
        print("{:<30} {:<10} {:<15}".format(
            result.check.name, 
            result.get_status_str(), 
            line_nums
        ))
    
    print("\n")
    
    # Print detailed results
    print(f"{TermColors.HEADER}===== Detailed Results ====={TermColors.ENDC}")
    for result in results:
        status = result.get_status_str()
        print(f"\n{status} {TermColors.BOLD}{result.check.name}{TermColors.ENDC}")
        print(f"Description: {result.check.description}")
        
        if not result.passed:
            if not result.check.is_critical:
                print(f"{TermColors.WARNING}This is a warning for a best practice, not a critical error.{TermColors.ENDC}")
            else:
                print(f"{TermColors.FAIL}This is a critical issue that should be fixed.{TermColors.ENDC}")
                
            # Provide suggestions
            print("\nSuggestion:")
            if result.check.name == "sensor_registration":
                print("Include proper sensor registration using Sensor.registerSensorDataListener()")
                print("Example: Sensor.registerSensorDataListener(method(:onSensorData), {options})")
            elif result.check.name == "sensor_unregistration":
                print("Include proper sensor unregistration using Sensor.unregisterSensorDataListener()")
                print("Example: Sensor.unregisterSensorDataListener()")
            elif result.check.name == "registration_in_onshow":
                print("Move sensor registration to the onShow() method")
            elif result.check.name == "unregistration_in_onhide":
                print("Move sensor unregistration to the onHide() method")
            elif result.check.name == "heart_rate_enabled":
                print("Enable heart rate sensor in options:")
                print("Example: :heartRate => { :enabled => true }")
            elif result.check.name == "accelerometer_enabled":
                print("Enable accelerometer sensor in options:")
                print("Example: :accelerometer => { :enabled => true }")
            elif result.check.name == "heart_rate_access" or result.check.name == "accelerometer_access":
                print("Check for existence and null before accessing sensor data:")
                print("Example: if (sensorData has :heartRate && sensorData.heartRate != null)")
            elif result.check.name == "try_catch_registration" or result.check.name == "try_catch_unregistration":
                print("Wrap sensor operations in try-catch blocks to handle exceptions")
            elif result.check.name == "sensor_period_set":
                print("Set a sampling period for sensors to optimize performance")
                print("Example: :period => 1, // 1-second updates")
            elif result.check.name == "ui_update_requested":
                print("Call WatchUi.requestUpdate() after processing sensor data to update the UI")
        else:
            print(f"{TermColors.OKGREEN}Correctly implemented!{TermColors.ENDC}")
            if result.matches:
                print("\nMatched code:")
                # Print just the first match if there are multiple
                match_excerpt = result.matches[0]
                if len(match_excerpt) > 100:
                    match_excerpt = match_excerpt[:100] + "..."
                print(match_excerpt)
    
    # Print overall assessment
    print(f"\n{TermColors.HEADER}===== Overall Assessment ====={TermColors.ENDC}")
    if score >= 90:
        print(f"{TermColors.OKGREEN}Excellent implementation! The sensor code follows best practices.{TermColors.ENDC}")
    elif score >= 75:
        print(f"{TermColors.OKGREEN}Good implementation with minor issues to address.{TermColors.ENDC}")
    elif score >= 50:
        print(f"{TermColors.WARNING}Acceptable implementation but needs improvement.{TermColors.ENDC}")
    else:
        print(f"{TermColors.FAIL}Poor implementation with significant issues to fix.{TermColors.ENDC}")
    
    # Generate recommendations
    if critical_failures > 0:
        print("\nRecommended actions:")
        for result in results:
            if not result.passed and result.check.is_critical:
                print(f"- Fix {result.check.name}: {result.check.description}")

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path_to_mc_file>")
        sys.exit(1)
        
    file_path = sys.argv[1]
    results = run_sensor_checks(file_path)
    print_check_results(results, file_path)

    # Write report to file in the project directory
    report_file = os.path.join(PROJECT_DIR, "sensor_implementation_report.txt")
    try:
        with open(report_file, 'w') as f:
            f.write(f"Sensor Implementation Report for {file_path}\n")
            f.write("=" * 50 + "\n\n")
            
            # Write basic summary
            passed_checks, critical_failures, score = calculate_score(results)
            total_checks = len(results)
            
            f.write(f"Score: {score:.1f}% ({passed_checks}/{total_checks} checks passed)\n")
            if critical_failures > 0:
                f.write(f"Critical Issues: {critical_failures} checks failed\n")
            else:
                f.write("No critical issues found!\n")
            
        print(f"\nReport written to {report_file}")
    except Exception as e:
        print(f"Error writing report: {e}")

if __name__ == "__main__":
    main() 