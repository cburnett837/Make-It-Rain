//
//  CBStartingAmount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation

@Observable
class CBStartingAmount: Codable, Identifiable, Hashable, Equatable, CurrencyConvertable {
    //var amountTypeLingo: String = "Starting Amount"
    
    var amountTypeLingo: String {
        "Flip"
//        if (payMethod?.isCreditOrLoan ?? false) {
//            amountString.contains("-") ? "Payment" : "Expense"
//        } else {
//            amountString.contains("-") ? "Expense" : "Income"
//        }
    }
    
    var id: String
    var uuid: String?
    var month: Int
    var year: Int
    var date: Date?
    
    /// AMOUNT DETAILS
    var country: Country?
    var amountString: String = ""
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
    }
    
    /// PRECONVERSION AMOUNT DETAILS
    var condataOriginalCountry: Country?
    var condataOriginalAmountString: String
    var condataOriginalAmount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(condataOriginalAmountString) ?? 0.0
    }
    
    /// CONVERSION DETAILS
    var condataOriginCountryToPayMethodCountryExchangeRate: Decimal?
    var condataPayMethodCountryToAccountCountryExchangeRate: Decimal?
    var condataPayMethodAmountString: String
    var condataPayMethodAmount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(condataPayMethodAmountString) ?? 0.0
    }
        
    var hostExRate: Decimal?
        
    var active: Bool
    var payMethod: CBPaymentMethod?
    var action: StartingAmountAction
            
    enum CodingKeys: CodingKey { case id, uuid, month, year, amount, payment_method, user_id, account_id, device_uuid, active, condata__pay_method_amount,
                                      condata__pay_method_country_id,
                                      condata__original_amount,
                                      condata__original_country_id,
                                      condata__origin_country_to_pay_method_country_exchange_rate,
                                      condata__pay_method_country_to_account_country_exchange_rate,
                                      amount_country_id }
    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.month = 0
        self.year = 0
        self.date = Helpers.createDate(month: 0, year: 0)!
        self.amountString = ""
        self.condataOriginalAmountString = ""
        self.condataPayMethodAmountString = ""
        //self.amountUsd = 0
        //self.originalUnconvertedAmount = 0
        self.payMethod = nil
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
        try container.encode(condataPayMethodAmount, forKey: .condata__pay_method_amount)
        try container.encode(payMethod?.country?.id, forKey: .condata__pay_method_country_id)
        try container.encode(condataOriginalAmount, forKey: .condata__original_amount)
        try container.encode(condataOriginalCountry?.id, forKey: .condata__original_country_id)
        try container.encode(condataOriginCountryToPayMethodCountryExchangeRate, forKey: .condata__origin_country_to_pay_method_country_exchange_rate)
        try container.encode(condataPayMethodCountryToAccountCountryExchangeRate, forKey: .condata__pay_method_country_to_account_country_exchange_rate)
        try container.encode(country?.id, forKey: .amount_country_id)
        
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
        
        let payMethod = try container.decode(CBPaymentMethod?.self, forKey: .payment_method)
        self.payMethod = payMethod
        
        /// AMOUNT DETAILS
        let amount = try container.decode(Decimal.self, forKey: .amount)
        if let countryID = try container.decode(Int?.self, forKey: .amount_country_id),
           let country = Countries.fetch(by: countryID) {
            self.amountString = CurrencyHelpers.formatAmountText(amount: amount, currencyCode: country.currencyCode)
            self.country = country
        } else {
            self.amountString = CurrencyHelpers.formatAmountText(amount: amount, currencyCode: AppState.shared.country.currencyCode)
        }
        
        /// PRECONVERSION AMOUNT DETAILS
        let condataOriginalAmount = try container.decode(Decimal?.self, forKey: .condata__original_amount)
        if let condataOriginalCountryID = try container.decode(Int?.self, forKey: .condata__original_country_id),
           let condataOriginalCountry = Countries.fetch(by: condataOriginalCountryID) {
            self.condataOriginalCountry = condataOriginalCountry
            self.condataOriginalAmountString = CurrencyHelpers.formatAmountText(amount: condataOriginalAmount, currencyCode: condataOriginalCountry.currencyCode)
        } else {
            self.condataOriginalAmountString = ""
        }
        
        
        /// CONVERSION DETAILS
        if let condataPayMethodAmount = try container.decode(Decimal?.self, forKey: .condata__pay_method_amount),
           let countryID = payMethod?.country?.id,
           let country = Countries.fetch(by: countryID) {
            self.condataPayMethodAmountString = CurrencyHelpers.formatAmountText(amount: condataPayMethodAmount, currencyCode: country.currencyCode)
        } else {
            self.condataPayMethodAmountString = ""
        }
        
        
        self.condataOriginCountryToPayMethodCountryExchangeRate = try container.decode(Decimal?.self, forKey: .condata__origin_country_to_pay_method_country_exchange_rate)
        
        self.condataPayMethodCountryToAccountCountryExchangeRate = try container.decode(Decimal?.self, forKey: .condata__pay_method_country_to_account_country_exchange_rate)
        
        
        
        
        let month = try container.decode(Int.self, forKey: .month)
        let year = try container.decode(Int.self, forKey: .year)
        self.month = month
        self.year = year
        self.date = Helpers.createDate(month: month, year: year)!
        //self.payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
        action = .edit
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.month == deepCopy.month
            && self.year == deepCopy.year
            && self.date == deepCopy.date
            && self.amountString == deepCopy.amountString
            && self.payMethod == deepCopy.payMethod
            && self.condataOriginalAmount == deepCopy.condataOriginalAmount
            && self.condataOriginalCountry == deepCopy.condataOriginalCountry
            && self.condataPayMethodAmount == deepCopy.condataPayMethodAmount
            && self.condataOriginCountryToPayMethodCountryExchangeRate == deepCopy.condataOriginCountryToPayMethodCountryExchangeRate
            && self.condataPayMethodCountryToAccountCountryExchangeRate == deepCopy.condataPayMethodCountryToAccountCountryExchangeRate
            {
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
            copy.date = self.date
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            copy.country = self.country
            
            copy.condataOriginalAmountString = self.condataOriginalAmountString
            copy.condataOriginalCountry = self.condataOriginalCountry
            
            copy.condataPayMethodAmountString = self.condataPayMethodAmountString
            copy.condataOriginCountryToPayMethodCountryExchangeRate = self.condataOriginCountryToPayMethodCountryExchangeRate
            copy.condataPayMethodCountryToAccountCountryExchangeRate = self.condataPayMethodCountryToAccountCountryExchangeRate
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.month = deepCopy.month
                self.year = deepCopy.year
                self.date = deepCopy.date
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
                self.country = deepCopy.country
                self.condataOriginalAmountString = deepCopy.condataOriginalAmountString
                self.condataOriginalCountry = deepCopy.condataOriginalCountry
                
                self.condataPayMethodAmountString = deepCopy.condataPayMethodAmountString
                self.condataOriginCountryToPayMethodCountryExchangeRate = deepCopy.condataOriginCountryToPayMethodCountryExchangeRate
                self.condataPayMethodCountryToAccountCountryExchangeRate = deepCopy.condataPayMethodCountryToAccountCountryExchangeRate
            }
        case .clear:
            break
        }
    }
    
    
    
    
    static func == (lhs: CBStartingAmount, rhs: CBStartingAmount) -> Bool {
        if lhs.id == rhs.id
            && lhs.month == rhs.month
            && lhs.year == rhs.year
            && lhs.date == rhs.date
            && lhs.amountString == rhs.amountString
            && lhs.payMethod == rhs.payMethod
            && lhs.country == rhs.country
            && lhs.condataOriginalAmount == rhs.condataOriginalAmount
            && lhs.condataOriginalCountry == rhs.condataOriginalCountry
                
            && lhs.condataPayMethodAmount == rhs.condataPayMethodAmount
            && lhs.condataOriginCountryToPayMethodCountryExchangeRate == rhs.condataOriginCountryToPayMethodCountryExchangeRate
            && lhs.condataPayMethodCountryToAccountCountryExchangeRate == rhs.condataPayMethodCountryToAccountCountryExchangeRate
        {
            return true
        }
        return false
    }
    
    
    func setFromAnotherInstance(startingAmount: CBStartingAmount) {
        self.month = startingAmount.month
        self.year = startingAmount.year
        self.date = startingAmount.date
        self.amountString = startingAmount.amountString
        self.payMethod = startingAmount.payMethod
        self.country = startingAmount.country
        self.condataOriginalAmountString = startingAmount.condataOriginalAmountString
        self.condataOriginalCountry = startingAmount.condataOriginalCountry
        
        self.condataPayMethodAmountString = startingAmount.condataPayMethodAmountString
        self.condataOriginCountryToPayMethodCountryExchangeRate = startingAmount.condataOriginCountryToPayMethodCountryExchangeRate
        self.condataPayMethodCountryToAccountCountryExchangeRate = startingAmount.condataPayMethodCountryToAccountCountryExchangeRate
    }
    
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
