More info @ https://spike-app.com

Facebook support group @ https://www.facebook.com/groups/spikeapp/

Gitter Channel @ https://gitter.im/SpikeiOS/Lobby

Better readme soon!

*Note for iOS Developers*: 

 You'll notice that while the Today Widgets and Apple Watch app have Xcode projects and can be compiled using Xcode, the main Spike App project UI is missing, and the Spike project and storyboard are just empty place holders.

 While the iOS specific code is available and open source, building your own version of the Spike App with Xcode from this repository is not possible, for the following reasons:

 - Spike is based on [iOSxDripReader](https://github.com/JohanDegraeve/iosxdripreader), which was written for the Adobe Air runtime and is compiled with the commercial product FlashBuilder Premium.

 - The Spike App's theme and graphics were donated to the Spike project by a french designer and are not open source (you would need to supply your own)

 - Additionaly, there are many commerical AIR Native Extensions to support iOS functionality from AIR which include:
   - Bluetooth LE
   - Calendar
   - CloudStorage
   - Firebase
   - Network Info
   - Notifications
   - Push Notifications
   - Scanner
   - Open source
   - 3DTouchiOS by Adobe
