//
//  PayMethodTableReorderList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/13/26.
//


import SwiftUI
import LocalAuthentication

struct PayMethodTableReorderList: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(payModel.sections) { section in
                    Section(section.rawValue) {
                        ForEach(methodsBinding(for: section)) { meth in
                            HStack {
                                Label {
                                    Text(meth.wrappedValue.title)
                                } icon: {
                                    PayMethodLogoMashup(meth: meth.wrappedValue)
                                }
                                
                                if !meth.wrappedValue.isPermittedAndNotHidden || !meth.wrappedValue.accountHolderFilter() {
                                    Image(systemName: "eye.slash")
                                }
                                
                                Spacer()
                                
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)

                            }
                        }
                        .if(AppSettings.shared.paymentMethodSortMode == .listOrder) {
                            $0.onMove { indices, newOffset in
                                methodsBinding(for: section)
                                    .wrappedValue
                                    .move(fromOffsets: indices, toOffset: newOffset)
                                
                                Task {
                                    let updates = await payModel.setListOrders(calModel: calModel)
                                    await funcModel.submitListOrders(items: updates, for: .paymentMethods)
                                }
                            }
                        }
                    }
                }
            }
            //.listStyle(.plain)
            .navigationTitle("Reorder Accounts")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
                #else
                ToolbarItem(placement: .principal) {
                    closeButton
                }
                #endif
            }
        }
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    func methodsBinding(for section: PaymentMethodSection) -> Binding<[CBPaymentMethod]> {
        Binding(
            get: {
                payModel.getMethodsFor(
                    section: section,
                    type: .all,
                    sText: "",
                    includeHidden: true,
                    respectFilter: false
                )
            },
            set: { newValue in
                for (index, method) in newValue.enumerated() {
                    if let globalIndex = payModel.paymentMethods.firstIndex(where: { $0.id == method.id }) {
                        payModel.paymentMethods[globalIndex].listOrder = index
                    }
                }
            }
        )
    }
}
