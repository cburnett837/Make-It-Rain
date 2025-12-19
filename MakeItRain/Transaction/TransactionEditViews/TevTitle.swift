//
//  TransactionEditViewTitle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/2/25.
//

import SwiftUI

struct TevTitle: View {
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var trans: CBTransaction
    @Bindable var mapModel: MapModel
    var focusedField: FocusState<Int?>.Binding
    
    @State private var showTopTitles: Bool = false
    @State private var suggestedTitles: Array<CBSuggestedTitle> = []
    @State private var blockKeywordChangeWhenViewLoads = true
    @State private var blockSuggestionsFromPopulating = false


    var shouldShowSuggestions: Bool {
        if (showTopTitles && !(trans.category?.topTitles ?? []).isEmpty) {
            return true
        } else {
            switch transactionTitleSuggestionType {
            case .location:
                return !mapModel.completions.isEmpty
            case .history:
                return !suggestedTitles.isEmpty
            }
        }
        //return false
    }
    
    
    var body: some View {
        titleRow
            .onChange(of: focusedField.wrappedValue) {
                
                /// For titles.
                /// Clear map suggestions when unfocusing from the title field.
                if $0 == 1 && $1 != 1 {
                    //withAnimation {
                    suggestedTitles.removeAll()
                    mapModel.completions.removeAll()
                    //}
                }
            }
    }
    
    @ViewBuilder
    var titleRow: some View {
        VStack {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    Image(systemName: "t.circle")
                        .foregroundStyle(.gray)
                }
                
                titleTextField
            }
            .overlay {
                Color.red
                    .frame(height: 2)
                    .opacity(trans.factorInCalculations ? 0 : 1)
            }
            
            suggestionsRow
                .padding(.bottom, -7)
        }
    }
    
    
    @ViewBuilder
    var titleTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Title", text: $trans.title, onSubmit: {
                focusedField.wrappedValue = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: focusedField.projectedValue, disableUp: true)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            .uiTextColor(UIColor(trans.color))
            #else
            StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused(focusedField.projectedValue, equals: 0)
        
        /// Suggest top titles associated with a category if the title has not yet been entered when the category is selected.
        .onChange(of: trans.category) {
            if let newValue = $1 {
                if trans.action == .add && trans.title.isEmpty && !newValue.isNil {
                    showTopTitles = true
                }
            }
        }
        .onChange(of: trans.title) {
            let new = $1
            
            /// Handle search suggestions
            if !showTopTitles {
                mapModel.getAutoCompletions(for: new)
            }
            if !new.isEmpty {
                showTopTitles = false
            }
            ///
            
            /// Suggest adding a new keyword for common titles that may not have one.
            if new.isEmpty {
                suggestedTitles.removeAll()
                mapModel.completions.removeAll()
            } else {
                if !blockSuggestionsFromPopulating {
                    suggestedTitles = calModel.suggestedTitles.filter {
                        $0.title//.localizedCaseInsensitiveContains(new)
                            .range(of: new, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil
                    }//.prefix(3)
                } else {
                    blockSuggestionsFromPopulating = false
                }
            }
            
            if !blockKeywordChangeWhenViewLoads {
                let upVal = new.uppercased()
                
                for key in keyModel.keywords {
                    let upKey = key.keyword.uppercased()
                    
                    switch key.triggerType {
                    case .equals:
                        if upVal == upKey { trans.category = key.category }
                    case .contains:
                        if upVal.contains(upKey) { trans.category = key.category }
                    }
                }
            } else {
                blockKeywordChangeWhenViewLoads = false
            }
        }
    }
    
    @ViewBuilder
    var suggestionsRow: some View {
        if shouldShowSuggestions {
            HStack(spacing: 0) {
                Label {
                    Text("")
                } icon: {
                    AiAnimatedAliveSymbol(symbol: "brain", withGlow: true)
                    //AiAnimatedSwishSymbol(symbol: "brain", hasAnimated: $hasAnimatedBrain)
                }
                                    
                VStack(alignment: .leading) {
                    if showTopTitles && !(trans.category?.topTitles ?? []).isEmpty {
                        categoryTitleSuggestions
                    } else {
                        switch transactionTitleSuggestionType {
                        case .location:
                            if !mapModel.completions.isEmpty {
                                mapLocationSuggestions
                            }
                        case .history:
                            if !suggestedTitles.isEmpty {
                                historyTitleSuggestions
                            }
                        }
                    }
                }
            }
            .padding(.top, 7)
        }
    }
    
    
    @ViewBuilder
    var categoryTitleSuggestions: some View {
        let titleSuggestions = trans.category?.topTitles ?? []
        ScrollView(.horizontal) {
            HStack {
                ForEach(titleSuggestions, id: \.self) { title in
                    Button {
                        trans.title = title.capitalized
                        showTopTitles = false
                    } label: {
                        Text("\(title.capitalized)?")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    }
                    .padding(8)
                    .background(Capsule().foregroundStyle(.thickMaterial))
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 5, for: .scrollContent)
    }
    
        
    @ViewBuilder
    var historyTitleSuggestions: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(suggestedTitles.sorted { $0.transactionCount > $1.transactionCount }.prefix(3), id: \.id) { opt in
                    Button {
                        blockSuggestionsFromPopulating = true
                        trans.title = opt.title.capitalized
                        showTopTitles = false
                        suggestedTitles.removeAll()
                    } label: {
                        Text("\(opt.title.capitalized)?")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    }
                    .padding(8)
                    .background(Capsule().foregroundStyle(.thickMaterial))
                }
            }
        }
        .scrollIndicators(.hidden)
        //.contentMargins(.vertical, 5, for: .scrollContent)
    }
    
    
    
    var mapLocationSuggestions: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(mapModel.completions.prefix(3), id: \.self) { completion in
                        Button {
                            mapModel.blockCompletion = true
                            trans.title = completion.title
                            suggestedTitles.removeAll()
                            Task {
                                if let location = await mapModel.getMapItem(from: completion, parentID: trans.id, parentType: XrefEnum.transaction) {
                                    trans.upsert(location)
                                    mapModel.focusOnFirst(locations: trans.locations)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(AttributedString(completion.highlightedTitleStringForDisplay))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                
                                Text(AttributedString(completion.truncatedHighlightedSubtitleStringForDisplay))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(8)
                        .background(Capsule().foregroundStyle(.thickMaterial))
                    }
                    
                    mapLocationCurrentButton
                    mapLocationClearButton
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, 5, for: .scrollContent)
        }
    }

    
    var mapLocationCurrentButton: some View {
        Button {
            //withAnimation {
                mapModel.completions.removeAll()
            //}
            Task {
                if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: XrefEnum.transaction) {
                    trans.upsert(location)
                }
            }
        } label: {
            Image(systemName: "location.fill")
        }
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        .focusable(false)
        .bold(true)
        .font(.subheadline)
    }
    
    
    var mapLocationClearButton: some View {
        Button {
            //withAnimation {
                mapModel.completions.removeAll()
            //}
        } label: {
            Image(systemName: "xmark")
        }
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        .focusable(false)
        .bold(true)
        .font(.subheadline)
    }
    
    
}

