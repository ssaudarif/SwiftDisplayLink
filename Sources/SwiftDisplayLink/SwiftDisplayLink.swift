import Foundation

/// A SwiftDisplayLinkFrameData is a model object to store data related to a frame.
/// This model will be created by devs and passed to SwiftDisplayLink library.
///
/// This model encapsulte data like duration and isFrameConstructed flag.
/// During the course of SwiftDisplayLink lifecycle the SwiftDisplayLink library will
/// keep asking this model from calling app for each frame.
///
/// Initilialization of SwiftDisplayLinkFrameData.
///
///  ```
///     SwiftDisplayLinkFrameData(duration: 1.0)
///  ```
///
/// Another Initilialization of SwiftDisplayLinkFrameData that setup isFrameConstructed flag.
///
///  ```
///     SwiftDisplayLinkFrameData(duration: 1.0, isFrameConstructed: false)
///  ```
///
public struct SwiftDisplayLinkFrameData {

    /// The `duration` is a `CFTimeInterval` object that stores the duration
    /// that needs to be elapsed before calling event for this frame.
    ///
    /// `duration` is taken in form of seconds.
    /// For half-a-second ->  `duration = 0.5`
    /// For 10th-of-a-second ->  `duration = 0.1`
    ///
    /// Note : The minimum amount that can be passed in `duration` is
    /// for ``macOS`` - `0.008`
    /// for ``iOS`` - `0.016`
    ///
    let duration: CFTimeInterval

    /// The `isFrameConstructed` is a `Bool` flag if this flag is false, the calling application will
    /// recieve an extra callback for construct frame event.
    /// Developers can use this extra callback to perform some pre-render logic for that frame.
    ///
    let isFrameConstructed: Bool

    /// Constructor of `SwiftDisplayLinkFrameData` model.
    ///
    /// ```
    /// init(duration d: CFTimeInterval,
    ///      isFrameConstructed constructed: Bool = true)
    /// ```
    ///
    /// - Parameters:
    ///     - duration: The CFTimeInterval in seconds.
    ///     - isFrameConstructed: The Bool flag
    ///
    public init(duration durationInterval: CFTimeInterval, isFrameConstructed constructed: Bool = true) {
        duration = durationInterval
        isFrameConstructed = constructed
    }
}

typealias SwiftDisplayLinkEventInternalBlock = ((_ currentTime: CFTimeInterval, _ duration: CFTimeInterval) -> Void)
public typealias SwiftDisplayLinkFrameDataBlock = ((_ frame: Int) -> SwiftDisplayLinkFrameData)
public typealias SwiftDisplayLinkEventBlock = ((_ event: SwiftDisplayLink.Event, _ frame: Int) -> Void)

public class SwiftDisplayLink {

    public enum Event {
        case constructFrame
        case performAction(_ currentTime: CFTimeInterval, _ duration: CFTimeInterval)
    }

    private let numberOfFrames: Int
    private let frameDataBlock: SwiftDisplayLinkFrameDataBlock
    var eventCallBlock: SwiftDisplayLinkEventBlock?
    var isPlaying: Bool = false
    private var frame: Int = 0
    private var willRepeat: Bool
    private var nextDuration: CFTimeInterval = minDuration
    private static let minDuration: CFTimeInterval = 0.016666667
    private var durationSinceLastEvent: Double = 0.0

    public init( frameCount: Int, repeatFrames: Bool = false, _ frameData: @escaping SwiftDisplayLinkFrameDataBlock ) {
        frameDataBlock = frameData
        willRepeat = repeatFrames
        numberOfFrames = frameCount
    }

    public func play(_ eventCallback: @escaping SwiftDisplayLinkEventBlock ) {
        eventCallBlock = eventCallback
        setUpFrameStart()
        startEvents()
    }

    public func resume() {
        setUpFrameStart()
        startEvents()
    }

    public func pause() {
        stopEvents()
    }

    public func invalid() {
        eventCallBlock = nil
        SwiftDisplayLinkWrapper.shared.removeEventBlock(for: self)
    }

    private func setUpFrameStart() {
        SwiftDisplayLinkWrapper.shared.setUpFrameStart()
        SwiftDisplayLinkWrapper.shared.addEventBlock(object: self, getAnimatingBlock())
//        frame = 0
    }

    private func startEvents() {
        isPlaying = true
        let frameData = frameDataBlock(frame)
        nextDuration = frameData.duration
        durationSinceLastEvent = 0.0
        if frameData.isFrameConstructed == false {
            eventCallBlock?(.constructFrame, frame)
        }
        SwiftDisplayLinkWrapper.shared.start()
    }

    private func stopEvents() {
        isPlaying = false
    }

    private func getAnimatingBlock() -> SwiftDisplayLinkEventInternalBlock {
        return { [weak self] (timestamp, duration) in
            if let kSelf = self {
                guard kSelf.isPlaying else { return }

                kSelf.durationSinceLastEvent += duration
                kSelf.nextDuration -= duration
                if kSelf.nextDuration > 0 {
                    return
                }

                if kSelf.frame >= 0 {
                    kSelf.eventCallBlock?(.performAction(timestamp, kSelf.durationSinceLastEvent), kSelf.frame)
                }

                kSelf.setupForNextFrameFire()
            }
        }
    }

    private func setupForNextFrameFire() {
        frame += 1
        let num = numberOfFrames
        if frame >= num {
            if willRepeat {
                frame = 0
            } else {
                invalid()
                return
            }
        }
        let frameData = frameDataBlock(frame)
        self.nextDuration += frameData.duration
        durationSinceLastEvent = 0.0
        if frameData.isFrameConstructed == false {
            eventCallBlock?(.constructFrame, frame)
        }
    }

    deinit {
        SwiftDisplayLinkWrapper.shared.removeEventBlock(for: self)
    }

}

extension SwiftDisplayLink: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: SwiftDisplayLink, rhs: SwiftDisplayLink) -> Bool {
        return lhs === rhs
    }
}
