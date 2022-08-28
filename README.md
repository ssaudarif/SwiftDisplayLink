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




