//
//  SimpleLoader.swift
//  DemoApp (iOS)
//
//  Created by Syed Saud Arif on 10/09/22.
//

import SwiftUI
import SwiftDisplayLink

struct SimpleLoader: View {
    static let anglesCount = 50
    static let angles:[Double] = {
        var tempAngles = [Double]()
        let multiplier: Double = Double.pi * (2.0 / Double(anglesCount))
        for i in 0...(anglesCount - 1) {
            tempAngles.append(multiplier * Double(i))
        }
        return tempAngles
    }()
    
    let displayLink = SwiftDisplayLink(frameCount: SimpleLoader.anglesCount, repeatFrames: true) { frame in
        SwiftDisplayLinkFrameData(duration: 0.016, isFrameConstructed: true)
    }
    
    
    @State var index:Int = 0
    var body: some View {
        Text("🌀").font(.system(size: 50))
            .rotationEffect(.radians(SimpleLoader.angles[index]))
            .displayLinkAnchor(displayLink) { event, frame in
                index = frame
            }
    }
}

struct SimpleLoader_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLoader()
    }
}
