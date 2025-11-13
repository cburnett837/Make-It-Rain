//
//  TitleColorMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/24.
//

import SwiftUI

struct TitleColorMenu<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    @Environment(CalendarModel.self) private var calModel
    
    var transactions: Array<CBTransaction>
    let saveOnChange: Bool
    
    @ViewBuilder let content: Content
    
    var body: some View {
        Menu {
            Section("Default") {
                Button {
                    for trans in transactions {
                        trans.color = .primary
                        trans.updatedBy = AppState.shared.user!
                        trans.updatedDate = Date()
                        if saveOnChange {
                            //Task { await calModel.submit(trans) }
                            calModel.saveTransaction(id: trans.id)
                        }
                    }
                    
                } label: {
                    HStack { /// This can be a button or whatever you want
                        Text(colorScheme == .dark ? "White" : "Black")
                        Image(systemName: "circle.fill")
                            .tint(colorScheme == .dark ? .white : .black)
                            //.foregroundStyle(colorScheme == .dark ? .white : .black, .primary, .secondary)
                      }
                }
            }
            
            Section("Others") {
                ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                    Button {
                        for trans in transactions {
                            trans.color = color
                            trans.updatedBy = AppState.shared.user!
                            trans.updatedDate = Date()
                            if saveOnChange {
                                //Task { await calModel.submit(trans) }
                                calModel.saveTransaction(id: trans.id)
                            }
                        }
                    } label: {
                        HStack { /// This can be a button or whatever you want
                            Text(color.description.capitalized)
                            Image(systemName: "circle.fill")
                                .tint(color)
//                                #if os(iOS)
//                                .tint(color)
//                                #else
//                                .foregroundStyle(color, color, color)
//                                #endif
                                //.foregroundStyle(color, .primary, .secondary)
                          }
                    }
                }
            }
        } label: {
            content
        }                        
    }
}


struct TitleColorList: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var trans: CBTransaction
    let saveOnChange: Bool
    @Binding var navPath: NavigationPath

    
    var body: some View {
        List {
            Section("Default") {
                Button {
                    trans.color = .primary
                    trans.updatedBy = AppState.shared.user!
                    trans.updatedDate = Date()
                    if saveOnChange {
                        calModel.saveTransaction(id: trans.id)
                    }
                    navPath.removeLast()
                    
                } label: {
                    HStack {
                        Label(colorScheme == .dark ? "White" : "Black", systemImage: "circle.fill")
                            .schemeBasedForegroundStyle()
                        Spacer()
                        
                        if trans.color == .primary {
                            Image(systemName: "checkmark")
                        }
                    }
                    
                }
            }
            
            Section("Others") {
                ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                    Button {
                        trans.color = color
                        trans.updatedBy = AppState.shared.user!
                        trans.updatedDate = Date()
                        if saveOnChange {
                            calModel.saveTransaction(id: trans.id)
                        }
                        navPath.removeLast()
                    } label: {
                        HStack {
                            Label {
                                Text(color.description.capitalized)
                                    .schemeBasedForegroundStyle()
                            } icon: {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(color)
                            }
                            
                            Spacer()
                            
                            if trans.color == color {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Title Color")
    }
}


struct MultiTitleColorMenu<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    
    var transactions: Array<CBTransaction>
    @Binding var shouldSave: Bool
    @ViewBuilder let content: Content
    
    var body: some View {
        Menu {
            Section("Default") {
                Button {
                    for trans in transactions {
                        trans.color = .primary
                        trans.updatedBy = AppState.shared.user!
                        trans.updatedDate = Date()
                    }
                    shouldSave = true
                } label: {
                    HStack {
                        Text(colorScheme == .dark ? "White" : "Black")
                        Image(systemName: "circle.fill")
                            .tint(colorScheme == .dark ? .white : .black)
                            //.foregroundStyle(colorScheme == .dark ? .white : .black, .primary, .secondary)
                      }
                }
            }
            
            Section("Others") {
                ForEach(AppState.shared.colorMenuOptions, id: \.self) { color in
                    Button {
                        for trans in transactions {
                            trans.color = color
                            trans.updatedBy = AppState.shared.user!
                            trans.updatedDate = Date()
                        }
                        shouldSave = true
                    } label: {
                        HStack {
                            Text(color.description.capitalized)
                            Image(systemName: "circle.fill")
                                .tint(color)
//                                #if os(iOS)
//                                .tint(color)
//                                #else
//                                .foregroundStyle(color, .primary, .secondary)
//                                #endif
                                
                          }
                    }
                }
            }
        } label: {
            content
        }
    }
}
