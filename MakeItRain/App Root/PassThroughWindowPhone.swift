//
//  PassThroughWindowPhone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//


import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
class PassThroughWindowPhone: UIWindow {
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        guard let rootView = rootViewController?.view else { return nil }
//
//        // Perform default hit test
//        let hitView = super.hitTest(point, with: event)
//        print("Initial hitView: \(hitView?.accessibilityIdentifier)")
//
//        // For iOS 26+, use layer hit testing logic
//        if #available(iOS 26, *) {
//            // Do a layer-level hit test to check if anything visible was hit
//            let layerHit = rootView.layer.hitTest(point)
//            print("layerHit.name: \(layerHit?.name)")
//
//            // If layerHit has no name, it’s probably a transparent SwiftUI region
//            if layerHit?.name == nil {
//                print("laterHit name is nil")
//                // Nothing meaningful hit — ignore this touch
//                return nil
//            }
//        } else {
//            // On older systems, skip root view itself
//            if hitView == rootView {
//                return nil
//            }
//        }
//
//        print("returning hitView")
//        return hitView
//    }
    
    /// Kavsoft / my hybrid that works with the alerts and rectange with 0.8 opacity... but does not work with toast.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
                
        if #available(iOS 26, *) {
            guard let view, _hitTest(point, from: view) != rootViewController?.view else { return nil }
        } else {
            guard view != rootViewController?.view else { return nil }
        }
        
        return view
    }
    
    
    /// Original iOS 18 version
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        let view = super.hitTest(point, with: event)
//        
//        if #available(iOS 18, *) {
//            guard let view, _hitTest(point, from: view) != rootViewController?.view else { return nil }
//        } else {
//            guard view != rootViewController?.view else { return nil }
//        }
//        
//        return view
//    }
    
    private func _hitTest(_ point: CGPoint, from view: UIView) -> UIView? {
        let converted = convert(point, to: view)
        guard view.bounds.contains(converted) && view.isUserInteractionEnabled && !view.isHidden && view.alpha > 0 else { return nil }
        
        return view.subviews.reversed()
            .reduce(Optional<UIView>.none) { result, view in
                result ?? _hitTest(point, from: view)
            } ?? view
    }
}
#endif


#if os(macOS)
class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}
#endif

