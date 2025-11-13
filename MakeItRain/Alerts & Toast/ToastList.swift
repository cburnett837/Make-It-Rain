//
//  ToastList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct ToastList: View {
    
    @State private var toasts: Array<PersistentToast> = []
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Group {
            if toasts.isEmpty {
                ContentUnavailableView("No Notifications", systemImage: "bell.slash")
            } else {
                StandardContainerWithToolbar(.plainList) {
                    ForEach(toasts, id: \.objectID) { toast in
                        HStack {
                            Label {
                                toastText(toast)
                            } icon: {
                                symbol(toast)
                            }
                            
                            Spacer()
                            
                            Text(toast.enteredDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")
                                .foregroundStyle(.gray)
                                .font(.callout)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .schemeBasedForegroundStyle()
                }
                .confirmationDialog("Delete Notifications", isPresented: $showDeleteAlert) {
                    Button(role: .destructive) {
                        deleteAllToasts()
                    }
                } message: {
                    Text("Clear All Notifications")
                }
            }
        }
        .task { getToasts() }
    }
    
    @ViewBuilder func toastText(_ toast: PersistentToast) -> some View {
        VStack(alignment: .leading) {
            Text(toast.title ?? "No Title")
            if let subtitle = toast.subtitle {
                Text(subtitle)
                    .foregroundStyle(.gray)
                    .font(.callout)
            }
            if let body = toast.body {
                Text(body)
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
        }
    }
    
    
    @ViewBuilder func symbol(_ toast: PersistentToast) -> some View {
        Image(systemName: toast.symbol ?? "")
            .schemeBasedForegroundStyle()            
            .padding(10)
            .background(symbolBackground(toast))
    }
    
    @ViewBuilder func symbolBackground(_ toast: PersistentToast) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill((toast.hexCode ?? "").isEmpty ? Color.theme : (Color.fromHex(toast.hexCode) ?? Color.theme))
            .frame(width: 30, height: 30)
    }
    
    
    func getToasts() {
        let context = DataManager.shared.container.viewContext
        let sort = NSSortDescriptor(keyPath: \PersistentToast.enteredDate, ascending: false)
        if let toasts = DataManager.shared.getMany(context: context, type: PersistentToast.self, sort: [sort]) {
            self.toasts = toasts
        }
    }
    
    
    func deleteAllToasts() {
        let context = DataManager.shared.createContext()
        context.perform {
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
            let _ = DataManager.shared.save(context: context)
            
            self.toasts.removeAll()
        }
    }
}

#Preview {
    ToastList()
}
