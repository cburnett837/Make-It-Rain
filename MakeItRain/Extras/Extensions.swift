//
//  Extensions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/19/24.
//

import Foundation
import SwiftUI
import Charts

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

extension ChartContent {
    @ChartContentBuilder func `if`<Content: ChartContent>(_ condition: Bool, transform: (Self) -> Content) -> some ChartContent {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

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
//    func bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: Binding<CGFloat>, scrollContentMargins: Binding<CGFloat>) -> some View {
//        modifier(SheetHeightAdjuster(bottomPanelHeight: bottomPanelHeight, scrollContentMargins: scrollContentMargins))
//    }
   
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
    
    
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
    
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
        
//    
    
//    func deleteConfirmation(isPresented: Binding<Bool>, title: String, subtitle: String, yesAction: @escaping () -> Void, noAction: @escaping () -> Void) -> some View {
//        modifier(DeleteConfirmation(isPresented: isPresented, title: title, subtitle: subtitle, yesAction: yesAction, noAction: noAction))
//    }
    
    #endif
    
//    func widgetShape(height: CGFloat? = nil) -> some View {
//        modifier(WidgetFolderMods(height: height))
//    }                    
    
    func schemeBasedForegroundStyle() -> some View {
        modifier(SchemeBasedForegroundStyle())
    }
    
    func schemeBasedTint() -> some View {
        modifier(SchemeBasedTint())
    }
    
    func animatedLineChart<ChartContent: View>(beginAnimation: Bool, _ chart: @escaping (_ showLines: Bool) -> ChartContent) -> some View {
        modifier(AnimatedLineChart(beginAnimation: beginAnimation, chart: chart))
    }    
}
//
//struct CurrencyTextModifier: ViewModifier {
//    @Local(\.useWholeNumbers) var useWholeNumbers
//
//    func body(content: Content) -> some View {
//        // Try to extract the text and convert it to Double
//        if let text = Mirror(reflecting: content).descendant("storage", "anyTextStorage", "verbatim") as? String, let value = Double(text) {
//            let formatted = formatCurrency(value)
//            Text(formatted)
//        } else {
//            content
//        }
//    }
//
//    private func formatCurrency(_ value: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencyCode = "USD"
//        formatter.maximumFractionDigits = useWholeNumbers ? 0 : 2
//        return formatter.string(from: NSNumber(value: value)) ?? ""
//    }
//}
//
//extension View where Self == Text {
//    func currency() -> some View {
//        self.modifier(CurrencyTextModifier())
//    }
//}




#if os(macOS)
//extension Window {
//    func accessoryWindow(openIn location: UnitPoint = .topTrailing) -> some Scene {
//        self
//        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
//        /// Required to prevent the window from entering full screen if the main window is full screen.
//        .windowResizability(.contentSize)
//        /// Make sure any left over windows do not get opened when the app launches.
//        .restorationBehavior(.disabled)
//        /// Open in the top right corner.
//        .defaultPosition(location)
//    }
//}

extension Scene {
    func auxilaryWindow(openIn location: UnitPoint = .topTrailing) -> some Scene {
        self
        //.defaultLaunchBehavior(.suppressed) --> Not using because we terminate the app when the last window closes.
        /// Required to prevent the window from entering full screen if the main window is full screen.
        .windowResizability(.contentSize)
        /// Make sure any left over windows do not get opened when the app launches.
        .restorationBehavior(.disabled)
        /// Open in the top right corner.
        .defaultPosition(location)
    }
}
#endif



extension Array where Element == CBPaymentMethod {
    func getAmount(for date: Date) -> Double {
        return self
            .flatMap { $0.breakdowns }
            .filter { Calendar.current.isDate(date, equalTo: $0.date, toGranularity: .month) }
            .map { $0.income }
            .reduce(0, +)
    }
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
    
    
    func decimals(_ decimals: Int) -> String {
        let formatter = AppState.shared.numberFormatter
        formatter.numberStyle = .decimal
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
    
    static var theme: Color {
        @Local(\.colorTheme) var colorTheme
        return AppState.shared.colorMenuOptions.first(where: { $0.description == colorTheme })!
    }
    
    
    
    
    
    
//    static func getVariantTitleColor(for scheme: ColorScheme, color: Color) -> Color {
//        struct ColorModel: Identifiable {
//            var id = UUID()
//            var color: Color
//            var colorHex: String {
//                self.color.toHex() ?? "FFFFFF"
//            }
//            var lightVariant: String?
//            var darkVariant: String?
//        }
//        
//        let colors: Array<ColorModel> = [
//            ColorModel(color: .pink, lightVariant: "880800", darkVariant: "ff6a88"),
//            ColorModel(color: .red, lightVariant: "880800", darkVariant: "ff8f88"),
//            ColorModel(color: .orange, lightVariant: "935a00", darkVariant: "ffa924"),
//            ColorModel(color: .yellow, lightVariant: "806a00", darkVariant: "ffd60a"),
//            ColorModel(color: .green, lightVariant: "19722f", darkVariant: "60dc7f"),
//            ColorModel(color: .mint, lightVariant: "127270", darkVariant: "85ebe8"),
//            ColorModel(color: .teal, lightVariant: "157182", darkVariant: "6cd5e7"),
//            ColorModel(color: .cyan, lightVariant: "00719f", darkVariant: "97e1ff"),
//            ColorModel(color: .blue, lightVariant: "004080", darkVariant: "80bfff"),
//            ColorModel(color: .indigo, lightVariant: "1d1bb1", darkVariant: "908fee"),
//            ColorModel(color: .purple, lightVariant: "7d0eb4", darkVariant: "dba1f8"),
//            ColorModel(color: .brown, lightVariant: "665238", darkVariant: "cfbda7"),
//            
//            ColorModel(color: .white, lightVariant: "FFFFFF", darkVariant: "FFFFFF"),
//            ColorModel(color: .black, lightVariant: "000000", darkVariant: "000000")
//        ]
//        
//        
//        if color == .primary {
//            return scheme == .dark ? .white : .black
//        } else {
//            let theColor = colors.filter { $0.color == color }.first!
//            if scheme == .dark {
//                return Color.fromHex(theColor.darkVariant)!
//            } else {
//                return Color.fromHex(theColor.lightVariant)!
//            }
//        }
//    }
//    
    
    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: abs(percentage))
    }
    
    
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(by: -1 * abs(percentage))
    }
    
    
    func adjust(by percentage: CGFloat = 30.0) -> Color {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1.0
        #if os(iOS)
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        NSColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        return Color(red: min(red + percentage / 100, 1.0), green: min(green + percentage / 100, 1.0), blue: min(blue + percentage / 100, 1.0), opacity: alpha)
    }
    
