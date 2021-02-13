/* (c) 2021 Mark W. Mueller
*/

using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

//From Garmin's "Analog" example

class SwissRailwayWatchView extends WatchUi.WatchFace {
    var isAwake = true;
    // for always drawing seconds:
    var offscreenBuffer;
    var curClip;
    var doFullScreenRefresh;
    var partialUpdatesAllowed;
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
    var font;
    //settings:
    var setting_invertColors;
    var setting_simSecSyncPulse;
    var setting_drawDate;
    var setting_mode24hr;
    var setting_showBattWarning;
    var setting_showNotifications;
    var setting_alwaysShowSeconds;
    
    var hasAntiAlias; //whether to use anti-aliasing
	
    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        doFullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {
        // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_WHITE,
                    Graphics.COLOR_RED,
                    Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_DK_GRAY,
                ]
            });
        } else {
            offscreenBuffer = null;
        }

        curClip = null;
    
    	//compute geometry
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
        
        if(Toybox.Graphics.Dc has :setAntiAlias){
            hasAntiAlias = true;
        }else{
            hasAntiAlias = false;
        }
        //TODO FIXME
        hasAntiAlias = false;
        
        readSettings();
        
        font = WatchUi.loadResource(Rez.Fonts.smallJannScript);
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
    
    function readSettings(){
        setting_invertColors = Application.Properties.getValue("invertColors");
        setting_simSecSyncPulse = Application.Properties.getValue("simSecSyncPulse");
        setting_drawDate = Application.Properties.getValue("drawDate");
        setting_showBattWarning = Application.Properties.getValue("lowBattWarning");
        setting_mode24hr = Application.Properties.getValue("mode24hr");
        setting_showNotifications = Application.Properties.getValue("notificationsIcon");
        setting_alwaysShowSeconds = Application.Properties.getValue("alwaysShowSeconds");
    }
    
    /* Called every second in full power mode
     * Called every minute in low power mode
     */
    function onUpdate(dc) {
        //read settings
        readSettings();

        // We always want to refresh the full screen when we get a regular onUpdate call.
        doFullScreenRefresh = true;

        var targetDc = null;
        
        if(hasAntiAlias and isAwake){
        	targetDc = dc;
        }else{
            //reset any clipping regions
            dc.clearClip();
            curClip = null;
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        }

        var clockTime = System.getClockTime();

        // Fill the entire background with Black.
        if(setting_invertColors){
            targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        } else { 
            targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }
        targetDc.fillRectangle(0, 0, targetDc.getWidth(), targetDc.getHeight());

        // Draw the tick marks around the edges of the screen
        drawHashMarks(targetDc);

        drawDate(targetDc);

        drawIcons(targetDc);
    
        //draw the hour and minute hands
        if(setting_invertColors){
            targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }else{
            targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
        
        // Draw the hour hand. Convert it to minutes and compute the angle.
        var hourHandAngle;
        if(setting_mode24hr){
            hourHandAngle = (((clockTime.hour % 24) * 60) + clockTime.min);
            hourHandAngle = hourHandAngle / (24 * 60.0);
        }else{
            hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
            hourHandAngle = hourHandAngle / (12 * 60.0);
        }
        // degrees to radians:
        hourHandAngle = hourHandAngle * Math.PI * 2;

        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, hourHandAngle, hourHand_r1, hourHand_r2, hourHand_t));

        // Draw the minute hand.
        var minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        targetDc.fillPolygon(generateHandCoordinates(screenCenterPoint, minuteHandAngle, minuteHand_r1, minuteHand_r2, minuteHand_t));

        if(isAwake and hasAntiAlias){
            //draw second hand, fully AA
            var sbb_seconds = clockTime.sec;
            if(setting_simSecSyncPulse == true){
                sbb_seconds *= 62.0/60.0;
                //we use 58.9, because that's the last step before it hits a minute
                if(sbb_seconds > 58.9){
                  sbb_seconds = 58.9;
                }
            }
            var secondHand = (sbb_seconds / 60.0) * Math.PI * 2;
                
            var secondHandPoints = generateHandCoordinates(screenCenterPoint, secondHand, secondHand_r1, secondHand_r2, secondHand_t);
            var secondCircleCenter = [screenCenterPoint[0]-secondHand_r1*Math.sin(-secondHand), screenCenterPoint[1]-secondHand_r1*Math.cos(secondHand)];

            targetDc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            targetDc.fillPolygon(secondHandPoints);
            targetDc.fillCircle(secondCircleCenter[0], secondCircleCenter[1], secondHand_ball_r);
            //circle at centre of watch face
            targetDc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], (secondHand_t*11)/10);//10% thicker than hand
        
        }else {
            //draw what we've rendered so far:
            drawOffscreenBuffer(dc);
            if(isAwake or setting_alwaysShowSeconds){
            	//do a partial update for seconds (not AA)
                onPartialUpdate(dc);
            }else{
                //don't render seconds, but still draw circle at center of watch face
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
                dc.fillCircle(screenCenterPoint[0], screenCenterPoint[1], Math.round(secondHand_t*1.1));//10% thicker than hand
            }
        }

        // Output the offscreen buffers to the main display if required.
        doFullScreenRefresh = false;
    }

    // called for the first 59 seconds of every minute in low power mode.
    function onPartialUpdate( dc ) {
        // If we're not doing a full screen refresh we need to re-draw the background
        // before drawing the updated second hand position. Note this will only re-draw
        // the background in the area specified by the previously computed clipping region.
        if(!doFullScreenRefresh) {
			//goes here in "low power mode"
            drawOffscreenBuffer(dc);
        }
        
        var clockTime = System.getClockTime();
        var sbb_seconds = clockTime.sec;
        var secondHand;
        if(setting_simSecSyncPulse == true){
            sbb_seconds *= 62.0/60.0;
            if(sbb_seconds > 59.0){
              sbb_seconds = 59;
            }
        }
        secondHand = (sbb_seconds / 60.0) * Math.PI * 2;
            
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
    function drawOffscreenBuffer(dc) {
        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }
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

		//TODO Fix font
        dc.drawText(screenCenterPoint[0], (screenCenterPoint[1]*13)/10, font, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
//        dc.drawText(screenCenterPoint[0], (screenCenterPoint[1]*13)/10, Graphics.FONT_TINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }
    
    function drawIcons(dc){
        var showBattIcon = false;
        var battIconCritical = false;
        var showNotificationIcon = false;

        if(setting_showBattWarning){
            var battLvl = System.getSystemStats().battery;

            showBattIcon = battLvl < 30;
            battIconCritical = battLvl < 20;
        }

        if(setting_showNotifications){
            showNotificationIcon = System.getDeviceSettings().notificationCount!=0;
        }

        if(showBattIcon){
            drawBatteryWarningIcon(dc, battIconCritical, showNotificationIcon);
        }
        if(showNotificationIcon){
            drawNotificationIcon(dc, showBattIcon);
        }
    }

    function drawNotificationIcon(dc, shift) {
        if(setting_invertColors){
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }else{
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        }

        var iconLoc = [screenCenterPoint[0], (screenCenterPoint[1]*3)/5];
        //draw a "speech bubble"
        var iconWidth = screenCenterPoint[0]/5;
        var iconHeight = (iconWidth*4) / 5;

        if(shift){
            iconLoc[0] -= (iconWidth*2)/3;
        }

        dc.fillRoundedRectangle(iconLoc[0]-iconWidth/2,
        iconLoc[1]-iconHeight/2,
        iconWidth,
        (iconHeight*2)/3,
        iconWidth/5);

        //points of the speech bubble point, relative to icon centre
        var iconPts = [[iconLoc[0]-iconWidth/4, iconLoc[1]+0],
                        [iconLoc[0]+iconWidth/3, iconLoc[1]+iconHeight/2],
                        [iconLoc[0]+iconWidth/3, iconLoc[1]+0]];
        dc.fillPolygon(iconPts);
    }

    function drawBatteryWarningIcon(dc, critical, shift) {
        if(critical){
            //very low battery, show in red
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else {
            if(setting_invertColors){
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            }else{
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            }
        }
        
        var iconLoc = [screenCenterPoint[0], (screenCenterPoint[1]*3)/5];
        
        var iconWidth = screenCenterPoint[0]/5;
        var iconHeight = (iconWidth*3) / 5;

        if(shift){
            iconLoc[0] += (iconWidth*2)/3;
        }
        
        //main part of battery
        dc.fillRectangle(iconLoc[0]-iconWidth/2,
                 iconLoc[1]-iconHeight/2,
                 (iconWidth*8)/10,
                 iconHeight);
        //tip of battery
        dc.fillRectangle(iconLoc[0]-iconWidth/2,
                 iconLoc[1]-(iconHeight*3)/10,
                 iconWidth,
                 (iconHeight*3)/5);
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
