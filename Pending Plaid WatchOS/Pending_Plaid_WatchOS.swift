//
//  Pending_Plaid_WatchOS.swift
//  Pending Plaid WatchOS
//
//  Created by Cody Burnett on 6/27/26.
//

import WidgetKit
import SwiftUI

//
//struct WatchBudgetWidget: Widget {
//    let kind = "PlaidWidget"
//
//    var body: some WidgetConfiguration {
//        #if os(iOS)
//        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
//            BudgetWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Plaid Transactions")
//        .description("Shows your latest plaid transactions that require action.")
//        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
//        .pushHandler(BudgetWidgetPushHandler.self)
//        #elseif os(watchOS)
//        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
//            BudgetWatchWidgetView(entry: entry)
//            //BudgetWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Plaid Transactions")
//        .description("Shows your latest plaid transactions that require action.")
//        .supportedFamilies([
//            .accessoryRectangular,
//            .accessoryCircular,
//            .accessoryInline,
//            .accessoryCorner
//        ])
//        .pushHandler(BudgetWidgetPushHandler.self)
//        #endif
//    }
//}


//
//  Pending_Plaid_Widget.swift
//  Pending Plaid Widget
//
//  Created by Cody Burnett on 5/7/26.
//

//
//struct IosBudgetWidget: Widget {
//    let kind = "PlaidWidget"
//
//    var body: some WidgetConfiguration {
//        #if os(iOS)
//        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
//            BudgetWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Plaid Transactions")
//        .description("Shows your latest plaid transactions that require action.")
//        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
//        .pushHandler(BudgetWidgetPushHandler.self)
//        #elseif os(watchOS)
//        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
//            BudgetWatchWidgetView(entry: entry)
//            //BudgetWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Plaid Transactions")
//        .description("Shows your latest plaid transactions that require action.")
//        .supportedFamilies([
//            .accessoryRectangular,
//            .accessoryCircular,
//            .accessoryInline,
//            .accessoryCorner
//        ])
//        .pushHandler(BudgetWidgetPushHandler.self)
//        #endif
//    }
//}


struct BudgetEntry: TimelineEntry {
    let date: Date
    var data: PlaidResult
}



//
//func loadLogoFromCoreDataIfNeeded(for id: String) async -> Data? {
//    let context = DataManager.shared.createContext()
//    let logoData: Data? = await DataManager.shared.perform(context: context) {
//        let pred1 = NSPredicate(format: "relatedID == %@", id)
//        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: 42))
//        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
//
//        return DataManager.shared.getOne(
//            context: context,
//            type: PersistentLogo.self,
//            predicate: .compound(comp),
//            createIfNotFound: false
//        )?.photoData
//    }
//
//    return logoData
//}


struct BudgetWidgetProvider: TimelineProvider {
    let placeholder = PlaidResult(
        isPlaceholder: true,
        count: 8,
        trans: [
            PlaidTransLite(id: 0, title: "Apple", amount: "$123", payMethodId: 0),
            PlaidTransLite(id: 1, title: "Google", amount: "$456", payMethodId: 0),
            PlaidTransLite(id: 2, title: "Samsung", amount: "$789", payMethodId: 0),
            PlaidTransLite(id: 3, title: "Microsoft", amount: "$987", payMethodId: 0),
            PlaidTransLite(id: 4, title: "Lego", amount: "$1,000", payMethodId: 0),
            PlaidTransLite(id: 5, title: "7/11", amount: "$321", payMethodId: 0),
            PlaidTransLite(id: 7, title: "Publix", amount: "$321", payMethodId: 0),
            PlaidTransLite(id: 8, title: "Target", amount: "$321", payMethodId: 0),
        ]
    )
    
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: .now, data: placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(BudgetEntry(date: .now, data: placeholder))
    }
    
//    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
//        Task {
//            await uploadCurrentWidgetPushToken()
//
//            let downloaded = await BudgetWidgetAPI.fetchBudgetData()
//
//            if let downloaded {
//                WidgetCache.save(downloaded)
//            }
//
//            let data = downloaded
//                ?? WidgetCache.load()
//                ?? placeholder
//
//            let entry = BudgetEntry(
//                date: .now,
//                data: data
//            )
//
//            completion(Timeline(
//                entries: [entry],
//                policy: .after(.now.addingTimeInterval(60 * 60 * 3))
//            ))
//        }
//    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        print("WIDGET TIMELINE REQUESTED")
        Task {
            await uploadCurrentWidgetPushToken()
            
            let downloaded = await BudgetWidgetAPI.fetchBudgetData()

            if let downloaded {
                WidgetCache.save(downloaded)
            }
            
            let data = downloaded ?? WidgetCache.load() ?? placeholder
            
            var newData: Array<PlaidTransLite> = []
            for each in data.trans {
                //let logo = await loadLogoFromCoreDataIfNeeded(for: String(each.payMethodId))
                let new = PlaidTransLite(id: each.id, title: each.title, amount: each.amountString, payMethodId: each.payMethodId, logo: nil)
                newData.append(new)
            }
            
            let result = PlaidResult(isPlaceholder: data.isPlaceholder, count: data.count, trans: newData)
            let entry = BudgetEntry(date: .now, data: result)

            completion(Timeline(
                entries: [entry],
                policy: .after(.now.addingTimeInterval(60 * 60 * 3))
            ))
        }
    }
}



func uploadCurrentWidgetPushToken() async {
    if let pushInfo = await WidgetCenter.shared.currentPushInfo {
        let token = pushInfo.token.map { String(format: "%02x", $0) }.joined()
        await BudgetWidgetAPI.registerWidgetPushToken(token: token)
    }
}

