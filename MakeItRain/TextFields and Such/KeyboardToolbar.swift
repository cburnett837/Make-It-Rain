//
//  KeyboardToolbar.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/25/24.
//

import SwiftUI

#if os(iOS)
struct KeyboardToolbarView: View {
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) var colorScheme
    
    var focusedField: FocusState<Int?>.Binding
    
    var removeNavButtons: Bool = false
    
    var disableUp: Bool = false
    var disableDown: Bool = false
    
    
    var accessoryText1: String?
    var accessoryImage1: String?
    var accessoryFunc1: (() -> Void)?
    var focusUpExtraFunction: (() -> Void)?
    
    var accessoryText2: String?
    var accessoryImage2: String?
    var accessoryFunc2: (() -> Void)?
    var focusDownExtraFunction: (() -> Void)?
    
    var accessoryText3: String?
    var accessoryImage3: String?
    var accessoryFunc3: (() -> Void)?
    
    var accessoryText4: String?
    var accessoryImage4: String?
    var accessoryFunc4: (() -> Void)?
    
    
//    var accessoryText4: String?
//    var accessoryImage4: String?
//    var accessoryFunc4: (() -> Void)?
//    
    var extraDoneFunctionality: (() -> Void)?
    
    
    private var canUseLiquidGlass: Bool {
        guard #available(iOS 26, *) else {
            return false
        }
        return true
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            theView
                .glassEffect()
                .padding(.bottom, 8)
                .scenePadding(.horizontal)
        } else {
            theView
        }
        
    }
    
    var theView: some View {
        VStack(spacing: 0) {
            //Divider()
            
            HStack {
                HStack(spacing: 25) {
                    if accessoryText1 == nil && accessoryText2 == nil && accessoryImage1 == nil && accessoryImage2 == nil {
                        if !removeNavButtons {
                            
                            Button {
                                if let _ = focusedField.wrappedValue {
                                    focusedField.wrappedValue! -= 1
                                }
                                if let focusUpExtraFunction = focusUpExtraFunction {
                                    focusUpExtraFunction()
                                }
                                
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                            .schemeBasedTint()
                            .disabled(disableUp)
                            
                            Button {
                                if let _ = focusedField.wrappedValue {
                                    focusedField.wrappedValue! += 1
                                }
                                
                                if let focusDownExtraFunction = focusDownExtraFunction {
                                    focusDownExtraFunction()
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .schemeBasedTint()
                            .disabled(disableDown)
                        }
                        
                    } else {
                        if let accessoryFunc1 = accessoryFunc1 {
                            Button {
                                accessoryFunc1()
                            } label: {
                                if let accessoryText1 {
                                    Text(accessoryText1)
                                        //.font(.body)
                                        .font(.title2)
                                } else {
                                    if let accessoryImage1 {
                                        Image(systemName: accessoryImage1)
                                    }
                                }
                            }
                            .schemeBasedTint()
                        }
                        
                        if let accessoryFunc2 = accessoryFunc2 {
                            Button {
                                accessoryFunc2()
                            } label: {
                                if let accessoryText2 {
                                    Text(accessoryText2)
                                        //.font(.body)
                                        .font(.title2)
                                } else {
                                    if let accessoryImage2 {
                                        Image(systemName: accessoryImage2)
                                    }
                                }
                            }
                            .schemeBasedTint()
                        }
                    }
                }
                                        
                Spacer()
                            
                HStack(spacing: 25) {
                    if let accessoryFunc3 = accessoryFunc3 {
                        Button {
                            accessoryFunc3()
                        } label: {
                            if let accessoryText3 {
                                Text(accessoryText3)
                                    //.font(.body)
                                    .font(.title2)
                            } else {
                                if let accessoryImage3 {
                                    Image(systemName: accessoryImage3)
                                }
                            }
                        }
                        .schemeBasedTint()
                    }
                    
                    if let accessoryFunc4 = accessoryFunc4 {
                        Button {
                            accessoryFunc4()
                        } label: {
                            if let accessoryText4 {
                                Text(accessoryText4)
                                    .font(.body)
                            } else {
                                if let accessoryImage4 {
                                    Image(systemName: accessoryImage4)
                                }
                            }
                        }
                        .schemeBasedTint()
                    }

                    Button {
                        focusedField.wrappedValue = nil
                        
                        if let extra = extraDoneFunctionality {
                            extra()
                        }
                        
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                        //Text("Done")
                            //.font(.body)
    //                    Image(systemName: "keyboard.chevron.compact.down")
    //                        .foregroundStyle(.gray)
                    }
                    .schemeBasedTint()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .if(!canUseLiquidGlass) {
                $0.background(Color(.tertiarySystemBackground))
            }
            //.background(Color(.red))
            .font(.title2)
            //.schemeBasedForegroundStyle()
            //.foregroundStyle(Color.theme)
        }
    }
}

/// NOT USED - custom shitty swiftui implementation that goes with the .keyboardToolbar Modifier. 1/2/25
//struct KeyboardToolbarView4: View {
//    //@Local(\.colorTheme) var colorTheme
//    
//    @Binding var text: String
//    var focusedField: FocusState<Int?>.Binding
//    var focusViews: [FocusView]
//    
//    var body: some View {
//        HStack {
//            HStack(spacing: 10) {
//                Button {
//                    if let _ = focusedField.wrappedValue {
//                        focusedField.wrappedValue! -= 1
//                    }
//                } label: {
//                    Image(systemName: "chevron.up")
//                        .padding(.horizontal, 5)
//                        .padding(.vertical, 8)
//                        .contentShape(Rectangle())
//                        //.background(Color.red)
//                }
//                
//                
//                Button {
//                    if let _ = focusedField.wrappedValue {
//                        focusedField.wrappedValue! += 1
//                    }
//                } label: {
//                    Image(systemName: "chevron.down")
//                        .padding(.horizontal, 5)
//                        .padding(.vertical, 8)
//                        .contentShape(Rectangle())
//                        //.background(Color.red)
//                }
//                
//            }
//                        
//            Spacer()
//                        
//            HStack(spacing: 10) {
//                
//                let focusView = focusViews.filter { $0.focusID == focusedField.wrappedValue }.first
//                if let focusView = focusView {
//                    focusView.view
//                        .padding(.horizontal, 5)
//                        .padding(.vertical, 8)
//                        .contentShape(Rectangle())
//                        //.background(Color.red)
//                }
//                
//                
//                
//                Button {
//                    focusedField.wrappedValue = nil
//                } label: {
//                    Image(systemName: "keyboard.chevron.compact.down")
//                        .foregroundStyle(.gray)
//                        .padding(.horizontal, 5)
//                        .padding(.vertical, 8)
//                        .contentShape(Rectangle())
//                        //.background(Color.red)
//                }
//            }
//            
//                        
////            Button("Close") {
////                focusedField.wrappedValue = nil
////            }
//        }
//        .padding(.horizontal)
//        //.padding(.vertical, 10)
//        .background(Color(.tertiarySystemBackground))
//        .font(.title3)
//        .foregroundStyle(Color.theme)
//    }
//}
#endif
