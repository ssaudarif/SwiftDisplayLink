import XCTest
@testable import SwiftDisplayLink

final class SwiftDisplayLinkTests: XCTestCase {
    
    func testEventOccuredGettingFired() throws {
        
        let expectation = expectation(description: "Waitimg for events for each frame to get fired.")
        
        var timeStampsForPerformAction = [DispatchTime]()
        var frameCounter = [Int]()
        
        let displayLink = SwiftDisplayLink(frameCount: 10) { frame in
            SwiftDisplayLinkFrameData(duration: 0.1, isFrameConstructed: true)
        }
        
        //Collecting this time too so that we can find out how much time it takes to fire the first frame.
        timeStampsForPerformAction.append(DispatchTime.now())
        
        displayLink.play { event, frame  in
            if case .performAction( _, _) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                frameCounter.append(frame)
                if frame == 9 {
                    expectation.fulfill()
                }
            }
            if case .constructFrame = event {
                XCTAssert(false, "The construct frame should not get called as we are passing isFrameConstructed = true in SwiftDisplayLinkFrameData")
            }
        }
        
        waitForExpectations(timeout: 1.0)
        
        let countOfTimeStamps = timeStampsForPerformAction.count
        for index in 1..<countOfTimeStamps-1 {
            let timeIntervalInNanoSecs = timeStampsForPerformAction[index + 1].uptimeNanoseconds - timeStampsForPerformAction[index].uptimeNanoseconds
            //The below code might overflow if the test is too long.
            let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
            XCTAssert(0.09 < timeInterval && timeInterval < 0.11, "The time interval which is - \(timeInterval) was expected to be around 0.1 (± 0.01)")
        }
    }
    
    
    func testWhenFirstEventIsCalled() throws {
        
        let expectation = expectation(description: "Waitimg for events for each frame to get fired.")
        
        var timeStampForFirstAction = DispatchTime.now()
        
        let displayLink = SwiftDisplayLink(frameCount: 2) { frame in
            SwiftDisplayLinkFrameData(duration: 0.1, isFrameConstructed: true)
        }
        
        //Collecting this time too so that we can find out how much time it takes to fire the first frame.

        let timeStampBeforePlay = DispatchTime.now()
        displayLink.play { event, frame  in
            if case .performAction( _, _) = event {
                timeStampForFirstAction = DispatchTime.now()
                expectation.fulfill()
            }
            if case .constructFrame = event {
                XCTAssert(false, "The construct frame should not get called as we are passing isFrameConstructed = true in SwiftDisplayLinkFrameData")
            }
        }
        
        waitForExpectations(timeout: 0.2)
        
        let timeIntervalInNanoSecs = timeStampForFirstAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        //The below code might overflow if the test is too long.
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(0.01 < timeInterval && timeInterval < 0.03, "The time interval which is - \(timeInterval) was expected to be between 0.01 & 0.08") //keeping this well relaxed...
    }
}
