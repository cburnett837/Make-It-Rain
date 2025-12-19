//
//  TransactionEditViewRuleSuggestionButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/18/25.
//

import SwiftUI

struct TevRuleSuggestionButton: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(KeywordModel.self) private var keyModel
    var trans: CBTransaction
    
    var body: some View {
        if trans.category != nil && !(trans.category?.isNil ?? false) {
            let existingCount = calModel.justTransactions
                .filter {
                    $0.title.localizedCaseInsensitiveContains(trans.title)
                    && $0.category?.id == trans.category!.id
                }
                .count
            
            let comboExists = existingCount >= 3 && !trans.wasAddedFromPopulate
            
            let ruleDoesNotExist = keyModel
                .keywords
                .filter {
                    $0.keyword.localizedCaseInsensitiveContains(trans.title)
                    && $0.category?.id == trans.category!.id
                }
                .isEmpty
            
            if comboExists && ruleDoesNotExist {
                Section {
                    Button {
                        createRule()
                    } label: {
                        //AiLabel(text: "Add Rule")
                        //AiLabel2(text: "Add Rule")
                        //LiquidAliveTextForReal(text: "Add Rule")
                        
                        AiAnimatedAliveLabel("Create New Rule", systemImage: "brain", withGlow: true)
                    }
                } footer: {
                    let message: LocalizedStringKey = "**\(trans.title)** was categorized as **\(trans.category!.title)** at least \(existingCount) times this year. Consider creating a rule to auto-categorize in the future."
                    
                    Text(message)
                }
            }
        }
    }
    
    
    func createRule() {
        let keyword = CBKeyword()
        withAnimation {
            keyword.keyword = trans.title
            keyword.category = trans.category!
            keyword.triggerType = .contains
            
            keyword.deepCopy(.create)
            keyModel.upsert(keyword)
            keyModel.keywords.sort { $0.keyword < $1.keyword }
            
            AppState.shared.showToast(title: "Rule Created", subtitle: trans.title, body: "\(trans.category!.title)", symbol: "ruler", symbolColor: .green)
        }
        
        Task { await keyModel.submit(keyword) }
    }
}

