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




timefromPrev    8428708    deltaTime    0.008333366667
timefromPrev    8339208    deltaTime    0.00833339
timefromPrev    7459417    deltaTime    0.008333403001
timefromPrev    9302792    deltaTime    0.008333409767
timefromPrev    7347625    deltaTime    0.008333413204
timefromPrev    8348666    deltaTime    0.008333414933
timefromPrev    8333125    deltaTime    0.0083334158
timefromPrev    9275750    deltaTime    0.008333416234
timefromPrev    8258167    deltaTime    0.00833341645
timefromPrev    8318917    deltaTime    0.008333416559
timefromPrev    8343208    deltaTime    0.008333416613
timefromPrev    8340417    deltaTime    0.00833341664
timefromPrev    8321291    deltaTime    0.008333416654
timefromPrev    8336209    deltaTime    0.008333416661
timefromPrev    8332625    deltaTime    0.008333416664
timefromPrev    8332333    deltaTime    0.008333416666
timefromPrev    8353583    deltaTime    0.008333416667
timefromPrev    8308667    deltaTime    0.008333416667
timefromPrev    8357958    deltaTime    0.008333416667
timefromPrev    8322500    deltaTime    0.008333416667
timefromPrev    8316292    deltaTime    0.008333416667
timefromPrev    8343125    deltaTime    0.008333416667
timefromPrev    8336167    deltaTime    0.008333416667
timefromPrev    8326625    deltaTime    0.008333416667
timefromPrev    8339000    deltaTime    0.008333416667
timefromPrev    8333041    deltaTime    0.008333416667
timefromPrev    8333084    deltaTime    0.008333416667
timefromPrev    8330250    deltaTime    0.008333416667
timefromPrev    8336666    deltaTime    0.008333416667
timefromPrev    8329209    deltaTime    0.008333416667
timefromPrev    8334000    deltaTime    0.008333416667
timefromPrev    8333041    deltaTime    0.008333416667
timefromPrev    8333584    deltaTime    0.008333416667
timefromPrev    8336500    deltaTime    0.008333416667
timefromPrev    8333250    deltaTime    0.008333416667
timefromPrev    8330166    deltaTime    0.008333416667
timefromPrev    8330459    deltaTime    0.008333416667
timefromPrev    8337583    deltaTime    0.008333416667
timefromPrev    8330458    deltaTime    0.008333416667
timefromPrev    8339750    deltaTime    0.008333416667
timefromPrev    8348834    deltaTime    0.008333416667
timefromPrev    8315791    deltaTime    0.008333416667
timefromPrev    8329459    deltaTime    0.008333416667
timefromPrev    8335625    deltaTime    0.008333416667
timefromPrev    8332916    deltaTime    0.008333416667
timefromPrev    8331542    deltaTime    0.008333416667
timefromPrev    8337792    deltaTime    0.008333416667
timefromPrev    8332000    deltaTime    0.008333416667
timefromPrev    8330708    deltaTime    0.008333416667
timefromPrev    8335375    deltaTime    0.008333416667
timefromPrev    8330208    deltaTime    0.008333416667
timefromPrev    8334292    deltaTime    0.008333416667
timefromPrev    8331875    deltaTime    0.008333416667
timefromPrev    8348750    deltaTime    0.008333416667
timefromPrev    8328875    deltaTime    0.008333416667
timefromPrev    8334208    deltaTime    0.008333416667
timefromPrev    8332084    deltaTime    0.008333416667
timefromPrev    8319833    deltaTime    0.008333416667
timefromPrev    8336292    deltaTime    0.008333416667
timefromPrev    8343416    deltaTime    0.008333416667
timefromPrev    8332084    deltaTime    0.008333416667
timefromPrev    8326375    deltaTime    0.008333416667
timefromPrev    8345000    deltaTime    0.008333416667
timefromPrev    8328125    deltaTime    0.008333416667
timefromPrev    8324250    deltaTime    0.008333416667
timefromPrev    8361208    deltaTime    0.008333416667
timefromPrev    8292750    deltaTime    0.008333416667
timefromPrev    7495375    deltaTime    0.008333416667
timefromPrev    8361125    deltaTime    0.008333416667
timefromPrev    8309000    deltaTime    0.008333416667
timefromPrev    8345042    deltaTime    0.008333416667
timefromPrev    9262458    deltaTime    0.008333416667
timefromPrev    8232542    deltaTime    0.008333416667
timefromPrev    8344125    deltaTime    0.008333416667
timefromPrev    8343708    deltaTime    0.008333416667
timefromPrev    8331917    deltaTime    0.008333416667
timefromPrev    8365208    deltaTime    0.008333416667
timefromPrev    7451792    deltaTime    0.008333416667
timefromPrev    8360083    deltaTime    0.008333416667
timefromPrev    9155542    deltaTime    0.008333416667
timefromPrev    7956041    deltaTime    0.008333416667
timefromPrev    8858917    deltaTime    0.008333416667
timefromPrev    8156875    deltaTime    0.008333416667
timefromPrev    7484000    deltaTime    0.008333416667
timefromPrev    8334042    deltaTime    0.008333416667
timefromPrev    9277000    deltaTime    0.00833340948
timefromPrev    8255416    deltaTime    0.00833340948
timefromPrev    7465209    deltaTime    0.00833340948
timefromPrev    8349500    deltaTime    0.00833340948
timefromPrev    8331291    deltaTime    0.00833340948
timefromPrev    8331042    deltaTime    0.00833340948
timefromPrev    9294833    deltaTime    0.00833340948
timefromPrev    8223875    deltaTime    0.00833340948
timefromPrev    8369292    deltaTime    0.00833340948
timefromPrev    8327250    deltaTime    0.00833340948
timefromPrev    8317208    deltaTime    0.008333438266
timefromPrev    8338584    deltaTime    0.008333438266
timefromPrev    8349958    deltaTime    0.008333445617
timefromPrev    8314542    deltaTime    0.008333445617
timefromPrev    8342333    deltaTime    0.008333483786
timefromPrev    8323542    deltaTime    0.008333483786
timefromPrev    8333083    deltaTime    0.008333483786
timefromPrev    8331208    deltaTime    0.008333483786
timefromPrev    7456042    deltaTime    0.008333483786
timefromPrev    8345333    deltaTime    0.008333483786
timefromPrev    9275334    deltaTime    0.008333483786
timefromPrev    8250833    deltaTime    0.008333502607
timefromPrev    8337583    deltaTime    0.008333502607
timefromPrev    8330542    deltaTime    0.008333501771
timefromPrev    8347458    deltaTime    0.008333501771
timefromPrev    8332292    deltaTime    0.008333501771
timefromPrev    8327417    deltaTime    0.008333501771
timefromPrev    8332541    deltaTime    0.008333501771
timefromPrev    8334209    deltaTime    0.008333501771
timefromPrev    8349250    deltaTime    0.008333501771
timefromPrev    8328083    deltaTime    0.008333501771
timefromPrev    8319250    deltaTime    0.008333501771
timefromPrev    8334833    deltaTime    0.008333501771
timefromPrev    8339709    deltaTime    0.008333501771
timefromPrev    8353666    deltaTime    0.008333536091
timefromPrev    8301459    deltaTime    0.008333536091
timefromPrev    8331166    deltaTime    0.008333546134
timefromPrev    8345167    deltaTime    0.008333546134
timefromPrev    8330417    deltaTime    0.008333546134
timefromPrev    8337208    deltaTime    0.008333546134
timefromPrev    8330375    deltaTime    0.008333546134
timefromPrev    8335583    deltaTime    0.008333546134
timefromPrev    8333042    deltaTime    0.008333546134
timefromPrev    8334167    deltaTime    0.008333546134
timefromPrev    8329250    deltaTime    0.008333546134
timefromPrev    8338416    deltaTime    0.00833358784
timefromPrev    8317917    deltaTime    0.00833358784
timefromPrev    8335875    deltaTime    0.008333599665
timefromPrev    8346500    deltaTime    0.008333599665
timefromPrev    8323042    deltaTime    0.008333599665
timefromPrev    8341291    deltaTime    0.008333599665
timefromPrev    8329625    deltaTime    0.008333599665
timefromPrev    8334750    deltaTime    0.008333599665
timefromPrev    8333250    deltaTime    0.008333599665
timefromPrev    8331125    deltaTime    0.008333643322
timefromPrev    8329250    deltaTime    0.008333643322
timefromPrev    8339334    deltaTime    0.008333653283
timefromPrev    8332166    deltaTime    0.008333653283
timefromPrev    8347834    deltaTime    0.008333696818
timefromPrev    8308375    deltaTime    0.008333696818
timefromPrev    8334291    deltaTime    0.008333696818
timefromPrev    8333417    deltaTime    0.008333696818
timefromPrev    8336167    deltaTime    0.008333696818
timefromPrev    8328666    deltaTime    0.008333696818
timefromPrev    8336167    deltaTime    0.008333696818
timefromPrev    8333583    deltaTime    0.008333696818
timefromPrev    8330625    deltaTime    0.008333696818
timefromPrev    8334959    deltaTime    0.008333696818
timefromPrev    8347916    deltaTime    0.008333717776
timefromPrev    8309292    deltaTime    0.008333717776
timefromPrev    8338292    deltaTime    0.008333719543
timefromPrev    8340333    deltaTime    0.008333719543
timefromPrev    8338917    deltaTime    0.008333719543
timefromPrev    8331708    deltaTime    0.008333719543
timefromPrev    8333083    deltaTime    0.008333719543
timefromPrev    8338500    deltaTime    0.0083337592
timefromPrev    8315292    deltaTime    0.0083337592
timefromPrev    8379708    deltaTime    0.008333761779
timefromPrev    7435125    deltaTime    0.008333761779
timefromPrev    9286625    deltaTime    0.0083337622
timefromPrev    8243625    deltaTime    0.0083337622
timefromPrev    8344542    deltaTime    0.008333761545
timefromPrev    8340250    deltaTime    0.008333761545
timefromPrev    8327292    deltaTime    0.008333761545
timefromPrev    8332333    deltaTime    0.008333761545
timefromPrev    8334583    deltaTime    0.008333761545
timefromPrev    8361542    deltaTime    0.008333761545
timefromPrev    8312875    deltaTime    0.008333761545
timefromPrev    8360500    deltaTime    0.008333761545
timefromPrev    8292000    deltaTime    0.008333761545
timefromPrev    8346833    deltaTime    0.008333760357
timefromPrev    8324417    deltaTime    0.008333760357
timefromPrev    8335125    deltaTime    0.008333758653
timefromPrev    8367375    deltaTime    0.008333758653
timefromPrev    7415042    deltaTime    0.008333758653
timefromPrev    8369791    deltaTime    0.008333758653
timefromPrev    9264250    deltaTime    0.008333758653
timefromPrev    8241167    deltaTime    0.008333758653
timefromPrev    8349542    deltaTime    0.008333758653
timefromPrev    8364791    deltaTime    0.008333758653
timefromPrev    8312084    deltaTime    0.008333758653
timefromPrev    8337875    deltaTime    0.008333758095
timefromPrev    8304875    deltaTime    0.008333758095
timefromPrev    8360166    deltaTime    0.008333756235
timefromPrev    8309875    deltaTime    0.008333756235
timefromPrev    8364875    deltaTime    0.008333756235
timefromPrev    8320125    deltaTime    0.008333756235
timefromPrev    8321459    deltaTime    0.008333756235
timefromPrev    8329958    deltaTime    0.008333756235
timefromPrev    8331917    deltaTime    0.008333756235
timefromPrev    8334500    deltaTime    0.008333756235
timefromPrev    8333958    deltaTime    0.008333756235
        sum = 1641769208          sum =   1.641706133


