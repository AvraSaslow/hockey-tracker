#!/usr/bin/env python3
"""
Simple Heart Rate and Accelerometer Test Generator

This script generates random heart rate and accelerometer values that can be used
to test the SimpleHeartRateTest.mc app in the Garmin Connect IQ Simulator.

Usage:
    1. Run this script to generate test values
    2. Start the Garmin Connect IQ Simulator with the SimpleHeartRateTest app
    3. In the simulator, go to File -> Simulate -> Sensor Data
    4. Load the generated JSON file
"""

import json
import random
import math
import time
import os
from datetime import datetime, timedelta

# Configure test parameters
TEST_DURATION_SECONDS = 60  # 1 minute of data
HR_SAMPLE_RATE_HZ = 1  # 1 sample per second for heart rate
ACCEL_SAMPLE_RATE_HZ = 10  # 10 samples per second for accelerometer
OUTPUT_FILE = "sensor_test_data.json"

# Heart rate parameters
MIN_HR = 60
MAX_HR = 180
HR_VARIABILITY = 5  # how much HR can change between samples

# Accelerometer parameters
ACCEL_MIN = -2.0  # g-force
ACCEL_MAX = 2.0   # g-force


def generate_heart_rate_samples(duration, sample_rate):
    """Generate simulated heart rate samples."""
    samples = []
    num_samples = int(duration * sample_rate)
    current_hr = random.randint(MIN_HR, MIN_HR + 20)  # Start with a reasonable HR
    
    for i in range(num_samples):
        # Add some random variation, but keep within bounds
        delta = random.randint(-HR_VARIABILITY, HR_VARIABILITY)
        current_hr += delta
        current_hr = max(MIN_HR, min(MAX_HR, current_hr))
        
        timestamp = i / sample_rate
        samples.append({
            "timestamp": timestamp,
            "value": current_hr
        })
    
    return samples


def generate_accel_samples(duration, sample_rate):
    """Generate simulated accelerometer samples."""
    samples = []
    num_samples = int(duration * sample_rate)
    
    # Starting values
    x, y, z = 0.0, 0.0, 1.0  # z=1.0 accounts for gravity
    
    # Pattern for hockey-like motion
    for i in range(num_samples):
        timestamp = i / sample_rate
        
        # Create more interesting patterns with sine waves + randomness
        phase = (i / sample_rate) * 2 * math.pi / 5  # 5-second cycle
        
        # Simulate skating motion (alternating side-to-side movement)
        x = 0.5 * math.sin(phase) + random.uniform(-0.3, 0.3)
        
        # Simulate stride push (up-down movement)
        y = 0.3 * math.sin(2 * phase) + random.uniform(-0.2, 0.2)
        
        # Simulate forward acceleration variation
        z = 1.0 + 0.3 * math.sin(3 * phase) + random.uniform(-0.3, 0.3)
        
        # Every 10 seconds, simulate a more intense movement (like a shot or check)
        if i % (10 * sample_rate) < 3:
            multiplier = 1.5
            x *= multiplier
            y *= multiplier
            z *= multiplier
        
        samples.append({
            "timestamp": timestamp,
            "x": round(x, 3),
            "y": round(y, 3),
            "z": round(z, 3)
        })
    
    return samples


def generate_sensor_test_file():
    """Generate a JSON file with simulated sensor data for testing."""
    heart_rate_data = generate_heart_rate_samples(TEST_DURATION_SECONDS, HR_SAMPLE_RATE_HZ)
    accel_data = generate_accel_samples(TEST_DURATION_SECONDS, ACCEL_SAMPLE_RATE_HZ)
    
    # Create a test scenario
    test_data = {
        "description": "Hockey player sensor simulation",
        "heart_rate": heart_rate_data,
        "accelerometer": accel_data
    }
    
    # Save to file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(test_data, f, indent=2)
    
    print(f"Generated test data saved to {OUTPUT_FILE}")
    print(f"Test duration: {TEST_DURATION_SECONDS} seconds")
    print(f"Heart rate samples: {len(heart_rate_data)}")
    print(f"Accelerometer samples: {len(accel_data)}")
    print("\nInstructions:")
    print("1. Start the Garmin Connect IQ Simulator with the SimpleHeartRateTest app")
    print("2. In the simulator, go to File -> Simulate -> Sensor Data")
    print("3. Load the generated JSON file")


if __name__ == "__main__":
    generate_sensor_test_file() 