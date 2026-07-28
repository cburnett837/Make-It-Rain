//
//  XrefModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/25.
//

import Foundation



//
//enum RefType {
//    case eventTransactionStatuses
//    case relatedTransactionType
//    case fileTypes
//    case eventInviteStatus
//    case smartTransactionIssues
//    case openRecords
//    case locationTypes
//    case repeatingTransactionType
//    case categoryTypes
//    case accountTypes
//    case paymentMethodUserOptions
//    case logoTypes
//    case paymentMethodHolderTypes
//    case budgetTypes
////    case settingTypes
//}
//
//enum XrefEnum: String {
//    case pending
//    case claimed
//    
//    /// Related transactions
//    case transaction
//    case event
//    case eventTransaction
//    case eventTransactionOption
//    case christmasListGift
//    
//    case accepted
//    case rejected
//    
//    /// Smart Transaction Errors
//    case missingPaymentMethod
//    case missingDate
//    case missingPaymentMethodAndDate
//    case funkyDate
//    case missingTitle
//    
//    /// Repeating Transaction Types
//    case regular
//    case payment
//    case transfer
//    
//    /// Category Types
//    case income
//    case expense
//    case irregularIncome
//    
//    /// Account Types
//    case unifiedChecking
//    case unifiedCredit
//    case checking
//    case credit
//    case cash
//    case savings
//    case k401
//    case investment
//    case loan
//    case crypto
//    case brokerage
//    
//    /// Payment Method Options
//    case isHidden
//    case defaultForEditing
//    case defaultForViewing
//    
//    /// For logos
//    case repeatingTransaction
//    case paymentMethod
//    case plaidBank
//    case avatar
//    
//    /// For Payment Method Holders
//    case primary
//    case secondary
//    
//    /// For Budgets
//    case category
//    case categoryGroup
//    case tag
//    
//    case unknown
//    
//    /// For Settings
////    case useWholeNumbers
////    case trimTotals
////    case lowBalanceThreshold
////    case paymentMethodHolderFilter
////    case paymentMethodSortOrder
////    case transactionSortOrder
////    case categorySortOrder
////    case incomeColor
//}
//
//
//struct XrefModel {
//    static let eventTransactionStatuses = XrefEventTransactionStatus.items
//    static let relatedTransactionTypes = XrefRelatedTransactionType.items
//    static let fileTypes = XrefFileType.items
//    static let eventInviteStatuses = XrefEventInviteStatus.items
//    static let smartTransactionIssues = XrefSmartTransactionIssue.items
//    static let openRecords = XrefOpenRecordType.items
//    static let locationTypes = XrefLocationType.items
//    static let repeatingTransactionTypes = XrefRepeatingTransactionType.items
//    static let categoryTypes = XrefCategoryType.items
//    static let accountTypes = XrefAccountType.items
//    static let paymentMethodUserOptions = XrefPaymentMethodUserOption.items
//    static let logoTypes = XrefLogoParentType.items
//    static let paymentMethodHolderTypes = XrefPaymentMethodHolderType.items
//    static let budgetTypes = XrefBudgetType.items
//}
//
//struct XrefItem: Identifiable, Equatable, Hashable {
//    let id: Int
//    let refType: String
//    let description: String
//    let enumID: XrefEnum
//    
//    static func == (lhs: XrefItem, rhs: XrefItem) -> Bool {
//        if lhs.id == rhs.id
//        && lhs.refType == rhs.refType
//        && lhs.description == rhs.description
//        && lhs.enumID == rhs.enumID {
//            return true
//        }
//        return false
//    }
//}


protocol XrefRecord: CaseIterable, Identifiable, Hashable {
    var id: Int { get }
    var refType: String { get }
    var description: String { get }
}

