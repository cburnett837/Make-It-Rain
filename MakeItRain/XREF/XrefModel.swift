//
//  XrefModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/22/25.
//

import Foundation

enum RefType {
    case eventTransactionStatuses
    case relatedTransactionType
    case fileTypes
    case eventInviteStatus
    case smartTransactionIssues
    case openRecords
    case locationTypes
    case repeatingTransactionType
    case categoryTypes
    case accountTypes
    case paymentMethodUserOptions
    case logoTypes
    case paymentMethodHolderTypes
    case budgetTypes
    case settingTypes
}

enum XrefEnum: String {
    case pending
    case claimed
    
    /// Related transactions
    case transaction
    case event
    case eventTransaction
    case eventTransactionOption
    case christmasListGift
    
    case accepted
    case rejected
    
    /// Smart Transaction Errors
    case missingPaymentMethod
    case missingDate
    case missingPaymentMethodAndDate
    case funkyDate
    case missingTitle
    
    /// Repeating Transaction Types
    case regular
    case payment
    case transfer
    
    /// Category Types
    case income
    case expense
    
    /// Account Types
    case unifiedChecking
    case unifiedCredit
    case checking
    case credit
    case cash
    case savings
    case k401
    case investment
    case loan
    case crypto
    case brokerage
    
    /// Payment Method Options
    case isHidden
    case defaultForEditing
    case defaultForViewing
    
    /// For logos
    case repeatingTransaction
    case paymentMethod
    case plaidBank
    case avatar
    
    /// For Payment Method Holders
    case primary
    case secondary
    
    /// For Budgets
    case category
    case categoryGroup
    
    /// For Settings
    case useWholeNumbers
    case trimTotals
    case lowBalanceThreshold
    case paymentMethodHolderFilter
    case paymentMethodSortOrder
    case transactionSortOrder
    case categorySortOrder
    case incomeColor
}

struct XrefItem: Identifiable, Equatable, Hashable {
    let id: Int
    let refType: String
    let description: String
    let enumID: XrefEnum
    
    static func == (lhs: XrefItem, rhs: XrefItem) -> Bool {
        if lhs.id == rhs.id
        && lhs.refType == rhs.refType
        && lhs.description == rhs.description
        && lhs.enumID == rhs.enumID {
            return true
        }
        return false
    }
}

struct XrefModel {
    static let eventTransactionStatuses: Array<XrefItem> = [
        XrefItem(id: 1, refType: "event_transaction_status", description: "Pending", enumID: .pending),
        XrefItem(id: 2, refType: "event_transaction_status", description: "Claimed", enumID: .claimed)
    ]
    
    static let relatedTransactionTypes: Array<XrefItem> = [
        XrefItem(id: 3, refType: "related_transaction_type", description: "Transaction", enumID: .transaction),
        XrefItem(id: 4, refType: "related_transaction_type", description: "Event Transaction", enumID: .eventTransaction),
        XrefItem(id: 50, refType: "related_transaction_type", description: "Christmas List Gift", enumID: .christmasListGift)
    ]
    
    static let fileTypes: Array<XrefItem> = [
        XrefItem(id: 5, refType: "file_type", description: "Transaction", enumID: .transaction),
        XrefItem(id: 6, refType: "file_type", description: "Event Transaction", enumID: .eventTransaction),
        XrefItem(id: 17, refType: "file_type", description: "Event", enumID: .event),
        XrefItem(id: 18, refType: "file_type", description: "Event Transaction Option", enumID: .eventTransactionOption),
        //XrefItem(id: 50, refType: "file_type", description: "Avatar", enumID: .avatar)
    ]
    
    static let eventInviteStatuses: Array<XrefItem> = [
        XrefItem(id: 7, refType: "event_invite_status", description: "Pending", enumID: .pending),
        XrefItem(id: 8, refType: "event_invite_status", description: "Accepted", enumID: .accepted),
        XrefItem(id: 9, refType: "event_invite_status", description: "Rejected", enumID: .rejected)
    ]
    
    static let smartTransactionIssues: Array<XrefItem> = [
        XrefItem(id: 10, refType: "smart_transaction_issue", description: "Missing Payment Method", enumID: .missingPaymentMethod),
        XrefItem(id: 11, refType: "smart_transaction_issue", description: "Missing Date", enumID: .missingDate),
        XrefItem(id: 12, refType: "smart_transaction_issue", description: "Missing Payment Method And Date", enumID: .missingPaymentMethodAndDate),
        XrefItem(id: 13, refType: "smart_transaction_issue", description: "Funky Date", enumID: .funkyDate),
        XrefItem(id: 53, refType: "smart_transaction_issue", description: "Missing Title", enumID: .missingTitle)
    ]
    
    static let openRecords: Array<XrefItem> = [
        XrefItem(id: 14, refType: "open_record_type", description: "Event", enumID: .event),
        XrefItem(id: 15, refType: "open_record_type", description: "Event Transaction", enumID: .eventTransaction),
        XrefItem(id: 16, refType: "open_record_type", description: "Event Transaction Option", enumID: .eventTransactionOption)
    ]
    
    static let locationTypes: Array<XrefItem> = [
        XrefItem(id: 19, refType: "location_type", description: "Transaction", enumID: .transaction),
        XrefItem(id: 20, refType: "photo_type", description: "Event", enumID: .event),
        XrefItem(id: 21, refType: "location_type", description: "Event Transaction", enumID: .eventTransaction),
        XrefItem(id: 22, refType: "location_type", description: "Event Transaction Option", enumID: .eventTransactionOption)
    ]
        
    static let repeatingTransactionTypes: Array<XrefItem> = [
        XrefItem(id: 23, refType: "repeating_transaction_type", description: "Regular", enumID: .regular),
        XrefItem(id: 24, refType: "repeating_transaction_type", description: "Payment", enumID: .payment),
        XrefItem(id: 25, refType: "repeating_transaction_type", description: "Transfer", enumID: .transfer),
    ]
    
