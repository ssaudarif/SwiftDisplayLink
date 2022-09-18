//
//  DisplayLinkTimerClock.swift
//  DemoApp
//
//  Created by Syed Saud Arif on 17/09/22.
//

import SwiftUI
import SwiftDisplayLink

struct TimerCount {
    var hours: Int
    var minutes: Int
    var seconds: Int
    var nanosecond: Int
    var nanoSecStr: String {
        return String(String(nanosecond).first ?? Character("0"))
    }

    var timer: String {
        "\(hours):\(minutes):\(seconds).\(nanoSecStr)"
    }

    mutating func increaseNanoSec(_ diff: Int) {
        nanosecond += (diff * 100000000)
        if nanosecond > 1000000000 {
            seconds += 1
            nanosecond -= 1000000000
        }
        if seconds > 60 {
            minutes += 1
            seconds -= 60
        }
        if minutes > 60 {
            hours += 1
            minutes -= 60
        }
    }

    init() {
        let date = Date() // save date, so all components use the same date
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)

        hours = calendar.component(.hour, from: date)
        minutes = calendar.component(.minute, from: date)
        seconds = calendar.component(.second, from: date)
        nanosecond = calendar.component(.nanosecond, from: date)
    }
}

struct DisplayLinkTimerClock: View {
    @State var timerCounter: TimerCount = TimerCount()

    let displayLink = SwiftDisplayLink(frameCount: 1, repeatFrames: true) { _ in
        SwiftDisplayLinkFrameData(duration: 0.1, isFrameConstructed: true)
    }

    var body: some View {
        Text(timerCounter.timer)// .font(.system(size: 36))
            .font(.custom( "DBLCDTempBlack", fixedSize: 36))
            .displayLinkAnchor(displayLink) { _, _ in
                timerCounter.increaseNanoSec(1)
            }
    }
}

struct DisplayLinkTimerClock_Previews: PreviewProvider {
    static var previews: some View {
        DisplayLinkTimerClock()
    }
}
