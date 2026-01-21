//
//  Modifiers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation
import SwiftUI
import Charts


// NOT USED 3/11/25
//struct StandardTextFieldStyle: ViewModifier {
//    var padding: Double
//    var alignment: TextAlignment
//    var submit: () -> ()
//    func body(content: Content) -> some View {
//        content
//            .padding(padding)
//            .padding(.leading, 0)
//            .background(Color(.tertiarySystemFill))
//            .cornerRadius(8)
//            .multilineTextAlignment(alignment)
//            .frame(maxWidth: .infinity)
//            .onSubmit {
//                submit()
//            }
//    }
//}


//#if os(iOS)
///// NOT USED - custom shitty swiftui implementation that goes with the .keyboardToolbar Modifier. 1/2/25
//struct KeyboardToolbar: ViewModifier {
//    @Binding var text: String
//    //@FocusState var focusedField: Int?
//    var focusedField: FocusState<Int?>.Binding
//    var focusViews: [FocusView]
//    
//    @State private var offset: CGFloat = 100
//    
//    func body(content: Content) -> some View {
//        content
//        .overlay {
//            VStack {
//                Spacer()
//                //Text("Hey")
//                KeyboardToolbarView4(text: $text, focusedField: focusedField, focusViews: focusViews)
//                    .offset(y: offset)
//                    .transaction {
////                        if AppState.shared.showKeyboardToolbar {
////                            $0.animation = .none
////                        } else {
////                            $0.animation = .default
////                        }
//                        
//                        if offset == 0 {
//                            $0.animation = .none
//                        } else {
//                            $0.animation = .default
//                        }
//                    }
//                    .frame(width: UIScreen.main.bounds.width)
//                    .onChange(of: AppState.shared.showKeyboardToolbar) { oldValue, newValue in
//                        if newValue {
//                            offset = 0
//                        } else {
//                            offset = 100
//                        }
//                    }
//            }
//        }
//    }
//}
//#endif



#if os(iOS)
//struct KeyboardToolbarNew: ViewModifier {
//    var plequalsFunc: () -> Void
//    @FocusState var focusedField: Int?
//    var fields: [Int]
//    
//    @State private var offset: CGFloat = 100
//    
//    func body(content: Content) -> some View {
//        content
//        .overlay {
//            VStack {
//                Spacer()
//                KeyboardToolbarViewNew(plequalsFunc: plequalsFunc, focusedField: _focusedField, fields: fields)
//                    .offset(y: offset)
//                    .transaction {
////                        if AppState.shared.showKeyboardToolbar {
////                            $0.animation = .none
////                        } else {
////                            $0.animation = .default
////                        }
//                        
//                        if offset == 0 {
//                            $0.animation = .none
//                        } else {
//                            $0.animation = .default
//                        }
//                    }
//                    .frame(width: UIScreen.main.bounds.width)
//                    .onChange(of: AppState.shared.showKeyboardToolbar) { oldValue, newValue in
//                        if newValue {
//                            offset = 0
//                        } else {
//                            offset = 100
//                        }
//                    }
//            }
//        }
//    }
//}

#endif

//struct KeyboardToolbarOnChange: ViewModifier {
//    @Binding var showKeyboardToolbar: Bool
//    @FocusState var focusedField: FocusedField?
//    func body(content: Content) -> some View {
//        content
//            .onChange(of: focusedField, { oldValue, newValue in
//                if newValue != nil && oldValue == nil {
////                    var transaction = Transaction(animation: .none)
////                    transaction.disablesAnimations = true
////                    withTransaction(transaction) { showKeyboardToolbar = true }
//                    
//                } else if newValue == nil && oldValue != nil{
//                    var transaction = Transaction(animation: .none)
//                    transaction.disablesAnimations = true
//                    withTransaction(transaction) { showKeyboardToolbar = false }
//                    
//                } else if newValue != nil {
//                    var transaction = Transaction(animation: .default)
//                    transaction.disablesAnimations = true
//                    withTransaction(transaction) { showKeyboardToolbar = true }
//                }
//            })
//    }
//}

#if os(macOS)
struct ToolbarBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .stroke(Color(nsColor: .darkGray), lineWidth: 0.5)
            )
        
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(uiColor: .darkGray), lineWidth: 0.5)
            )
    }
}
#endif



struct FormatCurrencyLiveAndOnUnFocus: ViewModifier {
    var focusValue: Int
    var focusedField: Int?
    var amountString: String?
    @Binding var amountStringBinding: String
    var amount: Double?
    
