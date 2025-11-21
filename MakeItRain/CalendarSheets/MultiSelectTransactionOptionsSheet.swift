//
//  MultiSelectTransactionOptionsSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/28/25.
//

import SwiftUI

struct MultiSelectTransactionOptionsSheet: View {
    //@Local(\.colorTheme) var colorTheme
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
    @State private var showCategorySheet = false
    @State private var selectedCategory: CBCategory?
        
    @Binding var showInspector: Bool
    
    
    var body: some View {
        #if os(iOS)
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
        #else
        sheetHeader
            /// Need this in case the user clicks the red close button.        
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
        Section {
            summarizeButton
            deleteButton
        }
        
        Section {
            MultiTitleColorMenu(transactions: calModel.multiSelectTransactions, shouldSave: $shouldSave) { Text("Change title color") }
            changeCategoryButton
            factorInCalculationsButton
            excludeFromCalculationsButton
        }
    }
    
    
    var contentGrid: some View {
        TagLayout {
            summarizeButton
            deleteButton
            MultiTitleColorMenu(transactions: calModel.multiSelectTransactions, shouldSave: $shouldSave) { Text("Change title color") }
            changeCategoryButton
            factorInCalculationsButton
            excludeFromCalculationsButton
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
                .schemeBasedForegroundStyle()
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
                    trans.factorInCalculations = true
                    
                    if trans.relatedTransactionID != nil && trans.relatedTransactionType?.enumID == .transaction {
                        let trans2 = calModel.getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                        trans2.factorInCalculations = true
                    }
                }
            }
            shouldSave = true
            
            Task {
                let _ = calModel.calculateTotal(for: calModel.sMonth)
            }            
        } label: {
            Text("Include in calculations")
        }
    }
    
    var excludeFromCalculationsButton: some View {
        Button {
            withAnimation {
                for trans in calModel.multiSelectTransactions {
                    trans.factorInCalculations = false
                    
                    if trans.relatedTransactionID != nil && trans.relatedTransactionType?.enumID == .transaction {
                        let trans2 = calModel.getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                        trans2.factorInCalculations = false
                    }
                }
            }
            shouldSave = true
            
            Task {
                let _ = calModel.calculateTotal(for: calModel.sMonth)
            }
        } label: {
            Text("Exclude from calculations")
        }
    }
    
    
    var changeCategoryButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Text("Change category")
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            withAnimation {
                for trans in calModel.multiSelectTransactions {
                    trans.category = selectedCategory
                    
                    if trans.relatedTransactionID != nil && trans.relatedTransactionType?.enumID == .transaction {
                        let trans2 = calModel.getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                        trans2.category = selectedCategory
                    }
                    
                }
                selectedCategory = nil
            }
            shouldSave = true
        }) {
            CategorySheet(category: $selectedCategory)
        }
    }
    
    var deleteButton: some View {
        Button {
            withAnimation {
                for trans in calModel.multiSelectTransactions {
                    trans.action = .delete
                    trans.intendedServerAction = .delete
                    /// Pre set the status so the trash icon will show.
                    /// However, the delete operation will not perform until the user closes the sheet,
                    trans.status = .deleteSucceess
                    
                    //trans.active = false
                    //calModel.performLineItemAnimations(for: trans)
                    if trans.relatedTransactionID != nil && trans.relatedTransactionType?.enumID == .transaction {
                        let trans2 = calModel.getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                        //trans2.deepCopy(.create)
                        trans2.action = .delete
                        trans2.intendedServerAction = .delete
                        /// Pre set the status so the trash icon will show.
                        /// However, the delete operation will not perform until the user closes the sheet,
                        trans2.status = .deleteSucceess
                    }
                }
                selectedCategory = nil
            }
            shouldSave = true
        } label: {
            Text("Delete")
        }
        .tint(.red)
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
                
                var transToEdit = calModel.multiSelectTransactions
                
                if shouldSave {
                    for trans in transToEdit {
                        if trans.relatedTransactionID != nil && trans.relatedTransactionType?.enumID == .transaction {
                            let trans2 = calModel.getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                            transToEdit.append(trans2)
                        }
                    }
                    
                    Task {
                        
                        
                        print("editing multiple transactions \(transToEdit)")
                        
                        await calModel.editMultiple(trans: transToEdit)
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
