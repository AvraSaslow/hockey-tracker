# Default configuration
DEFAULT_CONFIG = {
    "duration": 60,       # 1 minute of data
    "hr_min": 60,         # Minimum heart rate in bpm
    "hr_max": 180,        # Maximum heart rate in bpm  
    "hr_variability": 5,  # How much HR can change between samples
    "hr_sample_rate": 1,  # 1 sample per second for heart rate
    "accel_sample_rate": 10, # 10 samples per second for accelerometer
    "output_file": os.path.join(SCRIPT_DIR, "test_outputs", "sensor_test_data.json"),
    "test_mode": False,   # Whether to run in direct test mode
    "device_id": "fenix6", # Default device when in test mode
    "test_port": 7381,    # Port for test communication
} 

def setup_test_environment(config, test_data):
    """Set up the test environment for direct sensor testing."""
    print("\nSetting up direct sensor testing environment...")
    
    # Create temporary test directory if it doesn't exist
    test_dir = os.path.join(SCRIPT_DIR, "test_outputs", "test_run")
    os.makedirs(test_dir, exist_ok=True)
    
    # Create a test configuration file
    test_config = {
        "device_id": config["device_id"],
        "test_port": config["test_port"],
        "sensor_data": test_data,
        "test_duration": config["duration"]
    }
    
    test_config_file = os.path.join(test_dir, "test_config.json")
    with open(test_config_file, 'w') as f:
        json.dump(test_config, f, indent=2)
    
    print(f"Test environment set up in {test_dir}")
    return test_config_file 