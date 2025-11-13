//
//  PlaidSyncInfoSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/1/25.
//


import SwiftUI

struct PlaidSyncInfoSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section {
                    Text("Sync is handled per user bank instance.")
                    Text("Gets all balances for all accounts at the bank.")
                    Text("Balance will be returned in the payload.")
                } header: {
                    Text("Force Sync Balances Button")
                } footer: {
                    Text("Cost: $0.10 per successful call")
                }
                
                
                Section {
                    Text("Sync is handled per user bank instance.")
                    Text("Gets all transactions for all accounts at the bank.")
                    Text("Will initiate request, and send a webhook to server when transactions are available to consume.")
                } header: {
                    Text("Force Sync Transactions Button")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("$0.30 per account/month")
                        Text("$0.12 per successful call")
                    }
                }
                
                
                Section {
                    Text("The last time Plaid initiated a sync event with the bank.")
                    Text("This fetches both the balances and transactions.")
                } header: {
                    Text("Last Plaid To Bank Sync Time")
                }
                
                
                Section {
                    Text("Only for balances.")
                    Text("The last time I checked the Plaid API, to see when they last synced with the bank.")
                    Text("This will check the Plaid API to see when they last synced with the bank. I will then check my database to see if what I have on record happened before the last time Plaid synced with the bank. If the Plaid data is newer, I will grab it and alert the user.")
                } header: {
                    Text("Last Cody Sync Time")
                }
            }
            .navigationTitle("Plaid Sync Info")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
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
}
