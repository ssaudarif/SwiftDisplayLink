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
- Each framedata can be configured to fire at different duration.
- Provide an opportunity to create an upcoming frame so that the frame data is ready when the actual event arrives.
- It Provides the duration and frame index for each event it may help in some calculations.
- Also you can temporary pause and play with changed event callback.



