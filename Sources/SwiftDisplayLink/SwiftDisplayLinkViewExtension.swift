//
//  SwiftUIView.swift
//  
//
//  Created by Syed Saud Arif on 10/09/22.
//

import SwiftUI

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public extension View {
    func displayLinkAnchor(_ link: SwiftDisplayLink, _ eventCallback: @escaping(SwiftDisplayLinkEventBlock)) -> Self {
        if link.isPlaying {
            link.eventCallBlock = eventCallback
        } else {
            link.play(eventCallback)
        }
        return self
    }
}