    func body(content: Content) -> some View {
        content
//            .onChange(of: amountString) {
//                Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $amountStringBinding)
//            }
            .onChange(of: focusedField) {
                //print("Formatting \(focusValue)")
                
                if amountStringBinding == "-" {
                    amountStringBinding = ""
                    return
                }
                
                if focusValue == $0, !amountStringBinding.isEmpty, let string = Helpers.formatCurrency(
                    focusValue: focusValue,
                    oldFocus: $0,
                    newFocus: $1,
                    amountString: amountStringBinding,
                    amount: amount
                ) {
                    amountStringBinding = string
                }
            }
            #if os(macOS)
            .onSubmit {
                if !(amountString ?? "").isEmpty {
                    if amountString == "$" || amountString == "-$" {
                        amountStringBinding = ""
                    } else {
                        /// When I click submit, the amount and amountString aren't updated with the new value that the Binding contains.
                        let localAmount = Double(amountStringBinding.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
                        
                        amountStringBinding = localAmount.currencyWithDecimals()
                    }
                } else {
                    amountStringBinding = amountString ?? ""
                }
            }
            #endif
    }
}




struct CalculateAndFormatCurrencyLiveAndOnUnFocus: ViewModifier {
    

    var focusValue: Int
    var focusedField: Int?
    var amountString: String?
    @Binding var amountStringBinding: String
    var amount: Double?
    
    @State private var tokens: [CalcToken] = []
    @State private var currentNumber: String = ""
    
    func body(content: Content) -> some View {
        content
            .onChange(of: amountString) {
                Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $amountStringBinding)
                
                if let new = $1 {
                    if new.isEmpty {
                        currentNumber = ""
                        tokens.removeAll()
                    }
                }
            }
            .onChange(of: focusedField) {
                //print("Formatting \(focusValue)")
                
                if amountStringBinding == "-" {
                    amountStringBinding = ""
                    return
                }
                
                if focusValue == $0, !amountStringBinding.isEmpty, let string = Helpers.formatCurrency(
                    focusValue: focusValue,
                    oldFocus: $0,
                    newFocus: $1,
                    amountString: amountStringBinding,
                    amount: amount
                ) {
                    amountStringBinding = string
                    
                    commitCurrentNumber()

                    if let result = CalculatorEngine.evaluate(tokens: tokens) {
                        amountStringBinding = result
                        //amountStringBinding = format(result)
                        tokens = [.number(result)]
                    }
                }
            }
            #if os(macOS)
            .onSubmit {
                if !(amountString ?? "").isEmpty {
                    if amountString == "$" || amountString == "-$" {
                        amountStringBinding = ""
                    } else {
                        /// When I click submit, the amount and amountString aren't updated with the new value that the Binding contains.
                        let localAmount = Double(amountStringBinding.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
                        
                        amountStringBinding = localAmount.currencyWithDecimals()
                    }
                } else {
                    amountStringBinding = amountString ?? ""
                }
            }
            #endif
    }
    
    func commitCurrentNumber() {
        let process: String = currentNumber.replacing("$", with: "")
        guard let _ = Double(process) else { return }
        tokens.append(.number(process))
        currentNumber = ""
    }
    
    func format(_ value: Double) -> String {
        AppSettings.shared.useWholeNumbers ? String(Int(value)) : String(value)
    }
}


//
//#if os(macOS)
//struct AccessoryWindow: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .windowResizability(.contentSize)
//            .restorationBehavior(.disabled)
//            .defaultPosition(.topTrailing)
//    }
//}
//#endif
//

struct CalendarLoadingSpinner: ViewModifier {
    @Environment(CalendarModel.self) var calModel
    let id: NavDestination
    let text: String?
    
    init(id: NavDestination) {
        self.id = id
        self.text = nil
    }
    
    init(id: NavDestination, text: String) {
        self.id = id
        self.text = text
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(calModel.months.get(byEnumId: id).showCalendarLoadingSpinner ? 0 : 1)
            .overlay {
                Group {
                    if let text {
                        VStack {
                            ProgressView()
                                .tint(.none)
                            Text(text)
                        }
                        #if os(iOS)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                    } else {
                        ProgressView()
                            .tint(.none)
                    }
                }
                .opacity(calModel.months.get(byEnumId: id).showCalendarLoadingSpinner ? 1 : 0)
            }
    }
}

struct ChevronMenuOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.gray)
                        .bold()
                        .scaleEffect(0.6)
                        //.padding(.trailing, 2)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            //.padding(.leading, 4)
    }
}

//
//struct WidgetFolderMods: ViewModifier {
//    var height: CGFloat?
//    func body(content: Content) -> some View {
//        content
//            .if(height != nil) { view in
//                view.frame(height: height)
//            }
//            .frame(maxWidth: .infinity)
//            //.background(Rectangle().fill(Color.clear))
//            //.background(Color(.secondarySystemBackground))
//            #if os(iOS)
//            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
//            #else
//            //.background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray)))
//            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemFill)))
//            #endif
//            //.background(Color(.tertiarySystemBackground))
//            //.cornerRadius(8)
//            //.cornerRadius(20)
//    }
//}