extension XrefRecord where Self: RawRepresentable, RawValue == Int {
    init(id: Int, file: String = #file, line: Int = #line, function: String = #function) {
        guard let value = Self(rawValue: id) else {
            fatalError("Invalid \(Self.self) id: \(id) -- \(file), \(line), \(function)")
        }

        self = value
    }
}

//extension XrefRecord where Self: RawRepresentable, RawValue == Int {
//    static func item(id: Int) -> Self {
//        guard let item = Self(rawValue: id) else {
//            fatalError("Could not find \(Self.self) for id \(id)")
//        }
//
//        return item
//    }
//
//    static func item(enumID: XrefEnum) -> Self {
//        guard let item = allCases.first(where: { $0.enumID == enumID }) else {
//            fatalError("Could not find \(Self.self) for enumID \(enumID)")
//        }
//
//        return item
//    }
//}

enum XrefRelatedTransactionType: Int, XrefRecord {
    case transaction = 3
    case christmasListGift = 50

    var id: Int { rawValue }
    var refType: String { "related_transaction_type" }

    var description: String {
        switch self {
        case .transaction: "Transaction"
        case .christmasListGift: "Christmas List Gift"
        }
    }
}

enum XrefFileType: Int, XrefRecord {
    case transaction = 5

    var id: Int { rawValue }
    var refType: String { "file_type" }

    var description: String {
        switch self {
        case .transaction: "Transaction"
        }
    }
}

enum XrefSmartTransactionIssue: Int, XrefRecord {
    case missingPaymentMethod = 10
    case missingDate = 11
    case missingPaymentMethodAndDate = 12
    case funkyDate = 13
    case missingTitle = 53

    var id: Int { rawValue }
    var refType: String { "smart_transaction_issue" }

    var description: String {
        switch self {
        case .missingPaymentMethod: "Missing Payment Method"
        case .missingDate: "Missing Date"
        case .missingPaymentMethodAndDate: "Missing Payment Method And Date"
        case .funkyDate: "Funky Date"
        case .missingTitle: "Missing Title"
        }
    }
}

enum XrefOpenRecordType: Int, XrefRecord {
    case event = 14
    case eventTransaction = 15
    case eventTransactionOption = 16

    var id: Int { rawValue }
    var refType: String { "open_record_type" }

    var description: String {
        switch self {
        case .event: "Event"
        case .eventTransaction: "Event Transaction"
        case .eventTransactionOption: "Event Transaction Option"
        }
    }
}

enum XrefLocationType: Int, XrefRecord {
    case transaction = 19

    var id: Int { rawValue }
    var refType: String { "location_type" }

    var description: String {
        switch self {
        case .transaction: "Transaction"
        }
    }
}

enum XrefRepeatingTransactionType: Int, XrefRecord {
    case regular = 23
    case payment = 24
    case transfer = 25

    var id: Int { rawValue }
    var refType: String { "repeating_transaction_type" }

    var description: String {
        switch self {
        case .regular: "Regular"
        case .payment: "Payment"
        case .transfer: "Transfer"
        }
    }
}

enum XrefCategoryType: Int, XrefRecord {
    case income = 26
    case irregularIncome = 64
    case expense = 27
    case payment = 28
    case savings = 29

    var id: Int { rawValue }
    var refType: String { "category_type" }

    var description: String {
        switch self {
        case .income: "Income"
        case .irregularIncome: "Irregular Income"
        case .expense: "Expense"
        case .payment: "Payment"
        case .savings: "Savings"
        }
    }
}

enum XrefAccountType: Int, XrefRecord {
    case unifiedChecking = 30
    case unifiedCredit = 31
    case checking = 32
    case credit = 33
    case cash = 34
    case savings = 35
    case k401 = 36
    case investment = 37
    case loan = 38
    case crypto = 45
    case brokerage = 46

    var id: Int { rawValue }
    var refType: String { "account_type" }

