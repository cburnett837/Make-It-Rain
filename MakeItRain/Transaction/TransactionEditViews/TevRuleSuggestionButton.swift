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
    @Binding var shouldSuggestAddingNewRule: Bool
    var existingCount: Int
    
    var body: some View {
        if trans.category != nil && !(trans.category?.isNil ?? false) {
            if shouldSuggestAddingNewRule {
                Section {
                    Button {
                        createRule()
                    } label: {
                        //AiLabel(text: "Add Rule")
                        //AiLabel2(text: "Add Rule")
                        //LiquidAliveTextForReal(text: "Add Rule")
                        
                        AiAnimatedAliveLabel("Create New Rule", systemImage: "brain", withGlow: true)
                    }
                    
                    Button {
                        ignoreSuggestion()
                    } label: {
                        Text("Ignore Suggestion")
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
    
    func ignoreSuggestion() {
        shouldSuggestAddingNewRule = false
        Task {
            let ignore = CBKeyword()
            ignore.keyword = trans.title
            ignore.category = trans.category!
            ignore.isIgnoredSuggestion = true
            keyModel.upsert(ignore)
            let _ = await keyModel.submit(ignore)
            
        }
    }
}

