# Hockey Tracker Development Roadmap

## 📱 Phase 1: Sensor Integration Basics

### 1. Project Setup and Configuration ✅
- Define target Garmin devices ✅
- Set required permissions ✅
- Update app name and identifiers ✅
- Add language support ✅

### 2. Read and Display Sensor Data (Heart Rate & Accelerometer) ⬜
- Access heart rate data from the built-in HR sensor
- Read accelerometer data (X, Y, Z axis values)
- Display these values on the screen in real-time
- Test: Move your watch and check if the values update

### 3. Detect Movement (Basic Acceleration Changes) ⬜
- Set a threshold to detect movement (e.g., when acceleration exceeds a certain value)
- Display "Moving" or "Not Moving" based on activity
- Test: Shake the watch → It should detect movement

## 🧪 Phase 1.5: Testing Infrastructure ✅

### 3.5. Direct Sensor Testing Framework ✅
- Create tools for direct sensor testing without simulator dependency ✅
- Implement a test data generator for heart rate and accelerometer ✅
- Develop direct test runner for sensor implementation validation ✅
- Create a simple interface for running tests (run_sensor_test.sh) ✅
- Update documentation to reflect testing approach ✅

## 🏒 Phase 2: Implementing Shift Detection

### 4. Detect Shift Start (Acceleration Burst) ⬜
- Record timestamp when acceleration increases sharply
- Display "Shift Started" when movement is detected
- Test: Quickly shake the watch → It should start a shift

### 5. Detect Shift End (Rest Detection) ⬜
- When acceleration remains low for X seconds, end the shift
- Record total shift duration
- Display shift time on-screen
- Test: Move → Stop → It should calculate and show shift duration

### 6. Store Shift Data & Add Rest Time Calculation ⬜
- After a shift ends, store the shift duration in a list
- When movement resumes, calculate rest time
- Display both "Last Shift Time" & "Rest Time"
- Test: Complete 3 shifts and confirm data is recorded

## 📡 Phase 3: GPS & Speed Calculation

### 7. Read GPS Speed (If Available) ⬜
- Get GPS speed from the device
- Display real-time speed
- Test: Walk or run outdoors and confirm speed updates

### 8. Estimate Speed from Accelerometer (For Indoor Rinks) ⬜
- Compute instantaneous speed by integrating acceleration
- Display calculated speed
- Test: Move your arm as if skating → It should show speed

### 9. Combine GPS & Accelerometer for Optimized Speed ⬜
- Implement a Kalman Filter or weighted average to merge both data sources
- If GPS is weak (indoor rinks), rely on accelerometer speed
- Test: Skate (or simulate movement) and compare speed values

## 📊 Phase 4: Data Storage & Visualization

### 10. Store Data for Post-Game Review ⬜
- Save each shift, rest time, and speed data
- Display total time on ice, average shift length, average rest time
- Test: Complete multiple shifts and confirm the stats

### 11. Sync Data to Garmin Connect ⬜
- Send shift data & heart rate to Garmin Connect
- Test: Start a session → End it → Check data in the Garmin app

### 12. Create Summary Screen (Basic UI) ⬜
- Display:
  - Total Shifts
  - Average Shift Time
  - Max Speed
  - Heart Rate Graph
- Test: Complete a session and view the summary

## 🎮 Phase 5: Advanced Features & Polish

### 13. Add Game Management ⬜
- Track periods in a hockey game
- Record goals and assists
- Calculate plus/minus
- Test: Simulate a full game with multiple shifts

### 14. Implement Intensity Analysis ⬜
- Calculate shift intensity based on:
  - Heart rate zones
  - Movement patterns
  - Speed variations
- Test: Compare different intensity shifts

### 15. Add Benchmarks & Goals ⬜
- Set target shift lengths
- Create recovery time goals
- Compare performance to previous games
- Test: Set goals and track progress over time

### 16. Optimize Battery Usage ⬜
- Fine-tune sensor sampling rates
- Implement efficient algorithms
- Add battery-saving mode for long games
- Test: Monitor battery drain during extended use

## Current Development Focus
- Developing simple heart rate sensor test (Phase 1, Step 2)
- Setting up basic sensor reading and display

## Next Milestone Target
- Complete Phase 1 by [TARGET DATE]
- Begin work on shift detection (Phase 2) 