//
//  RecentReceiptsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/22/25.
//

import SwiftUI

struct RecentReceiptsView: View {
    #if os(macOS)
    @Environment(\.dismiss) var dismiss
    #endif
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var searchText = ""
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay?
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    
    @State private var props = FileViewProps()
    @State private var selectedFile: CBFile?
    
    var transactions: [CBTransaction] {
        calModel.justTransactions
            .filter { ($0.isSmartTransaction ?? false) || !($0.files ?? []).isEmpty }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) })
    }
    
    var body: some View {
        if AppState.shared.isIphone {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }
    
    @ViewBuilder
    var content: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        
        List(transactions) { trans in
            HStack {
                TransactionListLine(trans: trans, withDate: true)
                    .onTapGesture {
                        guard let month = calModel.months.first(where: { $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }) else { return }
                        guard let day = month.days.first(where: { $0.id == trans.dateComponents?.day }) else { return }
                        self.transDay = day
                        self.transEditID = trans.id
                    }
                
                if let files = trans.files?.filter({ $0.active }), !files.isEmpty {
                    ForEach(files.prefix(1)) { file in
                        ConditionalFileView(
                            file: file,
                            selectedFile: $selectedFile,
                            displayStyle: .standard,
                            parentType: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction),
                            fileUploadCompletedDelegate: calModel,
                            placeholderView: {
                                LoadingPlaceholder(text: "Uploading…", displayStyle: .standard)
                            }, photoView: {
                                CustomAsyncImage(file: file) { image in
                                    image
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .aspectRatio(contentMode: .fill)
                                        .clipShape(.rect(cornerRadius: 14))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThickMaterial)
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            ProgressView()
                                                .tint(.none)
                                        }
                                }
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .environment(props)
        .searchable(text: $searchText)
        .navigationTitle("Receipts")
        #if os(iOS)
        //.navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ToolbarRefreshButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    TakePhotoButton(showCamera: $showCamera)
                    SelectPhotoButton(showPhotosPicker: $showPhotosPicker)
                } label: {
                    Image(systemName: "plus")
                        /// This is needed to fix the liquid class bug.
                        .allowsHitTesting(false)
                        .schemeBasedForegroundStyle()
                }
            }
        }
        #endif
        .task {
            setSelectedDay()
        }
        #if os(iOS)
        .sheet(item: $selectedFile) { file in
            PhotoWebPreview(file: file)
        }
        #endif
        .photoPickerAndCameraSheet(
            fileUploadCompletedDelegate: calModel,
            parentType: .transaction,
            allowMultiSelection: false,
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera
        )
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
    }
                        
    func setSelectedDay() {
        transDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
    }
}