//    static var lavendar: Color {
//        return Color(uiColor: UIColor(red: 0.60, green: 0.60, blue: 1.00, alpha: 1.00))
//    }
//    
//    static var lightLavendar: Color {
//        return Color(uiColor: UIColor(red: 0.80, green: 0.80, blue: 1.00, alpha: 1.00))
//    }    

//    var name: String {
//        switch self {
//        case .pink:   return "pink"
//        case .red:    return "red"
//        case .orange: return "orange"
//        case .yellow: return "yellow"
//        case .green: return "green"
//        case .mint: return "mint"
//        case .teal: return "teal"
//        case .cyan: return "cyan"
//        case .blue: return "blue"
//        case .lavendar: return "lavendar"
//        case .lightLavendar: return "lightLavendar"
//        case .purple: return "purple"
//        case .brown: return "brown"
//        default: return "white"
//        }
//    }
//    
    
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
    static var brainPink = Color(NSColor(red: 0.85, green: 0.65, blue: 0.70, alpha: 1.00))
#else
    static var totalDarkGray = Color(UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1.00))
    static var darkGray = Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00))
    static var darkGray2 = Color(UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.00))
    static var darkGray3 = Color(UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.00))
    static var brainPink = Color(UIColor(red: 0.85, green: 0.65, blue: 0.70, alpha: 1.00))
#endif
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





#if os(iOS)
extension View {
    func disableZoomInteractiveDismiss() -> some View {
        self
            .background(RemoveZoomDismissGestures())
    }
}

extension UIView {
    var viewController: UIViewController? {
        sequence(first: self) { $0.next }
            .compactMap({$0 as? UIViewController})
            .first
    }
}

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
                zoomViewControllerView.gestureRecognizers?.removeAll(where: {$0.name == "com.apple.UIKit.ZoomInteractiveDismissSwipeDown" || $0.name == "com.apple.UIKit.ZoomInteractiveDismissPinch"})
            }
        }
    }
}
#endif
