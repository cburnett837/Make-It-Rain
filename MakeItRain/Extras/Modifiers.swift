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
                        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
                        amountStringBinding = localAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                    }
                } else {
                    amountStringBinding = amountString ?? ""
                }
            }
            #endif
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


struct WidgetFolderMods: ViewModifier {
    var height: CGFloat?
    func body(content: Content) -> some View {
        content
            .if(height != nil) { view in
                view.frame(height: height)
            }
            .frame(maxWidth: .infinity)
            //.background(Rectangle().fill(Color.clear))
            //.background(Color(.secondarySystemBackground))
            #if os(iOS)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
            #else
            //.background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray)))
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemFill)))
            #endif
            //.background(Color(.tertiarySystemBackground))
            //.cornerRadius(8)
            //.cornerRadius(20)
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

struct MaxChartWidthObserver: ViewModifier {
    func body(content: Content) -> some View {
        return content.background {
            GeometryReader { geo in
                Color.clear.preference(key: MaxChartSizePreferenceKey.self, value: geo.size.width)
            }
        }
    }
}




struct TransactionEditSheetAndLogic: ViewModifier {
    @Bindable var calModel: CalendarModel
    @Binding var transEditID: String?
    @Binding var editTrans: CBTransaction?
    @Binding var selectedDay: CBDay?
    @Binding var overviewDay: CBDay?
    @Binding var findTransactionWhere: WhereToLookForTransaction
    var presentTip: Bool
    var resetSelectedDayOnClose: Bool
    
    func body(content: Content) -> some View {
        return content
            .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
            .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
            .sheet(item: $editTrans) { trans in
                TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: false, transLocation: findTransactionWhere)
                    //#warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
                    /// needed to prevent the view from being incorrect.
                    .id(trans.id)
                    /// This is needed for the drag to dismiss.
                    .onDisappear {
                        transEditID = nil
                    }
                    //.presentationSizing(.page)
            }
        }
    

    func transEditIdChanged(oldValue: String?, newValue: String?) {
        print(".onChange(of: transEditID) - old: \(String(describing: oldValue)) -- new: \(String(describing: newValue))")
        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
        if oldValue != nil && newValue == nil {
            
            #if os(iOS)
            if presentTip {
                /// Present tip after trying to add 3 new transactions.
                let trans = calModel.getTransaction(by: oldValue!, from: findTransactionWhere)
                if trans.action == .add {
                    TouchAndHoldPlusButtonTip.didTouchPlusButton.sendDonation()
                }
            }
            #endif
                                
            calModel.saveTransaction(id: oldValue!, day: selectedDay!, location: findTransactionWhere)
            /// - When adding a transaction via a day's context menu, `selectedDay` gets changed to the contexts day.
            ///   So when closing the transaction, put `selectedDay`back to today so the normal plus button works and the gray box goes back to today.
            /// - Gotta have a `selectedDay` for the editing of a transaction and transfer sheet.
            ///   Since one is not always used in details view, set to the current day if in the current month, otherwise set to the first of the month.
            /// - If you're viewing the bottom panel, reset `selectedDay` to `overviewDay` so any transactions that are added via the bottom panel have the date of the bottom panel.
            
            if resetSelectedDayOnClose {
                if overviewDay != nil {
                    selectedDay = overviewDay
                } else {
                    let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
                    selectedDay = targetDay
                }
            }
            
            /// Keep the model clean, and show alert for a photo that may be taking a long time to upload.
            //calModel.pictureTransactionID = nil
            PhotoModel.shared.pictureParent = nil
            
            /// Force this to `.normalList` since smart transactions will change the variable to look in the temp list.
            findTransactionWhere = .normalList
            
            /// Prevent a transaction from being opened while another one is trying to save.
            calModel.editLock = false
                                                            
        } else if newValue != nil {
            if !calModel.editLock {
                /// Prevent a transaction from being opened while another one is trying to save.
                calModel.editLock = true
                editTrans = calModel.getTransaction(by: newValue!, from: findTransactionWhere)
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
