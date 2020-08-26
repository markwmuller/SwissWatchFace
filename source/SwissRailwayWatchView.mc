using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;

var partialUpdatesAllowed = false;

//From Garmin's "Analog" example

class SwissRailwayWatchView extends WatchUi.WatchFace {
    var font;
    var isAwake;
    var screenShape;
    var dndIcon;
    var offscreenBuffer;
    //var dateBuffer;
    var curClip;
    var screenCenterPoint;
    var fullScreenRefresh;
    var hourHand_r1; 
    var hourHand_r2; 
    var hourHand_t; 
    var minuteHand_r1; 
    var minuteHand_r2; 
    var minuteHand_t; 
    var secondHand_r1; 
    var secondHand_r2; 
    var secondHand_t; 
    var secondHand_ball_r; 
    var hourMarker_ri;
    var hourMarker_ro;
    var hourMarker_t;
    var minuteMarker_ri;
    var minuteMarker_ro;
    var minuteMarker_t;
    
    //settings:
    var hideSecondsPowerSaver; 
    var invertColors;
    var simSecSyncPulse;
	
    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
        fullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
        
        hideSecondsPowerSaver = Application.Properties.getValue("hideSecondsPowerSaver");
        invertColors = Application.Properties.getValue("invertColors");
        simSecSyncPulse = Application.Properties.getValue("simSecSyncPulse");
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // Load the custom font we use for drawing the 3, 6, 9, and 12 on the watchface.
        font = WatchUi.loadResource(Rez.Fonts.id_font_black_diamond);

        // If this device supports the Do Not Disturb feature,
        // load the associated Icon into memory.
        if (System.getDeviceSettings() has :doNotDisturb) {
            dndIcon = WatchUi.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }
        //HACK! Remove DND for now.
        dndIcon = null;

        // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            // Allocate a full screen size buffer with a palette of only 4 colors to draw
            // the background image of the watchface.  This is used to facilitate blanking
            // the second hand during partial updates of the display
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE
                ]
            });
        } else {
            offscreenBuffer = null;
        }

        curClip = null;

        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
        hourHand_r1 = Math.round(30/50.0*dc.getWidth()/2);
        hourHand_r2 = Math.round(11/50.0*dc.getWidth()/2);
        hourHand_t = Math.round(5.3/50.0*dc.getWidth()/2);
        minuteHand_r1 = Math.round(44/50.0*dc.getWidth()/2);
        minuteHand_r2 = Math.round(11/50.0*dc.getWidth()/2);
        minuteHand_t = Math.round(4/50.0*dc.getWidth()/2);
        secondHand_r1 = Math.round(30/50.0*dc.getWidth()/2);
        secondHand_r2 = Math.round(17/50.0*dc.getWidth()/2);
        secondHand_t = Math.round(1.7/50.0*dc.getWidth()/2);
        secondHand_ball_r = Math.round(3.7/50.0*dc.getWidth()/2);

        hourMarker_ri = Math.round(34/50.0*dc.getWidth()/2);
        hourMarker_ro = Math.round(46/50.0*dc.getWidth()/2);
        hourMarker_t = Math.round(3.4/50.0*dc.getWidth()/2);
        minuteMarker_ri = Math.round(42/50.0*dc.getWidth()/2);
        minuteMarker_ro = Math.round(46/50.0*dc.getWidth()/2);
        minuteMarker_t = Math.round(1.2/50.0*dc.getWidth()/2);
    }

    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-Math.round(0.8*width / 2), -handLength], [Math.round(0.8*width / 2), -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }

    function generateTickCoordinates(centerPoint, angle, innerRadius, outerRadius, width) {
        // Map out the coordinates of the watch face
        var coords = [[-(width / 2), -innerRadius], [-(width / 2), -outerRadius], [width / 2, -outerRadius], [width / 2, -innerRadius]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }

    // Draws the clock tick marks around the outside edges of the screen.
    function drawHashMarks(dc) {
        if(invertColors){
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        }else{
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        }

        //hours
        for (var i = 0; i < 12; i += 1) {
        	//todo
            dc.fillPolygon(generateTickCoordinates(screenCenterPoint, i*Math.PI*2.0/12.0, hourMarker_ri, hourMarker_ro, hourMarker_t));
        }
        //minutes
        for (var i = 0; i < 60; i += 1) {
            if(i%5 == 0){
                //do nothing, already drew hours
            }else{
                dc.fillPolygon(generateTickCoordinates(screenCenterPoint, i*Math.PI*2.0/60.0, minuteMarker_ri, minuteMarker_ro, minuteMarker_t));
            }
        }
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;
        var targetDc = null;

        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        if(null != offscreenBuffer) {
            dc.clearClip();
            curClip = null;
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }

        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with Black.
        if(invertColors){
            targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else { 
            targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the tick marks around the edges of the screen
        drawHashMarks(targetDc);

        // Draw the do-not-disturb icon if we support it and the setting is enabled
        if (null != dndIcon && System.getDeviceSettings().doNotDisturb) {
            targetDc.drawBitmap( width * 0.75, height / 2 - 15, dndIcon);
        }

        //draw the hour and minute hands
        if(invertColors){
            targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }else{
            targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }

        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;

        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, hourHand_r1, hourHand_r2, hourHand_t));

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, minuteHand_r1, minuteHand_r2, minuteHand_t));


        // Output the offscreen buffers to the main display if required.
        drawBackground(dc);

        if( partialUpdatesAllowed ) {
            // If this device supports partial updates and they are currently
            // allowed run the onPartialUpdate method to draw the second hand.
            onPartialUpdate(dc);
        } else if ( isAwake ) {
            //NEVER EXECUTES
            // Otherwise, if we are out of sleep mode, draw the second hand
            // directly in the full update method.
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            var sbb_seconds = clockTime.sec;
            sbb_seconds *= 62.0/60.0;
            if(sbb_seconds > 59.0){
              sbb_seconds = 59;
            }
            var secondHand = ((sbb_seconds+1) / 60.0) * Math.PI * 2;

			//never run by simulator!!!!
            dc.fillPolygon(generateHandCoordinates(screenCenterPoint, secondHand, secondHand_r1, secondHand_r2, secondHand_t));
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            //dc.fillCircle(secondHand[2][0], secondHand[2][1], secondHand_ball_r);
            dc.fillCircle(secondHand[2][0], secondHand[2][1], secondHand_ball_r);//this should fail, throw an exception. I don't think I ever reach this. 
        }

        fullScreenRefresh = false;
    }

	/*
    // Draw the date string into the provided buffer at the specified location
    function drawDateString( dc, x, y ) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
    */
    
    // Handle the partial update event
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
        if(!fullScreenRefresh) {
			//goes here in "low power mode"
            drawBackground(dc);
        }
        
        if(isAwake==false and hideSecondsPowerSaver==true){
            //don't render seconds
            return;
        }

        var clockTime = System.getClockTime();
        var sbb_seconds = clockTime.sec;
        var secondHand;
        if(simSecSyncPulse){
            sbb_seconds *= 62.0/60.0;
            if(sbb_seconds > 59.0){
              sbb_seconds = 59;
            }
            secondHand = ((sbb_seconds+1) / 60.0) * Math.PI * 2;
        }
        else{
            secondHand = (sbb_seconds / 60.0) * Math.PI * 2;
        }
            
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, secondHand_r1, secondHand_r2, secondHand_t);
        var secondCircleCenter = [screenCenterPoint[0]-secondHand_r1*Math.sin(-secondHand), screenCenterPoint[1]-secondHand_r1*Math.cos(secondHand)];


        // Update the cliping rectangle to the new location of the second hand.
        var bboxPoints = [[secondHandPoints[0][0], secondHandPoints[0][1]],
        				  [secondHandPoints[1][0], secondHandPoints[1][1]], 
        				  [secondHandPoints[2][0], secondHandPoints[2][1]], 
        				  [secondHandPoints[3][0], secondHandPoints[3][1]],
        				  [secondCircleCenter[0] - secondHand_ball_r, secondCircleCenter[1] - secondHand_ball_r],
        				  [secondCircleCenter[0] - secondHand_ball_r, secondCircleCenter[1] + secondHand_ball_r],
        				  [secondCircleCenter[0] + secondHand_ball_r, secondCircleCenter[1] - secondHand_ball_r],
        				  [secondCircleCenter[0] + secondHand_ball_r, secondCircleCenter[1] + secondHand_ball_r]
        				  ];
        				  
        curClip = getBoundingBox( bboxPoints );
        var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
        var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
        dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.fillPolygon(secondHandPoints );
        dc.fillCircle(secondCircleCenter[0], secondCircleCenter[1], secondHand_ball_r);
        //circle at centre of watch face
        dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], Math.round(secondHand_t*1.1));//10% thicker than hand
    }

    // Compute a bounding box from the passed in points
    function getBoundingBox( points ) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }

    // Draw the watch face background
    // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
    // to the main display.
    // onPartialUpdate uses this to blank the second hand from the previous
    // second before outputing the new one.
    function drawBackground(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }
    }

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

class AnalogDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}

