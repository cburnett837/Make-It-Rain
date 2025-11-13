//
//  PlaidList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/22/25.
//

import SwiftUI



#if os(iOS)
struct PlaidTable: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(PlaidModel.self) private var plaidModel
    //@State private var fetchBanks = false
        
    @State private var searchText = ""
    @State private var editBank: CBPlaidBank?
    @State private var bankEditID: CBPlaidBank.ID?
    @State private var sortOrder = [KeyPathComparator(\CBPlaidBank.title)]
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var showInfoSheet = false
    
    var filteredBanks: [CBPlaidBank] {
        plaidModel.banks
            .filter { $0.active }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        
        Group {
            if !plaidModel.banks.isEmpty {
                #if os(macOS)
                macTable
                #else
                if filteredBanks.isEmpty {
                    ContentUnavailableView("No banks found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    phoneList
                }
                #endif
            } else {
                ContentUnavailableView("No Plaid Banks", systemImage: "building.columns", description: Text("Click the plus button above to add a bank."))
            }
        }
        
        
        .environment(plaidModel)
        .navigationTitle("Plaid Institutions")
        .id(plaidModel.fuckYouSwiftuiTableRefreshID)
        .toolbar {
            phoneToolbar()
        }
        .searchable(text: $searchText)
//        .onChange(of: fetchBanks) { oldValue, newValue in
//            if newValue {
//                Task {
//                    await plaidModel.fetchBanks()
//                }
//            }
//        }
        .sheet(item: $editBank, onDismiss: {
            bankEditID = nil
//            Task {
//                await plaidModel.fetchBanks()
//            }
        }) { bank in
            PlaidBankView(bank: bank, editID: $bankEditID)
                .environment(plaidModel)
                #if os(macOS)
                .frame(minWidth: 700)
                #endif
        }
        .onChange(of: sortOrder) { _, sortOrder in
            plaidModel.banks.sort(using: sortOrder)
        }
        .onChange(of: bankEditID) { oldValue, newValue in
            if let newValue {
                editBank = plaidModel.getBank(by: newValue)
            } else {
                plaidModel.saveBank(id: oldValue!)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            PlaidSyncInfoSheet()
        }
    }
    
    
    
    
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if AppState.shared.user?.id == 1 {
                infoButton
            }
        }
                
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            PlaidLinkView(plaidModel: plaidModel, linkMode: .newBank)
            .tint(.none)
        }
    
    }
    
    var phoneList: some View {
        List(filteredBanks, selection: $bankEditID) { bank in
            HStack {
                if let logoBase = bank.logo, let data = Data(base64Encoded: logoBase), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 30, height: 30, alignment: .center)
                        .clipShape(Circle())
                        //.alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                }
                
                VStack(alignment: .leading) {
                    Text(bank.title)
                        //.alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                                        
                    Text("Accounts: \(bank.numberOfAccounts)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text("Last Plaid To Bank Sync: \(bank.lastTimePlaidSyncedWithInstitutionDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text("Last Cody Sync: \(bank.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                if bank.hasIssues {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                }
            }
        }
        .listStyle(.plain)
    }
    
    
    
    
    var infoButton: some View {
        Button {
            showInfoSheet = true
        } label: {
            Image(systemName: "info")
                .schemeBasedForegroundStyle()
        }
    }
    
    
}
#endif
