import Toybox.Lang;
import Toybox.WatchUi;

class hockey_garminDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new hockey_garminMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}