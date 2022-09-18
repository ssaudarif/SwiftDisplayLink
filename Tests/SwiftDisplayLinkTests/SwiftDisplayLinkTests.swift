import XCTest
@testable import SwiftDisplayLink

final class SwiftDisplayLinkTests: XCTestCase {
    
    override func setUpWithError() throws {
        XCTAssert( SwiftDisplayLinkWrapper.shared.isPlaying == false )
    }
    
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

        waitForExpectations(timeout: 1.0 + 0.1)

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
                if frame == 0 {
                    timeStampForFirstAction = DispatchTime.now()
                }
                if frame == 1 {
                    expectation.fulfill()
                }
            }
            if case .constructFrame = event {
                XCTAssert(false, "The construct frame should not get called as we are passing isFrameConstructed = true in SwiftDisplayLinkFrameData")
            }
        }

        waitForExpectations(timeout: 0.2 + 0.1)

        let timeIntervalInNanoSecs = timeStampForFirstAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        //The below code might overflow if the test is too long.
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(0.01 < timeInterval && timeInterval < 0.2, "The time interval which is - \(timeInterval) was expected to be between 0.01 & 0.2") //keeping this well relaxed...
    }
    
    
    func testFrameConstructionIsAlsoCalled() throws {

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

        waitForExpectations(timeout: 1.0 + 0.05)
        
        let timeStampForLastAction = DispatchTime.now()
        
        let timeIntervalInNanoSecs = timeStampForLastAction.uptimeNanoseconds - timeStampBeforePlay.uptimeNanoseconds
        let timeInterval = Double(timeIntervalInNanoSecs) / 1_000_000_000
        XCTAssert(timeInterval < (1.0 + 0.05) && timeInterval > 0.9)
        
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
        XCTAssert(timeInterval < 1.05 && timeInterval > 1.0)
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
            if case .performAction( _, _) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                frameCounter.append(frame)
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

        waitForExpectations(timeout: 2.0 + 0.02)
        
        XCTAssert(frameCounter.count == 100)
    }
    
    func testChangedDuration() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        var timeStampsForPerformAction = [DispatchTime]()
        let displayLink = SwiftDisplayLink(frameCount: 5, repeatFrames: true) { frame in
            SwiftDisplayLinkFrameData(duration: 0.02 * Double(frame + 1), isFrameConstructed: true)
        }
        var counter = 0
        timeStampsForPerformAction.append(DispatchTime.now())

        displayLink.play { event, frame  in
            if case .performAction( _, _) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                if frame == 4 {
                    counter = counter + 1
                    if counter == 2 {
                        displayLink.invalid()
                        expect.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 4.01)
        
        // The time must be around these values...
        let durationsExpected = [(0.01, 0.20), //0 -> 0.02 But as this is first event. Keeping things relaxed.
                                 (0.025, 0.055), //1 -> 0.04
                                 (0.045, 0.075), //2 -> 0.06
                                 (0.065, 0.095), //3 -> 0.08
                                 (0.085, 0.115), //4 -> 0.10
                                 (0.005, 0.035), //0 -> 0.02
                                 (0.025, 0.055), //1 -> 0.04
                                 (0.045, 0.075), //2 -> 0.06
                                 (0.065, 0.095), //3 -> 0.08
                                 (0.085, 0.115), //4 -> 0.10
        ]
        
        for i in 1...10 {
            let difference = timeStampsForPerformAction[i].uptimeNanoseconds - timeStampsForPerformAction[i-1].uptimeNanoseconds
            let timeInterval = Double(difference) / 1_000_000_000
            XCTAssert(timeInterval > durationsExpected[i-1].0,
                      "index:\(i) failed, timeInterval:\(timeInterval) should be greater than \(durationsExpected[i-1].0)")
            XCTAssert(timeInterval < durationsExpected[i-1].1,
                      "index:\(i) failed, timeInterval:\(timeInterval) should be less than \(durationsExpected[i-1].1)")
        }
        
    }
    
    func testFirstDuration() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        var timeStampsForPerformAction = [DispatchTime]()
        let displayLink = SwiftDisplayLink(frameCount: 1, repeatFrames: false) { frame in
            SwiftDisplayLinkFrameData(duration: 1.0, isFrameConstructed: true)
        }
        timeStampsForPerformAction.append(DispatchTime.now())

        displayLink.play { event, frame  in
            if case .performAction = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0 + 0.02)
        
        XCTAssert(timeStampsForPerformAction.count == 2)
        let difference = timeStampsForPerformAction[1].uptimeNanoseconds - timeStampsForPerformAction[0].uptimeNanoseconds
        let timeInterval = Double(difference) / 1_000_000_000
        XCTAssert(timeInterval >= 0.95 && timeInterval < 1.03)
        
    }
    
    func testPauseResumeDuration() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        var timeStampsForPerformAction = [DispatchTime]()
        let displayLink = SwiftDisplayLink(frameCount: 1, repeatFrames: true) { frame in
            SwiftDisplayLinkFrameData(duration: 1.0, isFrameConstructed: true)
        }
        timeStampsForPerformAction.append(DispatchTime.now())

        var counter = 0
        var dispatchEventBlock: SwiftDisplayLinkEventBlock = { event, frame  in } // dummy declaraion as we need to use dispatchEventBlock again inside the block.
        
        dispatchEventBlock = { event, frame  in
            if case .performAction = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                counter = counter + 1
                if counter % 2 == 1 {
                    displayLink.pause()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                        if counter != 7 {
                            displayLink.play(dispatchEventBlock)
                        }
                    }
                }
                if counter == 7 {
                    expect.fulfill()
                    displayLink.invalid()
                }
            }
        }
        
        displayLink.play(dispatchEventBlock)
        
        // first call -> 1.0, frame = 0 -> counter = 1, pause -> 1.0 -> play    =   2.0
        // second call-> 1.0, frame = 2 -> counter = 2                          =   1.0
        // third call -> 1.0, frame = 3 -> counter = 3, pause -> 1.0 -> play    =   2.0
        // fourth call-> 1.0, frame = 4 -> counter = 4                          =   1.0
        // fifth call -> 1.0, frame = 5 -> counter = 5, pause -> 1.0 -> play    =   2.0
        // sixth call -> 1.0, frame = 6 -> counter = 6                          =   1.0
        // seven call -> 1.0, frame = 7 -> counter = 7, pause                   =   1.0
        //                                                               Total  =  10.0
        
        waitForExpectations(timeout: 10.5)
        
        
    }
    
    func testDurationWithEachEvent() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        var timeStampsForPerformAction = [DispatchTime]()
        let displayLink = SwiftDisplayLink(frameCount: 5, repeatFrames: true) { frame in
            SwiftDisplayLinkFrameData(duration: 0.02 * Double(frame + 1), isFrameConstructed: true)
        }
        var counter = 0
        timeStampsForPerformAction.append(DispatchTime.now())
        
        // The time must be around these values...
        let durationsExpected = [(0.01, 0.20), //0 -> 0.02 But as this is first event. Keeping things relaxed.
                                 (0.025, 0.055), //1 -> 0.04
                                 (0.045, 0.075), //2 -> 0.06
                                 (0.065, 0.095), //3 -> 0.08
                                 (0.085, 0.115)  //4 -> 0.10
        ]

        displayLink.play { event, frame  in
            if case let .performAction( _, duration) = event {
                timeStampsForPerformAction.append(DispatchTime.now())
                XCTAssert(duration > durationsExpected[frame].0 && duration < durationsExpected[frame].1, "Failed for frame \(frame), duration = \(duration)")
                if frame == 4 {
                    counter = counter + 1
                    if counter == 2 {
                        displayLink.invalid()
                        expect.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 4.01)
        

    }
    
    
    func testCreateFrameCallForEachEvent() throws {
        let expect = expectation(description: "Waitimg for events for each frame to get fired.")

        let displayLink = SwiftDisplayLink(frameCount: 10, repeatFrames: false) { frame in
            SwiftDisplayLinkFrameData(duration: 0.02, isFrameConstructed: false)
        }
        
        var checkerArray:[Int] = []
        
        displayLink.play { event, frame  in
            if case .performAction = event {
                XCTAssert(checkerArray[frame] == 1)
                if frame == 9 {
                    expect.fulfill()
                }
            }
            else if case .constructFrame = event {
                checkerArray.append(1)
            }
        }
        
        waitForExpectations(timeout: 0.22)
        
    }

}

