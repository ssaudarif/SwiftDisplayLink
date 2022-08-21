# SwiftDisplayLink

A description of this package.











## Some notes on Display links:

Your app initializes a new display link, providing a target object and a selector to call when the system updates the screen. To synchronize your display loop with the display, your application adds it to a run loop.

Once you associate the display link with a run loop, the system calls the selector on the target when the screen’s contents need to update. The target can read the display link’s timestamp property to retrieve the time the system displayed the previous frame. For example, an app that displays movies might use timestamp to calculate which video frame to display next. An app that performs its own animations might use timestamp to determine where and how visible objects appear in the upcoming frame.

The duration property provides the amount of time between frames at the maximumFramesPerSecond. To calculate the actual frame duration, use targetTimestamp - timestamp. You can use this value in your app to calculate the frame rate of the display, the approximate time the system displays the next frame, and to adjust the drawing behavior so that the next frame is ready in time to display.

This repository uses following:
 - CADisplayLink for iOS
 - CVDisplayLink for macOS
 
 
### CADisplayLink
When CADisplayLink will call the selector it will provide CADisplayLink object. This object will provide following information :
#### timestamp
    Can be accessed by `displaylink.timestamp`. It is the time interval that represents when the last frame displayed.
#### targetTimestamp
    Can be accessed by `displaylink.targetTimestamp`. It is the time interval that represents when the next frame displays.
#### duration
    Can be accessed by `displaylink.duration`. It is the time interval between screen refresh updates.
    
    
### CVDisplayLink
When CVDisplayLink will call the selector it will provide CADisplayLink object. This object will provide following information :
#### inNow 
    Its a UnsafePointer<CVTimeStamp>, a pointer to the current time. 
#### inOutputTime
    Its a UnsafePointer<CVTimeStamp>, A pointer to the display time for a frame.

And the CVTimeStamp will provide following - 
#### flags: UInt64
    A bit field containing additional information about the timestamp. See CVTimeStamp Flags for a list of possible values. .
#### hostTime: UInt64
    The system time measured by the timestamp.
#### rateScalar: Double
    The current rate of the device as measured by the timestamps, divided by the nominal rate.
#### reserved: UInt64
    Reserved. Do not use.
#### smpteTime: CVSMPTETime
    The SMPTE time representation of the timestamp.
#### version: UInt32
    The current CVTimeStamp structure is version 0. Some functions require you to specify a version when passing in a timestamp structure to be filled.
#### videoRefreshPeriod: Int64
#### videoTime: Int64
    The start of a frame (or field for interlaced video).
#### videoTimeScale: Int32
    The scale (in units per second) of the videoTimeScale and videoRefreshPeriod fields.


## Changes done to make CADisplayLink and CVDisplayLink provide similar callback.
How much info you need to provide to the client? i.e. What parameters to expose? 
    I like the CADisplayLink's parameters - `timestamp` and `duration`
In this was CADisplayLink is sorted. It already provides these infos.
But the CVDisplayLink callback does not provides these so we need to calculate them from the provided info. 

Let us start with duration :
We can use the following logic to calculate the duration.
    `let deltaTime: TimeInterval = 1.0 / (inOutputTime.pointee.rateScalar * Double( inOutputTime.pointee.videoTimeScale) / Double(inOutputTime.pointee.videoRefreshPeriod));`
If this Looks too much of calculation. we can pre-calculate those values that are not changing. So I found out that only `rateScalar` value keeps on changing. It will be around 1 but still keeps changing. so we can calculate : `Double( inOutputTime.pointee.videoTimeScale) / Double(inOutputTime.pointee.videoRefreshPeriod)` and store it.
Note: I have done some testing to support that the time provided by deltaTime is correct or not.  see the table at the end.


Now the time stamp we can get by using `let timeStamp = Double(DispatchTime.now().uptimeNanoseconds) * 0.00000000001`




