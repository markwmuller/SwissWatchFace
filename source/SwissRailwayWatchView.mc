/* (c) 2020 Mark W. Mueller

TODO
1. Re-enable setting to always show seconds?
*/


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
    var isAwake;
    // define watch geometry:
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
    var setting_invertColors;
    var setting_simSecSyncPulse;
    var setting_drawDate;
    var setting_lowBattWarning;
	
    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();

    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {
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
    // from "analog" example
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
        if(setting_invertColors){
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

    function onUpdate(dc) {
		//read settings
        setting_invertColors = Application.Properties.getValue("invertColors");
        setting_simSecSyncPulse = Application.Properties.getValue("simSecSyncPulse");
        setting_drawDate = Application.Properties.getValue("drawDate");
        setting_lowBattWarning = Application.Properties.getValue("lowBattWarning");

		dc.setAntiAlias(true);

        var clockTime = System.getClockTime();

        // Fill the entire background with Black.
        if(setting_invertColors){
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else { 
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the tick marks around the edges of the screen
        drawHashMarks(dc);

		drawDate(dc);

		drawBatteryWarning(dc);
		
        //draw the hour and minute hands
        if(setting_invertColors){
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

        if(isAwake==false){
            //don't render seconds
            //draw circle at center of watch face
			dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
			dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], Math.round(secondHand_t*1.1));//10% thicker than hand
            return;
        }
        
        //draw second hand too
        var sbb_seconds = clockTime.sec;
        if(setting_simSecSyncPulse == true){
            sbb_seconds *= 62.0/60.0;
            if(sbb_seconds > 59.0){
              sbb_seconds = 59;
            }
        }
        var secondHand = (sbb_seconds / 60.0) * Math.PI * 2;
            
        var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, secondHand_r1, secondHand_r2, secondHand_t);
        var secondCircleCenter = [screenCenterPoint[0]-secondHand_r1*Math.sin(-secondHand), screenCenterPoint[1]-secondHand_r1*Math.cos(secondHand)];

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
        dc.fillPolygon(secondHandPoints);
        dc.fillCircle(secondCircleCenter[0], secondCircleCenter[1], secondHand_ball_r);
        //circle at centre of watch face
        dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], Math.round(secondHand_t*1.1));//10% thicker than hand
    }
    
    function drawDate(dc) {
		if(!setting_drawDate){
			return;
		}
	
		var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var dateStr = Lang.format("$1$ $2$", [info.day_of_week, info.day]);

		if(setting_invertColors){
			dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
		}else{
			dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
		}

		dc.drawText(screenCenterPoint[0], (screenCenterPoint[1]*13)/10, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawBatteryWarning(dc) {
		if(!setting_lowBattWarning){
			return;
		}
	
		var battLvl = System.getSystemStats().battery;
		
		if(battLvl > 30){
			//plenty of battery
			return;
		}
		if(battLvl < 20){
			//very low battery, show in red
			dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
		} else {
			if(setting_invertColors){
				dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
			}else{
				dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
			}
		}
		
		var battIconLoc = [screenCenterPoint[0], (screenCenterPoint[1]*3)/5];
		
		var battWidth = screenCenterPoint[0]/4;
		var battHeight = (battWidth*2) / 3;
	  	var battWrnPts = [[-battWidth/2, -battHeight/2],
	  					  [-battWidth/2, +battHeight/2],
	  					  [+(battWidth*4)/10, +battHeight/2],
	  					  [+(battWidth*4)/10, -battHeight/2],
	  					 ];
        for (var i = 0; i < 4; i += 1) {
        	battWrnPts[i][0] += battIconLoc[0];
        	battWrnPts[i][1] += battIconLoc[1];
        }
        dc.fillPolygon(battWrnPts);
        battHeight = (battHeight*3)/5;
	  	battWrnPts = [[-battWidth/2, -battHeight/2],
	  				  [-battWidth/2, +battHeight/2],
	  				  [+battWidth/2, +battHeight/2],
	  				  [+battWidth/2, -battHeight/2],
	  				 ];
        for (var i = 0; i < 4; i += 1) {
        	battWrnPts[i][0] += battIconLoc[0];
        	battWrnPts[i][1] += battIconLoc[1];
        }
        dc.fillPolygon(battWrnPts);
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