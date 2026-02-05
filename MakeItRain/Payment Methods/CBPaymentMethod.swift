//
//  CBPaymentMethod.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI

struct PaymentMethodHolder: Identifiable {
    var id: Int
    var holder: CBUser?
    var type: XrefItem?
}

@Observable
class CBPaymentMethod: Codable, Identifiable, Equatable, Hashable, CanHandleLogo {
    var id: String
    var uuid: String?
    var title: String
    
    var dueDate: Int? {
        Int(dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1) ?? "0")
    }
    var dueDateString: String?
    
    var limit: Double? {
        Double(limitString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var limitString: String?
        
    var accountType: AccountType
    var color: Color
    var isViewingDefault = false
    var isEditingDefault = false
    var isHidden = false
    var isPrivate = true
    var active: Bool
    var action: PaymentMethodAction
    
    var notificationOffset: Int = 0
    var notifyOnDueDate: Bool = false
    var last4: String?
    var logo: Data?
    var logoParentType: XrefItem = XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod)
    
    var holderOne: CBUser?
    var holderOneType: XrefItem?
    var holderTwo: CBUser?
    var holderTwoType: XrefItem?
    var holderThree: CBUser?
    var holderThreeType: XrefItem?
    var holderFour: CBUser?
    var holderFourType: XrefItem?
    
    var fallbackImage: String {
        accountType == .checking || accountType == .cash ? "banknote.fill" : "creditcard.fill"
    }
    
    var interestRate: Double? {
        Double(interestRateString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var interestRateString: String?
    
    var loanDuration: Double? {
        Double(loanDurationString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var loanDurationString: String?
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    var listOrder: Int?
    
    
    // MARK: - Analytic Variables
    var breakdowns: Array<PayMethodMonthlyBreakdown> = []
    /// This is here so the unified payment method can hold it's children for analysis purposes.
    var breakdownsRegardlessOfPaymentMethod: [PayMethodMonthlyBreakdown] = []
    
    var profitLossMinPercentage: Double = 0.0
    var profitLossMaxPercentage: Double = 0.0
    
    var profitLossMinAmount: Double { Double(profitLossMinAmountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0 }
    var profitLossMinAmountString: String = ""
    
    var profitLossMaxAmount: Double { Double(profitLossMaxAmountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0 }
    var profitLossMaxAmountString: String = ""
    
    var minEod: Double { Double(minEodString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0 }
    var minEodString: String = ""
    
    var maxEod: Double { Double(maxEodString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0 }
    var maxEodString: String = ""
    
    
    var recentTransactionCount: Int = 0
    var sectionType: PaymentMethodSection {
        if self.isDebitOrCash || self.isUnifiedDebit {
            return .debit
        } else if self.isCreditOrLoan || self.isUnifiedCredit{
            return .credit
        } else {
            return .other
        }
    }
    
    // MARK: - View Helper Variables
    var isPermitted: Bool {
        isPrivate ? AppState.shared.user!.id == enteredBy.id : true
    }
    
    var isPermittedAndViewable: Bool {
        isPermitted && !isHidden
    }
    
    var isDebitOrUnified: Bool {
        [.unifiedChecking, .checking, .cash].contains(accountType)
    }
    
    var isCreditOrUnified: Bool {
        [.unifiedCredit, .credit, .loan].contains(accountType)
    }
    
    var isInvestment: Bool {
        [.investment, .brokerage, .k401].contains(accountType)
    }
    
//    var isDebit: Bool {
//        accountType == .checking
//    }
    
    var isDebitOrCash: Bool {
        [.checking, .cash].contains(accountType)
    }
    
    var isCreditOrLoan: Bool {
        [.credit, .loan].contains(accountType)
    }
    
    var isUnifiedDebit: Bool {
        accountType == .unifiedChecking
    }
    
    var isUnifiedCredit: Bool {
        accountType == .unifiedCredit
    }
    
    var isUnified: Bool {
        isUnifiedDebit || isUnifiedCredit
    }
    
    var allHolders: [PaymentMethodHolder] {
        return [
            PaymentMethodHolder(id: 1, holder: self.holderOne, type: self.holderOneType),
            PaymentMethodHolder(id: 2, holder: self.holderTwo, type: self.holderTwoType),
            PaymentMethodHolder(id: 3, holder: self.holderThree, type: self.holderThreeType),
            PaymentMethodHolder(id: 4, holder: self.holderFour, type: self.holderFourType)
        ]
        
    }
    
    // MARK: - Init
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = .primary
        self.accountType = .checking
        self.action = .add
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.accountType = .checking
        self.action = .add
        self.color = .primary
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
        
        self.holderOne = AppState.shared.user!
        self.holderOneType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .primary)
    }
    
//    init(unifiedAccountType: AccountType) {
//        
//        if unifiedAccountType == .unifiedChecking {
//            self.id = 100000000
//            self.title = "All Checking"
//        } else if unifiedAccountType == .unifiedCredit {
//            self.id = 100000001
//            self.title = "All Credit"
//        } else {
//            self.id = 0
//            self.title = ""
//        }
//        
//        self.accountType = unifiedAccountType
//        self.action = .edit
//        self.color = .white
//        self.active = true
//    
    init(entity: PersistentPaymentMethod) {
        self.id = entity.id!
        self.title = entity.title ?? ""
        self.dueDateString = String(entity.dueDate)
        
        
        self.limitString = entity.limit.currencyWithDecimals()
        
        self.accountType = AccountType(rawValue: Int(entity.accountType)) ?? .checking
        self.color = Color.fromHex(entity.hexCode) ?? .clear
        //self.color = Color.fromName(entity.hexCode ?? "white")
        self.action = .edit
        self.isViewingDefault = entity.isViewingDefault
        self.isEditingDefault = entity.isEditingDefault
        self.active = true
        self.notificationOffset = Int(entity.notificationOffset)
        self.notifyOnDueDate = entity.notifyOnDueDate
        self.last4 = entity.last4
        self.interestRateString = String(entity.interestRate)
        self.loanDurationString = String(entity.loanDuration)
        
//        self.enteredBy = AppState.shared.user!
//        self.updatedBy = AppState.shared.user!
//        self.enteredDate = Date()
//        self.updatedDate = Date()
        
        self.enteredBy = AppState.shared.getUserBy(id: Int(entity.enteredByID)) ?? AppState.shared.user!
        self.updatedBy = AppState.shared.getUserBy(id: Int(entity.updatedByID)) ?? AppState.shared.user!
        self.enteredDate = entity.enteredDate ?? Date()
        self.updatedDate = entity.updatedDate ?? Date()
        
        self.holderOne = AppState.shared.getUserBy(id: Int(entity.holderOneID))
        self.holderTwo = AppState.shared.getUserBy(id: Int(entity.holderTwoID))
        self.holderThree = AppState.shared.getUserBy(id: Int(entity.holderThreeID))
        self.holderFour = AppState.shared.getUserBy(id: Int(entity.holderFourID))
        
        if Int(entity.holderOneTypeID) != 0 {
            self.holderOneType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: Int(entity.holderOneTypeID))
        }
        if Int(entity.holderTwoTypeID) != 0 {
            self.holderTwoType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: Int(entity.holderTwoTypeID))
        }
        if Int(entity.holderThreeTypeID) != 0 {
            self.holderThreeType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: Int(entity.holderThreeTypeID))
        }
        if Int(entity.holderFourTypeID) != 0 {
            self.holderFourType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: Int(entity.holderFourTypeID))
        }
        
        
        self.isHidden = entity.isHidden
        self.isPrivate = entity.isPrivate
        //self.logo = entity.logo?.photoData
        
        self.listOrder = Int(entity.listOrder)
        self.recentTransactionCount = Int(entity.recentTransactionCount)
        
        
        /// Fetch the logo from core data and store it in the image cache.
        let pred1 = NSPredicate(format: "relatedID == %@", id)
        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
        
        let context = DataManager.shared.createContext()
        if let perLogo = DataManager.shared.getOne(
            context: context,
            type: PersistentLogo.self,
            predicate: .compound(comp),
            createIfNotFound: false
        ) {
            self.logo = perLogo.photoData
            
            if ImageCache.shared.loadFromCache(
                parentTypeId: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id,
                parentId: entity.id!,
                id: entity.id!
            ) == nil {
                if let data = perLogo.photoData {
                    Task {
                        await ImageCache.shared.saveToCache(
                            parentTypeId: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id,
                            parentId: entity.id!,
                            id: entity.id!,
                            data: data
                        )
                    }
                }
            }
        }
    }
    
    /// Send the current year to the server when updating a payment method for 1 use case:
    /// If the method goes from private to public, update the starting amount records so the long poll will push them to other users on the account.
    var viewingYear: Int?
    
    enum CodingKeys: CodingKey { case id, uuid, title, due_date, limit, account_type_id, hex_code, is_viewing_default, is_editing_default, active, user_id, account_id, device_uuid, notification_offset, notify_on_due_date, last_4_digits, entered_by, updated_by, entered_date, updated_date, breakdowns, interest_rate, loan_duration, is_hidden, is_private, logo, list_order, viewing_year, holder_one, holder_two, holder_three, holder_four, holder_one_type_id, holder_two_type_id, holder_three_type_id, holder_four_type_id, transaction_count }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(dueDate, forKey: .due_date)
        try container.encode(limit, forKey: .limit)
        try container.encode(accountType.rawValue, forKey: .account_type_id)
        try container.encode(color.toHex(), forKey: .hex_code)
        //try container.encode(color.description, forKey: .hex_code)
        try container.encode(isViewingDefault ? 1 : 0, forKey: .is_viewing_default)
        try container.encode(isEditingDefault ? 1 : 0, forKey: .is_editing_default)
        try container.encode(isHidden ? 1 : 0, forKey: .is_hidden)
        try container.encode(isPrivate ? 1 : 0, forKey: .is_private)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(notificationOffset, forKey: .notification_offset)
        try container.encode(notifyOnDueDate ? 1 : 0, forKey: .notify_on_due_date)
        try container.encode(last4, forKey: .last_4_digits)
        try container.encode(logo, forKey: .logo)
        try container.encode(interestRate, forKey: .interest_rate)
        try container.encode(loanDuration, forKey: .loan_duration)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        
        try container.encode(listOrder, forKey: .list_order)
        
        //print("going to encode holder id1 \(holderOne?.id)")
        
        try container.encode(holderOne, forKey: .holder_one)
        try container.encode(holderTwo, forKey: .holder_two)
        try container.encode(holderThree, forKey: .holder_three)
        try container.encode(holderFour, forKey: .holder_four)
        try container.encode(holderOneType?.id, forKey: .holder_one_type_id)
        try container.encode(holderTwoType?.id, forKey: .holder_two_type_id)
        try container.encode(holderThreeType?.id, forKey: .holder_three_type_id)
        try container.encode(holderFourType?.id, forKey: .holder_four_type_id)
        
        /// Send the current year to the server when updating a payment method for 1 use case:
        /// If the method goes from private to public, update the starting amount records so the long poll will push them to other users on the account.
        try container.encode(viewingYear, forKey: .viewing_year)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        
        title = try container.decode(String.self, forKey: .title)
        
        let dueDate = try container.decode(Int?.self, forKey: .due_date)
        self.dueDateString = String(dueDate ?? 0)
        
        let limit = try container.decode(Double?.self, forKey: .limit)
        
        self.limitString = limit?.currencyWithDecimals()
        
        let accountType = try container.decode(Int.self, forKey: .account_type_id)
        self.accountType = AccountType(rawValue: accountType) ?? .checking
        
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        self.color = Color.fromHex(hexCode) ?? .primary
        //let colorDescription = try container.decode(String?.self, forKey: .hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        
        
        
        let isViewingDefault = try container.decode(Int?.self, forKey: .is_viewing_default)
        self.isViewingDefault = isViewingDefault == 1
        
        let isEditingDefault = try container.decode(Int?.self, forKey: .is_editing_default)
        self.isEditingDefault = isEditingDefault == 1
        
        let isHidden = try container.decode(Int?.self, forKey: .is_hidden)
        self.isHidden = isHidden == 1
        
        let isPrivate = try container.decode(Int?.self, forKey: .is_private)
        self.isPrivate = isPrivate == 1
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1
        
//        let offset = try container.decode(Int?.self, forKey: .notification_offset)
//        if offset == nil {
//            self.notificationOffset = 0
//        } else {
//            self.notificationOffset = offset
//        }
        
        
        let offset = try container.decode(Int?.self, forKey: .notification_offset)
        if let offset {
            self.notificationOffset = offset
        } else {
            self.notificationOffset = 0
        }
        
        let notifyOnDueDate = try container.decode(Int?.self, forKey: .notify_on_due_date)
        self.notifyOnDueDate = notifyOnDueDate == 1
        
        self.last4 = try container.decode(String?.self, forKey: .last_4_digits)
        //self.logo = try container.decode(String?.self, forKey: .logo)
        holderOne = try container.decode(CBUser?.self, forKey: .holder_one)
        holderTwo = try container.decode(CBUser?.self, forKey: .holder_two)
        holderThree = try container.decode(CBUser?.self, forKey: .holder_three)
        holderFour = try container.decode(CBUser?.self, forKey: .holder_four)
        
        let holderOneTypeID = try container.decode(Int?.self, forKey: .holder_one_type_id)
        let holderTwoTypeID = try container.decode(Int?.self, forKey: .holder_two_type_id)
        let holderThreeTypeID = try container.decode(Int?.self, forKey: .holder_three_type_id)
        let holderFourTypeID = try container.decode(Int?.self, forKey: .holder_four_type_id)
                
        if let holderOneTypeID { holderOneType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: holderOneTypeID) }
        if let holderTwoTypeID { holderTwoType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: holderTwoTypeID) }
        if let holderThreeTypeID { holderThreeType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: holderThreeTypeID) }
        if let holderFourTypeID { holderFourType = XrefModel.getItem(from: .paymentMethodHolderTypes, byID: holderFourTypeID) }
        
        //self.interestRate = try container.decode(Double?.self, forKey: .interest_rate)
        //self.loanDuration = try container.decode(Int?.self, forKey: .loan_duration)
        
        if let interestRate = try container.decode(Double?.self, forKey: .interest_rate) {
            self.interestRateString = String(interestRate)
        }
        
        if let loanDuration = try container.decode(Double?.self, forKey: .loan_duration) {
            self.loanDurationString = String(loanDuration)
        }
        
        action = .edit
        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine enteredDate date")
        }
        
        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine updatedDate date")
        }
                
        self.breakdowns = try container.decodeIfPresent(Array<PayMethodMonthlyBreakdown>.self, forKey: .breakdowns) ?? []
                        
        let pred1 = NSPredicate(format: "relatedID == %@", self.id)
        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
        
        /// Fetch the logo out of core data since the encoded strings can be heavy and I don't want to use Async Image for every logo.
        let context = DataManager.shared.createContext()
        if let logo = DataManager.shared.getOne(
           context: context,
           type: PersistentLogo.self,
           predicate: .compound(comp),
           createIfNotFound: false
        ) {
            self.logo = logo.photoData
        }
        
        
        
        listOrder = try container.decode(Int?.self, forKey: .list_order)
        
        recentTransactionCount = try container.decodeIfPresent(Int.self, forKey: .transaction_count) ?? 0
    }
    
    
    func getAmount(for date: Date) -> Double? {
        breakdowns.filter { Calendar.current.isDate(date, equalTo: $0.date, toGranularity: .month) }.first?.income
    }
    
