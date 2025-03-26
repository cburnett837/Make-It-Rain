//
//  Extensions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let updateCategoryAnalytics = Notification.Name("updateCategoryAnalytics")
}


#if os(iOS)
// The notification we'll send when a shake gesture happens.
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

//  Override the default behavior of shake gestures to send our notification instead.
extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
     }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}


extension UIView {
    var allSubviews: [UIView] {
        return self.subviews.flatMap({ [$0] + $0.allSubviews })
    }
}


#endif



extension Int: @retroactive Identifiable {
    public var id: Int {
        return self
    }
}

extension String: @retroactive Identifiable {
    public var id: String {
        return self
    }
}

extension URL: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}


extension Int {
    func withOrdinal() -> String {
        /// Number formatter in ``MakeItRainApp``
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .ordinal
        let first = formatter.string(from: NSNumber(value: self))
        return first ?? ""
    }
}

extension Double {
    var isWholeNumber: Bool {
        return self.isZero || (self.isNormal && self.exponent >= 0)
    }
    
    var isNegative: Bool {
        return self.sign == .minus
    }
}

extension Optional where Wrapped == Int {
    var specialDefaultIfNil: Int {
        switch self {
        case let .some(wrapped): wrapped
        case .none: Int.max
        }
    }
}

extension Optional where Wrapped == Double {
    var specialDefaultIfNil: Double {
        switch self {
        case let .some(wrapped): wrapped
        case .none: Double.greatestFiniteMagnitude
        }
    }
}

extension String?: @retroactive Comparable {
    public static func < (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" < rhs ?? ""
    }
    
    public static func > (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" > rhs ?? ""
    }
    
    public static func <= (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" <= rhs ?? ""
    }
    
    public static func >= (lhs: Optional, rhs: Optional) -> Bool {
        return lhs ?? "" >= rhs ?? ""
    }
    
    
}



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
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
#endif

extension View {
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
//
//    func standardButton() -> some View {
//        modifier(StandardButtonStyle())
//    }
    
//    func keyboardToolbarOnChange(showKeyboardToolbar: Binding<Bool>, focusedField: FocusState<Int?>) -> some View {
//        modifier(KeyboardToolbarOnChange(showKeyboardToolbar: showKeyboardToolbar, focusedField: focusedField))
//    }
    
    
    func formatCurrencyLiveAndOnUnFocus(focusValue: Int, focusedField: Int?, amountString: String?, amountStringBinding: Binding<String>, amount: Double?) -> some View {
        /// This will format the text with a $ or a -$ on the front when typing, and then fully format the text with decimals, and commas when unfocusing the textfield, or when clicking enter (macOS).
        modifier(FormatCurrencyLiveAndOnUnFocus(focusValue: focusValue, focusedField: focusedField, amountString: amountString, amountStringBinding: amountStringBinding, amount: amount))
    }
    
        
    func toast() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let toast = AppState.shared.toast {
                    ToastView(toast: toast)
                }
            }
    }
    
    func toolbarKeyboard(padding: Double = 6, alignment: TextAlignment = .leading) -> some View {
        modifier(ToolbarKeyboard(padding: padding, alignment: alignment))
    }
    
    func toolbarBorder() -> some View {
        modifier(ToolbarBorder())
    }
    
    func chevronMenuOverlay() -> some View {
        modifier(ChevronMenuOverlay())
    }
    
    func maxViewWidthObserver() -> some View {
        modifier(MaxViewWidthObserver())
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
    
    func loadingSpinner(id: NavDestination, text: String) -> some View {
        modifier(LoadingSpinner(id: id, text: text))
    }
    
    func loadingSpinner(id: NavDestination) -> some View {
        modifier(LoadingSpinner(id: id))
    }
    
    
    func sheetHeightAdjuster(height: Binding<CGFloat>) -> some View {
        modifier(SheetHeightAdjuster(height: height))
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
}



// MARK: - Backgrounds
extension View {
    #if os(iOS)
    func standardBackground() -> some View {
        modifier(StandardBackground())
    }

    func standardRowBackground() -> some View {
        modifier(StandardRowBackground())
    }

    func standardRowBackgroundWithSelection(id: String, selectedID: String?) -> some View {
        modifier(StandardRowBackgroundWithSelection(id: id, selectedID: selectedID))
    }
    
    // NAVIGATION SPECIFIC (TO ACCOMODATE IPAD)
    func standardNavBackground() -> some View {
        modifier(StandardNavBackground())
    }

    func standardNavRowBackground() -> some View {
        modifier(StandardNavRowBackground())
    }
    
    func standardNavRowBackgroundWithSelection(id: String, selectedID: String?) -> some View {
        modifier(StandardNavRowBackgroundWithSelection(id: id, selectedID: selectedID))
    }
    #endif
}



extension [LayoutSubviews.Element] {
    func maxHeight(_ proposal: ProposedViewSize) -> CGFloat {
        return self.compactMap { view in
            return view.sizeThatFits(proposal).height
        }.max() ?? 0
    }
}

extension VerticalAlignment {
    enum CircleAndTitle: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let circleAndTitle = VerticalAlignment(CircleAndTitle.self)
}


extension HorizontalAlignment {
    enum LabelAndField: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.leading]
        }
    }
    
    static let customHorizontalAlignment = HorizontalAlignment(LabelAndField.self)
}

