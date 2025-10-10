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
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if #available(iOS 26, *) {
            guard let view, _hitTest(point, from: view) != rootViewController?.view else { return nil }
        } else {
            guard view != rootViewController?.view else { return nil }
        }
        
        return view
        
        guard let hitView = super.hitTest(point, with: event),
                let rootView = rootViewController?.view
        else { return nil }

        if #available(iOS 26, *) {
            if rootView.layer.hitTest(point)?.name == nil {
                return rootView
            } else {
                return nil
            }
        } else {
            if #available(iOS 18, *) {
                for subview in rootView.subviews.reversed() {
                    /// Finding if any of rootview's is receving hit test
                    let pointInSubView = subview.convert(point, from: rootView)
                    if subview.hitTest(pointInSubView, with: event) != nil {
                        return hitView
                    }
                }
                
                return nil
            } else {
                return hitView == rootView ? nil : hitView
            }
        }
    }
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        guard let rootView = rootViewController?.view else {
//            return nil
//        }
//        
//        if rootView.layer.hitTest(point)?.name == nil {
//            return rootView
//        } else {
//            // pass through the touch to the window below
//            return nil
//        }
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

