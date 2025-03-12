import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.System;

//! Main application class for the heart rate test
class HR_test extends Application.AppBase {

    //! Heart rate view
    private var _view;

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! onStart callback
    function onStart(state) {
        // Enable the heart rate sensor
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    //! onStop callback
    function onStop(state) {
        // Disable sensor events when the app stops
        Sensor.enableSensorEvents(null);
    }

    //! Sensor callback
    //! Updated method signature to match Garmin requirements
    function onSensor(sensorInfo as Sensor.Info) as Void {
        // If the view is available, update with heart rate data
        if (_view != null) {
            _view.setHeartRate(sensorInfo.heartRate);
            WatchUi.requestUpdate();
        }
    }

    //! Return the initial view
    function getInitialView() {
        _view = new HeartRateView();
        return [_view, new hockey_garminDelegate()];
    }
}

//! Heart rate display view
class HeartRateView extends WatchUi.View {

    //! Current heart rate
    private var _heartRate = 0;

    //! Constructor
    function initialize() {
        View.initialize();
    }

    //! Set heart rate value
    function setHeartRate(heartRate) {
        if (heartRate != null) {
            _heartRate = heartRate;
        }
    }

    //! Update the view
    function onUpdate(dc) {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Set text properties
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Draw title
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 - 30,
            Graphics.FONT_MEDIUM,
            "Heart Rate",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw heart rate
        var heartRateText = (_heartRate != null && _heartRate > 0) ? _heartRate.toString() : "--";
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 10,
            Graphics.FONT_LARGE,
            heartRateText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw units (bpm)
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 45,
            Graphics.FONT_SMALL,
            "bpm",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
} 