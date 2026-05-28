//
//  DashboardToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardToolbar: ToolbarContent {
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var model: DashboardModel
    @Binding var showCategorySheet: Bool
    @Binding var showAnalysisSheet: Bool
    @Binding var navPath: [NavDest]
    var isForSelectedMonth: Bool
    
    //@ToolbarContentBuilder
    var body: some ToolbarContent {
        #if os(iOS)
                
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
        }
        
//        if !isForSelectedMonth {
//            ToolbarItem(placement: .topBarLeading) { showOptionsSheetButton }
//        }
        
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) { closeButton }
        } else {
            if !isForSelectedMonth {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await model.fetchDashboard()
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: model.isLoading)
                    }
                    .tint(.none)
                    .disabled(model.isLoading)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) { showCategorySheetButton }
            ToolbarItem(placement: .topBarTrailing) { showOptionsSheetButton }
        }

        if isForSelectedMonth {
            //ToolbarSpacer(.fixed, placement: .topBarLeading)
            if !model.categories.isEmpty || !model.groups.isEmpty {
                ToolbarItem(placement: .bottomBar) { showCalendarButton }
                //ToolbarSpacer(.fixed, placement: .topBarLeading)
            }
        }
        
        
        #else
        ToolbarItemGroup(placement: .destructiveAction) {
            HStack {
                showCategorySheetButton
                showMonthsButton
            }
        }
        
        ToolbarItemGroup(placement: .confirmationAction) {
            HStack {
                closeButton
            }
        }
        
        #endif
    }
    
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Label {
                Text("Select Categories")
            } icon: {
                Image(systemName: "books.vertical")
            }
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showOptionsSheetButton: some View {
        Button {
            model.showOptionsSheet = true
        } label: {
            Image(systemName: "ellipsis")
            //Text("\(model.formattedDateRange)")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showCalendarButton: some View {
        Button {
            withAnimation {
                calModel.sCategories = (model.categories + model.groups.flatMap { $0.categories }).uniqued(on: { $0.id })
                calModel.sPayMethod = nil
            }
                                    
            #if os(iOS)
            if AppState.shared.isIphone {
                navPath.removeLast()
            }
            #else
            //dismiss()
            #endif
            
        } label: {
            Text("View Filtered Calendar")
//            Label {
//                Text("View Filtered Calendar")
//            } icon: {
//                Image(systemName: "calendar")
//            }
        }
        .tint(.none)
    }
    
    
    var closeButton: some View {
        Button {
            #if os(iOS)
            withAnimation {
                calModel.isInMultiSelectMode = false
                showAnalysisSheet = false
            }
            #else
            dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
}
