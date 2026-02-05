//
//  ToastList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/28/25.
//

import SwiftUI

struct ToastList: View {
    
    //@State private var toasts: Array<PersistentToast> = []
    @State private var toastsByDay: Array<ToastsByDay> = []
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Group {
            if toastsByDay.isEmpty {
                ContentUnavailableView("No Notifications", systemImage: "bell.slash", description: Text("Note: Notifications are specific to this device."))
            } else {
                StandardContainerWithToolbar(.plainList) {
                    ForEach(toastsByDay) { obj in
                        Section(obj.date) {
                            ForEach(obj.toasts, id: \.objectID) { toast in
                                toastInfo(toast)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            delete(toast: toast)
                                            //getToasts()
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .toolbar {
            #if os(iOS)
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
            #endif
        }
        .onDisappear {
            AppState.shared.unreadToasts.removeAll()
        }
        .task {
            getToasts()
        }
    }
    
    @ViewBuilder
    func toastInfo(_ toast: PersistentToast) -> some View {
        HStack(alignment: .circleAndTitle, spacing: 5) {
            symbol(toast)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
            VStack(alignment: .leading) {
                Group {
                    HStack {
                        Text(toast.title ?? "No Title")
                        
                        Spacer()
                        
                        Text(toast.enteredDate?.string(to: .timeAmPm) ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.callout)
                    }
                    
                    if let subtitle = toast.subtitle {
                        Text(subtitle)
                            //.foregroundStyle(.gray)
                            .font(.callout)
                    }
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                
                if let body = toast.body {
                    Text(body)
                        .foregroundStyle(.gray)
                        .font(.callout)
                }
            }
        }
    }
    
    
    @ViewBuilder
    func symbol(_ toast: PersistentToast) -> some View {
        
        HStack(spacing: 5) {
            Circle()
                .fill(AppState.shared.unreadToasts.contains(toast.id ?? "") ? .blue : .clear)
                .frame(width: 10, height: 10)
            
            Image(systemName: toast.symbol ?? "")
                .schemeBasedForegroundStyle()
                .padding(10)
                .background(symbolBackground(toast))
        }
    }
    
    
    @ViewBuilder
    func symbolBackground(_ toast: PersistentToast) -> some View {
        Circle()
        //RoundedRectangle(cornerRadius: 8)
            .fill((toast.hexCode ?? "").isEmpty ? Color.theme : (Color.fromHex(toast.hexCode) ?? Color.theme))
            .frame(width: 30, height: 30)
    }
    
    
    struct ToastsByDay: Identifiable {
        var id: String { date }
        var date: String
        var toasts: [PersistentToast]
    }
    
    
    func getToasts() {
        let context = DataManager.shared.container.viewContext
        let sort = NSSortDescriptor(keyPath: \PersistentToast.enteredDate, ascending: false)
        if let toasts = DataManager.shared.getMany(context: context, type: PersistentToast.self, sort: [sort]) {
            
            self.toastsByDay = toasts
                .compactMap { $0.enteredDate?.string(to: .monthDayShortYear) }
                .uniqued()
                .compactMap { date in
                    let theToasts = toasts.filter { $0.enteredDate?.string(to: .monthDayShortYear) == date }
                    return ToastsByDay(date: date, toasts: theToasts)
                }
        }
    }
    
    
    func delete(toast: PersistentToast) {
        if let id = toast.id {
            let context = DataManager.shared.container.viewContext
            DataManager.shared.delete(
                context: context,
                type: PersistentToast.self,
                predicate: .byId(.string(id))
            )
            
            
            
            let toastDate = toast.enteredDate?.string(to: .monthDayShortYear) ?? ""
            
            if let index = toastsByDay.firstIndex(where: { $0.date == toastDate }) {
                toastsByDay[index].toasts.removeAll { $0.id == toast.id }
                
                if toastsByDay[index].toasts.isEmpty {
                    toastsByDay.remove(at: index)
                }
            }
        }
    }
    
    
    func deleteAllToasts() {
        let context = DataManager.shared.createContext()
        context.perform {
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
            let _ = DataManager.shared.save(context: context)
            self.toastsByDay.removeAll()
            //self.toasts.removeAll()
        }
    }
}
