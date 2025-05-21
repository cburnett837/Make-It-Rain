//
//  MultiSelectTransactionOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/28/25.
//

import SwiftUI

struct MultiSelectTransactionOptionsSheet: View {
    @Local(\.colorTheme) var colorTheme
    
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    #endif
    @Environment(CalendarModel.self) private var calModel
    
    @Binding var bottomPanelContent: BottomPanelContent?
    @Binding var bottomPanelHeight: CGFloat
    @Binding var scrollContentMargins: CGFloat
    @Binding var showAnalysisSheet: Bool
    
    @State private var shouldSave = false
        
    
    var body: some View {
        StandardContainer(AppState.shared.isIpad ? .sidebarScrolling : .bottomPanel) {
            content
        } header: {
            if AppState.shared.isIpad {
                sidebarHeader
            } else {
                sheetHeader
            }
        } subHeader: {
            Text("What would you like to do with the selected transactions?")
                .foregroundStyle(.secondary)
                .font(.subheadline)
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
    
    
    var content: some View {
        TagLayout {
            Button("Summarize") {
                calModel.sCategoriesForAnalysis = calModel.multiSelectTransactions
                    .compactMap(\.category)
                    .uniqued(on: \.id)
                
                #if os(iOS)
                withAnimation {
                    showAnalysisSheet = true
                    
                    if AppState.shared.isIpad {
                        bottomPanelContent = .categoryAnalysis
                    }
                }
                #else
                openWindow(id: "analysisSheet")
                #endif
                
            }
            .buttonStyle(.borderedProminent)
                        
            MultiTitleColorMenu(transactions: calModel.multiSelectTransactions, shouldSave: $shouldSave) {
                Text("Change Title Color")
            }
            .buttonStyle(.borderedProminent)
            
            factorInCalculationsButton
        }
        .padding(.top, 6)
    }
    
    
    var sheetHeader: some View {
        SheetHeader(
            title: "Multi-Select Options",
            close: {
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
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
        )
        #if os(iOS)
        .bottomPanelAndScrollViewHeightAdjuster(bottomPanelHeight: $bottomPanelHeight, scrollContentMargins: $scrollContentMargins)
        #endif
    }
    
    
    var sidebarHeader: some View {
        SidebarHeader(
            title: "Multi-Select Options",
            close: {
                #if os(iOS)
                withAnimation {
                    bottomPanelContent = nil
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
                dismiss()
                #endif
            }
        )
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
        .buttonStyle(.borderedProminent)
    }
}
