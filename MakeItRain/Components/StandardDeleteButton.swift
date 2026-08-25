//
//  StandardDeleteButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/22/26.
//

import SwiftUI

enum DeleteType: String {
    case transaction, payMethod, category, categoryGroup, recurringTransaction, keyword, budget, plaidBank, plaidAccount
    
    var buttonTitle: String {
        switch self {
        case .transaction: "Transaction"
        case .payMethod: "Account"
        case .category: "Category"
        case .categoryGroup: "Group"
        case .recurringTransaction: "Recurring"
        case .keyword: "Rule"
        case .budget: "Budget"
        case .plaidBank: "Bank"
        case .plaidAccount: "Account"
        }
    }
    
    static let basePrompt = "Are you sure you want to delete this"
    
    var prompt: String {
        "\(DeleteType.basePrompt) \(self.buttonTitle)?"
    }
    
    var promptPlusMessage: String {
        "\(DeleteType.basePrompt) \(self.buttonTitle.lowercased())?\n\(self.message)"
    }
    
    var message: String {
        switch self {
        case .transaction: prompt
        case .payMethod: "This will also delete all associated transactions."
        case .category: "This will not delete any associated transactions."
        case .categoryGroup: "This will not delete any associated transactions."
        case .recurringTransaction: "This will not delete any associated transactions."
        case .keyword: "This will not delete any associated transactions."
        case .budget: "This will not delete any associated transactions."
        case .plaidBank: "\nThis will remove plaids link to this bank.\nYou can re-add this bank again in the future.\n\nNOTE: Some banks, such as Chase and Wells Fargo, require you to remove the plaid integration via your security preferences on their website."
        case .plaidAccount: "This will not delete any associated transactions."
        }
    }
}

struct StandardDeleteButton: View {
    var type: DeleteType
    var delete: () -> Void
    
    @State private var showAlert = false
    
    var body: some View {
        Button {
            showAlert = true
        } label: {
            Text("Delete \(type.buttonTitle)")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.red)
        }
        .sensoryFeedback(.warning, trigger: showAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog(type.prompt, isPresented: $showAlert, actions: {
            Button("Delete \(type.buttonTitle)", role: .destructive, action: delete)
        }, message: {
            #if os(iOS)
            Text(type.promptPlusMessage)
            #else
            Text(type.message)
            #endif
        })
    }
}