extension Double {
    func currencyWithDecimals(_ decimals: Int) -> String {
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}



extension String {
//    func toColor() -> Color {
//        var color: Color = .white
//        switch self {
//        case "red":
//            color = .red
//        case "orange":
//            color = .orange
//        case "yellow":
//            color = .yellow
//        case "green":
//            color = .green
//        case "blue":
//            color = .blue
//        case "purple":
//            color = .purple
//        case "pink":
//            color = .pink
//        case "brown":
//            color = .brown
//        case "black":
//            color = .black
//        case "white":
//            color = .white
//        default:
//            color = .white
//        }
//        
//        return color
//    }
//    
    
//    func toColor() -> Color {
//        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//        return Color(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
    
//    func toColorOG() -> Color {
//        var cString = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
//
//        if (cString.hasPrefix("#")) {
//            cString.remove(at: cString.startIndex)
//        }
//
//        if ((cString.count) != 6) {
//            return Color.gray
//        }
//
//        var rgbValue: UInt64 = 0
//        Scanner(string: cString).scanHexInt64(&rgbValue)
//
//        return Color (
//            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
//            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
//            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
//        )
//    }
}

#if os(iOS)

extension UIColor {
    public var lightVariant: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }
    public var darkVariant: UIColor {
        resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    }
    public var asColor: Color {
        Color(self)
    }
}
#endif