| Time taken in nanoseconds     |  delta Time |
| -------- | ------------- |
| 8428708  |   0.008333366667  |
| 8339208  |   0.00833339  |
| 7459417  |   0.008333403001  |
| 9302792  |   0.008333409767  |
| 7347625  |   0.008333413204  |
| 8348666  |   0.008333414933  |
| 8333125  |   0.0083334158  |
| 9275750  |   0.008333416234  |
| 8258167  |   0.00833341645  |
| 8318917  |   0.008333416559  |
| 8343208  |   0.008333416613  |
| 8340417  |   0.00833341664  |
| 8321291  |   0.008333416654  |
| 8336209  |   0.008333416661  |
| 8332625  |   0.008333416664  |
| 8332333  |   0.008333416666  |
| 8353583  |   0.008333416667  |
| 8308667  |   0.008333416667  |
| 8357958  |   0.008333416667  |
| 8322500  |   0.008333416667  |
| 8316292  |   0.008333416667  |
| 8343125  |   0.008333416667  |
| 8336167  |   0.008333416667  |
| 8326625  |   0.008333416667  |
| 8339000  |   0.008333416667  |
| 8333041  |   0.008333416667  |
| 8333084  |   0.008333416667  |
| 8330250  |   0.008333416667  |
| 8336666  |   0.008333416667  |
| 8329209  |   0.008333416667  |
| 8334000  |   0.008333416667  |
| 8333041  |   0.008333416667  |
| 8333584  |   0.008333416667  |
| 8336500  |   0.008333416667  |
| 8333250  |   0.008333416667  |
| 8330166  |   0.008333416667  |
| 8330459  |   0.008333416667  |
| 8337583  |   0.008333416667  |
| 8330458  |   0.008333416667  |
| 8339750  |   0.008333416667  |
| 8348834  |   0.008333416667  |
| 8315791  |   0.008333416667  |
| 8329459  |   0.008333416667  |
| 8335625  |   0.008333416667  |
| 8332916  |   0.008333416667  |
| 8331542  |   0.008333416667  |
| 8337792  |   0.008333416667  |
| 8332000  |   0.008333416667  |
| 8330708  |   0.008333416667  |
| 8335375  |   0.008333416667  |
| 8330208  |   0.008333416667  |
| 8334292  |   0.008333416667  |
| 8331875  |   0.008333416667  |
| 8348750  |   0.008333416667  |
| 8328875  |   0.008333416667  |
| 8334208  |   0.008333416667  |
| 8332084  |   0.008333416667  |
| 8319833  |   0.008333416667  |
| 8336292  |   0.008333416667  |
| 8343416  |   0.008333416667  |
| 8332084  |   0.008333416667  |
| 8326375  |   0.008333416667  |
| 8345000  |   0.008333416667  |
| 8328125  |   0.008333416667  |
| 8324250  |   0.008333416667  |
| 8361208  |   0.008333416667  |
| 8292750  |   0.008333416667  |
| 7495375  |   0.008333416667  |
| 8361125  |   0.008333416667  |
| 8309000  |   0.008333416667  |
| 8345042  |   0.008333416667  |
| 9262458  |   0.008333416667  |
| 8232542  |   0.008333416667  |
| 8344125  |   0.008333416667  |
| 8343708  |   0.008333416667  |
| 8331917  |   0.008333416667  |
| 8365208  |   0.008333416667  |
| 7451792  |   0.008333416667  |
| 8360083  |   0.008333416667  |
| 9155542  |   0.008333416667  |
| 7956041  |   0.008333416667  |
| 8858917  |   0.008333416667  |
| 8156875  |   0.008333416667  |
| 7484000  |   0.008333416667  |
| 8334042  |   0.008333416667  |
| 9277000  |   0.00833340948  |
| 8255416  |   0.00833340948  |
| 7465209  |   0.00833340948  |
| 8349500  |   0.00833340948  |
| 8331291  |   0.00833340948  |
| 8331042  |   0.00833340948  |
| 9294833  |   0.00833340948  |
| 8223875  |   0.00833340948  |
| 8369292  |   0.00833340948  |
| 8327250  |   0.00833340948  |
| 8317208  |   0.008333438266  |
| 8338584  |   0.008333438266  |
| 8349958  |   0.008333445617  |
| 8314542  |   0.008333445617  |
| 8342333  |   0.008333483786  |
| 8323542  |   0.008333483786  |
| 8333083  |   0.008333483786  |
| 8331208  |   0.008333483786  |
| 7456042  |   0.008333483786  |
| 8345333  |   0.008333483786  |
| 9275334  |   0.008333483786  |
| 8250833  |   0.008333502607  |
| 8337583  |   0.008333502607  |
| 8330542  |   0.008333501771  |
| 8347458  |   0.008333501771  |
| 8332292  |   0.008333501771  |
| 8327417  |   0.008333501771  |
| 8332541  |   0.008333501771  |
| 8334209  |   0.008333501771  |
| 8349250  |   0.008333501771  |
| 8328083  |   0.008333501771  |
| 8319250  |   0.008333501771  |
| 8334833  |   0.008333501771  |
| 8339709  |   0.008333501771  |
| 8353666  |   0.008333536091  |
| 8301459  |   0.008333536091  |
| 8331166  |   0.008333546134  |
| 8345167  |   0.008333546134  |
| 8330417  |   0.008333546134  |
| 8337208  |   0.008333546134  |
| 8330375  |   0.008333546134  |
| 8335583  |   0.008333546134  |
| 8333042  |   0.008333546134  |
| 8334167  |   0.008333546134  |
| 8329250  |   0.008333546134  |
| 8338416  |   0.00833358784  |
| 8317917  |   0.00833358784  |
| 8335875  |   0.008333599665  |
| 8346500  |   0.008333599665  |
| 8323042  |   0.008333599665  |
| 8341291  |   0.008333599665  |
| 8329625  |   0.008333599665  |
| 8334750  |   0.008333599665  |
| 8333250  |   0.008333599665  |
| 8331125  |   0.008333643322  |
| 8329250  |   0.008333643322  |
| 8339334  |   0.008333653283  |
| 8332166  |   0.008333653283  |
| 8347834  |   0.008333696818  |
| 8308375  |   0.008333696818  |
| 8334291  |   0.008333696818  |
| 8333417  |   0.008333696818  |
| 8336167  |   0.008333696818  |
| 8328666  |   0.008333696818  |
| 8336167  |   0.008333696818  |
| 8333583  |   0.008333696818  |
| 8330625  |   0.008333696818  |
| 8334959  |   0.008333696818  |
| 8347916  |   0.008333717776  |
| 8309292  |   0.008333717776  |
| 8338292  |   0.008333719543  |
| 8340333  |   0.008333719543  |
| 8338917  |   0.008333719543  |
| 8331708  |   0.008333719543  |
| 8333083  |   0.008333719543  |
| 8338500  |   0.0083337592  |
| 8315292  |   0.0083337592  |
| 8379708  |   0.008333761779  |
| 7435125  |   0.008333761779  |
| 9286625  |   0.0083337622  |
| 8243625  |   0.0083337622  |
| 8344542  |   0.008333761545  |
| 8340250  |   0.008333761545  |
| 8327292  |   0.008333761545  |
| 8332333  |   0.008333761545  |
| 8334583  |   0.008333761545  |
| 8361542  |   0.008333761545  |
| 8312875  |   0.008333761545  |
| 8360500  |   0.008333761545  |
| 8292000  |   0.008333761545  |
| 8346833  |   0.008333760357  |
| 8324417  |   0.008333760357  |
| 8335125  |   0.008333758653  |
| 8367375  |   0.008333758653  |
| 7415042  |   0.008333758653  |
| 8369791  |   0.008333758653  |
| 9264250  |   0.008333758653  |
| 8241167  |   0.008333758653  |
| 8349542  |   0.008333758653  |
| 8364791  |   0.008333758653  |
| 8312084  |   0.008333758653  |
| 8337875  |   0.008333758095  |
| 8304875  |   0.008333758095  |
| 8360166  |   0.008333756235  |
| 8309875  |   0.008333756235  |
| 8364875  |   0.008333756235  |
| 8320125  |   0.008333756235  |
| 8321459  |   0.008333756235  |
| 8329958  |   0.008333756235  |
| 8331917  |   0.008333756235  |
| 8334500  |   0.008333756235  |
| 8333958  |   0.008333756235  |
| sum = 1641769208 | sum =   1.641706133 |



