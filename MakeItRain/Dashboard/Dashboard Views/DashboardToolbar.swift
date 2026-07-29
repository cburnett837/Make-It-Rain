//
//  DashboardToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardToolbar: ToolbarContent {
    #if os(macOS)
    @Environment(\.dismiss) var dismiss
    #endif
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Bindable var model: DashboardModel
    @Binding var showCategorySheet: Bool
    @Binding var showPayMethodSheet: Bool
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
//            ToolbarItem(placement: .topBarTrailing) { showPaymentMethodSheetButton }
//            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            
            if !isForSelectedMonth {
                ToolbarItem(placement: .topBarTrailing) { refreshButton }
//                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            
            if model.payMethod != nil {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            
//            ToolbarItem(placement: .topBarTrailing) { showPaymentMethodSheetButton }
//            ToolbarItem(placement: .topBarTrailing) { showCategorySheetButton }
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
            }
        }
        
        ToolbarItemGroup(placement: .confirmationAction) {
            HStack {
                closeButton
            }
        }
        
        #endif
    }
    
    var refreshButton: some View {
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
    
    var showPaymentMethodSheetButton: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            PayMethodLogoMashup(meth: model.payMethod)
        }
        .tint(.none)
        .disabled(model.isLoading)
//        .if(model.payMethod != nil) {
//            $0.badge(1)
//        }
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
        .if(!model.allCatsSelected) {
            $0.badge(model.categories.count + model.groups.count)
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
            if model.payMethod == nil {
                Image(systemName: "ellipsis")
            } else {
                PayMethodLogoMashup(meth: model.payMethod)
            }
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
