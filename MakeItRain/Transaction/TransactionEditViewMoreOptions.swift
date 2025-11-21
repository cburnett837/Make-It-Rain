//
//  TransactionEditViewMoreOptions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/31/25.
//

import SwiftUI

struct TransactionEditViewMoreOptions: View {
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Bindable var trans: CBTransaction
    @Binding var showSplitSheet: Bool
    var isTemp: Bool
    @Binding var navPath: NavigationPath
    @Binding var showBadgeBell: Bool
    @Binding var showHiddenEye: Bool
    
    var titleColorDescription: String {
        trans.color == .primary ? (colorScheme == .dark ? "White" : "Black") : trans.color.description.capitalized
    }
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            Section {
                NavigationLink(value: TransNavDestination.titleColorMenu) {
                    HStack {
                        Label {
                            Text("Title Color")
                        } icon: {
                            //Image(systemName: "paintbrush")
                            Image(systemName: "paintpalette")
                                .symbolRenderingMode(.multicolor)
                                //.foregroundStyle(trans.color)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        Text(titleColorDescription)
                            .foregroundStyle(trans.color)
                    }
                    
                }
            }
            
            Section {
                factorInCalculationsToggleRow
            } footer: {
                Text("Choose if this transaction should be included in calculations and analytics.")
            }
            
            if !isTemp {
                Section {
                    notificationButton
                    if trans.notifyOnDueDate {
                        ReminderPicker(title: "for…", notificationOffset: $trans.notificationOffset)
                    }
                } footer: {
                    if trans.notifyOnDueDate {
                        Text("You will be notified around 9:00 AM.")
                            //.foregroundStyle(.gray)
                            //.font(.caption)
                            //.multilineTextAlignment(.leading)
                    }
                }
            }
            
            
            if !isTemp {
                Section {
                    //copyButton
                    splitButton
                } footer: {
                    Text("Split this transaction into multiple categories & amounts.")
                }
                .disabled(trans.title.isEmpty)
                
                Section {
                    copyButton
                    //splitButton
                } footer: {
                    Text("Touch and hold on a day to paste.")
                }
                .disabled(trans.title.isEmpty)
            }
            
            Section {
                Picker("", selection: $transactionTitleSuggestionType) {
                    Label {
                        Text("History")
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundStyle(.gray)
                    }
                    .tag(TitleSuggestionType.history)
                    
                    Label {
                        Text("Locations")
                    } icon: {
                        Image(systemName: "map")
                            .foregroundStyle(.gray)
                    }
                    .tag(TitleSuggestionType.location)

//                    Label("History", systemImage: "clock")
//                        .tag(TitleSuggestionType.history)
//                    Label("Locations", systemImage: "map")
//                        .tag(TitleSuggestionType.location)
                }
                .labelsHidden()
                .pickerStyle(.inline)
                //.pickerStyle(.navigationLink)

//                Menu("Title Suggestions") {
//                    Button {
//                        transactionTitleSuggestionType = .history
//                    } label: {
//                        Label("History", systemImage: "clock")
//                    }
//
//                    Button {
//                        transactionTitleSuggestionType = .history
//                    } label: {
//                        Label("Locations", systemImage: "map")
//                    }
//                }
            } header: {
                Text("Title Autofill Suggestions")
            } footer: {
                let description: LocalizedStringKey = "When entering a title, choose how suggestions are made.\n**History** will search your past transactions.\n**Locations** will search nearby businesses."
                Text(description)
            }
        }
        .navigationTitle("Transaction Options")        
    }
    
    
    var copyButton: some View {
        Button {
            
            if trans.title.isEmpty {
                navPath.removeLast()
                AppState.shared.showToast(
                    title: "Failed To Copy",
                    body: "Title cannot be blank",
                    symbol: "exclamationmark.triangle",
                    symbolColor: .orange
                )
                return
            } else {
                calModel.transactionToCopy = trans
                navPath.removeLast()
                AppState.shared.showToast(
                    title: "\(trans.title) Copied",
                    symbol: "doc.on.doc.fill",
                    symbolColor: .green
                )
            }
            
            
        } label: {
            Text("Copy Transaction")
//            Label {
//                Text("Copy Transaction")
//            } icon: {
//                Image(systemName: "doc.on.doc.fill")
//            }
        }
    }
    
    var splitButton: some View {
        Button {
            navPath.removeLast()
            showSplitSheet = true
            
        } label: {
            Text("Split Transaction")
//            Label {
//                Text("Split Transaction")
//            } icon: {
//                Image(systemName: "plus.square.fill.on.square.fill")
//            }
        }
    }
    
    //@State private var bellDisabled = false
    /// Use a dedicated state property instead of `trans.notifyOnDueDate` otherwise the animation will be funky. Not sure why.
    var notificationButton: some View {
        Toggle(isOn: $trans.notifyOnDueDate.animation()) {
            Label {
                Text("Set Reminder")
            } icon: {
                Image(systemName: showBadgeBell ? "bell.badge" : "bell")
                    .foregroundStyle(.gray)
                    .symbolRenderingMode(showBadgeBell ? .multicolor : .monochrome)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.wiggle, value: trans.notifyOnDueDate)
                
                    /// Run initially so the symbol gets set properly if we have a notificaiton enabled.
                    .onChange(of: trans.notifyOnDueDate, initial: true) {
                        showBadgeBell = $1
                    }
            }
            
            //Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
        }
        .onChange(of: trans.notifyOnDueDate) {
            if !$1 {
                trans.notificationOffset = nil
            } else {
                trans.notificationOffset = 0
            }
        }
//        Button {
//            withAnimation {
//                if trans.notifyOnDueDate {
//                    trans.notifyOnDueDate = false
//                    trans.notificationOffset = nil
//                } else {
//                    trans.notifyOnDueDate = true
//                    trans.notificationOffset = 0
//                }
//            }
//            //navPath.removeLast()
//        } label: {
//            Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
////            Label {
////                Text(trans.notifyOnDueDate ? "Cancel Notification" : "Add Notification")
////            } icon: {
////                Image(systemName: trans.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
////            }
//        }
    }
    
//    var factorInCalculationsButton: some View {
//        Button {
//            withAnimation {
//                trans.factorInCalculations.toggle()
//            }
//            navPath.removeLast()
//        } label: {
//            Text(trans.factorInCalculations ? "Exclude from Calculations" : "Include in Calculations")
////            Label {
////                Text(trans.factorInCalculations ? "Exclude from Calculations" : "Include in Calculations")
////            } icon: {
////                Image(systemName: trans.factorInCalculations ? "eye.slash.fill" : "eye.fill")
////            }
//        }
//    }
    var factorInCalculationsToggleRow: some View {
        Toggle(isOn: $trans.factorInCalculations.animation()) {
            Label {
                Text("Include In Calculations")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: showHiddenEye ? "eye.slash" : "eye")
                    .foregroundStyle(.gray)
                    .contentTransition(.symbolEffect(.replace))
                    .onChange(of: trans.factorInCalculations) { old, new in
                        withAnimation { showHiddenEye = !new }
                    }
            }
        }
        .onAppear {
            if !trans.factorInCalculations {
                showHiddenEye = true
            }
        }
    }
    
}