extension Color {
    func toHex() -> String? {
#if os(macOS)
        let uic = NSColor(self)
#else
        let uic = UIColor(self)
#endif
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(1.0)
        
        if components.count >= 4 {
            //a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    //    init(hex: String) {
    //        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    //        var int: UInt64 = 0
    //        Scanner(string: hex).scanHexInt64(&int)
    //        let a, r, g, b: UInt64
    //        switch hex.count {
    //        case 3: // RGB (12-bit)
    //            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    //        case 6: // RGB (24-bit)
    //            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    //        case 8: // ARGB (32-bit)
    //            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    //        default:
    //            (a, r, g, b) = (1, 1, 1, 0)
    //        }
    //
    //        self.init(
    //            .sRGB,
    //            red: Double(r) / 255,
    //            green: Double(g) / 255,
    //            blue:  Double(b) / 255,
    //            opacity: Double(a) / 255
    //        )
    //    }
    
    //    static func fromHex(_ hex: String?) -> Color? {
    //        if let hex = hex {
    //            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    //            var int: UInt64 = 0
    //            Scanner(string: hex).scanHexInt64(&int)
    //
    //            let r, g, b, a: UInt64
    //
    //            switch hex.count {
    //            case 3:  (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
    //            case 6:  (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
    //            case 8:  (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
    //            default: (r, g, b, a) = (1, 1, 1, 1)
    //            }
    //
    //            return self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    //        } else {
    //            return nil
    //        }
    //    }
    
    static func fromHex(_ hex: String?) -> Color? {
        if let hex = hex {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var rgbValue: UInt64 = 0
            
            Scanner(string: hex).scanHexInt64(&rgbValue)
            
            let a, r, g, b: UInt64
            
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (rgbValue >> 8) * 17, (rgbValue >> 4 & 0xF) * 17, (rgbValue & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, rgbValue >> 16, rgbValue >> 8 & 0xFF, rgbValue & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (rgbValue >> 24, rgbValue >> 16 & 0xFF, rgbValue >> 8 & 0xFF, rgbValue & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
            }
            
            return self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue:  Double(b) / 255,
                opacity: Double(a) / 255
            )
            
        } else {
            return nil
        }
    }
    
    static func fromName(_ name: String) -> Color {
        //print(name)
        if name == "primary" {
            return Color.primary
        } else {
            return AppState.shared.colorMenuOptions.first(where: { $0.description == name })!
        }
    }
    
    
    
    
    
    
    static func getVariantTitleColor(for scheme: ColorScheme, color: Color) -> Color {
        struct ColorModel: Identifiable {
            var id = UUID()
            var color: Color
            var colorHex: String {
                self.color.toHex() ?? "FFFFFF"
            }
            var lightVariant: String?
            var darkVariant: String?
        }
        
        let colors: Array<ColorModel> = [
            ColorModel(color: .pink, lightVariant: "880800", darkVariant: "ff6a88"),
            ColorModel(color: .red, lightVariant: "880800", darkVariant: "ff8f88"),
            ColorModel(color: .orange, lightVariant: "935a00", darkVariant: "ffa924"),
            ColorModel(color: .yellow, lightVariant: "806a00", darkVariant: "ffd60a"),
            ColorModel(color: .green, lightVariant: "19722f", darkVariant: "60dc7f"),
            ColorModel(color: .mint, lightVariant: "127270", darkVariant: "85ebe8"),
            ColorModel(color: .teal, lightVariant: "157182", darkVariant: "6cd5e7"),
            ColorModel(color: .cyan, lightVariant: "00719f", darkVariant: "97e1ff"),
            ColorModel(color: .blue, lightVariant: "004080", darkVariant: "80bfff"),
            ColorModel(color: .indigo, lightVariant: "1d1bb1", darkVariant: "908fee"),
            ColorModel(color: .purple, lightVariant: "7d0eb4", darkVariant: "dba1f8"),
            ColorModel(color: .brown, lightVariant: "665238", darkVariant: "cfbda7"),
            
            ColorModel(color: .white, lightVariant: "FFFFFF", darkVariant: "FFFFFF"),
            ColorModel(color: .black, lightVariant: "000000", darkVariant: "000000")
        ]
        
        
        if color == .primary {
            return scheme == .dark ? .white : .black
        } else {
            let theColor = colors.filter { $0.color == color }.first!
            if scheme == .dark {
                return Color.fromHex(theColor.darkVariant)!
            } else {
                return Color.fromHex(theColor.lightVariant)!
            }
        }
    }
    
    
    
    //    static func fromName(_ name: String) -> Color {
    //        let colors: Array<Color> = [.pink, .red, .orange, .yellow, .green, .mint, .cyan, .blue, .indigo, .purple, .brown, .teal]
    //        return colors.first(where: { $0.description == name })!
    //    }
    
    
    
#if os(iOS)
    static func getGrayFromName(_ name: String) -> Color {
        //print(name)
        if name == "secondarySystemBackground" {
            return Color(.secondarySystemBackground)
            
        } else if name == "gray" {
            return Color.gray
            
        } else if name == "darkGray" {
            return Color.darkGray
        } else if name == "darkGray2" {
            return Color.darkGray2
        } else if name == "darkGray3" {
            return Color.darkGray3
            
        } else if name == "black" {
            return Color.black
            
        } else if name == "systemGray" {
            return Color(uiColor: .systemGray)
        } else if name == "systemGray2" {
            return Color(uiColor: .systemGray2)
        } else if name == "systemGray3" {
            return Color(uiColor: .systemGray3)
        } else if name == "systemGray4" {
            return Color(uiColor: .systemGray4)
        } else if name == "systemGray5" {
            return Color(uiColor: .systemGray5)
        } else if name == "systemGray6" {
            return Color(uiColor: .systemGray6)
            
        } else {
            return Color.black
        }
    }
#else
    static func getGrayFromName(_ name: String) -> Color {
        //print(name)
        if name == "secondarySystemBackground" {
            return Color(.systemGray)
            
        } else if name == "gray" {
            return Color.gray
            
        } else if name == "darkGray" {
            return Color.darkGray
        } else if name == "darkGray2" {
            return Color.darkGray2
        } else if name == "darkGray3" {
            return Color.darkGray3
            
        } else if name == "black" {
            return Color.black
            
        } else if name == "systemGray" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray2" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray3" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray4" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray5" {
            return Color(nsColor: .systemGray)
        } else if name == "systemGray6" {
            return Color(nsColor: .systemGray)
            
        } else {
            return Color.black
        }
    }
#endif
    
    
    
#if os(macOS)
    static var totalDarkGray = Color(NSColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.00))
    static var darkGray = Color(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00))
    static var darkGray2 = Color(NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.00))
    static var darkGray3 = Color(NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.00))
#else
    static var totalDarkGray = Color(UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.00))
    static var darkGray = Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00))
    static var darkGray2 = Color(UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.00))
    static var darkGray3 = Color(UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.00))
#endif
    
