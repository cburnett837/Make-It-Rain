//
//  MultiSelectTransactionOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/28/25.
//

import SwiftUI

struct MultiSelectTransactionOptionsSheet: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    #endif
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    
//    @Binding var bottomPanelContent: BottomPanelContent?
//    @Binding var bottomPanelHeight: CGFloat
//    @Binding var scrollContentMargins: CGFloat
//    @Binding var showAnalysisSheet: Bool
    
    @State private var shouldSave = false
        
    @Binding var showInspector: Bool
    
    
    var body: some View {
        if AppState.shared.isIphone {
            StandardContainer(.bottomPanel) {
                contentGrid
            } header: {
                sheetHeader
            }
        } else {
            NavigationStack {
                StandardContainerWithToolbar(.list) {
                    contentList
                }
                .navigationTitle("Multi-Select Options")
                .navigationSubtitle("What would you like to do with the selected transactions?")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { closeButton }
                }
                #endif
            }
        }
        /// Need this in case the user clicks the red close button.
        #if os(macOS)
        .onDisappear {
            withAnimation {
                calModel.isInMultiSelectMode = false
                calModel.sCategoriesForAnalysis.removeAll()
                
                if shouldSave {
                    Task {
                        await calModel.editMultiple(trans: calModel.multiSelectTransactions)
                        calModel.multiSelectTransactions.removeAll()
                    }
                } else {
                    calModel.multiSelectTransactions.removeAll()
                }
            }
        }
        #endif
    }
    
    
    @ViewBuilder
    var contentList: some View {
        summarizeButton
        MultiTitleColorMenu(transactions: calModel.multiSelectTransactions, shouldSave: $shouldSave) { Text("Change Title Color") }
        factorInCalculationsButton
    }
    
    
    var contentGrid: some View {
        TagLayout {
            summarizeButton
            MultiTitleColorMenu(transactions: calModel.multiSelectTransactions, shouldSave: $shouldSave) { Text("Change Title Color") }
            factorInCalculationsButton
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 6)
    }
    
    
    @ViewBuilder var sheetHeader: some View {
        @Bindable var calProps = calProps
        SheetHeader(
            title: "Multi-Select Options",
            close: {
                closeSheet()
            }
        )
//        #if os(iOS)
//        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $calProps.bottomPanelHeight, scrollContentMargins: $calProps.scrollContentMargins)
//        #endif
    }
    
    
    var closeButton: some View {
        Button {
            closeSheet()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var summarizeButton: some View {
        Button("Summarize") {
            calModel.sCategoriesForAnalysis = calModel.multiSelectTransactions
                .compactMap(\.category)
                .uniqued(on: \.id)
            
            #if os(iOS)
            withAnimation {
                //calProps.showAnalysisSheet = true
                
                if AppState.shared.isIphone {
                    calProps.showAnalysisSheet = true
                } else {
                    calProps.inspectorContent = .analysisSheet
                    calProps.showInspector = true
                }
            }
            #else
            openWindow(id: "analysisSheet")
            #endif
            
        }
    }
    
    
    var factorInCalculationsButton: some View {
        Button {
            withAnimation {
                for trans in calModel.multiSelectTransactions {
                    trans.factorInCalculations.toggle()
                }
            }
            shouldSave = true
            
            Task {
                let _ = calModel.calculateTotal(for: calModel.sMonth)
            }            
        } label: {
            let isTrue = calModel.multiSelectTransactions.map { $0.factorInCalculations }.allSatisfy { $0 }
            Label {
                Text(isTrue ? "Exclude from Calculations" : "Include in Calculations")
            } icon: {
                Image(systemName: isTrue ? "eye.slash.fill" : "eye.fill")
            }
        }
    }
    
    
    func closeSheet() {
        #if os(iOS)
            withAnimation {
                if AppState.shared.isIphone {
                    calProps.bottomPanelContent = nil
                } else {
                    showInspector = false
                }
                calModel.isInMultiSelectMode = false
                calModel.sCategoriesForAnalysis.removeAll()
                
                if shouldSave {
                    Task {
                        await calModel.editMultiple(trans: calModel.multiSelectTransactions)
                        calModel.multiSelectTransactions.removeAll()
                    }
                } else {
                    calModel.multiSelectTransactions.removeAll()
                }
            }
        #else
            /// Clean up & saving logic will be handled in the .onDisappear()
            dismiss()
        #endif
    }
}
