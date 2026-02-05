//
//  PayMethodSortMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct PayMethodSortMenu: View {
    @Environment(PayMethodModel.self) private var payModel

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
//        .onChange(of: AppSettings.shared.paymentMethodSortMode) { oldValue, newValue in
//            AppSettings.shared.sendToServer(setting: .init(settingId: 58, setting: newValue.rawValue))
//        }
    }
    
    
    var titleButton: some View {
        Button {
            AppSettings.shared.paymentMethodSortMode = .title
            //performSort()
        } label: {
            Label {
                Text("Alphabetically")
            } icon: {
                Image(systemName: AppSettings.shared.paymentMethodSortMode == .title ? "checkmark" : "textformat.abc")
            }
        }
    }
    
    
    var listOrderButton: some View {
        Button {
            AppSettings.shared.paymentMethodSortMode = .listOrder
            //performSort()
        } label: {
            Label {
                Text("Custom")
            } icon: {
                Image(systemName: AppSettings.shared.paymentMethodSortMode == .listOrder ? "checkmark" : "list.bullet")
            }
        }
    }
    
    func performSort() {
//        withAnimation {
//            #if os(macOS)
//            //sortOrder = [KeyPathComparator(\CBPaymentMethod.title)]
//            #else
//            for i in sections.indices {
//                sections[i].payMethods.sort(by: Helpers.paymentMethodSorter())
//            }
//            payModel.paymentMethods.sort(by: Helpers.paymentMethodSorter())
//            #endif
//        }
    }
}
