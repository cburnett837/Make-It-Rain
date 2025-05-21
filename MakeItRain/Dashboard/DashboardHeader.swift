//
//  DashboardHeader.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/25.
//

import SwiftUI

struct DashboardHeader: View {
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    //'@Bindable var model: DashboardModel
    //@Binding var selectedWidgets: [DashboardWidget]
    //@Binding var updateWidget: Bool
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(calModel.sMonth.name)
                        .font(.largeTitle)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                    
                    Text("\(String(calModel.sYear))")
                        .font(.title3)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack {
//                    if horizontalSizeClass == .regular {
//                        Image(systemName: "trash.fill")
//                            .foregroundColor(.gray)
//                            .symbolRenderingMode(.multicolor)
//                            .scaleEffect(1.5)
//                            .padding(.trailing, 16)
//                            .dropDestination(for: String.self) { items, location in
//                                //model.deleteWidget(key: items[0])
//                                return true
//                            }
//                    }
                    
                    
                    Button {
                        funcModel.refreshTask = Task {
                            LoadingManager.shared.showInitiallyLoadingSpinner = true
                            calModel.months.forEach { month in
                                month.days.removeAll()
                                month.budgets.removeAll()
                            }
                            calModel.prepareMonths()
                            await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.gray)
                            .symbolRenderingMode(.multicolor)
                            //.opacity(model.isLoading ? 0 : 1)
                            //.overlay(ProgressView().opacity(model.isLoading ? 1 : 0))
                            .scaleEffect(1.5)
                    }
                    .padding(.trailing, 16)
                                        
                    Menu {
                        Section("Available Widgets") {
//                            ForEach(model.availableWidgets, id: \.id) { serverWidget in
//                                let result = model.selectedWidgets.filter {$0.key == serverWidget.key}.count
//                                if result == 0 {
//                                    Button(serverWidget.name) {
//                                        Task {
//                                            model.insertNewWidget(key: serverWidget.key, name: serverWidget.name, listOrder: selectedWidgets.count)
//                                            await model.updateAllWidgets()
//                                        }
//                                    }
//                                }
//                            }
                        }
                        Button(role: .destructive) {
                            //model.deleteAllWidgets()
                        } label: {
                            Text("Remove All")
                        }
                        
                    } label: {
                        Image(systemName: "folder.fill.badge.plus")
                            .scaleEffect(1.5)
                            .symbolRenderingMode(.multicolor)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                    
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.gray)
                            //.symbolRenderingMode(.multicolor)
                            //.opacity(model.isLoading ? 0 : 1)
                            //.overlay(ProgressView().opacity(model.isLoading ? 1 : 0))
                            .scaleEffect(1.5)
                    }
                    
                    
                    
                    
                    
                }
                .padding(.trailing, 4)
            }
            Divider()
        }
        .padding(.top, 10)
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
}
