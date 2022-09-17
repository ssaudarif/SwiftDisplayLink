# SwiftDisplayLink

SwiftDisplayLink is a small libraray that provides abstraction of display links for macOS and iOS.

The underlying components that are used to implement this are :

OS | macOS | iOS |
--- | --- | --- |
Component Used | CVDisplayLink | CADisplayLink |

How to use:

First you need to create a SwiftDisplayLink Object.

```
let displayLink = SwiftDisplayLink(frameCount: 10) { frame in
    SwiftDisplayLinkFrameData(duration: 0.1, isFrameConstructed: true)
}
```

Now you need to start the displaylink using play command by providing a closure that will get called for each frame.
```
displayLink.play { event, frame  in
    // this part will get called 10 (`frameCount`) times.
}
```

The best thing about SwiftDisplayLink is that it offers a lot of flexibility to developer. Some of those are listed below.
- Can be paused and resumed
- Change the frameCount to change the number of fired events.
- Can be configured as infinite by using `repeatFrames` parameter.
- Each frame event can be configured to fire at different duration.
- Provide an opportunity to create an upcoming frame so that the data for that frame is ready when the actual event arrives.
- It Provides the duration and frame index for each event it may help in some calculations.
- Also you can temporary pause and play with changed event callback.

## Tutorials

### All configurable parameters :

#### How to repeat events ?
When you first create a SwiftDisplayLink Object at that time you can provide this information :
```
let displayLink = SwiftDisplayLink(frameCount: 1, repeatFrames: true) { frame in
    SwiftDisplayLinkFrameData(duration: 1.0, isFrameConstructed: true)
}
```
Now the above code will keep on firing frames until explicitly stopped. Each fire will happen after a second.


#### How to vary durations between events ?
Construct SwiftDisplayLink in following way.
```
let displayLink = SwiftDisplayLink(frameCount: 10) { frame in
    SwiftDisplayLinkFrameData(duration: 0.1 + (frame * 2), isFrameConstructed: true)
}
```
The above code will fire 10 events, with variable durations between them. These durations are calculated using expression - `0.1 + (frame * 2)`. Where frame variable will be between 0 to 9.
So the gaps between the events will be - `0.1`, `2.1`, `4.1`, `6.1`  ....  `18.1` 


## Example

In the demo project I have tested the SwiftDisplayLink, here you can see 60 instances of SwiftDisplayLink working perfectly fine without any jitters.

<p align="center">
    </br>
    <img src="https://github.com/ssaudarif/SwiftDisplayLink/blob/main/Extras/Displaylinkdemo.gif" align="center" />
</p>



