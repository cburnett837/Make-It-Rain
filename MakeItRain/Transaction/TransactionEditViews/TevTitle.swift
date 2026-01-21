//
//  TransactionEditViewTitle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/2/25.
//

import SwiftUI
import MapKit


struct TevTitle: View {
    @AppStorage("transactionTitleSuggestionType") var transactionTitleSuggestionType: TitleSuggestionType = .location
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var trans: CBTransaction
    @Bindable var mapModel: MapModel
    @Binding var suggestedCategories: [CBCategory]
    var focusedField: FocusState<Int?>.Binding
    
    //@State private var showTopTitles: Bool = false
    @State private var suggestedTitles: Array<CBSuggestedTitle> = []
    //@State private var blockKeywordChangeWhenViewLoads = true
    @State private var blockSuggestionsFromPopulating = false
    
    @State private var localTitleSuggestionType: TitleSuggestionType = .history
    
    var topThreeTitles: Array<CBSuggestedTitle>.SubSequence {
        suggestedTitles.sorted { $0.transactionCount > $1.transactionCount }.prefix(3)
    }


    var shouldShowSuggestions: Bool {
//        if (showTopTitles && !(trans.category?.topTitles ?? []).isEmpty) {
//            return true
//        } else {
//            switch transactionTitleSuggestionType {
//            case .location:
//                return !mapModel.completions.isEmpty
//            case .history:
//                return !suggestedTitles.isEmpty
//            }
//        }
//        //return false
        
        
        
        switch localTitleSuggestionType {
        case .location:
            return !mapModel.completions.isEmpty
        case .history, .byCategoryFrequency:
            return !suggestedTitles.isEmpty
        }
    }
    
    
    var body: some View {
        titleRow
            .task {
                resetLocalTitleSuggestionType()
            }
        
            /// Clear map & history suggestions when unfocusing from the title field.
            .onChange(of: focusedField.wrappedValue) { old, new in
                print("focusedField.wrappedValue changed from \(String(describing: old)) to \(String(describing: new))")
                if old == 0 && new != 0 {
                    resetTitleSuggestionState()
                }
            }
        
            /// Suggest top titles associated with a category if the title is blank when the category is selected.
            .onChange(of: trans.category) {
                showCatTitles(for: $1)
                suggestedCategories = []
            }
        
            .onChange(of: trans.title) { _, newTitle in
                if newTitle.isEmpty {
                    resetTitleSuggestionState()
                    suggestedCategories = []
                } else {
                    /// Handle location search suggestions.
                    mapModel.getAutoCompletions(for: newTitle)
                
                    /// Suggest adding a new keyword for common titles that may not have one.
                    /// `blockSuggestionsFromPopulating` - When selecting a suggestion, prevent it from trying to search suggestions based on the one that was just picked.
                    if blockSuggestionsFromPopulating {
                        blockSuggestionsFromPopulating = false
                    } else {
                        setSuggestionsBasedOnCurrentTitleText(newTitle)
                    }
                }
                
                setKeyword(for: newTitle)
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
            
//            suggestionsRow
//                .padding(.bottom, -7)
        }
        .listRowSeparator(shouldShowSuggestions ? .hidden : .automatic)
        
        suggestionsRow
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
//                    if showTopTitles && !(trans.category?.topTitles ?? []).isEmpty {
//                        categoryTitleSuggestions
//                    } else {
//                        switch transactionTitleSuggestionType {
//                        case .location:
//                            
//                            if localTitleSuggestionType == .history {
//                                if !suggestedTitles.isEmpty {
//                                    titleSuggestions
//                                }
//                            } else if !mapModel.completions.isEmpty {
//                                mapLocationSuggestions
//                            }
//                        case .history:
//                            if localTitleSuggestionType == .location {
//                                if !mapModel.completions.isEmpty {
//                                    mapLocationSuggestions
//                                }
//                            } else if !suggestedTitles.isEmpty {
//                                titleSuggestions
//                            }
//                        }
//                    }
                    
                    
                    switch localTitleSuggestionType {
                    case .location:
                        if !mapModel.completions.isEmpty {
                            mapLocationSuggestions
                        }
                    case .history, .byCategoryFrequency:
                        if !suggestedTitles.isEmpty {
                            titleSuggestions
                        }
                    }
                }
                
                Spacer()
            }
            //.padding(.top, 7)
        }
    }
    
    
