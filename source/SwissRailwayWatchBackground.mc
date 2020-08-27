using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Time;

class Background extends WatchUi.Drawable {

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);
    }

    function onLayout(dc) {
        //Clear any clip that may currently be set by the partial update
        dc.clearClip();
    }

    function draw(dc) {
        // Set the background color then call to clear the screen
        dc.setAntiAlias(true);
        dc.setColor(Graphics.COLOR_WHITE, Application.getApp().getProperty("BackgroundColor"));
        dc.clear();
    }

    // Update the clock face graphics during update
    function onUpdate(dc) {
    	//do nothing
    }
}
