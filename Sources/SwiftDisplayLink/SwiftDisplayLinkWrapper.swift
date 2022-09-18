//
//  SwiftDisplayLinkWrapper.swift
//  
//
//  Created by Syed Saud Arif on 11/09/22.
//

import Foundation
import QuartzCore

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
        if error != kCVReturnSuccess {
            Swift.print("Error: CVDisplayLinkCreateWithCGDisplay error")
            return
        }

        guard displaylink != nil else {
            Swift.print("Error: Failed to get displayLink")
            return
        }
#endif
    }

#if os(iOS)

    @objc func renderFrame(displaylink: CADisplayLink) {
        displayLinkClick(timeStamp: displaylink.timestamp, duration: displaylink.duration)
    }
#else

    func dataSetupCallback( displayLink: CVDisplayLink,
                            inNow: UnsafePointer<CVTimeStamp>,
                            inOutputTime: UnsafePointer<CVTimeStamp>,
                            flagsIn: UInt64,
                            flagsOut: UnsafeMutablePointer<UInt64>,
                            displayLinkContext: UnsafeMutableRawPointer?
                        ) -> Int32 {

        let videoTimeScaleOverRefreshPeriod = Double( inOutputTime.pointee.videoTimeScale) / Double(inOutputTime.pointee.videoRefreshPeriod)
        dataHolderObj = DataHolder(oldTime: DispatchTime.now(), videoTimeScaleOverRefreshPeriod: videoTimeScaleOverRefreshPeriod)

        CVDisplayLinkSetOutputCallback(displayLink, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
            SwiftDisplayLinkWrapper.shared.renderCallback(displayLink: displayLink,
                                                          inNow: inNow,
                                                          inOutputTime: inOutputTime,
                                                          flagsIn: flagsIn,
                                                          flagsOut: flagsOut,
                                                          displayLinkContext: displayLinkContext)
        }, nil)
        return 0
    }

    func renderCallback(
        displayLink: CVDisplayLink,
        inNow: UnsafePointer<CVTimeStamp>,
        inOutputTime: UnsafePointer<CVTimeStamp>,
        flagsIn: UInt64,
        flagsOut: UnsafeMutablePointer<UInt64>,
        displayLinkContext: UnsafeMutableRawPointer?
    ) -> Int32 {

        let deltaTime: TimeInterval = 1.0 / (inOutputTime.pointee.rateScalar * dataHolderObj.videoTimeScaleOverRefreshPeriod)
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
        CVDisplayLinkSetOutputCallback(link, { displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext in
            SwiftDisplayLinkWrapper.shared.dataSetupCallback(displayLink: displayLink,
                                                             inNow: inNow,
                                                             inOutputTime: inOutputTime,
                                                             flagsIn: flagsIn,
                                                             flagsOut: flagsOut,
                                                             displayLinkContext: displayLinkContext)
        }, nil)
        CVDisplayLinkStart(link)

#endif
    }

    private func stopInternal() {
        guard let link = displaylink else { return }
#if os(iOS)
        link.invalidate()
#else
        CVDisplayLinkStop(link)
#endif
    }
}

extension SwiftDisplayLinkWrapper {

    func setUpFrameStart() {
        // empty for now, may come handy in future.
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
