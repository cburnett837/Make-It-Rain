//
//  Extensions+View.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/25.
//

import Foundation
import SwiftUI


extension View {
    #if os(iOS)
    func disableZoomInteractiveDismiss() -> some View {
        self.background(RemoveZoomDismissGestures())
    }
    #endif
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    #if os(iOS)
    @ViewBuilder func viewExtractor(result: @escaping (UIView) -> ()) -> some View {
        self
            .background(ViewExtractorHelper(result: result))
            .compositingGroup()
    }
    #endif
    
    func formatCurrencyLiveAndOnUnFocus(focusValue: Int, focusedField: Int?, amountString: String?, amountStringBinding: Binding<String>, amount: Double?) -> some View {
        /// This will format the text with a $ or a -$ on the front when typing, and then fully format the text with decimals, and commas when unfocusing the textfield, or when clicking enter (macOS).
        modifier(FormatCurrencyLiveAndOnUnFocus(focusValue: focusValue, focusedField: focusedField, amountString: amountString, amountStringBinding: amountStringBinding, amount: amount))
    }
    
    #if os(iOS)
    func calculateAndFormatCurrencyLiveAndOnUnFocus(focusValue: Int, focusedField: Int?, amountString: String?, amountStringBinding: Binding<String>, amount: Double?) -> some View {
        /// This will format the text with a $ or a -$ on the front when typing, and then fully format the text with decimals, and commas when unfocusing the textfield, or when clicking enter (macOS).
        modifier(CalculateAndFormatCurrencyLiveAndOnUnFocus(focusValue: focusValue, focusedField: focusedField, amountString: amountString, amountStringBinding: amountStringBinding, amount: amount))
    }
    #endif
    
        
    func toast() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast = AppState.shared.toast {
                    ToastView(toast: toast)
                }
            }
            .accessibilityIdentifier("UniversalToastContent")
    }
    
    #if os(macOS)
    func toolbarKeyboard(padding: Double = 6, alignment: TextAlignment = .leading) -> some View {
        modifier(ToolbarKeyboard(padding: padding, alignment: alignment))
    }
    
    func toolbarBorder() -> some View {
        modifier(ToolbarBorder())
    }
    #endif
    
    func chevronMenuOverlay() -> some View {
        modifier(ChevronMenuOverlay())
    }
    
    func maxViewWidthObserver() -> some View {
        modifier(MaxViewWidthObserver())
    }
    
    func maxChartWidthObserver() -> some View {
        modifier(MaxChartWidthObserver())
    }
    
    func maxViewHeightObserver() -> some View {
        modifier(MaxViewHeightObserver())
    }
    
    func transMaxViewHeightObserver() -> some View {
        modifier(TransMaxViewHeightObserver())
    }
    
    func viewWidthObserver() -> some View {
        modifier(ViewWidthObserver())
    }
    
    func viewHeightObserver() -> some View {
        modifier(ViewHeightObserver())
    }
    
    func calendarLoadingSpinner(id: NavDestination, text: String) -> some View {
        modifier(CalendarLoadingSpinner(id: id, text: text))
    }
    
    func calendarLoadingSpinner(id: NavDestination) -> some View {
        modifier(CalendarLoadingSpinner(id: id))
    }
    
    #if os(iOS)
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
    
    
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
    
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
    #endif
   
    
    func schemeBasedForegroundStyle(isDisabled: Bool = false) -> some View {
        modifier(SchemeBasedForegroundStyle(isDisabled: isDisabled))
    }
    
    func schemeBasedTint() -> some View {
        modifier(SchemeBasedTint())
    }
    
    func animatedLineChart<ChartContent: View>(beginAnimation: Bool, _ chart: @escaping (_ showLines: Bool) -> ChartContent) -> some View {
        modifier(AnimatedLineChart(beginAnimation: beginAnimation, chart: chart))
    }
    
    #if os(macOS)
    func questionCursor() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor(image: NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "")!, hotSpot: .zero).set()

                //NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .foregroundStyle(.red)
    }
    #endif
}


#if os(iOS)
fileprivate struct RemoveZoomDismissGestures: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        removeGestures(from: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func removeGestures(from view: UIView) {
        DispatchQueue.main.async {
            
//            if let zoomViewController = view.viewController {
//                print(zoomViewController.view.gestureRecognizers?.compactMap({$0.name}))
//            }
            
            if let zoomViewControllerView = view.viewController?.view {
                zoomViewControllerView
                    .gestureRecognizers?
                    .removeAll(where: {
                        $0.name == "com.apple.UIKit.ZoomInteractiveDismissSwipeDown" ||
                        $0.name == "com.apple.UIKit.ZoomInteractiveDismissPinch"
                    })
            }
        }
    }
}
#endif


#if os(iOS)
fileprivate struct ViewExtractorHelper: UIViewRepresentable {
    var result: (UIView) -> ()
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        DispatchQueue.main.async {
            if let uiKitView = view.superview?.superview?.subviews.last?.subviews.first {
                result(uiKitView)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
