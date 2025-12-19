////
////  CalendarFakeNavHeader.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/3/25.
////
//
//import SwiftUI
//import TipKit
//
//struct CalendarFakeNavHeader: View {
//    @Environment(CalendarProps.self) private var calProps
//    @Environment(CalendarModel.self) private var calModel
//    
//    var body: some View {
//        CalendarMonthLabel()
//            .padding(.bottom, 10)
//            .scenePadding(.horizontal)
//        
////        HStack {
////            @Bindable var calModel = calModel
////            Menu {
////                Section("Accounts") {
////                    Button(calModel.sPayMethod?.title ?? "Select Account") {
////                        calProps.showPayMethodSheet = true
////                    }
////                }
////                
////                Section("Optional Filter By Categories") {
////                    Button(calModel.sCategory?.title ?? "Select Categories") {
////                        calProps.showCategorySheet = true
////                        //TouchAndHoldMonthToFilterCategoriesTip.didSelectCategoryFilter = true
////                        //touchAndHoldMonthToFilterCategoriesTip.invalidate(reason: .actionPerformed)
////                    }
////                    
////                    if !calModel.sCategories.isEmpty {
////                        Button("Reset", role: .destructive) {
////                            calModel.sCategories.removeAll()
////                        }
////                    }
////                }
////            } label: {
////                CalendarMonthLabel()
////                    .contentShape(Rectangle())
////            } primaryAction: {
////                calProps.showPayMethodSheet = true
////            }
////            .layoutPriority(1)
////            //.padding(.leading, 16)
////            .scenePadding(.horizontal)
////            .padding(.bottom, 4)
////            .frame(maxWidth: .infinity, alignment: .leading)
////        }
////        .padding(.bottom, 10)
////        .contentShape(Rectangle())
//    }
//}
