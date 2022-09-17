//
//  ContentView.swift
//  Shared
//
//  Created by Syed Saud Arif on 19/08/22.
//

import SwiftUI

struct ContentView: View {
    
    @State private var isShowingRotatorsView = false
    @State private var isTimerCompareView = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: StackOfRotators(),
                               isActive: $isShowingRotatorsView) {
                    
                    Text("Tap to see Rotators...").onTapGesture {
                        isShowingRotatorsView = true
                    }
                }
                NavigationLink(destination: TimerCompareView(),
                               isActive: $isTimerCompareView) {
                    
                    Text("Tap to see Timer...").onTapGesture {
                        isTimerCompareView = true
                    }
                }
            }.padding()
            .navigationTitle("Demo Of SwiftDisplayLink")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
