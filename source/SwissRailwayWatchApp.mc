using Toybox.Application;
using Toybox.WatchUi;

class SwissRailwayWatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new SwissRailwayWatchView() ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        hideSecondsPowerSaver = Application.Properties.getValue("hideSecondsPowerSaver");
        invertColors = Application.Properties.getValue("invertColors");
        simSecSyncPulse = Application.Properties.getValue("simSecSyncPulse");
        WatchUi.requestUpdate();
    }

}