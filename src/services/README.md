# Changes in bluetoothrevamp8

### Possiblity to have multiple iPhones that can connect to the same MiaoMiao. 
You may already have two iPhones configured as master today, for the same MiaoMiao.
If the MiaoMiao connects to device A, then device B will not connect - it will never get readings. 
If device A disconnects - and B is in range, then B will connect.
But then you may have the same BG values uploaded to NS, that means duplicate uploads, with possiblity a minor timing difference.

The difference with the new implementation here is that it is possible to define an iOS device both as 'master' and as 'follower'. (in the settings, not yet in the UI)
In that case, each iOS device (configured as master and follower) will interact with NightScout :
* download calibrations that may have been uploaded to NS from any other iOS device
    If it finds a calibration, the bg value will be used as new calibration.
* If a device doesn't receive readings (because it's not connected) , then it will regulary (every 5 minutes) check at NS if there are readings and if yes download them (it will use the raw values and recalibrate). Like this it works as follower.
* Avoid multiple uploads. Device A may be connected, upload data .. then A disconnects, B connects, B should not be uploading readings that are already uploaded by device A.
When downloading readings from NS, a device will use the raw data, and recalibrate. As a result, A and B may (and most probably will) show different values.

    
My idea originally was to have all iOS devices in my house configured as master & follower. When at home, I could pick up any phone to see my readings.
Main disadvantage off course is the battery drain. I have set the deepsleep service timer to 5 seconds if configured as master & follower. (follower demands 5 seconds too my experience)
Every phone, even those I don't use but have Spike running, would be empty in just a few hours.

Conclusion : bad plan, however there's still an advantage, I can switch easily from one phone to another. Or pick up any phone, open Spike, it will either connect or get values from NS.
And maybe we should have an option to have a user defined suspension prevention set to "no suspension prevention". This way, in most case NS upload would still work, but still the user would have the advantage of low battery consumption

### Don't prevent suspension if not needed (only MiaoMiao)
I also started looking at battery drain. Obviously suspension prevention is causing high battery usage.
Theoretically, it should work fine without suspension prevention.
If an app 'had' a connection with a bluetooth device, or 'has' a connection, and if the app is suspended by iOS, in both cases, iOS will re-activate the app as soon as the device is there.
- either the app 'had' a connection but is now disconnected.
As soon as the disconnect occurs, Spike will ask a reconnect, you see this here : https://github.com/SpikeApp/Spike/blob/master/Native%20Extension/iOS/NativeExtensioniOS/NativeExtensioniOS/FQBleManager.m#L210
Spike can now go to sleep (suspended), which will happen, at least if there's no suspension prevention running.
When the device is back in range, and starts broadcasting, iOS will wake up Spike and connect it, and then Spike and the device can communicate (G5 is actually always in this case, after having sent a reading, it disconnects. It will reconnect after 5 minutes)
- or the app 'has' a connection, but the device has nothing to tell (MiaoMiao communicates data every 5 minutes, but for the rest there's not a lot to say - the same accounts to xbridge, blucon)
Again, Spike can go to sleep, which will happen (if no ...). 5 minutes later, the device has something to tell and will start transmitting data. iOS will wake up Spike, and again Spike and device can communicate.

So I started changing code, so that if not necessary, suspension prevention is not active.
And that seems to work so far. During the night, my battery goes from 100% to 85%. NightScout disabled in that case.
But I had to do an important change in the ANE handling MiaoMiao, which will also increase the stability in general. (consider this as a teaser, so keep reading).

But there's a but. Nightscout upload. (and also Dexcom Share and probably others like upload to internal http server ?)
In theory, that should still work, even without suspension prevention, and here's the theory :
An app in the background, suspended, is actually not allowed to do any background internet activity. 
But, when the app is being re-activated (ie from suspended to active), then it has a short period of time to do some Internet up-/download.
This is how the Dexcom app is working, this is also how loop works (the app written by Pete S). From what I read, loop is actually being woken up by an additional device (is it raspberry PI ?), which gives loop the opportunity to do some background stuff. (note that this has nothing to do with the iOS feature "Background Refresh" - in fact you san simply disable this for Spike in the iOS settings, try it, you won't notice any difference). 

This works also for Spike. Most of the time.
"Most of the time", means, if suspension prevention is disabled, when the app is activated, and receives a reading - it will be able to upload to NS. But sometimes this upload just stops working, and the only way to get it working again is to bring the app in the foreground. That's why usage of NS requires the suspension prevention.

The change I did was
- if not "user defined" suspension prevention
- if no Nightscout/Dexcom upload needed
- if MiaoMiao then don't do suspension prevention.

This reduces battery consumption a lot. It allows me to go out the whole day with my iPhone without having to carry a powerbank with me. At the end of the day, battery is still at 60% (tested between 10 and 23, iPhone Internet and Wifi on, but not used for anything else but MiaoMiao)

As said , I had to do another important change in the bluetooth code for MiaoMiao :

### only MiaoMiao  : After reconnect, and if previous reading is less than 5 minutes old, then immediately send startreading command
a startreading command needs to be send immediately after connecting to the MiaoMiao, each time it connects or reconnects, and only once (per connect). The MiaoMiao will then immediately send a reading, and 5 minutes later send a new reading, ... 5 minutes later again and so on.
In previous version, start reading command would not be sent immediately after a reconnect. A timer was started, which would expire exactly 5 minutes after the previous reading. To avoid that new readings keep coming in each time the device reconnects. (this may happen frequently, it does for me while I'm working in my graden and I don't have my phone with me, the MiaoMiao disconnects/reconnects frequently).
I think this may however lead to failing behaviour. If the app suspends in between connect and the timer expiry, the app would never be able to send the start reading command, so the MiaoMiao would never send a characteristic update,  and so Spike would never be re-activated

So I did a change in the code. Main purpose was to be able to switch off suspension prevention.  And that's not only when MultipleMiaoMiao is used and not only when suspension prevention is disabled. It's for all cases. After a reconnect, the startreading command will be sent immediately to the MiaoMiao.

Right now, reconnect works very well, without suspension prevention. I tested with two phones, about 10 meters away from each other (one in the  kitchen, the other outside). As I walk around in the garden, usually one of them reconnects when I approach it.

### Consequences of not using suspension prevention
- Nightscout and Dexcom upload will become unstable
- functionality like internal http server will not work anymore ?
- missed readings will not work anymore
- phone muted alert will not work anymore
- repeating alerts will not work anymore
- ... in fact anything which relies on a timer will not work anymore
- 
### TODO's
What I propose :
- check avoidance of multiple upload of the same raw value, doesn't seem to work right now as it should - stil  needs to be fixed.
- add option to have "no suspension prevention" with warning that lots's of stuff (mentioned here) will not work anymore. Like this the user can choose to have a low battery consuming Spike which is stable enough to have readings, but with other functionality missing.

or
- even in the "not user defined" case of suspension prevention, if NS/dexcom upload not needed, and if no other stuff enabled (like send to internal http server) - and Follow mode not enabled, then don't do suspensen prevention
- MultipleMiaoMiao : add a setting when transmittertype = MiaoMiao, to add follower functionality, meaning the device would automatically switch from master to follower when disconnecting
