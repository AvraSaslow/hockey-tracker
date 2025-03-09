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
        // Request both heart rate and accelerometer data
        var options = {
            :period => 1,
            :heartRate => {
                :enabled => true
            },
            :accelerometer => {
                :enabled => true
            }
        };
        
        Sensor.registerSensorDataListener(method(:onSensorData), options);
    }

    // Called when the view is hidden
    function onHide() {
        // Disable the sensor when not visible to save battery
        Sensor.unregisterSensorDataListener();
    }

    // Callback for sensor data
    function onSensorData(sensorData as Sensor.SensorData) as Void {
        if (sensorData has :heartRate && sensorData.heartRate != null) {
            hrValue = sensorData.heartRate.toString();
        } else {
            hrValue = "--";
        }
        
        if (sensorData has :accelerometer && sensorData.accelerometer != null) {
            // Safely format the accelerometer values
            var x = sensorData.accelerometer.x;
            var y = sensorData.accelerometer.y;
            var z = sensorData.accelerometer.z;
            
            accelX = (x != null) ? x.format("%.2f") : "--";
            accelY = (y != null) ? y.format("%.2f") : "--";
            accelZ = (z != null) ? z.format("%.2f") : "--";
        } else {
            accelX = "--";
            accelY = "--";
            accelZ = "--";
        }
        
        WatchUi.requestUpdate();
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