//    @ViewBuilder
//    var categoryTitleSuggestions: some View {
//        let titleSuggestions = trans.category?.topTitles ?? []
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(titleSuggestions) { suggestion in
//                    Button {
//                        trans.title = suggestion.title.capitalized
//                        //showTopTitles = false
//                    } label: {
//                        Text("\(suggestion.title.capitalized)?")
//                        .foregroundStyle(.gray)
//                        .font(.subheadline)
//                    }
//                    .padding(8)
//                    .background(Capsule().foregroundStyle(.thickMaterial))
//                }
//            }
//        }
//        .scrollIndicators(.hidden)
//        .contentMargins(.vertical, 5, for: .scrollContent)
//    }
    
        
    @ViewBuilder
    var titleSuggestions: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(topThreeTitles) { opt in
                    Button {
                        blockSuggestionsFromPopulating = true
                        trans.title = opt.title.capitalized
                        suggestedTitles.removeAll()
                        resetLocalTitleSuggestionType()
                        suggestCategory(for: opt.title)
                    } label: {
                        Text("\(opt.title.capitalized)?")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Capsule().foregroundStyle(.thickMaterial))
                }
                
                if localTitleSuggestionType == .history {
                    Divider()
                    switchSuggestionTypeButton(to: .location)
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
                    ForEach(mapModel.completions.prefix(3)) {
                        mapSuggestionButton(for: $0)
                    }
                    //mapLocationCurrentButton
                    //mapLocationClearButton
                    
                    Divider()
                    switchSuggestionTypeButton(to: .history)
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, 5, for: .scrollContent)
        }
    }
    
    
    @ViewBuilder
    func mapSuggestionButton(for completion: MKLocalSearchCompletion) -> some View {
        Button {
            mapModel.blockCompletion = true
            trans.title = completion.title
            suggestedTitles.removeAll()
            resetLocalTitleSuggestionType()
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
    
    
    @ViewBuilder
    func switchSuggestionTypeButton(to type: TitleSuggestionType) -> some View {
        Button {
            localTitleSuggestionType = type
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                Text(type == .location ? "Locations" : "History")
            }
            .foregroundStyle(Color.theme)
            .font(.subheadline)
        }
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
    }
    
    
    
//    var mapLocationCurrentButton: some View {
//        Button {
//            mapModel.completions.removeAll()
//            Task {
//                if let location = await mapModel.saveCurrentLocation(parentID: trans.id, parentType: XrefEnum.transaction) {
//                    trans.upsert(location)
//                }
//            }
//        } label: {
//            Image(systemName: "location.fill")
//        }
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        .focusable(false)
//        .bold(true)
//        .font(.subheadline)
//    }
//    
//    
//    var mapLocationClearButton: some View {
//        Button {
//            //withAnimation {
//                mapModel.completions.removeAll()
//            //}
//        } label: {
//            Image(systemName: "xmark")
//        }
//        .padding(8)
//        .background(Capsule().foregroundStyle(.thickMaterial))
//        .focusable(false)
//        .bold(true)
//        .font(.subheadline)
//    }
//    
//    
    
    // MARK: - Functions
    func resetTitleSuggestionState() {
        suggestedTitles.removeAll()
        mapModel.completions.removeAll()
        resetLocalTitleSuggestionType()
    }
    
    
    func resetLocalTitleSuggestionType() {
        localTitleSuggestionType = transactionTitleSuggestionType
    }
    
    
    func setSuggestionsBasedOnCurrentTitleText(_ newTitle: String) {
        suggestedTitles = calModel.suggestedTitles.filter {
            $0.title.range(of: newTitle, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil
        }
    }
    
    
    func showCatTitles(for category: CBCategory?) {
        if let category = category, trans.action == .add, trans.title.isEmpty, !category.isNil {
            localTitleSuggestionType = .byCategoryFrequency
            suggestedTitles = trans.category?.topTitles ?? []
            //showTopTitles = true
        }
    }
    
    
    func setKeyword(for title: String) {
        //if !blockKeywordChangeWhenViewLoads {
            let upVal = title.uppercased()
            
            for key in keyModel.keywords {
                let upKey = key.keyword.uppercased()
                
                switch key.triggerType {
                case .equals:
                    if upVal == upKey { trans.category = key.category }
                case .contains:
                    if upVal.contains(upKey) { trans.category = key.category }
                }
            }
        //} else {
            //blockKeywordChangeWhenViewLoads = false
        //}
    }
    
    
    func suggestCategory(for title: String) {
        let suggestions = catModel.categories
            .filter({ cat in
                //print("--\(cat.title)")
                return cat.topTitles.map({ tit in
                    //print(tit.title)
                    return tit.title.lowercased()
                }).contains(title.lowercased())
            })
             
        suggestedCategories = suggestions
    }
}

