//
//  TimerClock.swift
//  DemoApp
//
//  Created by Syed Saud Arif on 17/09/22.
//

import SwiftUI
import SwiftDisplayLink

struct TimerClock: View {

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State var timerStr: String = "00:00:00.0"

    private static var valueFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        Text(timerStr)
            .font(.custom( "DBLCDTempBlack", fixedSize: 36))
            .onReceive(timer) { _ in
                let date = Date() // save date, so all components use the same date
                let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)

                let hours = calendar.component(.hour, from: date)
                let minutes = calendar.component(.minute, from: date)
                let seconds = calendar.component(.second, from: date)
                let nanosecond = calendar.component(.nanosecond, from: date)
                let namoSecStr = String(nanosecond).first ?? "0"
                // Self.valueFormatter.string(from: NSNumber.init(value: nanosecond))
                timerStr = "\(hours):\(minutes):\(seconds).\(namoSecStr)"
            }
    }
}

struct TimerClock_Previews: PreviewProvider {
    static var previews: some View {
        TimerClock()
    }
}
