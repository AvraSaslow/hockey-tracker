import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.Graphics;
import Toybox.Timer;
import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;

class SimpleHeartRateTest extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Nothing special needed here
    }

    function onStop(state) {
        // Nothing special needed here
    }

    function getInitialView() {
        return [new HeartRateAndAccelView()];
    }
}

class HeartRateAndAccelView extends WatchUi.View {
    private var hrValue = "--";
    private var accelX = "--";
    private var accelY = "--";
    private var accelZ = "--";

    function initialize() {
        View.initialize();
    }

    // Called when the view is loaded
    function onLayout(dc) {
        // Layout is handled in onUpdate
    }

    // Called when the view becomes visible
    function onShow() {
        try {
            var options = {
                :period => 1,  // 1-second updates
                :accelerometer => {
                    :enabled => true
                },
                :heartRate => {
                    :enabled => true
                }
            };
            
            Sensor.registerSensorDataListener(method(:onSensorData), options);
        } catch (e) {
            System.println("Error registering sensors: " + e.getErrorMessage());
        }
    }

    // Called when the view is hidden
    function onHide() {
        // Disable the sensor when not visible to save battery
        try {
            Sensor.unregisterSensorDataListener();
        } catch (e) {
            System.println("Error unregistering sensors: " + e.getErrorMessage());
        }
    }

    // Callback for sensor data
    function onSensorData(sensorData as Sensor.SensorData) as Void {
        try {
            // Add null check for sensorData itself
            if (sensorData != null) {
                if (sensorData has :heartRate && sensorData.heartRate != null) {
                    hrValue = sensorData.heartRate.toString();
                } else {
                    hrValue = "--";
                }
                
                if (sensorData has :accelerometer && sensorData.accelerometer != null) {
                    var accelData = sensorData.accelerometer;
                    if (accelData has :x && accelData has :y && accelData has :z) {
                        var x = accelData.x;
                        var y = accelData.y;
                        var z = accelData.z;
                        
                        // Safely format or default to "--"
                        if (x instanceof Float) {
                            accelX = x.format("%.2f");
                        } else {
                            accelX = "--";
                        }
                        
                        if (y instanceof Float) {
                            accelY = y.format("%.2f");
                        } else {
                            accelY = "--";
                        }
                        
                        if (z instanceof Float) {
                            accelZ = z.format("%.2f");
                        } else {
                            accelZ = "--";
                        }
                    }
                } else {
                    accelX = "--";
                    accelY = "--";
                    accelZ = "--";
                }
            } else {
                // Handle case where sensorData is null
                hrValue = "--";
                accelX = "--";
                accelY = "--";
                accelZ = "--";
            }
            
            WatchUi.requestUpdate();
        } catch(e) {
            System.println("Error in sensor data processing: " + e.getErrorMessage());
        }
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Set text colors
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw the title
        dc.drawText(dc.getWidth() / 2, 
                   20, 
                   Graphics.FONT_MEDIUM, 
                   "Sensor Data", 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw the heart rate value
        dc.drawText(20, 
                   60, 
                   Graphics.FONT_SMALL, 
                   "Heart Rate: " + hrValue + " bpm", 
                   Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw the accelerometer data
        dc.drawText(20, 
                   90, 
                   Graphics.FONT_SMALL, 
                   "Accel X: " + accelX, 
                   Graphics.TEXT_JUSTIFY_LEFT);
                   
        dc.drawText(20, 
                   120, 
                   Graphics.FONT_SMALL, 
                   "Accel Y: " + accelY, 
                   Graphics.TEXT_JUSTIFY_LEFT);
                   
        dc.drawText(20, 
                   150, 
                   Graphics.FONT_SMALL, 
                   "Accel Z: " + accelZ, 
                   Graphics.TEXT_JUSTIFY_LEFT);
    }
}


