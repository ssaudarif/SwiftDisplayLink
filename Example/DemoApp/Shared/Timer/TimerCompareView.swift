//
//  TimerCompareView.swift
//  
//
//  Created by Syed Saud Arif on 17/09/22.
//

import SwiftUI

struct TimerCompareView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Actual Time")
            TimerClock()
            Spacer()
            Text("Display Link")
            DisplayLinkTimerClock()
            Spacer()
        }
    }
}

struct TimerCompareView_Previews: PreviewProvider {
    static var previews: some View {
        TimerCompareView()
    }
}