#if os(iOS)
struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) var family
    
    var entry: BudgetEntry
    
    var title: String {
        switch family {
        case .systemSmall:
            "Pending"
        case .systemMedium, .systemLarge:
            "Pending Transactions"
        default:
            "Pending"
        }
    }
    
    var limit: Int {
        switch family {
        case .systemSmall, .systemMedium: 3
        case .systemLarge: 8
        default: 3
        }
    }
    
    var updatedDate: Text {
        Text(entry.date, style: .time)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    
    var body: some View {
        VStack {
            if entry.data.trans.isEmpty {
                ContentUnavailableView("No Pending Transactions", systemImage: "dollarsign.bank.building.fill", description: updatedDate)
                
            } else {
                VStack {
                    header
                    Divider()
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            ForEach(entry.data.trans.prefix(limit)) {
                                transLine($0)
                                    .frame(height: geo.size.height / CGFloat(limit))
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "makeitrain://plaid_transactions"))
    }
    
    
    @ViewBuilder
    var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                updatedDate
            }
            
            Text("\(entry.data.count)")
                .padding(10)
                .background {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                }
        }
    }
    
    
    @ViewBuilder
    func transLine(_ trans: PlaidTransLite) -> some View {
        HStack {
            if let data = trans.logo, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 20, height: 20, alignment: .center)
                    .clipShape(Circle())
            }
            
            Text(trans.title)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(trans.amount.currencyWithDecimals())")
        }
        //.frame(maxHeight: .infinity)
        .font(.subheadline)
    }
}
#endif

#if os(watchOS)
//struct BudgetWatchWidgetView: View {
//    var entry: BudgetEntry
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("Pending")
//                .font(.headline)
//
//            Text("\(entry.data.count) transactions")
//                .font(.caption)
//
//            if let first = entry.data.trans.first {
//                Text(first.title)
//                    .font(.caption2)
//                    .lineLimit(1)
//
//                Text(first.amount.currencyWithDecimals())
//                    .font(.caption2)
//            }
//        }
//        .containerBackground(.background, for: .widget)
//        .widgetURL(URL(string: "makeitrain://plaid_transactions"))
//    }
//}

struct BudgetWatchWidgetView: View {
    var entry: BudgetEntry
    
    var updatedDate: Text {
        Text(entry.date, style: .time)
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    
    var body: some View {
        VStack {
            if entry.data.trans.isEmpty {
                ContentUnavailableView("No Pending Transactions", systemImage: "dollarsign.bank.building.fill", description: updatedDate)
                
            } else {
                VStack {
                    header
                    Divider()
                                        
                    if let first = entry.data.trans.first {
                        transLine(first)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "makeitrain://plaid_transactions"))
    }
    
    
    @ViewBuilder
    var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Pending Transactions")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                updatedDate
            }
            
            Text("\(entry.data.count)")
                .padding(10)
                .background {
                    Circle()
                        .fill(.tertiary)
                }
        }
    }
    
    
    @ViewBuilder
    func transLine(_ trans: PlaidTransLite) -> some View {
        HStack {
            if let data = trans.logo, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 20, height: 20, alignment: .center)
                    .clipShape(Circle())
            }
            
            Text(trans.title)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(trans.amount.currencyWithDecimals())")
        }
        //.frame(maxHeight: .infinity)
        //.font(.subheadline)
        .font(.caption2)
    }
}


#endif


struct BudgetWidgetPushHandler: WidgetPushHandler {
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        let token = pushInfo.token.map { String(format: "%02x", $0) }.joined()
        Task {
            await BudgetWidgetAPI.registerWidgetPushToken(token: token)
        }
    }
}



struct BudgetWidget: Widget {
    let kind = "PlaidWidget"

    var body: some WidgetConfiguration {
        #if os(iOS)
        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Plaid Transactions")
        .description("Shows your latest plaid transactions that require action.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .pushHandler(BudgetWidgetPushHandler.self)
        #elseif os(watchOS)
        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
            BudgetWatchWidgetView(entry: entry)
            //BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Plaid Transactions")
        .description("Shows your latest plaid transactions that require action.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
            .accessoryCorner
        ])
        .pushHandler(BudgetWidgetPushHandler.self)
        #endif
    }
}


enum WidgetCache {
    private static let suiteName = "group.dev.cburnett837.MakeItRain"
    private static let plaidResultKey = "pendingPlaidWidgetResult"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func save(_ result: PlaidResult) {
        do {
            let data = try JSONEncoder().encode(result)
            defaults?.set(data, forKey: plaidResultKey)
        } catch {
            print("Widget cache save failed:", error)
        }
    }

    static func load() -> PlaidResult? {
        guard let data = defaults?.data(forKey: plaidResultKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(PlaidResult.self, from: data)
        } catch {
            print("Widget cache load failed:", error)
            return nil
        }
    }
}

//
//enum KeychainHelper {
//    private static let accessGroup = "N83B9B3ZN6.com.codyburnett.MakeItRain"
//    
//    static func readAuthToken() -> String? {
//        let query: [String: Any] = [
//            kSecClass as String: kSecClassInternetPassword,
//            kSecAttrAccount as String: "user_api_key",
//            kSecAttrAccessGroup as String: accessGroup,
//            kSecReturnData as String: true,
//            kSecMatchLimit as String: kSecMatchLimitOne
//        ]
//
//        var result: AnyObject?
//        let status = SecItemCopyMatching(query as CFDictionary, &result)
//
//        guard status == errSecSuccess,
//              let data = result as? Data,
//              let token = String(data: data, encoding: .utf8) else {
//            return nil
//        }
//
//        return token
//    }
//}
