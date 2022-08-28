import Foundation
import QuartzCore

public struct SwiftDisplayLinkFrameData {
    let duration: CFTimeInterval
    let isFrameConstructed: Bool
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
    private var eventCallBlock: SwiftDisplayLinkEventBlock?
    private var isPlaying: Bool = false
    private var frame:Int = 0
    private var willRepeat: Bool
    private var nextDuration: CFTimeInterval = minDuration
    private static let minDuration:CFTimeInterval = 0.016666667

    
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
        SwiftDisplayLinkWrapper.shared.start()
    }
    
    private func stopEvents() {
        isPlaying = false
    }
    
    
    private func getAnimatingBlock() -> SwiftDisplayLinkEventInternalBlock {
        return { [weak self] (timestamp, duration) in
            if let kSelf = self {
                guard kSelf.isPlaying else { return }
                
                kSelf.nextDuration = kSelf.nextDuration - duration
                if kSelf.nextDuration > 0 {
                    return
                }
                
                let frameData = kSelf.frameDataBlock(kSelf.frame)
                if frameData.isFrameConstructed == false {
                    kSelf.eventCallBlock?(.constructFrame, kSelf.frame)
                }
                
                if kSelf.frame >= 0 {
                    kSelf.eventCallBlock?(.performAction(timestamp, duration), kSelf.frame)
                }
                kSelf.setupForNextFrameFire(duration: frameData.duration)
            }
        }
    }
    
    

    
    private func setupForNextFrameFire(duration: CFTimeInterval) {
        frame = frame + 1
        let n = numberOfFrames
        if frame >= n {
            if willRepeat {
                frame = 0
            } else {
                invalid()
            }
        }
        self.nextDuration += duration
    }
    
    deinit {
        print("******hello-------")
        SwiftDisplayLinkWrapper.shared.removeEventBlock(for: self)
    }
    
}

extension SwiftDisplayLink : Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func ==(lhs: SwiftDisplayLink, rhs: SwiftDisplayLink) -> Bool {
        return lhs === rhs
    }
}



class SwiftDisplayLinkWrapper {
    
    private init() {
        setup()
    }
    
    static let shared = SwiftDisplayLinkWrapper()
    private var eventBlocks = [ SwiftDisplayLink: SwiftDisplayLinkEventInternalBlock ]()
    var isPlaying: Bool = false
        
#if os(iOS)
    var displaylink: CADisplayLink?
#else
    var displaylink: CVDisplayLink?
    
    private struct DataHolder {
        let oldTime: DispatchTime
        let videoTimeScaleOverRefreshPeriod: Double
    }
    
    private var dataHolderObj = DataHolder(oldTime: DispatchTime.now(),
                                           videoTimeScaleOverRefreshPeriod: 120)
#endif
    

    func setup() {
#if os(iOS)
        
#else
        let displayID = CGMainDisplayID()
        let error = CVDisplayLinkCreateWithCGDisplay(displayID, &displaylink)
        if (error != kCVReturnSuccess) {
            Swift.print("Error: CVDisplayLinkCreateWithCGDisplay error")
            return
        }

        guard let link = displaylink else {
            Swift.print("Error: Failed to get displayLink")
            return
        }
#endif
    }
    
#if os(iOS)
        
    @objc func renderFrame(displaylink: CADisplayLink) {
//        eventInternalBlock?(displaylink.timestamp, displaylink.targetTimestamp, displaylink.duration)
        displayLinkClick(timeStamp: displaylink.timestamp, duration: displaylink.duration)
    }
#else
    
