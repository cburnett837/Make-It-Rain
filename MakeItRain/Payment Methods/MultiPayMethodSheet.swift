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
    @Environment(PlaidModel.self) private var plaidModel
    @Local(\.useBusinessLogos) var useBusinessLogos
    @Local(\.paymentMethodFilterMode) var paymentMethodFilterMode

    @Binding var payMethods: Array<CBPaymentMethod>
    
    var includeHidden: Bool = false
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    @State private var sections: Array<PaySection> = []
//    var filteredSections: Array<PaySection> {
//        if searchText.isEmpty {
//            return sections
//        } else {
//            return sections
//                .filter { !$0.payMethods.filter { $0.title.localizedCaseInsensitiveContains(searchText) }.isEmpty }
//        }
//    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sections.flatMap({ $0.payMethods }).isEmpty && !searchText.isEmpty {
                    ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    StandardContainerWithToolbar(.list) {
                        content
                    }
                }
            }
            
            .task { populateSections() }
            .onChange(of: paymentMethodFilterMode) { populateSections() }
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle("Accounts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                
                ToolbarItem(placement: .bottomBar) { PayMethodFilterMenu() }
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarTrailing : .bottomBar) { PayMethodSortMenu(sections: $sections) }
                
                if AppState.shared.isIpad {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            .onChange(of: searchText) { populateSections() }
            /// Update the sheet if viewing and something changes on another device.
            .onChange(of: payModel.paymentMethods.filter { !$0.isHidden && !$0.isPrivate }.count) {
                populateSections()
            }
            #endif
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        if sections.isEmpty {
            ContentUnavailableView("No accounts found", systemImage: "exclamationmark.magnifyingglass")
        } else {
            ForEach(sections) { section in
                if !section.payMethods.isEmpty {
                    Section(section.kind.rawValue) {
                        ForEach(section.payMethods) { meth in
                            methLine(meth)
                                .onTapGesture {
                                    selectPaymentMethod(meth)
                                }
                        }
                    }
                }
            }
            
            
//            ForEach(filteredSections) { section in
//                if !section.payMethods.isEmpty {
//                    Section(section.kind.rawValue) {
//                        ForEach(searchText.isEmpty ? section.payMethods : section.payMethods.filter { $0.title.localizedCaseInsensitiveContains(searchText) }) { meth in
//                            HStack {
//                                Image(systemName: "circle.fill")
//                                    .if(meth.isUnified) {
//                                        $0.foregroundStyle(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                                    }
//                                    .if(!meth.isUnified) {
//                                        $0.foregroundStyle(meth.isUnified ? (colorScheme == .dark ? .white : .black) : meth.color, .primary, .secondary)
//                                    }
//                                Text(meth.title)
//                                //.bold(meth.isUnified)
//                                Spacer()
//                                
//                                Image(systemName: "checkmark")
//                                    .opacity(payMethods.contains(meth) ? 1 : 0)
//                            }
//                            .contentShape(Rectangle())
//                            .onTapGesture { selectPaymentMethod(meth) }
//                        }
//                    }
//                }
//            }
        }
    }
    
    @ViewBuilder func methLine(_ meth: CBPaymentMethod) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(meth.title)
                }
            } icon: {
                //methColorCircle(meth)
                //BusinessLogo(parent: meth, fallBackType: .color)
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: .color
                ))
            }
                                            
            Spacer()
            
                                 
            if payMethods.contains(meth) {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
    
    
//    var selectButton: some View {
//        Button {
//            withAnimation {
//                categories = categories.isEmpty ? catModel.categories : []
//            }
//        } label: {
//            //Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
//            Text(categories.isEmpty ? "Select All" : "Deselect All")
//            //Image(systemName: categories.isEmpty ? "checkmark.rectangle.stack" : "checklist.checked")
//                .schemeBasedForegroundStyle()
//        }
//    }
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    var moreMenu: some View {
        Menu {
            useBusinessLogosToggle
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
    }
    
    var selectButton: some View {
        Button {
            withAnimation {
                payMethods = payMethods.isEmpty ? payModel.paymentMethods : []
            }
        } label: {
            Text(payMethods.isEmpty ? "Select All" : "Deselect All")
            //Image(systemName: payMethods.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func selectPaymentMethod(_ payMethod: CBPaymentMethod) {
        if payMethods.contains(payMethod) {
            payMethods.removeAll(where: { $0.id == payMethod.id })
        } else {
            payMethods.append(payMethod)
        }
    }
    
    func populateSections() {
        sections = payModel.getApplicablePayMethods(
            type: .allExceptUnified,
            calModel: calModel,
            plaidModel: plaidModel,
            searchText: $searchText,
            includeHidden: includeHidden
        )
    }
}
