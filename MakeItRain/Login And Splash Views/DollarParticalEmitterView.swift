//
//  DollarParticalEmitterView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/20/24.
//

import Foundation
import SwiftUI

#if os(iOS)
struct EmitterView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
                
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .line
        emitterLayer.emitterCells = createEmiterCells()
        
        emitterLayer.emitterSize = CGSize(width: getRect().width, height: 1)
        emitterLayer.emitterPosition = CGPoint(x: getRect().width / 2, y: -96)
        
        view.layer.addSublayer(emitterLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    func createEmiterCells() -> [CAEmitterCell] {
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "cartoon_dollar_bill")?.cgImage
        //cell.color = UIColor.red.cgColor
        cell.birthRate = 4
        cell.lifetime = 10
        cell.velocity = 120
        cell.velocityRange = 100
        cell.scale = 0.1
        //cell.scaleRange = 0.05
        cell.emissionLongitude = .pi
        cell.emissionRange = 0.5
        cell.spin = 3.5
        cell.spinRange = 1
        
        return [cell]
    }
}



#else
struct EmitterView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        //view.layer?.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        //view.layer = CALayer()
        //view.window?.backgroundColor = NSColor.clear
        
        
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .line
        emitterLayer.emitterCells = createEmiterCells()
        //UIScreen.main.bounds
        emitterLayer.emitterSize = CGSize(width: NSScreen.main?.frame.width ?? 0, height: 1)
        emitterLayer.emitterPosition = CGPoint(x: (NSScreen.main?.frame.width ?? 0) / 2, y: 0)
        
        view.layer?.addSublayer(emitterLayer)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
    func createEmiterCells()->[CAEmitterCell] {
        let cell = CAEmitterCell()
        //cell.contents = NSImage(named: "cartoon_dollar_bill")?.cgImage
        
        cell.contents = NSImage(named:"cartoon_dollar_bill").flatMap {
            return $0.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        
        //cell.color = UIColor.red.cgColor
        cell.birthRate = 4
        cell.lifetime = 10
        cell.velocity = 120
        cell.velocityRange = 100
        cell.scale = 0.1
        //cell.scaleRange = 0.05
        cell.emissionLongitude = .pi
        cell.emissionRange = 0.5
        cell.spin = 3.5
        cell.spinRange = 5
        
        return [cell]
    }
}




//struct EmitterView: NSViewRepresentable {
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        view.backgroundColor = .clear
//
//
//        let emitterLayer = CAEmitterLayer()
//        emitterLayer.emitterShape = .line
//        emitterLayer.emitterCells = createEmiterCells()
//
//        emitterLayer.emitterSize = CGSize(width: getRect().width, height: 1)
//        emitterLayer.emitterPosition = CGPoint(x: getRect().width / 2, y: 0)
//
//        view.layer.addSublayer(emitterLayer)
//
//        return view
//    }
//
//    func updateNSView(_ uiView: NSView, context: Context) {
//
//    }
//
//    func createEmiterCells()->[CAEmitterCell] {
//        let cell = CAEmitterCell()
//        cell.contents = UIImage(named: "dollar")?.cgImage
//        //cell.color = UIColor.red.cgColor
//        cell.birthRate = 4
//        cell.lifetime = 10
//        cell.velocity = 120
//        cell.scale = 0.02
//        //cell.scaleRange = 0.05
//        cell.emissionLongitude = .pi
//        cell.emissionRange = 0.5
//        cell.spin = 3.5
//        cell.spinRange = 1
//
//        return [cell]
//    }
//}
#endif