//    static var empty: CBPaymentMethod {
//        CBPaymentMethod()
//    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.dueDate == deepCopy.dueDate
            && self.limit == deepCopy.limit
            && self.accountType == deepCopy.accountType
            && self.notificationOffset == deepCopy.notificationOffset
            && self.notifyOnDueDate == deepCopy.notifyOnDueDate
            && self.last4 == deepCopy.last4
            && self.interestRate == deepCopy.interestRate
            && self.loanDuration == deepCopy.loanDuration
            && self.isHidden == deepCopy.isHidden
            && self.isPrivate == deepCopy.isPrivate
            && self.color == deepCopy.color
            && self.logo == deepCopy.logo
            && self.listOrder == deepCopy.listOrder
            && self.holderOne == deepCopy.holderOne
            && self.holderTwo == deepCopy.holderTwo
            && self.holderThree == deepCopy.holderThree
            && self.holderFour == deepCopy.holderFour
            && self.holderOneType == deepCopy.holderOneType
            && self.holderTwoType == deepCopy.holderTwoType
            && self.holderThreeType == deepCopy.holderThreeType
            && self.holderFourType == deepCopy.holderFourType
            {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBPaymentMethod?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBPaymentMethod()
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.dueDateString = self.dueDateString
            copy.limitString = self.limitString
            copy.accountType = self.accountType
            copy.color = self.color
            copy.isViewingDefault = self.isViewingDefault
            copy.isEditingDefault = self.isEditingDefault
            copy.notificationOffset = self.notificationOffset
            copy.notifyOnDueDate = self.notifyOnDueDate
            copy.last4 = self.last4
            copy.interestRateString = self.interestRateString
            copy.loanDurationString = self.loanDurationString
            copy.active = self.active
            copy.isHidden = self.isHidden
            copy.isPrivate = self.isPrivate
            copy.logo = self.logo
            copy.listOrder = self.listOrder
            copy.holderOne = self.holderOne
            copy.holderTwo = self.holderTwo
            copy.holderThree = self.holderThree
            copy.holderFour = self.holderFour
            copy.holderOneType = self.holderOneType
            copy.holderTwoType = self.holderTwoType
            copy.holderThreeType = self.holderThreeType
            copy.holderFourType = self.holderFourType
            //copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.dueDateString = deepCopy.dueDateString
                self.limitString = deepCopy.limitString
                self.accountType = deepCopy.accountType
                self.color = deepCopy.color
                self.isViewingDefault = deepCopy.isViewingDefault
                self.isEditingDefault = deepCopy.isEditingDefault
                self.notificationOffset = deepCopy.notificationOffset
                self.notifyOnDueDate = deepCopy.notifyOnDueDate
                self.last4 = deepCopy.last4
                self.interestRateString = deepCopy.interestRateString
                self.loanDurationString = deepCopy.loanDurationString
                self.active = deepCopy.active
                self.isHidden = deepCopy.isHidden
                self.isPrivate = deepCopy.isPrivate
                self.logo = deepCopy.logo
                self.listOrder = deepCopy.listOrder
                self.holderOne = deepCopy.holderOne
                self.holderTwo = deepCopy.holderTwo
                self.holderThree = deepCopy.holderThree
                self.holderFour = deepCopy.holderFour
                self.holderOneType = deepCopy.holderOneType
                self.holderTwoType = deepCopy.holderTwoType
                self.holderThreeType = deepCopy.holderThreeType
                self.holderFourType = deepCopy.holderFourType
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(payMethod: CBPaymentMethod) {
        self.title = payMethod.title
        self.dueDateString = payMethod.dueDateString
        
        
        self.limitString = payMethod.limit?.currencyWithDecimals()
        
        self.accountType = payMethod.accountType
        self.color = payMethod.color
        self.isViewingDefault = payMethod.isViewingDefault
        self.isEditingDefault = payMethod.isEditingDefault
        self.active = payMethod.active
        self.notificationOffset = payMethod.notificationOffset
        self.notifyOnDueDate = payMethod.notifyOnDueDate
        self.last4 = payMethod.last4
        self.interestRateString = payMethod.interestRateString
        self.loanDurationString = payMethod.loanDurationString
        self.isHidden = payMethod.isHidden
        self.isPrivate = payMethod.isPrivate
        self.logo = payMethod.logo
        
        self.enteredBy = payMethod.enteredBy
        self.updatedBy = payMethod.updatedBy
        self.enteredDate = payMethod.enteredDate
        self.updatedDate = payMethod.updatedDate
        self.listOrder = payMethod.listOrder
        self.holderOne = payMethod.holderOne
        self.holderTwo = payMethod.holderTwo
        self.holderThree = payMethod.holderThree
        self.holderFour = payMethod.holderFour
        self.holderOneType = payMethod.holderOneType
        self.holderTwoType = payMethod.holderTwoType
        self.holderThreeType = payMethod.holderThreeType
        self.holderFourType = payMethod.holderFourType
        self.recentTransactionCount = payMethod.recentTransactionCount
    }
            
    
    func changeDefault(_ to: Bool) async {
        self.isViewingDefault = to
        let id = self.id
        
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(id)), createIfNotFound: false) {
                entity.isViewingDefault = to
                let _ = DataManager.shared.save(context: context)
            }
        }
    }
    

    static func == (lhs: CBPaymentMethod, rhs: CBPaymentMethod) -> Bool {
        //print("-- \(#function) for \(lhs.title) && \(rhs.title)")
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.dueDate == rhs.dueDate
        && lhs.limitString == rhs.limitString
        && lhs.accountType == rhs.accountType
        && lhs.color == rhs.color
        && lhs.isViewingDefault == rhs.isViewingDefault
        && lhs.isEditingDefault == rhs.isEditingDefault
        && lhs.notificationOffset == rhs.notificationOffset
        && lhs.notifyOnDueDate == rhs.notifyOnDueDate
        && lhs.last4 == rhs.last4
        && lhs.interestRate == rhs.interestRate
        && lhs.loanDuration == rhs.loanDuration
        && lhs.isHidden == rhs.isHidden
        && lhs.isPrivate == rhs.isPrivate
        && lhs.logo == rhs.logo
        && lhs.listOrder == rhs.listOrder
        && lhs.active == rhs.active
        && lhs.holderOne == rhs.holderOne
        && lhs.holderTwo == rhs.holderTwo
        && lhs.holderThree == rhs.holderThree
        && lhs.holderFour == rhs.holderFour
        && lhs.holderOneType == rhs.holderOneType
        && lhs.holderTwoType == rhs.holderTwoType
        && lhs.holderThreeType == rhs.holderThreeType
        && lhs.holderFourType == rhs.holderFourType
        {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
