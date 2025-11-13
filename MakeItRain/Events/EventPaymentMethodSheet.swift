////
////  EventPayMethodSheet.swift
////  MakeItRain
////
////  Created by Cody Burnett on 4/2/25.
////
//
//
//import SwiftUI
//
//struct EventPayMethodSheet: View {
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss
//    
//    @Environment(CalendarModel.self) private var calModel
//    
//    @Environment(PayMethodModel.self) private var payModel
//        
//    @Binding var payMethod: CBPaymentMethod?
//    var trans: CBTransaction?
//    let calcAndSaveOnChange: Bool
//    let whichPaymentMethods: ApplicablePaymentMethods
//    var isPendingSmartTransaction: Bool
//    
//    init(payMethod: Binding<CBPaymentMethod?>, whichPaymentMethods: ApplicablePaymentMethods) {
//        //print("-- \(#function)")
//        self._payMethod = payMethod
//        self.trans = nil
//        self.calcAndSaveOnChange = false
//        self.whichPaymentMethods = whichPaymentMethods
//        self.isPendingSmartTransaction = false
//    }
//    
//    
//    init(payMethod: Binding<CBPaymentMethod?>, trans: CBTransaction?, calcAndSaveOnChange: Bool, whichPaymentMethods: ApplicablePaymentMethods, isPendingSmartTransaction: Bool = false) {
//        //print("-- \(#function)")
//        self._payMethod = payMethod
//        self.trans = trans
//        self.calcAndSaveOnChange = calcAndSaveOnChange
//        self.whichPaymentMethods = whichPaymentMethods
//        self.isPendingSmartTransaction = isPendingSmartTransaction
//    }
//    
//    
//    @FocusState private var focusedField: Int?
//    @State private var searchText = ""
//    
//    @State private var sections: Array<PaySection> = []
//    var filteredSections: Array<PaySection> {
//        if searchText.isEmpty {
//            return sections
//        } else {
//            return sections
//                .filter { !$0.payMethods.filter { $0.title.localizedCaseInsensitiveContains(searchText) }.isEmpty }
//        }
//    }
//    
//    var body: some View {
//        SheetContainerView(.list) {
//            content
//        } header: {
//            SheetHeader(title: "Payment Methods", close: { dismiss() })
//        } subHeader: {
//            SearchTextField(title: "Payment Methods", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
//                .padding(.horizontal, -20)
//                #if os(macOS)
//                .focusable(false) /// prevent mac from auto focusing
//                #endif
//        }
//        .task {
//            sections = getApplicablePayMethods(type: whichPaymentMethods)
//        }
//    }
//    
//    var content: some View {
//        ForEach(filteredSections) { section in
//            if !section.payMethods.isEmpty {
//                Section(section.kind.rawValue) {
//                    ForEach(searchText.isEmpty ? section.payMethods : section.payMethods.filter { $0.title.localizedCaseInsensitiveContains(searchText) }) { meth in
//                        HStack {
//                            Image(systemName: "circle.fill")
//                                .if(meth.isUnified) {
//                                    $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                                }
//                                .if(!meth.isUnified) {
//                                    $0.foregroundStyle(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color, .primary, .secondary)
//                                }
//                            Text(meth.title)
//                                //.bold(meth.isUnified)
//                            Spacer()
//                            
//                            if trans == nil {
//                                let count = calModel.getTransCount(for: meth, and: calModel.sMonth)
//                                if count > 0 {
//                                    TextWithCircleBackground(text: "\(count)")
//                                }
//                            }
//                            
//                            
//                            if payMethod?.id == meth.id {
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            if calcAndSaveOnChange && trans != nil {
//                                trans!.log(field: .payMethod, old: trans!.payMethod?.id, new: meth.id, groupID: UUID().uuidString)
//                                
//                                payMethod = meth
//                                
//                                trans!.action = .edit
//                                //calModel.saveTransaction(id: trans!.id, isPendingSmartTransaction: isPendingSmartTransaction)
//                                calModel.saveTransaction(id: trans!.id, location: isPendingSmartTransaction ? .smartList : .normalList)
//                                calModel.tempTransactions.removeAll()
//                                
////                                if isPendingSmartTransaction {
////                                    calModel.pendingSmartTransaction = nil
////                                }
//                            } else {
//                                payMethod = meth
//                            }
//                            dismiss()
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    
//    
//    
//    func getApplicablePayMethods(type: ApplicablePaymentMethods) -> Array<PaySection> {
//        switch type {
//        case .all:
//            return [
//                //PaySection(kind: .combined, payMethods: payModel.paymentMethods.filter { $0.accountType == .unifiedCredit || $0.accountType == .unifiedChecking }),
//                PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking || $0.accountType == .unifiedChecking }),
//                PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit || $0.accountType == .unifiedCredit  }),
//                PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })
//            ]
//            
//        case .allExceptUnified:
//            return [
//                PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking }),
//                PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit }),
//                PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })
//            ]
//            
//        case .basedOnSelected:
//            if calModel.sPayMethod?.accountType == .unifiedChecking {
//                return [PaySection(kind: .debit, payMethods: payModel.paymentMethods.filter { $0.accountType == .checking })]
//    
//            } else if calModel.sPayMethod?.accountType == .unifiedCredit {
//                return [PaySection(kind: .credit, payMethods: payModel.paymentMethods.filter { $0.accountType == .credit })]
//    
//            } else {
//                return [PaySection(kind: .other, payMethods: payModel.paymentMethods.filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) })]
//            }
//        }
//    }
//}
