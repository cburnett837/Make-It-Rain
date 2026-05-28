//
//  Pending_Plaid_Widget.swift
//  Pending Plaid Widget
//
//  Created by Cody Burnett on 5/7/26.
//

import WidgetKit
import SwiftUI
import Security


struct CBUser: Decodable, Identifiable {
    var id: Int
    var accountID: Int
    var name: String
    var initials: String
    var email: String
    var avatar: Data?
    
    enum CodingKeys: CodingKey { case id, account_id, name, initials, email, avatar, device_uuid, year }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountID = try container.decode(Int.self, forKey: .account_id)
        name = try container.decode(String.self, forKey: .name)
        initials = try container.decode(String.self, forKey: .initials)
        email = try container.decode(String.self, forKey: .email)
    }    
}


struct CBNotificationToken: Encodable {
    var id: Int?
    var userID: Int?
    var accountID: Int?
    var deviceUUID: String?
    var notificationToken: String = ""
    
    enum CodingKeys: CodingKey { case id, user_id, account_id, device_uuid, notification_token }
    
    init(token: String) {
        self.notificationToken = token
        
        if let ud = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.data(forKey: "user") {
            do {
                let user = try JSONDecoder().decode(CBUser.self, from: ud)
                self.id = user.id
                self.userID = user.id
                self.accountID = user.accountID
            } catch {
                print("Unable to Decode User (\(error))")
            }
        }
        
        if let uuid = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.string(forKey: "deviceUUID") {
            self.deviceUUID = uuid
        }
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .user_id)
        try container.encode(accountID, forKey: .account_id)
        try container.encode(deviceUUID, forKey: .device_uuid)
        try container.encode(notificationToken, forKey: .notification_token)

    }
}


struct BudgetWidgetData: Codable {
    let currentMonthSpend: Double
    let budgetAmount: Double
    let lastUpdated: Date

    static let placeholder: Array<String> = ["Test", "test2"]
}


struct BudgetEntry: TimelineEntry {
    let date: Date
    var data: PlaidResult
}


struct PlaidResult: Codable {
    var isPlaceholder: Bool
    var count: Int
    var trans: [PlaidTransLite]
    
    enum CodingKeys: CodingKey {
        case count, trans
    }
    
    init (isPlaceholder: Bool, count: Int, trans: [PlaidTransLite]) {
        self.isPlaceholder = isPlaceholder
        self.count = count
        self.trans = trans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        trans = try container.decode(Array<PlaidTransLite>.self, forKey: .trans)
        isPlaceholder = false
    }
}


struct PlaidTransLite: Identifiable, Codable {
    var id: Int
    var title: String
    var amountString: String
    var payMethodId: Int
    var logo: Data?

    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }

    enum CodingKeys: CodingKey {
        case id, title, amount, payment_method_id, logo
    }

    init(id: Int, title: String, amount: String, payMethodId: Int, logo: Data? = nil) {
        self.id = id
        self.title = title
        self.amountString = amount
        self.payMethodId = payMethodId
        self.logo = logo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amountString = try container.decode(String.self, forKey: .amount)
        payMethodId = try container.decode(Int.self, forKey: .payment_method_id)
        logo = try container.decodeIfPresent(Data.self, forKey: .logo)
    }
    
    /// Needed to store in the cache.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amountString, forKey: .amount)
        try container.encode(payMethodId, forKey: .payment_method_id)
        try container.encodeIfPresent(logo, forKey: .logo)
    }
}


extension Double {
    func currencyWithDecimals() -> String {
        formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }
}



func loadLogoFromCoreDataIfNeeded(for id: String) async -> Data? {
    let context = DataManager.shared.createContext()
    let logoData: Data? = await DataManager.shared.perform(context: context) {
        let pred1 = NSPredicate(format: "relatedID == %@", id)
        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: 42))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])

        return DataManager.shared.getOne(
            context: context,
            type: PersistentLogo.self,
            predicate: .compound(comp),
            createIfNotFound: false
        )?.photoData
    }

    return logoData
}


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
                let logo = await loadLogoFromCoreDataIfNeeded(for: String(each.payMethodId))
                let new = PlaidTransLite(id: each.id, title: each.title, amount: each.amountString, payMethodId: each.payMethodId, logo: logo)
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
        StaticConfiguration(kind: kind, provider: BudgetWidgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Plaid Transactions")
        .description("Shows your latest plaid transactions that require action.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .pushHandler(BudgetWidgetPushHandler.self)
    }
}




enum BudgetWidgetAPI {
    static func fetchBudgetData() async -> PlaidResult? {
        print("I should download")
        //return []
        
        guard let apiKey = KeychainHelper.readAuthToken() else { return nil }
        
        let earl = String(format: "\(Keys.prodBaseURL)/budget_app")
        let url = URL(string: earl)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60
        
        guard let token = await WidgetCenter.shared.currentPushInfo?.token.map({ String(format: "%02x", $0) }).joined() else { return nil }
        print(token)
        
        let tokenModel = CBNotificationToken(token: token)
        let requestModel = RequestModel(requestType: "download_plaid_trans_for_widget", model: tokenModel)

        do {
            let jsonData = try! JSONEncoder().encode(requestModel)
            request.httpBody = jsonData
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try! decoder.decode(PlaidResult?.self, from: data)
        } catch {
            return nil
        }
    }

    
    static func registerWidgetPushToken(token: String) async {
        struct Body: Codable {
            let token: String
            let widgetKind: String
        }
        
        print("The widget token is \(token)")
        
        let tokenModel = CBNotificationToken(token: token)
        let requestModel = RequestModel(requestType: "add_new_notification_token_for_widget", model: tokenModel)
        
        guard let apiKey = KeychainHelper.readAuthToken() else { return }
        
        let earl = String(format: "\(Keys.prodBaseURL)/budget_app")
        let url = URL(string: earl)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let jsonData = try! JSONEncoder().encode(requestModel)
            request.httpBody = jsonData
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Widget extensions should fail silently.
        }
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


enum KeychainHelper {
    private static let accessGroup = "N83B9B3ZN6.com.codyburnett.MakeItRain"
    
    static func readAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: "user_api_key",
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }
}