    func dataSetupCallback( displayLink: CVDisplayLink,
                            inNow: UnsafePointer<CVTimeStamp>,
                            inOutputTime: UnsafePointer<CVTimeStamp>,
                            flagsIn: UInt64,
                            flagsOut: UnsafeMutablePointer<UInt64>,
                            displayLinkContext: Optional<UnsafeMutableRawPointer>
                        ) -> Int32 {

        let videoTimeScaleOverRefreshPeriod = Double( inOutputTime.pointee.videoTimeScale) / Double(inOutputTime.pointee.videoRefreshPeriod)
        dataHolderObj = DataHolder(oldTime: DispatchTime.now(), videoTimeScaleOverRefreshPeriod: videoTimeScaleOverRefreshPeriod)
        
        CVDisplayLinkSetOutputCallback(displayLink, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
            SwiftDisplayLinkWrapper.shared.renderCallback(displayLink: displayLink, inNow: inNow, inOutputTime: inOutputTime, flagsIn: flagsIn, flagsOut: flagsOut, displayLinkContext: displayLinkContext)
        }, nil)
        return 0
    }
    
    
    
    
    func renderCallback(
        displayLink: CVDisplayLink,
        inNow: UnsafePointer<CVTimeStamp>,
        inOutputTime: UnsafePointer<CVTimeStamp>,
        flagsIn: UInt64,
        flagsOut: UnsafeMutablePointer<UInt64>,
        displayLinkContext: Optional<UnsafeMutableRawPointer>
    ) -> Int32 {
        
        let deltaTime: TimeInterval = 1.0 / (inOutputTime.pointee.rateScalar * dataHolderObj.videoTimeScaleOverRefreshPeriod);
        let timeStamp = Double(DispatchTime.now().uptimeNanoseconds) * 0.00000000001
        
        displayLinkClick(timeStamp: timeStamp, duration: deltaTime)
        return 0
    }
    
#endif
    
    private func startInternal() {
#if os(iOS)
        let link = CADisplayLink(
            target: self,
            selector: #selector(SwiftDisplayLinkWrapper.renderFrame(displaylink:))
        )
        link.add(to: .main, forMode: .default)
        displaylink = link
#else
        guard let link = displaylink else { return }
//        dataHolderObj = DataHolder()
        CVDisplayLinkSetOutputCallback(link, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
            SwiftDisplayLinkWrapper.shared.dataSetupCallback(displayLink: displayLink, inNow: inNow, inOutputTime: inOutputTime, flagsIn: flagsIn, flagsOut: flagsOut, displayLinkContext: displayLinkContext)
        }, nil)
        CVDisplayLinkStart(link)
        
#endif
    }
    
    private func stopInternal() {
        guard let link = displaylink else { return }
#if os(iOS)
//        link.isPaused = true
        link.invalidate()
#else
//        dataHolderObj = DataHolder()
//        CVDisplayLinkSetOutputCallback(link, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
//            SwiftDisplayLinkWrapper.shared.dataSetupCallback(displayLink: displayLink, inNow: inNow, inOutputTime: inOutputTime, flagsIn: flagsIn, flagsOut: flagsOut, displayLinkContext: displayLinkContext)
//        }, nil)
        CVDisplayLinkStop(link)
#endif
    }
}



extension SwiftDisplayLinkWrapper {
    
    func setUpFrameStart() {
#if os(iOS)
//        displaylink?.preferredFramesPerSecond = 0
#endif
    }
    
    func start() {
        if isPlaying == false {
            startInternal()
            isPlaying = true
        }
    }
    
    /// This is a simple function that will just add the eventBlock in a collection.
    ///
    /// And when the event will occur on displayLink all of these eventblocks will get called.
    func addEventBlock(object: SwiftDisplayLink, _ callback: @escaping SwiftDisplayLinkEventInternalBlock) {
        eventBlocks[object] = callback
    }
    
    /// This is a simple function that will just remove the eventBlock that belongs to provided object
    ///
    /// And when the next event will occur on displayLink none of these events will get called.
    func removeEventBlock(for object: SwiftDisplayLink) {
        eventBlocks[object] = nil
        if eventBlocks.isEmpty {
            stopInternal()
            isPlaying = false
        }
    }
    
    private func displayLinkClick(timeStamp: CFTimeInterval, duration: CFTimeInterval ) {
        for (_, callback) in eventBlocks {
            callback(timeStamp, duration)
        }
    }
    
}
