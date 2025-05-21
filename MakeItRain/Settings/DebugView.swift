//
//  DebugView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/15/25.
//

import SwiftUI

struct DebugView: View {
    @AppStorage("debugPrint") var debugPrint = false

    @Environment(FuncModel.self) var funcModel
    
    var body: some View {
        List {
            Section("Xcode") {
                consolePrintToggle
            }
            
            loadTimeSection
        }
        .navigationTitle("Debug")
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
    }
    
    
    var consolePrintToggle: some View {
        Toggle(isOn: $debugPrint) {
            Label {
                VStack(alignment: .leading) {
                    Text("Console print")
                }
            } icon: {
                Image(systemName: "apple.terminal")
            }
        }
        .onChange(of: debugPrint) { oldValue, newValue in
            if newValue {
                UserDefaults.standard.set("YES", forKey: "debugPrint")
                AppState.shared.debugPrintString = "YES"
            } else {
                UserDefaults.standard.set("NO", forKey: "debugPrint")
                AppState.shared.debugPrintString = "NO"
            }
        }
    }
    
    
    var loadTimeSection: some View {
        Section {
            if funcModel.loadTimes.isEmpty {
                Text("No Load Times")
            } else {
                ForEach(funcModel.loadTimes, id: \.id) { metric in
                    HStack {
                        Text("\(metric.date.string(to: .dateTime))")
                        Spacer()
                        Text("\(metric.load)")
                    }
                }
            }
        } header: {
            HStack {
                Text("Load Times")
                Spacer()
                Button("Clear") {
                    funcModel.loadTimes.removeAll()
                }
                .font(.caption)
            }
            
        } footer: {
            Text("Note: These times are not retained between app launches")
        }
    }
    
    
    
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                ToolbarNowButton()
                    .disabled(!AppState.shared.methsExist)
                ToolbarRefreshButton()
                    .toolbarBorder()
                    .disabled(!AppState.shared.methsExist)
            }
        }
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .debug)
        }
        ToolbarItem {
            Spacer()
        }
    }
    
    #else
    
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if AppState.shared.isIpad {
                HStack(spacing: 20) {
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                    
                    ToolbarLongPollButton()
                }
            }
        }
        
        if AppState.shared.isIphone {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 20) {
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                }
            }
        }
    }
    
    #endif
    
    
}
