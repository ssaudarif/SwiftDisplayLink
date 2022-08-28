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

        //check why the displayLink has reference count 2 at this place.

        //Collecting this time too so that we can find out how much time it takes to fire the first frame.
        timeStampsForPerformAction.append(DispatchTime.now())

        displayLink.play { event, frame  in
            if case let .performAction( timestamp, _) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                frameCounter.append(frame)
                print(frame, timestamp)

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
        XCTAssert( SwiftDisplayLinkWrapper.shared.isPlaying == false )

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
                if frame == 1 {
                    expectation.fulfill()
                }
            }
            if case .constructFrame = event {
                XCTAssert(false, "The construct frame should not get called as we are passing isFrameConstructed = true in SwiftDisplayLinkFrameData")
            }
        }

        waitForExpectations(timeout: 0.2)

        let timeIntervalInNanoSecs = timeStampForFirstAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        //The below code might overflow if the test is too long.
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(0.01 < timeInterval && timeInterval < 0.2, "The time interval which is - \(timeInterval) was expected to be between 0.01 & 0.2") //keeping this well relaxed...
    }
    
    
    func testFrameConstructionIsAlsoCalled() throws {
        XCTAssert( SwiftDisplayLinkWrapper.shared.isPlaying == false )

        let expectation = expectation(description: "Waitimg for events for each frame to get fired.")

        let displayLink = SwiftDisplayLink(frameCount: 20) { frame in
            SwiftDisplayLinkFrameData(duration: 0.05, isFrameConstructed: false)
        }

        //Collecting this time too so that we can find out how much time it takes to fire the first frame.
        var arrayIsConstructed:[Int] = [Int]()

        let timeStampBeforePlay = DispatchTime.now()
        displayLink.play { event, frame  in
            if case .performAction( _, _) = event {
                if frame == 19 { expectation.fulfill() }
                XCTAssert(arrayIsConstructed[frame] == 1)
                arrayIsConstructed[frame] = 2
            }
            
            if case .constructFrame = event {
                arrayIsConstructed.append(1)
            }
        }

        waitForExpectations(timeout: 1.1)
        
        let timeStampForLastAction = DispatchTime.now()
        let timeIntervalInNanoSecs = timeStampForLastAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(timeInterval < 1.01 && timeInterval > 0.9)
        
        XCTAssert(arrayIsConstructed.count == 20)
        XCTAssert(arrayIsConstructed.filter({ i in i == 2 }).count == 20 )
    }

    func testmultipleLinks() throws {
        
        var counter = 0
        func runDisplaylink() throws {
            let expectation = expectation(description: "Waitimg for events for each frame to get fired.")
            let displayLink = SwiftDisplayLink(frameCount: 20) { frame in
                SwiftDisplayLinkFrameData(duration: 0.05, isFrameConstructed: true)
            }
            displayLink.play { event, frame  in
                if case .performAction( _, _) = event {
                    counter = counter + 1
                    if frame == 19 { expectation.fulfill() }
                }
            }
        }
        
        XCTAssert( SwiftDisplayLinkWrapper.shared.isPlaying == false )
        
        let timeStampBeforePlay = DispatchTime.now()
        for _ in 0..<100 {
            try runDisplaylink()
        }
        waitForExpectations(timeout: 1.1)
        
        let timeStampForLastAction = DispatchTime.now()
        let timeIntervalInNanoSecs = timeStampForLastAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(timeInterval < 1.01 && timeInterval > 0.9)
        XCTAssert(counter == 2000)
    }
    
    func testPausePlay() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")
        var expect2: XCTestExpectation? = nil

        var timeStampsForPerformAction = [DispatchTime]()
        var frameCounter = [Int]()

        let displayLink = SwiftDisplayLink(frameCount: 20) { frame in
            SwiftDisplayLinkFrameData(duration: 0.1, isFrameConstructed: true)
        }

        //check why the displayLink has reference count 2 at this place.

        //Collecting this time too so that we can find out how much time it takes to fire the first frame.
        timeStampsForPerformAction.append(DispatchTime.now())

        displayLink.play { event, frame  in
            if case let .performAction( timestamp, _) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                frameCounter.append(frame)
                print(frame, timestamp)
                if frame == 9 {
                    displayLink.pause()
                    expect.fulfill()
                }
                if frame == 19 {
                    displayLink.pause()
                    expect2?.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 1.1)
        displayLink.resume()
        
        expect2 = expectation(description: "Waitimg for events for each frame to get fired.")
        waitForExpectations(timeout: 1.1)

        let countOfTimeStamps = timeStampsForPerformAction.count
        for index in 1..<countOfTimeStamps-1 {
            let timeIntervalInNanoSecs = timeStampsForPerformAction[index + 1].uptimeNanoseconds - timeStampsForPerformAction[index].uptimeNanoseconds
            //The below code might overflow if the test is too long.
            let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
            XCTAssert(0.09 < timeInterval && timeInterval < 0.11, "The time interval which is - \(timeInterval) was expected to be around 0.1 (± 0.01)")
        }
        
    }
    
    func testrepeatTimer() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        var frameCounter = [Int]()
        let displayLink = SwiftDisplayLink(frameCount: 5, repeatFrames: true) { frame in
            SwiftDisplayLinkFrameData(duration: 0.02, isFrameConstructed: true)
        }

        displayLink.play { event, frame  in
            if case .performAction( _, _) = event {
                frameCounter.append(frame)
                if frameCounter.count == 100 {
                    displayLink.invalid()
                    expect.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 2.01)
        
        XCTAssert(frameCounter.count == 100)        
    }
    
}

