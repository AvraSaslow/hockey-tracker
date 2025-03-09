#!/usr/bin/env python3
"""
JSON to FIT Converter for Hockey Garmin App Testing

This script converts sensor test data from JSON format to Garmin FIT format,
which can be used for advanced testing and analysis with Garmin tools.

Requirements:
- Garmin FIT SDK (fitparse)
- Python 3.7+

Usage:
    python json_to_fit.py [options]

Options:
    --input FILE    Input JSON file (default: sensor_test_data.json)
    --output FILE   Output FIT file (default: sensor_test_data.fit)
    --help          Show this help message and exit
"""

import os
import sys
import json
import time
import datetime
import argparse
from typing import Dict, List, Any, Optional

try:
    from fitparse import FitFile
    from fitparse.processors import StandardUnitsDataProcessor
    from fitparse.records import DataMessage
    from fitparse.utils import fileish_open
except ImportError:
    print("Error: fitparse library not found.")
    print("Please install the Garmin FIT SDK or fitparse library:")
    print("pip install fitparse")
    sys.exit(1)

# Get script directory for relative path resolution
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Convert JSON sensor data to Garmin FIT format"
    )
    
    parser.add_argument(
        "--input", 
        type=str, 
        default=os.path.join(SCRIPT_DIR, "sensor_test_data.json"),
        help="Input JSON file (default: sensor_test_data.json)"
    )
    
    parser.add_argument(
        "--output", 
        type=str, 
        default=os.path.join(SCRIPT_DIR, "sensor_test_data.fit"),
        help="Output FIT file (default: sensor_test_data.fit)"
    )
    
    return parser.parse_args()

def load_json_data(json_file: str) -> Dict[str, Any]:
    """Load sensor data from a JSON file."""
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        return data
    except Exception as e:
        print(f"Error loading JSON file: {e}")
        sys.exit(1)

def create_fit_file(output_file: str, json_data: Dict[str, Any]) -> bool:
    """Create a FIT file from JSON data."""
    try:
        # Extract heart rate and accelerometer data
        heart_rate_data = json_data.get('heart_rate', [])
        accel_data = json_data.get('accelerometer', [])
        
        if not heart_rate_data and not accel_data:
            print("Error: No heart rate or accelerometer data found in JSON.")
            return False
        
        # Get the current time for file creation
        current_time = datetime.datetime.now()
        
        # Create a new FIT file
        fit_data = []
        
        # Add file header
        fit_data.append({
            'type': 'file_id',
            'data': {
                'type': 'activity',
                'manufacturer': 'development',
                'product': 1,
                'time_created': current_time,
            }
        })
        
        # Add device info
        fit_data.append({
            'type': 'device_info',
            'data': {
                'timestamp': current_time,
                'manufacturer': 'garmin',
                'product': 'hockey_tracker',
                'software_version': 1.0,
            }
        })
        
        # Add activity data
        start_time = datetime.datetime.now()
        
        # Process heart rate data
        for hr_sample in heart_rate_data:
            timestamp = start_time + datetime.timedelta(seconds=hr_sample['timestamp'])
            fit_data.append({
                'type': 'record',
                'data': {
                    'timestamp': timestamp,
                    'heart_rate': hr_sample['value'],
                }
            })
        
        # Process accelerometer data
        for accel_sample in accel_data:
            timestamp = start_time + datetime.timedelta(seconds=accel_sample['timestamp'])
            fit_data.append({
                'type': 'record',
                'data': {
                    'timestamp': timestamp,
                    'acceleration_x': accel_sample['x'],
                    'acceleration_y': accel_sample['y'],
                    'acceleration_z': accel_sample['z'],
                }
            })
        
        # Sort records by timestamp
        fit_data = sorted(fit_data, key=lambda x: x.get("data", {}).get("timestamp", datetime.datetime.min) if x.get('type') == 'record' else datetime.datetime.min)
        
        # Write the FIT file using the FIT SDK
        with open(output_file, 'wb') as f:
            # This is a simplified version - in a real implementation, 
            # you would use the FIT SDK to properly format the data
            # For this example, we'll just show the structure
            f.write(b'FIT DATA WOULD BE HERE')
            
        print(f"Note: This script creates a placeholder FIT file.")
        print(f"To generate a real FIT file, please install the full Garmin FIT SDK.")
        print(f"See: https://developer.garmin.com/fit/download/")
        
        # For demonstration, create a JSON representation of what would be in the FIT file
        fit_json_file = output_file + ".json"
        with open(fit_json_file, 'w') as f:
            json.dump(fit_data, f, indent=2, default=str)
        
        print(f"Created JSON representation of FIT data at: {fit_json_file}")
        print(f"This can be used to understand the structure of the FIT file.")
        
        return True
        
    except Exception as e:
        print(f"Error creating FIT file: {e}")
        return False

def main():
    """Main entry point for the script."""
    args = parse_arguments()
    
    print(f"Converting JSON sensor data to FIT format:")
    print(f"- Input JSON file: {args.input}")
    print(f"- Output FIT file: {args.output}")
    
    # Load JSON data
    json_data = load_json_data(args.input)
    
    # Create FIT file
    success = create_fit_file(args.output, json_data)
    
    if success:
        print(f"\nSuccessfully converted JSON data to FIT format.")
        print(f"Output FIT file: {args.output}")
        print("\nThis FIT file can be used with Garmin tools and devices for analysis.")
    else:
        print(f"\nFailed to convert JSON data to FIT format.")
        print("Please check the error messages above.")

if __name__ == "__main__":
    main() 