//    struct Standard {
//        struct Dark {
//            static let background: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
//            
//            struct Row {
//                static let background: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
//                
////                struct WithSelection {
////                    static let background: Color = Color(.systemGray4)
////                }
//            }
//            
//            struct Nav {
//                static let backgroundIpad: Color = Color.darkGray
//                static let backgroundIphone: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
//                
//                struct Row {
//                    static let backgroundIpad: Color = Color.darkGray
//                    static let backgroundIphone: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
//                    
//                    struct WithSelection {
//                        static let backgroundIpadSelected: Color = Color(.systemGray6)
//                        static let backgroundIpadNotSelected: Color = Color.darkGray
//                        static let backgroundIphoneSelected: Color = Color(.systemGray5)
//                        static let backgroundIphoneNotSelected: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
//                    }
//                }
//            }
//        }
//        
//        struct Light {
//            static let background: Color = Color.white
//            
//            struct Row {
//                static let background: Color = Color.white
//                
////                struct WithSelection {
////                    static let background: Color = Color(.systemGray4)
////                }
//            }
//            
//            struct Nav {
//                static let backgroundIpad: Color = Color(.systemGray6)
//                static let backgroundIphone: Color = Color.white
//                
//                struct Row {
//                    static let backgroundIpad: Color = Color(.systemGray6)
//                    static let backgroundIphone: Color = Color.white
//                    
//                    struct WithSelection {                        
//                        static let backgroundIpadSelected: Color = Color(.tertiarySystemFill)
//                        static let backgroundIpadNotSelected: Color = Color(.systemGray6)
//                        static let backgroundIphoneSelected: Color = Color(.systemGray6)
//                        static let backgroundIphoneNotSelected: Color = Color.white
//                    }
//                }
//                
//                
//            }
//            
//            
//            
//        }
//    }
    
    
    
    //static let standardBackgroundDark: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
    //static let standardRowBackgroundDark: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
    
    //static let standardRowBackgroundWithSelectionDark: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeSelectionColor") ?? "darkGray3")
    //static let standardRowBackgroundWithSelectionLight: Color = Color(.tertiarySystemFill)
    
    //static let standardNavBackgroundDarkIpad: Color = Color.darkGray
    //static let standardNavBackgroundLightIpad: Color = Color(UIColor.systemGray6)
    
    //static let standardNavBackgroundDarkIphone: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
    //static let standardNavBackgroundLightIphone: Color = Color.white
    
    //static let standardNavRowBackgroundDarkIphone: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
    //static let standardNavRowBackgroundLightIphone: Color = Color.white
    
    //static let standardNavRowBackgroundWithSelectionDarkIpadSelected: Color = Color(.tertiarySystemFill)
    //static let standardNavRowBackgroundWithSelectionDarkIpadNotSelected: Color = Color.darkGray
    
    //static let standardNavRowBackgroundWithSelectionLightIpadSelected: Color = Color(.tertiarySystemFill)
    //static let standardNavRowBackgroundWithSelectionLightIpadNotSelected: Color = Color(UIColor.systemGray6)
    
    //static let standardNavRowBackgroundWithSelectionDarkIphoneSelected: Color = Color(.tertiarySystemFill)
    //static let standardNavRowBackgroundWithSelectionDarkIphoneNotSelected: Color = Color.getGrayFromName(UserDefaults.standard.string(forKey: "darkModeBackgroundColor") ?? "darkGray3")
    
    //static let standardNavRowBackgroundWithSelectionLightIphoneSelected: Color = Color(UIColor.systemGray4)
    //static let standardNavRowBackgroundWithSelectionLightIphoneNotSelected: Color = Color.white
    
    
    
    
    
}

extension UserDefaults {
    static func updateStringValue(valueToUpdate: String, keyToUpdate: String) {
        UserDefaults.standard.setValue(valueToUpdate, forKey: keyToUpdate)
    }
    
    static func fetchOneString(requestedKey: String) -> String? {
        return UserDefaults.standard.string(forKey: requestedKey) ?? nil
    }
    
    static func fetchManyString(requestedKey: String) -> [String] {
        return UserDefaults.standard.stringArray(forKey: requestedKey) ?? []
    }
    
    static func fetchOneBool(requestedKey: String) -> Bool {
        return UserDefaults.standard.bool(forKey: requestedKey)
    }
    
    static func fetchManyDicts(requestedKey: String) -> Dictionary<String, Any> {
        return UserDefaults.standard.dictionary(forKey: requestedKey) ?? ["" : ""]
    }
}


extension Array where Element: FloatingPoint {    
    func average() -> Element {
        reduce(0, +) / Element(count)
    }
}


//extension View {
//    func questionCursor() -> some View {
//        self.onHover { inside in
//            if inside {
//                NSCursor(image: NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "")!, hotSpot: .zero).set()
//                    
//                //NSCursor.pointingHand.set()
//            } else {
//                NSCursor.arrow.set()
//            }
//        }
//        .foregroundStyle(.red)
//    }
//}
