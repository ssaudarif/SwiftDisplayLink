import Foundation
import QuartzCore

/// `SwiftDisplayLinkDelegate` is a protocol that is used to send events by `SwiftDisplayLink`
///
/// Any object that needs to recieve the events of `SwiftDisplayLink` should implement this protocol.
///
public protocol SwiftDisplayLinkDelegate: AnyObject {
    
    func eventOccured(frame:Int, duration:CFTimeInterval)
    func getFrameDuration(_ index:Int) -> CFTimeInterval
    func getNumberOfFrames() -> Int
    func constructImage(_ frame:Int)
    func isImageConstructed(_ frame:Int) -> Bool
    func queueForDisplayImage(_ frame:Int)
    //func displayImage(_ frame:Int)
}

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
    
    public init( frameCount: Int, _ frameData: @escaping SwiftDisplayLinkFrameDataBlock ) {
        frameDataBlock = frameData
        numberOfFrames = frameCount
    }
    
    public func play(_ eventCallback: @escaping SwiftDisplayLinkEventBlock ) {
        eventCallBlock = eventCallback
        setUpFrameStart()
        startEvents()
    }
    
    private func setUpFrameStart() {
        SwiftDisplayLinkWrapper.shared.setUpFrameStart()
        SwiftDisplayLinkWrapper.shared.addEventBlock(object: self, getAnimatingBlock())
        frame = 0
    }
    
    private func startEvents() {
        isPlaying = true
        SwiftDisplayLinkWrapper.shared.start()
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
    
    
    private weak var delegate: SwiftDisplayLinkDelegate?
    
    
    private var frame:Int = -1
    private var nextDuration: CFTimeInterval = minDuration
    private static let minDuration:CFTimeInterval = 0.016666667
    
//    private var numberOfFrames: Int {
//        if let count = delegate?.getNumberOfFrames() {
//            return count
//        }
//        return 0
//    }
    
    


    
    
    
    
    private func setupForNextFrameFire(duration: CFTimeInterval) {
        frame = frame + 1
        let n = numberOfFrames
        if frame >= n {
            frame = 0
        }
        self.nextDuration += duration
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
    
    fileprivate static let shared = SwiftDisplayLinkWrapper()
    private var eventBlocks = [ SwiftDisplayLink: SwiftDisplayLinkEventInternalBlock ]()
    private var isPlaying: Bool = false
        
#if os(iOS)
    var displaylink: CADisplayLink?
#else
    var displaylink: CVDisplayLink?
    
    private struct DataHolder {
        let oldTime: DispatchTime/* = DispatchTime.now()*/
        let videoTimeScaleOverRefreshPeriod: Double/* = 120*/
//        var isFirstTimeCalled: Bool = false
        
//        mutating func firstTimeCalled(_ scaleTimesRefreshPeriod: Int64) {
//            videoTimeScaleTimesRefreshPeriod = scaleTimesRefreshPeriod
//            oldTime = DispatchTime.now()
////            isFirstTimeCalled = true
//        }
    }
    
    private var dataHolderObj = DataHolder(oldTime: DispatchTime.now(),
                                           videoTimeScaleOverRefreshPeriod: 120)
#endif
    
//    var eventInternalBlock: SwiftDisplayLinkEventInternalBlock?

    func setup() {
#if os(iOS)
        displaylink = CADisplayLink(
            target: self,
            selector: #selector(SwiftDisplayLinkWrapper.renderFrame(displaylink:))
        )
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
//        GifAnimatorDisplayLinkHolder.wrapper = self
        

        
//        CVDisplayLinkStart(link)
#endif
    }
    
#if os(iOS)
    
//    var oldTime = DispatchTime.now()
    
    @objc func renderFrame(displaylink: CADisplayLink) {
//        print(displaylink.timestamp, /*displaylink.targetTimestamp,*/ displaylink.duration)
//        eventInternalBlock?(displaylink.timestamp, /*displaylink.targetTimestamp,*/ displaylink.duration)
        displayLinkClick(timeStamp: displaylink.timestamp, duration: displaylink.duration)
        
//        let current = DispatchTime.now()
//        print("Current Time     ", current.uptimeNanoseconds,
//              "timeStamp       ", displaylink.timestamp,
//              "duration", displaylink.duration,
////              "targetTimestamp", displaylink.targetTimestamp,
//              "time from Prev", current.uptimeNanoseconds - oldTime.uptimeNanoseconds)
//        oldTime = current

    }
#else
    
    
    
    
//    var inNowTime: UInt64 = 0
//    var inOutputT: UInt64 = 0
    
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
        
        
        
//        if inOutputT == 0 {
//            inOutputT = inNow.pointee.hostTime
//        }
//
//
//        var timeBaseInfo = mach_timebase_info()
////        struct mach_timebase_info timeBaseInfo;
//        mach_timebase_info(&timeBaseInfo);
//
//        var clockFrequency = Double(timeBaseInfo.denom) / Double(timeBaseInfo.numer);
//        clockFrequency = clockFrequency * 100000.0;
        
//        let current = DispatchTime.now()
//        let deltaTime: TimeInterval = 1.0 / (inOutputTime.pointee.rateScalar * Double( inOutputTime.pointee.videoTimeScale) / Double(inOutputTime.pointee.videoRefreshPeriod));
//        var outTime = CVTimeStamp()
//        CVDisplayLinkGetCurrentTime(displayLink, &outTime)

//        let timeFromPrevUsingDL = (1.0 / Double(inOutputTime.pointee.hostTime - inNow.pointee.hostTime)) * clockFrequency
        
//        print("CurrentTime", current.uptimeNanoseconds,
////              "inNow Time       ", inNow.pointee.hostTime,
////              "inOutputTime Time", inOutputTime.pointee.hostTime,
////              "inOutputTime-inNow Time", inOutputTime.pointee.hostTime - inNow.pointee.hostTime,
////              "timefromPrev", current.uptimeNanoseconds - oldTime.uptimeNanoseconds,
////              "inNow from Prev", inNow.pointee.hostTime - inNowTime,
////              "inOutputTime from Prev", inOutputTime.pointee.hostTime - inOutputT,
////              "inNowTime - inOutputT", inOutputT - inNow.pointee.hostTime,
//              "deltaTime", deltaTime,
////              "outTime", outTime,
////              "clockFrequency", clockFrequency,
////              "timeFromPrevUsingDL", timeFromPrevUsingDL,
//              "rateScalar", inOutputTime.pointee.rateScalar,
//              "videoTimeScale", inOutputTime.pointee.videoTimeScale,
//              "videoRefreshPeriod", inOutputTime.pointee.videoRefreshPeriod
//        )

//        oldTime = current
//        inNowTime = inNow.pointee.hostTime
//        inOutputT = inOutputTime.pointee.hostTime
        
        
//        print("inNow", inNow.pointee)
//        print("inOutputTime", inOutputTime.pointee)
        
        
        let deltaTime: TimeInterval = 1.0 / (inOutputTime.pointee.rateScalar * dataHolderObj.videoTimeScaleOverRefreshPeriod);
        let timeStamp = Double(DispatchTime.now().uptimeNanoseconds) * 0.00000000001
        
        displayLinkClick(timeStamp: timeStamp, duration: deltaTime)
        return 0
    }
    
#endif
    
    private func startInternal() {
        guard let link = displaylink else { return }
#if os(iOS)
        link.add(to: .main, forMode: .default)
#else
//        dataHolderObj = DataHolder()
        CVDisplayLinkSetOutputCallback(link, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
            SwiftDisplayLinkWrapper.shared.dataSetupCallback(displayLink: displayLink, inNow: inNow, inOutputTime: inOutputTime, flagsIn: flagsIn, flagsOut: flagsOut, displayLinkContext: displayLinkContext)
        }, nil)
        CVDisplayLinkStart(link)
        
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
    }
    
    private func displayLinkClick(timeStamp: CFTimeInterval, duration: CFTimeInterval ) {
        for (_, callback) in eventBlocks {
            callback(timeStamp, duration)
        }
    }
    
}
