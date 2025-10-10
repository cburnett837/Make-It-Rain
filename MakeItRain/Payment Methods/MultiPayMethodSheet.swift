//
//  MultiPayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct MultiPayMethodSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(PayMethodModel.self) private var payModel
        
    @Binding var payMethods: Array<CBPaymentMethod>
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    @State private var sections: Array<PaySection> = []
    var filteredSections: Array<PaySection> {
        if searchText.isEmpty {
            return sections
        } else {
            return sections
                .filter { !$0.payMethods.filter { $0.title.localizedStandardContains(searchText) }.isEmpty }
        }
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                content
            }
            #if os(iOS)
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .task {
            sections = [
                PaySection(
                    kind: .debit,
                    payMethods: payModel
                        .paymentMethods
                        .filter { $0.accountType == .checking }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .credit,
                    payMethods: payModel
                        .paymentMethods
                        .filter { $0.accountType == .credit || $0.accountType == .loan }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                ),
                PaySection(
                    kind: .other,
                    payMethods: payModel
                        .paymentMethods
                        .filter { ![.unifiedCredit, .unifiedChecking, .credit, .checking].contains($0.accountType) }
                        .filter { $0.isAllowedToBeViewedByThisUser }
                        .filter { !$0.isHidden }
                )
            ]
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        if filteredSections.isEmpty {
            ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
        } else {
            ForEach(filteredSections) { section in
                if !section.payMethods.isEmpty {
                    Section(section.kind.rawValue) {
                        ForEach(searchText.isEmpty ? section.payMethods : section.payMethods.filter { $0.title.localizedStandardContains(searchText) }) { meth in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .if(meth.isUnified) {
                                        $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                                    }
                                    .if(!meth.isUnified) {
                                        $0.foregroundStyle(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color, .primary, .secondary)
                                    }
                                Text(meth.title)
                                //.bold(meth.isUnified)
                                Spacer()
                                
                                Image(systemName: "checkmark")
                                    .opacity(payMethods.contains(meth) ? 1 : 0)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { doIt(meth) }
                        }
                    }
                }
            }
        }
    }
    
    
    var selectButton: some View {
        Button {
            payMethods = payMethods.isEmpty ? payModel.paymentMethods : []                        
        } label: {
            Image(systemName: payMethods.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    func doIt(_ payMethod: CBPaymentMethod) {
        if payMethods.contains(payMethod) {
            payMethods.removeAll(where: { $0.id == payMethod.id })
        } else {
            payMethods.append(payMethod)
        }
    }
}
