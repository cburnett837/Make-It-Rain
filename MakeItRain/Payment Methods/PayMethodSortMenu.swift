//
//  PayMethodSortMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct PayMethodSortMenu: View {
    @AppStorage("paymentMethodSortMode") var paymentMethodSortMode: SortMode = .title
    @Environment(PayMethodModel.self) private var payModel

    @Binding var sections: Array<PaySection>

    var body: some View {
        Menu {
            Section("Choose Sort Order") {
                titleButton
                listOrderButton
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var titleButton: some View {
        Button {
            paymentMethodSortMode = .title
            performSort()
        } label: {
            Label {
                Text("Alphabetically")
            } icon: {
                Image(systemName: paymentMethodSortMode == .title ? "checkmark" : "textformat.abc")
            }
        }
    }
    
    
    var listOrderButton: some View {
        Button {
            paymentMethodSortMode = .listOrder
            performSort()
        } label: {
            Label {
                Text("Custom")
            } icon: {
                Image(systemName: paymentMethodSortMode == .listOrder ? "checkmark" : "list.bullet")
            }
        }
    }
    
    func performSort() {
        withAnimation {
            #if os(macOS)
            //sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
            #else
            for i in sections.indices {
                sections[i].payMethods.sort(by: Helpers.paymentMethodSorter())
            }
            payModel.paymentMethods.sort(by: Helpers.paymentMethodSorter())
            #endif
        }
    }
}
