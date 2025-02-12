//
//  Modifiers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation
import SwiftUI



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
                        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
                        amountStringBinding = amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? ""
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
                        .padding(.trailing, 2)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .padding(.leading, 4)
    }
}


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
    @AppStorage("darkModeBackgroundColor") var grayShade: String = "darkGray"

    func body(content: Content) -> some View {
        content
            .if(preferDarkMode) {
                //$0.background(Color(.secondarySystemBackground).ignoresSafeArea(.all))
                $0.background(Color.getGrayFromName(grayShade).ignoresSafeArea(.all))
                //$0.background(Color.darkGray.ignoresSafeArea(.all))
            }
            
    }
}

struct RowBackground: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeBackgroundColor") var darkModeBackgroundColor: String = "darkGray3"
    
    func body(content: Content) -> some View {
        content
            .if(preferDarkMode) {
                //$0.listRowBackground(Color(.secondarySystemBackground))
                $0.listRowBackground(Color.getGrayFromName(darkModeBackgroundColor))
                //$0.listRowBackground(Color.darkGray)
            }
    }
}

//
//struct RowBackgroundWithSelection: ViewModifier {
//    //@Environment(\.colorScheme) var colorScheme
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @AppStorage("useGrayBackground") var useGrayBackground = true
//    @AppStorage("grayShade") var grayShade: String = "darkGray"
//    
//    let id: Int
//    let selectedID: Int?
//    
//    func body(content: Content) -> some View {
//        content
//            .if(id == selectedID) {
//                $0.listRowBackground(
//                    useGrayBackground && preferDarkMode
//                    ? Color(.secondarySystemBackground)
//                    : preferDarkMode ? Color.darkGray : Color(.secondarySystemBackground))
//            }
//            .if(id != selectedID) {
//                $0.rowBackground()
//            }
//    }
//}

struct RowBackgroundWithSelection2: ViewModifier {
    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
    @AppStorage("darkModeSelectionColor") var darkModeSelectionColor: String = "darkGray3"
    
    let id: String
    let selectedID: String?
    
    func body(content: Content) -> some View {
        content
            .if(id == selectedID) {
//                $0.listRowBackground(
//                    useGrayBackground && preferDarkMode
//                    ? Color(.secondarySystemBackground)
//                    : preferDarkMode ? Color.darkGray : Color(.secondarySystemBackground))
                
                
                $0.listRowBackground(preferDarkMode ? Color.getGrayFromName(darkModeSelectionColor) : nil)
            }
            .if(id != selectedID) {
                $0.rowBackground()
            }
    }
}


//struct NavRowBackgroundWithSelection: ViewModifier {
//    //@Environment(\.colorScheme) var colorScheme
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    //@AppStorage("useGrayBackground") var useGrayBackground = true
//    @AppStorage("darkModeBackgroundColor") var grayShade: String = "darkGray"
//    
//    let selection: NavDestination
//    
//    func body(content: Content) -> some View {
//        content
//            .if(selection == NavigationManager.shared.selection) {
//                $0.listRowBackground(
//                    useGrayBackground && preferDarkMode
//                    ? Color(.secondarySystemBackground)
//                    : preferDarkMode ? Color.darkGray : Color(.secondarySystemBackground))
//            }
//            .if(selection != NavigationManager.shared.selection) {
//                $0.rowBackground()
//            }
//    }
//}




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
