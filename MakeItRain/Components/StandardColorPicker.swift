//
//  CustomColorPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/5/25.
//

import Foundation
import SwiftUI

#if os(iOS)
struct StandardColorPicker: View {
    @Binding var color: Color
    
    @State private var showColorPicker = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            #if os(macOS)
            .frame(minHeight: 27)
            #else
            .frame(minHeight: 34)
            #endif
            .onTapGesture { showColorPicker = true }
            .colorPickerSheet(isPresented: $showColorPicker, selection: $color, supportsAlpha: false)
    }
}


extension View {
    public func colorPickerSheet(isPresented: Binding<Bool>, selection: Binding<Color>, supportsAlpha: Bool = true, title: String? = nil) -> some View {
        self.background(ColorPickerSheet(isPresented: isPresented, selection: selection, supportsAlpha: supportsAlpha, title: title))
    }
}


private struct ColorPickerSheet: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var selection: Color
    var supportsAlpha: Bool
    var title: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, isPresented: $isPresented)
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        @Binding var selection: Color
        @Binding var isPresented: Bool
        var didPresent = false
        
        init(selection: Binding<Color>, isPresented: Binding<Bool>) {
            self._selection = selection
            self._isPresented = isPresented
        }
        
        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            selection = Color(viewController.selectedColor)
        }
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            isPresented = false
            didPresent = false
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
            didPresent = false
        }
    }

    func getTopViewController(from view: UIView) -> UIViewController? {
        guard var top = view.window?.rootViewController else {
            return nil
        }
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPresented && !context.coordinator.didPresent {
            let modal = UIColorPickerViewController()
            modal.selectedColor = UIColor(selection)
            modal.supportsAlpha = supportsAlpha
            modal.title = title
            modal.delegate = context.coordinator
            modal.presentationController?.delegate = context.coordinator
            let top = getTopViewController(from: uiView)
            top?.present(modal, animated: true)
            context.coordinator.didPresent = true
        }
    }
}
#endif

//
//private struct ColorPickerSheet: NSViewRepresentable {
//    @Binding var isPresented: Bool
//    @Binding var selection: Color
//    var supportsAlpha: Bool
//    var title: String?
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(selection: $selection, isPresented: $isPresented)
//    }
//    
//    class Coordinator: NSObject, NSColorPickerViewControllerDelegate, NSAdaptivePresentationControllerDelegate {
//        @Binding var selection: Color
//        @Binding var isPresented: Bool
//        var didPresent = false
//        
//        init(selection: Binding<Color>, isPresented: Binding<Bool>) {
//            self._selection = selection
//            self._isPresented = isPresented
//        }
//        
//        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
//            selection = Color(viewController.selectedColor)
//        }
//        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
//            isPresented = false
//            didPresent = false
//        }
//        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//            isPresented = false
//            didPresent = false
//        }
//    }
//
//    func getTopViewController(from view: UIView) -> UIViewController? {
//        guard var top = view.window?.rootViewController else {
//            return nil
//        }
//        while let next = top.presentedViewController {
//            top = next
//        }
//        return top
//    }
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.isHidden = true
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        if isPresented && !context.coordinator.didPresent {
//            let modal = UIColorPickerViewController()
//            modal.selectedColor = UIColor(selection)
//            modal.supportsAlpha = supportsAlpha
//            modal.title = title
//            modal.delegate = context.coordinator
//            modal.presentationController?.delegate = context.coordinator
//            let top = getTopViewController(from: uiView)
//            top?.present(modal, animated: true)
//            context.coordinator.didPresent = true
//        }
//    }
//}
