//
//  SmartReceiptViews.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/10/25.
//

import Foundation
import SwiftUI

//struct SmartReceiptDatePicker: View {
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @Environment(CalendarModel.self) private var calModel
//    
//    @Bindable var trans: CBTransaction
//        
//    var body: some View {
//        @Bindable var calModel = calModel
//        
//        Text("\((trans.date ?? Date()).string(to: .monthDayShortYear))")
//            //.fontWeight(.bold)
//            .foregroundStyle(preferDarkMode ? .white : .black)
//            .padding(.vertical, 10)
//            .frame(maxWidth: .infinity)
//            //.background(.gray.gradient, in: .rect(cornerRadius: 10))
//            .overlay {
//                DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
//                    .datePickerStyle(.compact)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .labelsHidden()
//                    .contentShape(Rectangle())
//                    .colorMultiply(.clear)
//            }
//    }
//}
//
//struct SmartReceiptPaymentMethodMenu: View {
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @Environment(CalendarModel.self) private var calModel
//    
//    
//    var body: some View {
//        @Bindable var calModel = calModel
//        
//        PaymentMethodMenu(
//            payMethod: Binding(
//                get: { calModel.pendingSmartTransaction?.payMethod == nil ? CBPaymentMethod() : calModel.pendingSmartTransaction?.payMethod },
//                set: { calModel.pendingSmartTransaction?.payMethod = $0 }
//            ),
//            whichPaymentMethods: .allExceptUnified,
//            content: {
//                Text((calModel.pendingSmartTransaction?.payMethod == nil ? "Payment Method" : calModel.pendingSmartTransaction?.payMethod!.title) ?? "Payment Method")
//                    //.fontWeight(.bold)
//                    //.foregroundStyle(preferDarkMode ? .white : .black)
//                    .foregroundStyle(preferDarkMode ? .white : .black)
//                    .padding(.vertical, 10)
//                    .frame(maxWidth: .infinity)
//                    //.background(.gray.gradient, in: .rect(cornerRadius: 10))
//            }
//        )
//    }
//}
//
//
//
//
//struct SmartReceiptDatePickerOG: View {
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @Environment(CalendarModel.self) private var calModel
//    
//    
//    var body: some View {
//        @Bindable var calModel = calModel
//        
//        Text("\((calModel.pendingSmartTransaction?.date ?? Date()).string(to: .monthDayShortYear))")
//            //.fontWeight(.bold)
//            .foregroundStyle(preferDarkMode ? .white : .black)
//            .padding(.vertical, 10)
//            .frame(maxWidth: .infinity)
//            //.background(.gray.gradient, in: .rect(cornerRadius: 10))
//            .overlay {
//                if let _ = calModel.pendingSmartTransaction {
//                    DatePicker("", selection: Binding($calModel.pendingSmartTransaction)!.date ?? Date(), displayedComponents: [.date])
//                        .datePickerStyle(.compact)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .labelsHidden()
//                        .contentShape(Rectangle())
//                        .colorMultiply(.clear)
//                }
//            }
//    }
//}
//
//struct SmartReceiptPaymentMethodMenuOG: View {
//    @AppStorage("preferDarkMode") var preferDarkMode: Bool = true
//    @Environment(CalendarModel.self) private var calModel
//    
//    
//    var body: some View {
//        @Bindable var calModel = calModel
//        
//        PaymentMethodMenu(
//            payMethod: Binding(
//                get: { calModel.pendingSmartTransaction?.payMethod == nil ? CBPaymentMethod() : calModel.pendingSmartTransaction?.payMethod },
//                set: { calModel.pendingSmartTransaction?.payMethod = $0 }
//            ),
//            whichPaymentMethods: .allExceptUnified,
//            content: {
//                Text((calModel.pendingSmartTransaction?.payMethod == nil ? "Payment Method" : calModel.pendingSmartTransaction?.payMethod!.title) ?? "Payment Method")
//                    //.fontWeight(.bold)
//                    //.foregroundStyle(preferDarkMode ? .white : .black)
//                    .foregroundStyle(preferDarkMode ? .white : .black)
//                    .padding(.vertical, 10)
//                    .frame(maxWidth: .infinity)
//                    //.background(.gray.gradient, in: .rect(cornerRadius: 10))
//            }
//        )
//    }
//}
