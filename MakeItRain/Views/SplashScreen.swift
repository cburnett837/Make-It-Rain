//
//  SplashScreen.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/20/24.
//

import SwiftUI
import SpriteKit

@MainActor
struct SplashScreen: View {
    
    @State private var logoScale: Double = 1
    
    var body: some View {
        ZStack {
            
//            SpriteView(scene: DollarScene.scene, options: [.allowsTransparency])
//                .ignoresSafeArea()
//                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            
            EmitterView()
                .scaleEffect(1, anchor: .top)
                .ignoresSafeArea()
                #if os(macOS)
                .rotationEffect(Angle(degrees: 180))
                #endif
                //.blur(radius: 1)
//            
            VStack {
                Spacer()
                
                Text("Make it Rain")
                    .scaleEffect(logoScale)
                    .transition(.asymmetric(insertion: .scale, removal: .opacity)) // top
                    .font(.title)
                    .foregroundStyle(.primary)
                    
                Spacer()
            }
//            .task {
//                withAnimation(.easeIn(duration: 2)) {
//                    logoScale = 1
//                }
//            }
        }
        #if os(iOS)
        .standardBackground()
        #endif
    }
}

class DollarScene: SKScene {
    let snowEmitterNode = SKEmitterNode(fileNamed: "DollarPartical.sks")

    override func didMove(to view: SKView) {
        guard let snowEmitterNode = snowEmitterNode else { return }
        snowEmitterNode.particleSize = CGSize(width: 50, height: 50)
        snowEmitterNode.particleLifetime = 2
        snowEmitterNode.particleLifetimeRange = 6
        addChild(snowEmitterNode)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard let snowEmitterNode = snowEmitterNode else { return }
        snowEmitterNode.particlePosition = CGPoint(x: size.width/2, y: size.height)
        snowEmitterNode.particlePositionRange = CGVector(dx: size.width, dy: size.height)
    }
    
    static var scene: SKScene {
        let scene = DollarScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}
