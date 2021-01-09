# SwissWatchFace

See it in the connect store [here](https://apps.garmin.com/en-US/apps/f68717e8-9ada-4919-a0b2-be634dd116e2).

![Default look](https://github.com/markwmuller/SwissWatchFace/blob/master/img_light.png)

# Title

Swiss Railway Watch

#  Description (Maximum 4,000 Characters)

An open source analog watch that is in the style of the clocks you'll find at Swiss Railway stations (SBB/CFF/FFS). 

In the settings, you can emulate a synchronization pulse, where the second hand runs a little fast, and then pauses at the 59 second mark before the minutes advance (emulating a central accurate clock sending a synchronization pulse). 

Note that the seconds hand will disappear when you're not looking at the watch (Garmin's "low power mode"). The hand should re-appear when you glance at the watch. Note that there is now a setting to force always showing the seconds hand, but this will cause MUCH higher battery usage, so use with caution.

A warning will show if battery drops below 30%, turning red for less than 20% (you can disable the icon you prefer). It'll also show you a notification icon (can also be disabled).

The date is printed, but that can be disabled too. 

You can also invert black / white colors for a darker watch face. 

#  What’s New (Optional) (Maximum 4,000 Characters)
**V0.4.0**
* Added a notification icon, with setting to disable if you don't want.
* Added setting to force always showing the seconds hand, by popular request. 
**V0.3.2**
* Bug fix
**V0.3.0**
* Added compatibility for older watches too (SDK3.1.x) &FR745 -- these devices simply don't use the anti-aliasing features. Thanks @Wolfgang for help figuring this out
**V0.2.2**
* Added 24hr mode for the hour hand (set in settings)
**V0.2.1**
* Added support for Venu & FR945. Note, for Venu, battery draw is likely atrocious unless you do "invert colors"
**V0.2** 
* Now only works with devices having anti-aliasing; removed all the code clutter from the non-anti-aliased options.
* Added a low battery warning, kicks in at below 30% battery level.
* Open-sourced code at https://github.com/markwmuller/SwissWatchFace/

**V0.1**
* Added Anti-aliasing, which will give a much nicer display. This only works on newer watches, I think. 
* Removed option to disable power-saving seconds hiding, this was causing some issues. 
* Added option to show date, but this only works if anti-aliasing is set to "true"



