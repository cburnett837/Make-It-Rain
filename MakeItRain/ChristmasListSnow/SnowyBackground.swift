//
//  Backgrounds.swift
//  Christmas List
//
//  Created by Cody Burnett on 11/28/23.
//

import Foundation
import SwiftUI
import SpriteKit

struct SnowyBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("enableSnow") private var enableSnow = false
    let blurred: Bool
    let withSnow: Bool
    
    @State private var startSnowing = false
    
    var body: some View {
        ZStack {
            Image(colorScheme == .dark ? "Snowman1" : "background-light")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: blurred ? 18 : 0)
            
            if withSnow {
                SpriteView(scene: SnowScene.scene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .opacity(startSnowing ? 1 : 0)
            }
        }
        .task {
            /// Prevent the white flash that happens when the SpriteView renders without a delay.
            if withSnow {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startSnowing = true
                }
            }
        }
    }
}
