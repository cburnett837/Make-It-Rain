//
//  CBStartingAmount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation

@Observable
class CBStartingAmount: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
        //Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String = ""
    var amountUsd: Decimal?
    var originalUnconvertedAmount: Decimal?
    var exchangeRate: Decimal?
//    var convertedDisplayAmount: Decimal? {
//        if let cunt = self.payMethod.country {
//            let setCunt = AppState.shared.country
//            if cunt != setCunt {
//                if let converted = Countries.convert(amount: self.amount, from: cunt, to: setCunt) {
//                    return converted
//                }
//            }
//        }
//        
//        return nil
//    }
        
    var active: Bool
    var payMethod: CBPaymentMethod
    var action: StartingAmountAction        
            
    enum CodingKeys: CodingKey { case id, uuid, month, year, amount, payment_method, user_id, account_id, device_uuid, active, country_id, original_unconverted_amount, exchange_rate }
    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.month = 0
        self.year = 0
        self.amountString = ""
        //self.amountUsd = 0
        //self.originalUnconvertedAmount = 0
        self.payMethod = CBPaymentMethod()
        self.action = .add
        self.active = true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        
        try container.encode(amount, forKey: .amount)
//        let USA = Countries.fetch(by: 225)!
//        if let amount = Countries.convert(amount: self.amount, from: AppState.shared.country, to: USA) {
//            try container.encode(amount, forKey: .amount)
//        }
        
        try container.encode(originalUnconvertedAmount, forKey: .original_unconverted_amount)
        try container.encode(exchangeRate, forKey: .exchange_rate)
        
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        let amount = try container.decode(Decimal.self, forKey: .amount)
        //self.amountString = "$\(amount)"
        
        //self.amountString = amount.currencyWithDecimals()
        
        let payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
        self.payMethod = payMethod
        
        self.amountUsd = amount
        //self.amountString = amount.currencyWithDecimals()
        
        if let currencyCode = payMethod.country?.currencyCode {
            self.amountString = CurrencyHelpers.formatAmountText(amount: amount, currencyCode: currencyCode)
        } else {
            self.amountString = amount.currencyWithDecimals()
        }
        
        
        
        /// Since we store all amounts in the database as USD, convert them to the app's user-defined country.
//        let USA = Countries.fetch(by: 225)!
//        if let amountConverted = Countries.convert(amount: amount, from: USA, to: AppState.shared.country),
//           let country = payMethod.country {
////            self.convertedDisplayAmount = Countries.convert(amount: amount, from: USA, to: AppState.shared.country)
//            self.amountString = CurrencyHelpers.formatAmountText(amount: amountConverted, currencyCode: country.currencyCode)
//            
//            
//        } else {
//            self.amountString = amount.currencyWithDecimals()
//        }
        
        self.originalUnconvertedAmount = try container.decode(Decimal?.self, forKey: .original_unconverted_amount)
        self.exchangeRate = try container.decode(Decimal?.self, forKey: .exchange_rate)
        
        
        
        
        
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        //self.payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
        action = .edit
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.month == deepCopy.month
            && self.year == deepCopy.year
            && self.amountString == deepCopy.amountString
            && self.payMethod == deepCopy.payMethod {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBStartingAmount?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBStartingAmount()
            copy.id = self.id
            copy.month = self.month
            copy.year = self.year
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.month = deepCopy.month
                self.year = deepCopy.year
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
            }
        case .clear:
            break
        }
    }
    
    
    
    
    static func == (lhs: CBStartingAmount, rhs: CBStartingAmount) -> Bool {
        if lhs.id == rhs.id
            && lhs.month == rhs.month
            && lhs.year == rhs.year
            && lhs.amountString == rhs.amountString
            && lhs.payMethod == rhs.payMethod
        {
            return true
        }
        return false
    }
    
    
    func setFromAnotherInstance(startingAmount: CBStartingAmount) {
        self.month = startingAmount.month
        self.year = startingAmount.year
        self.amountString = startingAmount.amountString
        self.payMethod = startingAmount.payMethod
    }
    
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