#if os(iOS)
//extension UIApplication {
//    var keyWindow: UIWindow? {
//        connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow }
//    }
//}
//
//
//
//struct SheetHeightAdjuster: ViewModifier {
//    
//    @Binding var bottomPanelHeight: CGFloat
//    @Binding var scrollContentMargins: CGFloat
//    
//    func body(content: Content) -> some View {
//        content
//            //.background(Color.red)
//            .overlay {
//                VStack {
//                    Capsule()
//                        .fill(Color(.tertiarySystemFill))
//                        .frame(width: 50, height: 6)
//                        .padding(.top, 5)
//                    Spacer()
//                }
//                
//            }
//            .gesture(DragGesture()
//                .onChanged { value in
//                    if value.translation.height < 0 { /// Make Bigger
//                        let oldHeight = bottomPanelHeight
//                        let newHeight = oldHeight + abs(value.translation.height)
//                        let maxAllowedHeight = (UIScreen.main.bounds.height - (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)) - 30
//                        bottomPanelHeight = min(maxAllowedHeight, newHeight)
//                        
//                    } else if value.translation.height > 0 { /// Make Smaller
//                        let oldHeight = bottomPanelHeight
//                        let newHeight = oldHeight - abs(value.translation.height)
//                        bottomPanelHeight = max(300, newHeight)
//                    }
//                }
//                .onEnded { value in
//                    scrollContentMargins = bottomPanelHeight
//                }
//            )
//    }
//}

#endif

#if os(macOS)
struct ToolbarKeyboard: ViewModifier {
    var padding: Double
    var alignment: TextAlignment
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5.55)
            .background(.clear)
            .toolbarBorder()
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity)
    }
}
#endif



//struct TodoToggleStyle: ToggleStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack {
//            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
//                .foregroundStyle(configuration.isOn ? .purple : .gray)
//                .contentTransition(.symbolEffect(.replace))
//            Spacer()
//            configuration.label
//                .truncationMode(.tail)
//        }
//    }
//}
//
//struct NamespaceContainer {
//    @Namespace static var defaultNamespace
//}


struct SchemeBasedForegroundStyle: ViewModifier {
    var isDisabled: Bool
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .foregroundStyle(isDisabled ? .gray : (colorScheme == .dark ? .white : .black))
    }
}

struct SchemeBasedTint: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .tint(colorScheme == .dark ? .white : .black)
    }
}





// MARK: - Width & Height Observers
struct MaxViewWidthObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content.background {
            GeometryReader { geo in
                Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.width)
            }
        }
    }
}

struct MaxViewHeightObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content.background {
            GeometryReader { geo in
                Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.height)
            }
        }
    }
}

struct TransMaxViewHeightObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content.background {
            GeometryReader { geo in
                Color.clear.preference(key: TransMaxSizePreferenceKey.self, value: geo.size.height)
            }
        }
    }
}

struct ViewWidthObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .background {
                GeometryReader { Color.clear.preference(key: ViewWidthKey.self, value: $0.size.width) }
            }
    }
}

struct ViewHeightObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .background {
                GeometryReader { Color.clear.preference(key: ViewHeightKey.self, value: $0.size.height) }
            }
    }
}

struct MaxChartWidthObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content.background {
            GeometryReader { geo in
                Color.clear.preference(key: MaxChartSizePreferenceKey.self, value: geo.size.width)
            }
        }
    }
}






//struct DeleteConfirmation: ViewModifier {
//    @Binding var isPresented: Bool
//    var title: String
//    var subtitle: String
//    var yesAction: () -> Void
//    var noAction: () -> Void
//    
//    func body(content: Content) -> some View {
//        return content
//            .confirmationDialog("Delete \"\(title)\"?", isPresented: $isPresented, actions: {
//                Button("Yes", role: .destructive) { yesAction() }
//                Button("No", role: .cancel) { noAction() }
//            }, message: {
//                #if os(iOS)
//                Text("Delete \"\(title)\"?\n\(subtitle)")
//                #else
//                Text(subtitle)
//                #endif
//            })
//    }
//}



#if os(iOS)
// A view modifier that detects shaking and calls a function of our choosing.
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}


struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}



#endif



struct AnimatedLineChart<ChartContent: View>: ViewModifier {
    var beginAnimation: Bool
    let chart: (_ showLines: Bool) -> ChartContent
        
    @State private var endFraction: CGFloat = 0.0
    @State private var plotSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { plotSize = proxy.size }
                        .onChange(of: proxy.size) { plotSize = $1 }
                }
            }
            .mask(
                Rectangle()
                    .fill(Color.white)
                    .padding(.trailing, (1 - endFraction) * plotSize.width)
            )
            // to show grid lines
            .chartOverlay(alignment: .center, content: { _ in
                chart(false)
            })
            .onChange(of: beginAnimation, initial: true) {
                if $1 { begin() }
            }
//            .task {
//                if beginAnimation {
//                    begin()
//                }
//            }
    }
    
    func begin() {
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        withAnimation(.linear(duration: 0.75)) {
                endFraction = 1.0
            }
        //}
    }
}