    var description: String {
        switch self {
        case .unifiedChecking: "Unified Checking"
        case .unifiedCredit: "Unified Credit"
        case .checking: "Checking"
        case .credit: "Credit"
        case .cash: "Cash"
        case .savings: "Savings"
        case .k401: "401K"
        case .investment: "Investment"
        case .loan: "Loan"
        case .crypto: "Crypto"
        case .brokerage: "Brokerage"
        }
    }
}

enum XrefPaymentMethodUserOption: Int, XrefRecord {
    case isHidden = 39
    case defaultForEditing = 40
    case defaultForViewing = 41

    var id: Int { rawValue }
    var refType: String { "payment_method_user_option" }

    var description: String {
        switch self {
        case .isHidden: "Is Hidden"
        case .defaultForEditing: "Default For Editing"
        case .defaultForViewing: "Default For Viewing"
        }
    }
}

enum XrefLogoParentType: Int, XrefRecord {
    case paymentMethod = 42
    case repeatingTransaction = 43
    case plaidBank = 44
    case avatar = 47

    var id: Int { rawValue }
    var refType: String { "logo_parent_type" }

    var description: String {
        switch self {
        case .paymentMethod: "Payment Method"
        case .repeatingTransaction: "Repeating Transaction"
        case .plaidBank: "Plaid Bank"
        case .avatar: "User Avatar"
        }
    }
}

enum XrefPaymentMethodHolderType: Int, XrefRecord {
    case primary = 48
    case secondary = 49

    var id: Int { rawValue }
    var refType: String { "payment_method_holder_type" }

    var description: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        }
    }
}

enum XrefBudgetType: Int, XrefRecord {
    case category = 51
    case categoryGroup = 52
    case tag = 65

    var id: Int { rawValue }
    var refType: String { "budget_type" }

    var description: String {
        switch self {
        case .category: "Category"
        case .categoryGroup: "Category Group"
        case .tag: "Tag"
        }
    }
}


