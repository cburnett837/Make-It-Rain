//
//  TransactionEditViewTrackingAndOrder.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct TevTrackingAndOrder: View {
    @State private var showTrackingOrderAndUrlFields = false
    var symbolWidth: CGFloat
    @Binding var trackingNumber: String
    @Binding var orderNumber: String
    @Binding var url: String
    var focusedField: FocusState<Int?>.Binding
    
    var body: some View {
        Section {
            if showTrackingOrderAndUrlFields {
                trackingNumberTextField
                orderNumberTextField
                StandardUrlTextField(url: $url, symbolWidth: symbolWidth, focusedField: focusedField, focusID: 4, showSymbol: true)
            } else {
                
                Button {
                    withAnimation { showTrackingOrderAndUrlFields = true }
                } label: {
                    Label {
                        Text("Show Fields")
                            .schemeBasedForegroundStyle()
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            //.foregroundStyle(.gray)
                    }
                }
            }
        } header: {
            HStack {
                Text("Tracking, Order, & Link")
                Spacer()
                hideTrackingSectionButton
            }
        }
        .task {
            /// Show the tracking / url fields if there is a value in them.
            if !trackingNumber.isEmpty || !orderNumber.isEmpty || !url.isEmpty {
                showTrackingOrderAndUrlFields = true
            }
        }
    }
    
    
    @ViewBuilder
    var hideTrackingSectionButton: some View {
        if trackingNumber.isEmpty && orderNumber.isEmpty && url.isEmpty {
            if showTrackingOrderAndUrlFields {
                Button {
                    withAnimation { showTrackingOrderAndUrlFields = false }
                } label: {
                    Text("Hide")
                }
                .tint(Color.theme)
                //.buttonStyle(.borderedProminent)
            }
        }
    }
    
    
    var trackingNumberTextField: some View {
        GeometryReader { geo in
            NavigationLink(value: TransNavDestination.tracking) {
                HStack {
                    Label {
                        Text("Tracking #")
                    } icon: {
                        Image(systemName: "truck.box.fill")
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: geo.size.width / 2, alignment: .leading)

                    Text(trackingNumber)
                        .frame(maxWidth: geo.size.width / 2, alignment: .trailing)
                        .lineLimit(1)
                }
            }
        }
    }
    
    
    var orderNumberTextField: some View {
        HStack {
            Label {
                Text("Order #")
            } icon: {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(.gray)
            }
                        
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "ABC123", text: $orderNumber, onSubmit: {
                    focusedField.wrappedValue = 4
                }, toolbar: {
                    KeyboardToolbarView(focusedField: focusedField)
                })
                .uiTag(3)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.right)
                .uiReturnKeyType(.next)
                .uiAutoCorrectionDisabled(true)
                #else
                TextField("", text: $orderNumber, prompt: Text("ABC123")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .light))
                )
                .autocorrectionDisabled(true)
                .onSubmit { focusedField.wrappedValue = 4 }
                #endif
            }
            .focused(focusedField, equals: 3)
        }
        //.padding(.bottom, 6)
    }
}
