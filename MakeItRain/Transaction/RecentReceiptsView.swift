//
//  RecentReceiptsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/22/25.
//

import SwiftUI

struct RecentReceiptsView: View {
    @AppStorage("receiptViewMode") fileprivate var receiptViewMode: ReceiptViewMode = .cards
    @Environment(\.colorScheme) private var colorScheme
    @Environment(FuncModel.self) private var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var searchText = ""
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    
    @State private var fileProps = FileViewProps()
    @State private var selectedFile: CBFile?
        
    //@State private var isLoading = true
    @State private var showInitialPage = true
    
    var transactions: [CBTransaction] {
        calModel.receiptTransactions
            .filter { $0.isPermitted }
            .filter {
                guard let payMethod = $0.payMethod else { return true }
                return !payMethod.isHidden
            }
            .filter {
                switch AppSettings.shared.paymentMethodFilterMode {
                case .all:
                    return true

                case .justPrimary:
                    return $0.payMethod?.holderOne?.id == AppState.shared.user?.id || $0.deepCopy?.payMethod?.holderOne?.id == AppState.shared.user?.id

                case .primaryAndSecondary:
                    let userId = AppState.shared.user?.id
                    return $0.payMethod?.holderOne?.id == userId
                        || $0.deepCopy?.payMethod?.holderOne?.id == userId
                        || $0.payMethod?.holderTwo?.id == userId
                        || $0.deepCopy?.payMethod?.holderTwo?.id == userId
                        || $0.payMethod?.holderThree?.id == userId
                        || $0.deepCopy?.payMethod?.holderThree?.id == userId
                        || $0.payMethod?.holderFour?.id == userId
                        || $0.deepCopy?.payMethod?.holderFour?.id == userId
                }
            }
            .filter { ($0.isSmartTransaction ?? false) || !($0.files ?? []).isEmpty }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
            //.sorted(by: Helpers.transactionSorter())
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
        Group {
            switch receiptViewMode {
            case .list: normalList
            case .cards: cardScrollerContainer
            }
        }
        .listStyle(.plain)
        .navigationTitle("Receipts")
        .toolbar { toolbar }
        #if os(iOS)
        .photoPickerAndCameraSheet(
            fileUploadCompletedDelegate: calModel,
            parentType: .transaction,
            allowMultiSelection: false,
            showPhotosPicker: $showPhotosPicker,
            showCamera: $showCamera
        )
        #endif
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: .constant(.receiptsList)
        )
        .environment(fileProps)
        #if os(iOS)
        .sheet(item: $selectedFile) { file in
            PhotoWebPreview(file: file)
        }
        #endif
    }
    
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("", selection: $receiptViewMode) {
                    ForEach(ReceiptViewMode.allCases, id: \.self) { opt in
                        Text(opt.prettyString)
                            .tag(opt)
                    }
                }
                .labelsHidden()
            } label: {
                Image(systemName: "line.3.horizontal")
                    /// This is needed to fix the liquid glass bug.
                    .allowsHitTesting(false)
                    .schemeBasedForegroundStyle()
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            ToolbarRefreshButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                TakePhotoButton(showCamera: $showCamera)
                SelectPhotoButton(showPhotosPicker: $showPhotosPicker)
            } label: {
                Image(systemName: "plus")
                    /// This is needed to fix the liquid glass bug.
                    .allowsHitTesting(false)
                    .schemeBasedForegroundStyle()
            }
        }
        #else
        ToolbarItem(placement: .confirmationAction) {
            Menu {
                Picker("", selection: $receiptViewMode) {
                    ForEach(ReceiptViewMode.allCases, id: \.self) { opt in
                        Text(opt.prettyString)
                            .tag(opt)
                    }
                }
                .labelsHidden()
            } label: {
                Image(systemName: "line.3.horizontal")
                    /// This is needed to fix the liquid glass bug.
                    .allowsHitTesting(false)
                    .schemeBasedForegroundStyle()
            }
        }
        #endif
    }
    
    
    @ViewBuilder
    var normalList: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        
        if transactions.isEmpty {
            ContentUnavailableView("No Receipts", systemImage: "receipt")
        } else {
            List(transactions) {
                transLine(for: $0, withPhotos: true)
            }
            .searchable(text: $searchText)
        }
    }
        

    @ViewBuilder
    var cardScrollerContainer: some View {
        @Bindable var calModel = calModel
        @Bindable var photoModel = FileModel.shared
        
        VStack {
            /// Since the scroller is expensive to render, show this view first so navigation doesn't get messed up.
            if showInitialPage {
                ProgressView()
                    .tint(.none)
                    .task {
                        //setSelectedDay()
                        showInitialPage = false
                    }
            } else {
                cardScroller
                
                if let id = calModel.currentReceiptId, let index = getIndexForId(id) {
                    Text("\(index + 1) of \(transactions.count)")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .padding(.bottom, 5)
                }
            }
        }
        #if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        #else
        .searchable(text: $searchText)
        #endif
    }
    
   
    @ViewBuilder
    var cardScroller: some View {
        @Bindable var calModel = calModel
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(transactions) { trans in
                        cardView(trans)
                            .id(trans.id)
                            .padding(.horizontal, 20)
                            .frame(width: geo.size.width)
                            .frame(height: geo.size.height)
                            .visualEffect { content, visualGeoProxy in
                                content
                                    .scaleEffect(scale(visualGeoProxy, scale: 0.1), anchor: .trailing)
                                    .rotationEffect(rotation(visualGeoProxy, rotation: 5))
                                    .offset(x: minX(visualGeoProxy))
                                    .offset(x: excessMinX(visualGeoProxy))
                            }
                            .zIndex(transactions.zIndex(trans))
                    }
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.ultraThickMaterial)
                        .overlay {
                            ContentUnavailableView("No More Receipts", systemImage: "receipt", description: Text("To view more receipts, please search for transactions using the Advanced Search page."))
                        }
                        .padding(.horizontal, 20)
                        .frame(width: geo.size.width)
                        
                    
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $calModel.currentReceiptId)
            .scrollTargetBehavior(.paging)
            .scrollIndicatorsFlash(onAppear: true)
            .contentMargins(.bottom, 20, for: .scrollContent)
            .scrollIndicators(.visible)
        }
    }
    
    
    @ViewBuilder
    func cardView(_ trans: CBTransaction) -> some View {
        VStack {
            GeometryReader { imageGeo in
                if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
                    ConditionalFileView(
                        file: firstFile,
                        selectedFile: $selectedFile,
                        displayStyle: .standard,
                        parentType: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction),
                        fileUploadCompletedDelegate: calModel,
                        placeholderView: {
                            LoadingPlaceholder(text: "Uploading…", displayStyle: .standard)
                        }, photoView: {
                            CustomAsyncImage(file: firstFile) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageGeo.size.width, height: imageGeo.size.height)
                                    .clipShape(.rect(cornerRadius: 15))
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.ultraThickMaterial)
                                    .frame(width: imageGeo.size.width, height: imageGeo.size.height)
                                    .clipShape(.rect(cornerRadius: 15))
                                    .overlay(ProgressView().tint(.none))
                            }
                            
                        }, pdfView: {
                            #if os(iOS)
                            CustomAsyncPdf(file: firstFile, displayStyle: .standard, useDefaultFrame: false)
                                .scaledToFill()
                                .frame(width: imageGeo.size.width, height: imageGeo.size.height)
                                .clipShape(.rect(cornerRadius: 15))
                            #endif
                            
                        }, csvView: {
                            #if os(iOS)
                            CustomAsyncCsv(file: firstFile, displayStyle: .standard, useDefaultFrame: false)
                                .scaledToFill()
                                .frame(width: imageGeo.size.width, height: imageGeo.size.height)
                                .clipShape(.rect(cornerRadius: 15))
                            #endif
                        }
                    )
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThickMaterial)
                        .overlay {
                            Image(systemName: "camera.macro.slash")
                                .font(.title)
                        }
                }
            }
            
            Divider()
            
            transLine(for: trans, withPhotos: false)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 15)
                #if os(iOS)
                .fill(Color(.secondarySystemBackground))
                #endif
        }
    }
           
    
    @ViewBuilder
    func transLine(for trans: CBTransaction, withPhotos: Bool) -> some View {
        TransactionListLine(trans: trans, withDate: true, withPhotos: withPhotos) {
            if
            let month = calModel.months.first(where: { $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }),
            let day = month.days.first(where: { $0.id == trans.dateComponents?.day }) {
                self.transDay = day
            } else {
                self.transDay = CBDay(date: Date())
            }
            
            self.transEditID = trans.id
        }
    }
    
    
    nonisolated func minX(_ proxy: GeometryProxy) -> CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        return minX < 0 ? 0 : -minX
    }
    
    
    nonisolated func progress(_ proxy: GeometryProxy, limit: CGFloat = 2) -> CGFloat {
        let maxX = proxy.frame(in: .scrollView(axis: .horizontal)).maxX
        let width = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
        let progress = (maxX / width) - 1.0
        let cappedProgress = min(progress, limit)
        return cappedProgress
    }
    
    
    nonisolated func scale(_ proxy: GeometryProxy, scale: CGFloat = 1.0) -> CGFloat {
        let progress = progress(proxy)
        return 1 - (progress * scale)
    }
    
    
    nonisolated func excessMinX(_ proxy: GeometryProxy, offset: CGFloat = 10) -> CGFloat {
        let progress = progress(proxy)
        return progress * offset
    }
    
    
    nonisolated func rotation(_ proxy: GeometryProxy, rotation: CGFloat = 5) -> Angle {
        let progress = progress(proxy)
        return .init(degrees: progress * rotation)
    }
    
    
    func getIndexForId(_ id: String) -> Int? {
        return transactions.firstIndex(where: {$0.id == id})
    }
    
    