    static let categoryTypes: Array<XrefItem> = [
        XrefItem(id: 26, refType: "category_type", description: "Income", enumID: .income),
        XrefItem(id: 27, refType: "category_type", description: "Expense", enumID: .expense),
        XrefItem(id: 28, refType: "category_type", description: "Payment", enumID: .payment),
        XrefItem(id: 29, refType: "category_type", description: "Savings", enumID: .savings),
    ]
    
    static let accountTypes: Array<XrefItem> = [
        XrefItem(id: 30, refType: "account_type", description: "Unified Checking", enumID: .unifiedChecking),
        XrefItem(id: 31, refType: "account_type", description: "Unified Credit", enumID: .unifiedCredit),
        XrefItem(id: 32, refType: "account_type", description: "Checking", enumID: .checking),
        XrefItem(id: 33, refType: "account_type", description: "Credit", enumID: .credit),
        XrefItem(id: 34, refType: "account_type", description: "Cash", enumID: .cash),
        XrefItem(id: 35, refType: "account_type", description: "Savings", enumID: .savings),
        XrefItem(id: 36, refType: "account_type", description: "401K", enumID: .k401),
        XrefItem(id: 37, refType: "account_type", description: "Investment", enumID: .investment),
        XrefItem(id: 38, refType: "account_type", description: "Loan", enumID: .loan),
        XrefItem(id: 45, refType: "account_type", description: "Loan", enumID: .crypto),
        XrefItem(id: 46, refType: "account_type", description: "Loan", enumID: .brokerage),
    ]
    
    static let paymentMethodUserOptions: Array<XrefItem> = [
        XrefItem(id: 39, refType: "payment_method_user_option", description: "Is Hidden", enumID: .isHidden),
        XrefItem(id: 40, refType: "payment_method_user_option", description: "Default For Editing", enumID: .defaultForEditing),
        XrefItem(id: 41, refType: "payment_method_user_option", description: "Default For Viewing", enumID: .defaultForViewing)
    ]
    
    static let logoTypes: Array<XrefItem> = [
        XrefItem(id: 42, refType: "logo_parent_type", description: "Payment Method", enumID: .paymentMethod),
        XrefItem(id: 43, refType: "logo_parent_type", description: "Repeating Transaction", enumID: .repeatingTransaction),
        XrefItem(id: 44, refType: "logo_parent_type", description: "Plaid Bank", enumID: .plaidBank),
        XrefItem(id: 47, refType: "logo_parent_type", description: "User Avatar", enumID: .avatar),
    ]
    
    static let paymentMethodHolderTypes: Array<XrefItem> = [
        XrefItem(id: 48, refType: "payment_method_holder_type", description: "Primary", enumID: .primary),
        XrefItem(id: 49, refType: "payment_method_holder_type", description: "Secondary", enumID: .secondary),
    ]
    
    static let budgetTypes: Array<XrefItem> = [
        XrefItem(id: 51, refType: "budget_type", description: "Category", enumID: .category),
        XrefItem(id: 52, refType: "budget_type", description: "Category Group", enumID: .categoryGroup),
    ]
    
    static let settingTypes: Array<XrefItem> = [
        XrefItem(id: 54, refType: "setting", description: "Use whole numbers", enumID: .useWholeNumbers),
        XrefItem(id: 55, refType: "setting", description: "Trim totals", enumID: .trimTotals),
        XrefItem(id: 56, refType: "setting", description: "Low balance threshold", enumID: .lowBalanceThreshold),
        XrefItem(id: 57, refType: "setting", description: "Payment method holder filter", enumID: .paymentMethodHolderFilter),
        XrefItem(id: 58, refType: "setting", description: "Payment method sort order", enumID: .paymentMethodSortOrder),
        XrefItem(id: 59, refType: "setting", description: "Transaction sort order", enumID: .transactionSortOrder),
        XrefItem(id: 60, refType: "setting", description: "Category sort order", enumID: .categorySortOrder),
        XrefItem(id: 61, refType: "setting", description: "Income color", enumID: .incomeColor),
    ]
    
    
    static func getItems(forRefType refType: RefType) -> Array<XrefItem> {
        return switch refType {
        case .eventTransactionStatuses: eventTransactionStatuses
        case .relatedTransactionType: relatedTransactionTypes
        case .fileTypes: fileTypes
        case .eventInviteStatus: eventInviteStatuses
        case .smartTransactionIssues: smartTransactionIssues
        case .openRecords: openRecords
        case .locationTypes: locationTypes
        case .repeatingTransactionType: repeatingTransactionTypes
        case .categoryTypes: categoryTypes
        case .accountTypes: accountTypes
        case .paymentMethodUserOptions: paymentMethodUserOptions
        case .logoTypes: logoTypes
        case .paymentMethodHolderTypes: paymentMethodHolderTypes
        case .budgetTypes: budgetTypes
        case .settingTypes: settingTypes
        }
    }
    
    
    static func getItem(from refType: RefType, byID id: Int) -> XrefItem {
        let items = self.getItems(forRefType: refType)
        if let item = items.filter({ $0.id == id }).first {
            return item
        } else {
            fatalError("Could not find item for \(id) in list \(refType)", file: #file, line: #line)
        }
    }
    
    static func getItem(from refType: RefType, byEnumID enumID: XrefEnum) -> XrefItem {
        let items = self.getItems(forRefType: refType)
        if let item = items.filter({ $0.enumID == enumID }).first {
            return item
        } else {
            fatalError("Could not find item for \(enumID.rawValue) in list \(refType)", file: #file, line: #line)
        }
    }
}