//
//struct XrefModel {
//    static let eventTransactionStatuses: Array<XrefItem> = [
//        XrefItem(id: 1, refType: "event_transaction_status", description: "Pending", enumID: .pending),
//        XrefItem(id: 2, refType: "event_transaction_status", description: "Claimed", enumID: .claimed)
//    ]
//    
//    static let relatedTransactionTypes: Array<XrefItem> = [
//        XrefItem(id: 3, refType: "related_transaction_type", description: "Transaction", enumID: .transaction),
//        XrefItem(id: 4, refType: "related_transaction_type", description: "Event Transaction", enumID: .eventTransaction),
//        XrefItem(id: 50, refType: "related_transaction_type", description: "Christmas List Gift", enumID: .christmasListGift)
//    ]
//    
//    static let fileTypes: Array<XrefItem> = [
//        XrefItem(id: 5, refType: "file_type", description: "Transaction", enumID: .transaction),
//        XrefItem(id: 6, refType: "file_type", description: "Event Transaction", enumID: .eventTransaction),
//        XrefItem(id: 17, refType: "file_type", description: "Event", enumID: .event),
//        XrefItem(id: 18, refType: "file_type", description: "Event Transaction Option", enumID: .eventTransactionOption),
//        //XrefItem(id: 50, refType: "file_type", description: "Avatar", enumID: .avatar)
//    ]
//    
//    static let eventInviteStatuses: Array<XrefItem> = [
//        XrefItem(id: 7, refType: "event_invite_status", description: "Pending", enumID: .pending),
//        XrefItem(id: 8, refType: "event_invite_status", description: "Accepted", enumID: .accepted),
//        XrefItem(id: 9, refType: "event_invite_status", description: "Rejected", enumID: .rejected)
//    ]
//    
//    static let smartTransactionIssues: Array<XrefItem> = [
//        XrefItem(id: 10, refType: "smart_transaction_issue", description: "Missing Payment Method", enumID: .missingPaymentMethod),
//        XrefItem(id: 11, refType: "smart_transaction_issue", description: "Missing Date", enumID: .missingDate),
//        XrefItem(id: 12, refType: "smart_transaction_issue", description: "Missing Payment Method And Date", enumID: .missingPaymentMethodAndDate),
//        XrefItem(id: 13, refType: "smart_transaction_issue", description: "Funky Date", enumID: .funkyDate),
//        XrefItem(id: 53, refType: "smart_transaction_issue", description: "Missing Title", enumID: .missingTitle)
//    ]
//    
//    static let openRecords: Array<XrefItem> = [
//        XrefItem(id: 14, refType: "open_record_type", description: "Event", enumID: .event),
//        XrefItem(id: 15, refType: "open_record_type", description: "Event Transaction", enumID: .eventTransaction),
//        XrefItem(id: 16, refType: "open_record_type", description: "Event Transaction Option", enumID: .eventTransactionOption)
//    ]
//    
//    static let locationTypes: Array<XrefItem> = [
//        XrefItem(id: 19, refType: "location_type", description: "Transaction", enumID: .transaction),
//        XrefItem(id: 20, refType: "photo_type", description: "Event", enumID: .event),
//        XrefItem(id: 21, refType: "location_type", description: "Event Transaction", enumID: .eventTransaction),
//        XrefItem(id: 22, refType: "location_type", description: "Event Transaction Option", enumID: .eventTransactionOption)
//    ]
//        
//    static let repeatingTransactionTypes: Array<XrefItem> = [
//        XrefItem(id: 23, refType: "repeating_transaction_type", description: "Regular", enumID: .regular),
//        XrefItem(id: 24, refType: "repeating_transaction_type", description: "Payment", enumID: .payment),
//        XrefItem(id: 25, refType: "repeating_transaction_type", description: "Transfer", enumID: .transfer),
//    ]
//    
//    static let categoryTypes: Array<XrefItem> = [
//        XrefItem(id: 26, refType: "category_type", description: "Income", enumID: .income),
//        XrefItem(id: 64, refType: "category_type", description: "Irregular Income", enumID: .irregularIncome),
//        XrefItem(id: 27, refType: "category_type", description: "Expense", enumID: .expense),
//        XrefItem(id: 28, refType: "category_type", description: "Payment", enumID: .payment),
//        XrefItem(id: 29, refType: "category_type", description: "Savings", enumID: .savings),
//    ]
//    
//    static let accountTypes: Array<XrefItem> = [
//        XrefItem(id: 30, refType: "account_type", description: "Unified Checking", enumID: .unifiedChecking),
//        XrefItem(id: 31, refType: "account_type", description: "Unified Credit", enumID: .unifiedCredit),
//        XrefItem(id: 32, refType: "account_type", description: "Checking", enumID: .checking),
//        XrefItem(id: 33, refType: "account_type", description: "Credit", enumID: .credit),
//        XrefItem(id: 34, refType: "account_type", description: "Cash", enumID: .cash),
//        XrefItem(id: 35, refType: "account_type", description: "Savings", enumID: .savings),
//        XrefItem(id: 36, refType: "account_type", description: "401K", enumID: .k401),
//        XrefItem(id: 37, refType: "account_type", description: "Investment", enumID: .investment),
//        XrefItem(id: 38, refType: "account_type", description: "Loan", enumID: .loan),
//        XrefItem(id: 45, refType: "account_type", description: "Loan", enumID: .crypto),
//        XrefItem(id: 46, refType: "account_type", description: "Loan", enumID: .brokerage),
//    ]
//    
//    static let paymentMethodUserOptions: Array<XrefItem> = [
//        XrefItem(id: 39, refType: "payment_method_user_option", description: "Is Hidden", enumID: .isHidden),
//        XrefItem(id: 40, refType: "payment_method_user_option", description: "Default For Editing", enumID: .defaultForEditing),
//        XrefItem(id: 41, refType: "payment_method_user_option", description: "Default For Viewing", enumID: .defaultForViewing)
//    ]
//    
//    static let logoTypes: Array<XrefItem> = [
//        XrefItem(id: 42, refType: "logo_parent_type", description: "Payment Method", enumID: .paymentMethod),
//        XrefItem(id: 43, refType: "logo_parent_type", description: "Repeating Transaction", enumID: .repeatingTransaction),
//        XrefItem(id: 44, refType: "logo_parent_type", description: "Plaid Bank", enumID: .plaidBank),
//        XrefItem(id: 47, refType: "logo_parent_type", description: "User Avatar", enumID: .avatar),
//    ]
//    
//    static let paymentMethodHolderTypes: Array<XrefItem> = [
//        XrefItem(id: 48, refType: "payment_method_holder_type", description: "Primary", enumID: .primary),
//        XrefItem(id: 49, refType: "payment_method_holder_type", description: "Secondary", enumID: .secondary),
//    ]
//    
//    static let budgetTypes: Array<XrefItem> = [
//        XrefItem(id: 51, refType: "budget_type", description: "Category", enumID: .category),
//        XrefItem(id: 52, refType: "budget_type", description: "Category Group", enumID: .categoryGroup),
//        XrefItem(id: 65, refType: "budget_type", description: "Tag", enumID: .tag),
//    ]
//    
////    static let settingTypes: Array<XrefItem> = [
////        XrefItem(id: 54, refType: "setting", description: "Use whole numbers", enumID: .useWholeNumbers),
////        XrefItem(id: 55, refType: "setting", description: "Trim totals", enumID: .trimTotals),
////        XrefItem(id: 56, refType: "setting", description: "Low balance threshold", enumID: .lowBalanceThreshold),
////        XrefItem(id: 57, refType: "setting", description: "Payment method holder filter", enumID: .paymentMethodHolderFilter),
////        XrefItem(id: 58, refType: "setting", description: "Payment method sort order", enumID: .paymentMethodSortOrder),
////        XrefItem(id: 59, refType: "setting", description: "Transaction sort order", enumID: .transactionSortOrder),
////        XrefItem(id: 60, refType: "setting", description: "Category sort order", enumID: .categorySortOrder),
////        XrefItem(id: 61, refType: "setting", description: "Income color", enumID: .incomeColor),
////    ]
//    
//    
//    static func getItems(forRefType refType: RefType) -> Array<XrefItem> {
//        return switch refType {
//        case .eventTransactionStatuses: eventTransactionStatuses
//        case .relatedTransactionType: relatedTransactionTypes
//        case .fileTypes: fileTypes
//        case .eventInviteStatus: eventInviteStatuses
//        case .smartTransactionIssues: smartTransactionIssues
//        case .openRecords: openRecords
//        case .locationTypes: locationTypes
//        case .repeatingTransactionType: repeatingTransactionTypes
//        case .categoryTypes: categoryTypes
//        case .accountTypes: accountTypes
//        case .paymentMethodUserOptions: paymentMethodUserOptions
//        case .logoTypes: logoTypes
//        case .paymentMethodHolderTypes: paymentMethodHolderTypes
//        case .budgetTypes: budgetTypes
////        case .settingTypes: settingTypes
//        }
//    }
//    
//    
//    static func getItem(from refType: RefType, byID id: Int) -> XrefItem {
//        let items = self.getItems(forRefType: refType)
//        if let item = items.filter({ $0.id == id }).first {
//            return item
//        } else {
//            fatalError("Could not find item for \(id) in list \(refType)", file: #file, line: #line)
//        }
//    }
//    
//    static func getItem(from refType: RefType, byEnumID enumID: XrefEnum) -> XrefItem {
//        let items = self.getItems(forRefType: refType)
//        if let item = items.filter({ $0.enumID == enumID }).first {
//            return item
//        } else {
//            fatalError("Could not find item for \(enumID.rawValue) in list \(refType)", file: #file, line: #line)
//        }
//    }
//}