//    func setSelectedDay() {
//        transDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.actualNum == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
//    }
    
    
//    func loadFromServerAndCacheFirstThree() async {
//        print("-- \(#function)")
//        
//        isLoading = true
//        
//        if calModel.receiptTransactions.isEmpty {
//            showInitialPage = true
//            await calModel.fetchReceiptsFromServer(funcModel: funcModel)
//            showInitialPage = false
//        } else {
//            await calModel.fetchReceiptsFromServer(funcModel: funcModel)
//            calModel.currentReceiptId = self.transactions.first?.id
//        }
//        
//        isLoading = false
//    }
    
//    
//    func loadFromServerAndCacheFirstThreeOG() async {
//        print("-- \(#function)")
//        
//        isLoading = true
//        
//        if calModel.receiptTransactions.isEmpty {
//            showInitialPage = true
//            let fetchModel = GenericUserInfoModel()
//            let trans = await fetchFromServer(fetchModel)
//            calModel.receiptTransactions = trans
//            
//            calModel.currentReceiptId = self.transactions.first?.id
//            
//            await withTaskGroup(of: Void.self) { group in
//                for trans in transactions.prefix(3) {
//                    if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
//                        group.addTask { await funcModel.downloadFile(file: firstFile) }
//                    }
//                }
//            }
//            
//            showInitialPage = false
//        } else {
//            let fetchModel = GenericUserInfoModel()
//            let transactions = await fetchFromServer(fetchModel)
//            for trans in transactions {
//                if let index = calModel.receiptTransactions.firstIndex(where: { $0.id == trans.id }) {
//                    calModel.receiptTransactions[index].setFromAnotherInstance(transaction: trans)
//                } else {
//                    calModel.receiptTransactions.insert(trans, at: 0)
//                }
//            }
//            
//            calModel.currentReceiptId = self.transactions.first?.id
//        }
//        
//        //currentID = transactions.first?.id
//        isLoading = false
//    }
//    
//    
//    
//    @MainActor
//    func fetchFromServer(_ fetchModel: GenericUserInfoModel) async -> [CBTransaction] {
//        let model = RequestModel(requestType: "fetch_receipts", model: fetchModel)
//        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            return model ?? []
//                
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("receiptView fetchFromServer Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch fit transactions.")
//            }
//            return []
//        }
//    }
}




fileprivate extension [CBTransaction] {
    func zIndex(_ trans: CBTransaction) -> CGFloat {
        if let index = firstIndex(where: { $0.id == trans.id }) {
            return CGFloat(count) - CGFloat(index)
        }
        
        return .zero
    }
}

fileprivate enum ReceiptViewMode: String, CaseIterable {
    case list, cards
    
    var prettyString: String {
        switch self {
        case .list: return "List"
        case .cards: return "Cards"
        }
    }
}
