//
//  EventCategoryView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//

import SwiftUI

struct EventCategoryView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
   
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var category: CBEventCategory
    @Bindable var event: CBEvent
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { category.action == .add ? "New Category" : "Edit Category" }
    
    @FocusState private var focusedField: Int?
    @State private var showSymbolPicker = false
                
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var body: some View {
        categoryPage
        .task {
            await prepareCategoryView()
        }
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                dismiss()
                event.deleteCategory(id: category.id)
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        
    }
    
    
    var categoryPage: some View {
        StandardContainer {
            LabeledRow("Name", labelWidth) {
                #if os(iOS)
                StandardUITextField("Title", text: $category.title, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 0)
                .cbClearButtonMode(.whileEditing)
                #else
                StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
                #endif
            }
                        
            StandardDivider()
            
            LabeledRow("Color", labelWidth) {
                //ColorPickerButton(color: $category.color)
                HStack {
                    ColorPicker("", selection: $category.color, supportsOpacity: false)
                        .labelsHidden()
                    Capsule()
                        .fill(category.color)
                        .onTapGesture {
                            AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: category.emoji ?? "theatermask.and.paintbrush", symbolColor: category.color)
                        }
                }
            }
                        
            StandardDivider()
            
            LabeledRow("Symbol", labelWidth) {
                #if os(macOS)
                HStack {
                    Button {
//                      Task {
//                          focusedField = .emoji
//                          try? await Task.sleep(for: .milliseconds(100))
//                          NSApp.orderFrontCharacterPalette($category.emoji)
//                      }
                        showSymbolPicker = true
                    } label: {
                        Image(systemName: category.emoji ?? "questionmark.circle.fill")
                            .foregroundStyle(category.color)
                    }
                    .buttonStyle(.codyStandardWithHover)
                    Spacer()
                }
                
                #else
                HStack {
                    Image(systemName: category.emoji ?? "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(category.color.gradient)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showSymbolPicker = true
                }
                #endif
            }
            
            StandardDivider()
          
            
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
                        
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPicker(selected: $category.emoji)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                //.frame(width: 300)
            #endif
        }
    }
    
    func closeSheet() {
        editID = nil
        dismiss()
    }
    
    
    func prepareCategoryView() async {
        category.deepCopy(.create)
        event.upsert(category)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if category.action == .add {
            focusedField = 0
        }
        #endif
    }
    
}
