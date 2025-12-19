//
//  PayMethodSortMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct PayMethodSortMenu: View {
    @Local(\.paymentMethodSortMode) var paymentMethodSortMode
    @Environment(PayMethodModel.self) private var payModel

    @Binding var sections: Array<PaySection>

    var body: some View {
        Menu {
            Section("Choose Sort Order") {
                titleButton
                listOrderButton
            }
        } label: {
            Label("Sort Order", systemImage: "arrow.up.arrow.down")
            ////Image(systemName: "arrow.up.arrow.down")
                //.schemeBasedForegroundStyle()
        }
        .schemeBasedTint()
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
