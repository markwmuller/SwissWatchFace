using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;

//From Garmin's "Analog" example

class SwissRailwayWatchView extends WatchUi.WatchFace {
    var font;
    var isAwake;
    var haveDrawnSleepFace;
    var screenShape;
    var dndIcon;
    //var dateBuffer;
    var screenCenterPoint;
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

		//read settings
        hideSecondsPowerSaver = Application.Properties.getValue("hideSecondsPowerSaver");
        invertColors = Application.Properties.getValue("invertColors");
        simSecSyncPulse = Application.Properties.getValue("simSecSyncPulse");
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
    	if(isAwake == false and haveDrawnSleepFace == true){
    		if(hideSecondsPowerSaver){
				//nothing to do, low power mode.
				return;
			}
		}
		
		dc.setAntiAlias(true);

        var clockTime = System.getClockTime();
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Fill the entire background with Black.
        if(invertColors){
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else { 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the tick marks around the edges of the screen
        drawHashMarks(dc);

//        // Draw the do-not-disturb icon if we support it and the setting is enabled
//        if (null != dndIcon && System.getDeviceSettings().doNotDisturb) {
//            dc.drawBitmap( width * 0.75, height / 2 - 15, dndIcon);
//        }

        //draw the hour and minute hands
        if(invertColors){
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }else{
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }

        // Draw the hour hand. Convert it to minutes and compute the angle.
        var hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;

        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, hourHand_r1, hourHand_r2, hourHand_t));

        // Draw the minute hand.
        var minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        dc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, minuteHand_r1, minuteHand_r2, minuteHand_t));

        if(isAwake==false and hideSecondsPowerSaver==true){
            //don't render seconds
            return;
        }
        
        var sbb_seconds = clockTime.sec;
        if(simSecSyncPulse == true){
            sbb_seconds *= 62.0/60.0;
            if(sbb_seconds > 59.0){
              sbb_seconds = 59;
            }
        }
        var secondHand = (sbb_seconds / 60.0) * Math.PI * 2;
            
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
        				  
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.fillPolygon(secondHandPoints );
        dc.fillCircle(secondCircleCenter[0], secondCircleCenter[1], secondHand_ball_r);
        //circle at centre of watch face
        dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], Math.round(secondHand_t*1.1));//10% thicker than hand
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

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        haveDrawnSleepFace = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

