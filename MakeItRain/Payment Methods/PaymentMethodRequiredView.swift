//
//  PaymentMethodRequiredView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/28/25.
//

import SwiftUI


struct PaymentMethodRequiredView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FuncModel.self) private var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var editPaymentMethod: CBPaymentMethod?
    @State private var paymentMethodEditID: CBPaymentMethod.ID?
    @State private var showLoadingSpinner = false
    
    var body: some View {
        VStack {
            Spacer()
            
            ContentUnavailableView("Let's Make it Rain", systemImage: "creditcard", description: Text("Get started by adding a payment method"))
            Spacer()
            
            if showLoadingSpinner {
                ProgressView {
                    Text("Saving…")
                }
            } else {
                Button("Add Payment Method") {
                    paymentMethodEditID = UUID().uuidString
                }
                .focusable(false)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .background(.green.gradient, in: .capsule)
                .buttonStyle(.plain)
                
                Button("Logout") {
                    AppState.shared.showPaymentMethodNeededSheet = false
                    funcModel.logout()
                }
                .focusable(false)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .background(.green.gradient, in: .capsule)
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $editPaymentMethod, onDismiss: {
            paymentMethodEditID = nil
        }, content: { meth in
            PayMethodView(payMethod: meth, payModel: payModel, editID: $paymentMethodEditID)
        })
        .onChange(of: paymentMethodEditID) { oldValue, newValue in
            if let newValue {
                let payMethod = payModel.getPaymentMethod(by: newValue)
                editPaymentMethod = payMethod
            } else {
                /// Slimmed down logic from `payModel.savePaymentMethod()`
                let payMethod = payModel.getPaymentMethod(by: oldValue!)
                if payMethod.title.isEmpty {
                    if payMethod.action != .add && payMethod.title.isEmpty {
                        payMethod.title = payMethod.deepCopy?.title ?? ""
                    }
                    return
                }
                                
                Task {
                    showLoadingSpinner = true
                    /// Save the newly created payment method to the server.
                    let _ = await payModel.submit(payMethod)
                    /// Fetch the newly added payment method, plus the 2 unified methods from the server.
                    await payModel.fetchPaymentMethods(calModel: calModel)
                    /// Allow entry into the normal app.
                    AppState.shared.methsExist = true
                    /// Close the sheet, which will kick off the normal download task.
                    dismiss()
                }
            }
        }
    }
}


