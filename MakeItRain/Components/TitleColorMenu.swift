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
                                #if os(iOS)
                                .tint(color)
                                #else
                                .foregroundStyle(color, color, color)
                                #endif
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
                                #if os(iOS)
                                .tint(color)
                                #else
                                .foregroundStyle(color, .primary, .secondary)
                                #endif
                                
                          }
                    }
                }
            }
        } label: {
            content
        }
    }
}
