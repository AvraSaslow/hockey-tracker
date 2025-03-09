import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;

//! A simple Hello World application for Garmin watches
class HelloWorld extends Application.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! onStart callback
    function onStart(state) {
        // Nothing special needed here
    }

    //! onStop callback
    function onStop(state) {
        // Nothing special needed here
    }

    //! Return the initial view
    function getInitialView() {
        return [ new HelloWorldView() ];
    }
}

//! A simple view that displays "Hello World"
class HelloWorldView extends WatchUi.View {

    //! Constructor
    function initialize() {
        View.initialize();
    }

    //! Load resources
    function onLayout(dc) {
        // Nothing special needed here
    }

    //! Called when the view becomes visible
    function onShow() {
        // Nothing special needed here
    }

    //! Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Set text color to white
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw "Hello World" text in the center of the screen
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_MEDIUM,
            "Hello World",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
} 