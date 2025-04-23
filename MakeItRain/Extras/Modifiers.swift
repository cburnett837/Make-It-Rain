//
//  Modifiers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation
import SwiftUI


// NOT USED 3/11/25
struct StandardTextFieldStyle: ViewModifier {
    var padding: Double
    var alignment: TextAlignment
    var submit: () -> ()
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .padding(.leading, 0)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(8)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity)
            .onSubmit {
                submit()
            }
    }
}


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


struct ToolbarBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .stroke(Color(nsColor: .darkGray), lineWidth: 0.5)
            )
        #else
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(uiColor: .darkGray), lineWidth: 0.5)
            )
        #endif
    }
    
}



struct FormatCurrencyLiveAndOnUnFocus: ViewModifier {
    var focusValue: Int
    var focusedField: Int?
    var amountString: String?
    @Binding var amountStringBinding: String
    var amount: Double?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: amountString) {
                Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $amountStringBinding)
            }
            .onChange(of: focusedField) {
                if let string = Helpers.formatCurrency(focusValue: focusValue, oldFocus: $0, newFocus: $1, amountString: amountStringBinding, amount: amount) {
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
                        let localAmount = Double(amountStringBinding.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
                        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
                        amountStringBinding = localAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                    }
                } else {
                    amountStringBinding = amountString ?? ""
                }
            }
            #endif
    }
}

struct LoadingSpinner: ViewModifier {
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
        .opacity(AppState.shared.downloadedData.contains(id) ? 1 : 0)
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
                    .standardBackground()
                    #endif
                } else {
                    ProgressView()
                        .tint(.none)
                }
            }
            .opacity(AppState.shared.downloadedData.contains(id) ? 0 : 1)
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
                        .scaleEffect(0.7)
                        //.padding(.trailing, 2)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            //.padding(.leading, 4)
    }
}

#if os(iOS)
extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}



struct SheetHeightAdjuster: ViewModifier {
    
    @Binding var bottomPanelHeight: CGFloat
    @Binding var scrollContentMargins: CGFloat
    
    func body(content: Content) -> some View {
        content
            //.background(Color.red)
            .overlay {
                VStack {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 50, height: 6)
                        .padding(.top, 5)
                    Spacer()
                }
                
            }
            .gesture(DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 { /// Make Bigger
                        let oldHeight = bottomPanelHeight
                        let newHeight = oldHeight + abs(value.translation.height)
                        let maxAllowedHeight = (UIScreen.main.bounds.height - (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)) - 30
                        bottomPanelHeight = min(maxAllowedHeight, newHeight)
                        
                    } else if value.translation.height > 0 { /// Make Smaller
                        let oldHeight = bottomPanelHeight
                        let newHeight = oldHeight - abs(value.translation.height)
                        bottomPanelHeight = max(300, newHeight)
                    }
                }
                .onEnded { value in
                    scrollContentMargins = bottomPanelHeight
                }
            )
    }
}

#endif

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



struct TodoToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(configuration.isOn ? .purple : .gray)
                .contentTransition(.symbolEffect(.replace))
            Spacer()
            configuration.label
                .truncationMode(.tail)
        }
    }
}


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




#if os(iOS)
struct StandardBackground: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem

    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
//            .if(preferDarkMode) {
//                $0.background(Color.getGrayFromName(darkModeBackgroundColor).ignoresSafeArea(.all))
//            }
            
    }
}

struct StandardRowBackground: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    
    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
//            .if(preferDarkMode) {
//                $0.listRowBackground(Color.getGrayFromName(darkModeBackgroundColor))
//            }
    }
}


struct StandardRowBackgroundWithSelection: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeSelectionColor") var darkModeSelectionColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    
    let id: String
    let selectedID: String?
    
    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
//            .if(id == selectedID) {
//                $0.listRowBackground(preferDarkMode ? Color.getGrayFromName(darkModeSelectionColor) : Color(.tertiarySystemFill))
//            }
//            .if(id != selectedID) {
//                $0.standardRowBackground()
//            }
    }
}











struct StandardNavBackground: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
            .if(AppState.shared.isIpad) {
                $0.background(colorScheme == .dark ? Color.darkGray.ignoresSafeArea(.all) : Color(UIColor.systemGray6).ignoresSafeArea(.all))
            }
        
            .if(!AppState.shared.isIpad) {
                $0.background(colorScheme == .dark ? Color.getGrayFromName(darkModeBackgroundColor) : Color.white)
            }
            
    }
}

struct StandardNavRowBackground: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
            .if(AppState.shared.isIpad) {
                $0.listRowBackground(colorScheme == .dark ? Color.darkGray : Color(UIColor.systemGray6))
            }
        
            .if(!AppState.shared.isIpad) {
                $0.listRowBackground(colorScheme == .dark ? Color.getGrayFromName(darkModeBackgroundColor) : Color.white)
            }
    }
}



struct StandardNavRowBackgroundWithSelection: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeSelectionColor") var darkModeSelectionColor: String = "darkGray3"
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    @AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    @Environment(\.colorScheme) var colorScheme
    
    let id: String
    let selectedID: String?
    
    func body(content: Content) -> some View {
        content
            //.preferredColorScheme(userColorScheme == .system ? nil : userColorScheme == .dark ? .dark : .light)
            .if(id == selectedID) {
                if AppState.shared.isIpad {
                    $0.listRowBackground(colorScheme == .dark ? Color(.tertiarySystemFill) : Color(.tertiarySystemFill))
                } else {
                    $0.listRowBackground(colorScheme == .dark ? Color(.tertiarySystemFill) : Color(UIColor.systemGray4))
                }
            }
            .if(id != selectedID) {
                if AppState.shared.isIpad {
                    $0.listRowBackground(colorScheme == .dark ? Color.darkGray : Color(UIColor.systemGray6))
                } else {
                    $0.listRowBackground(colorScheme == .dark ? Color.getGrayFromName(darkModeBackgroundColor) : nil)
                }
            }
        
        
        
            .if(id == selectedID) {
                $0.listRowBackground(colorScheme == .dark ? Color.getGrayFromName(darkModeSelectionColor) : nil)
            }
            .if(id != selectedID) {
                $0.listRowBackground(colorScheme == .dark ? Color.getGrayFromName(darkModeBackgroundColor) : nil)
                //$0.standardRowBackground()
            }
    }
}




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
