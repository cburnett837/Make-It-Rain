//
//  Enums.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum CloseAction {
    case save, cancel
}

enum InAppAlertPreference {
    case alert, toast
}

enum WhereToLookForTransaction {
    case normalList, tempList, searchResultList, /*eventList,*/ smartList, receiptsList
}

enum TransactionSaveActionToProcess {
    case normal, fromTransfer, fromEvent
}

enum AppError: Error {
    case serverError(String), connectionError, badtimeOut, taskCancelled, sessionError, incorrectCredentials, failedToGetPhoto, failedToUploadPhoto, accessRevoked
}

enum CalendarSearchWhat {
    case titles, tags
}

enum FunkyChatGptDateError: Error {
    case funkyYear, funkyMonth
}

enum KeywordTriggerType: String {
    case equals = "equals"
    case contains = "contains"
}

enum WhenType: String {
    case weekday = "weekday"
    case month = "month"
    case dayOfMonth = "dayOfMonth"
    case specificDate = "specificDate"
}

enum ShadowCopyAction {
    case create, restore, clear
}

enum TextFieldInputType {
    case text, double, currency
}

enum KeyboardLocation {
    case toolbar, app
}

enum AccountType: Int {
    case checking = 32
    case credit = 33
    case savings = 35
    case investment = 37
    case k401 = 36
    case cash = 34
    case unifiedChecking = 30
    case unifiedCredit = 31
    case loan = 38
    case crypto = 45
    case brokerage = 46
    
    var prettyValue: String {
        switch self {
        case .checking:
            "Checking"
        case .credit:
            "Credit"
        case .savings:
            "Savings"
        case .investment:
            "Investment"
        case .k401:
            "401K"
        case .cash:
            "Cash"
        case .unifiedChecking:
            "Unified Checking"
        case .unifiedCredit:
            "Unified Credit"
        case .loan:
            "Loan"
        case .crypto:
            "Crypto"
        case .brokerage:
            "Brokerage"
        }
    }
}

enum ViewThatTriggeredChange {
    case calendar, paymentMethodListOrders
}

public enum LineItemIndicator: String, CaseIterable {
    case dot, emoji, paymentMethod
    
    var mobilePrettyValue: String {
        switch self {
        case .dot: return "Category"
        case .emoji: return ""
        case .paymentMethod: return "Account"
        }
    }
    
    var macPrettyValue: String {
        switch self {
        case .dot: return "Category Dot"
        case .emoji: return "Category Symbol"
        case .paymentMethod: return "Account"
        }
    }
    
    static var mobileCases: [Self] {
        return [.dot, .paymentMethod]
    }
    
    static var macCases: [Self] {
        return [.dot, .emoji, .paymentMethod]
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "dot": return .dot
        case "emoji": return .emoji
        case "paymentMethod": return .paymentMethod
        default: return .emoji
        }
    }
}


enum CategoryIndicator: String, CaseIterable {
    case dot, emoji
    
    var prettyValue: String {
        switch self {
        case .dot: return "Dot"
        case .emoji: return "Symbol"
        }
    }
}


//enum MacCategoryDisplayMode: String {
//    case dot, emoji
//}

public enum SortMode: String, CaseIterable {
    case title, listOrder
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "listOrder": return .listOrder
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .listOrder:
            "Custom Order"
        }
    }
}

public enum TransactionSortMode: String, CaseIterable {
    case title, category, enteredDate
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "category": return .category
        case "enteredDate": return .enteredDate
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .category:
            "Category"
        case .enteredDate:
            "Entered Date"
        }
    }
}

enum TransactionListDisplayMode: String, CaseIterable {
    case byDay, byCategory, singleList
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "byDay": return .byDay
        case "byCategory": return .byCategory
        case "singleList": return .singleList
        default: return .singleList
        }
    }
    
    var prettyValue: String {
        switch self {
        case .byDay: "By Day"
        case .byCategory: "By Category"
        case .singleList: "List"
        }
    }
}


public enum PhoneLineItemDisplayItem: String, CaseIterable {
    case title, total, category, both
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "total": return .total
        case "category": return .category
        case "both": return .both
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .total:
            "Total"
        case .category:
            "Colored Indicator"
        case .both:
            "Title & Total"
        }
    }
}

public enum CreditEodView: String, CaseIterable {
    case availableCredit, remainingBalance
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "availableCredit": return .availableCredit
        case "remainingBalance": return .remainingBalance
        default: return .remainingBalance
        }
    }
    
    var prettyValue: String {
        switch self {
        case .availableCredit:
            "Available Credit"
        case .remainingBalance:
            "Remaining Balance"
        }
    }
}

enum PhoneLineItemTotalPosition: String, CaseIterable {
    case inline, below
    
    var prettyValue: String {
        switch self {
        case .inline:
            "Next to title"
        case .below:
            "Below title"
        }
    }
}

public enum UpdatedByOtherUserDisplayMode: String, CaseIterable {
    case concise, full, avatar
    
    var prettyValue: String {
        switch self {
        case .concise:
            "Bold & italic title"
        case .full:
            "Their Name"
        case .avatar:
            "Their Avatar"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "concise": return .concise
        case "full": return .full
        case "avatar": return .avatar
        default: return .concise
        }
    }
}

enum SearchScope: String, CaseIterable {
    case category, title
}

enum ImageState {
    case empty, loading(Progress), failure(AppError)
}

enum TransferError: Error {
    case importFailed
}

enum FocusedField {
    case title, dueDate, amount, notes, emoji, search, startingAmount, none, trackingNumber, orderNumber, url
}

enum CalendarViewMode: String {
    case bottomPanel, details, budget, split, scrollable
}

enum CalendarChartModel: String {
    case verticalBar, horizontalBar, pie, donut, line
}

enum RefreshTechnique: String {
    case viaInitial, viaButton, viaSceneChange, viaLongPoll, viaTempListButton, viaTempListSceneChange
}

public enum UserPreferedColorScheme: String {
    case userLight, userDark, userSystem
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "userLight": return .userLight
        case "userDark": return .userDark
        case "userSystem": return .userSystem
        default: return .userSystem
        }
    }
}



enum AppSuiteKey: String {
    case christmas = "christmas_list"
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "christmas_list": return .christmas
        default: return .christmas
        }
    }
}

enum ChristmasListDeletePreference: String {
    case delete = "delete"
    case resetStatusToIdea = "reset_status_to_idea"
}

enum ListOrderUpdateType: String {
    case categories = "categories"
    case eventCategories = "event_categories"
    case eventItems = "event_items"
    case paymentMethods = "payment_methods"
}

enum OpenOrClosed: String {
    case open, closed
}

enum OpenRecordViewType: String {
    case event, transaction, eventTransactionOption
}

enum FileUploadProgress {
    case performCleanup
    case readyForPlaceholder(String?, String)
    case uploaded(String?, String)
    case displayCompleteAlert(String?, String)
    case readyForDownload(String?, String)
    case failedToUpload(String?, String)
    case done(String?, String)
}

enum PlaidLinkMode: String {
    case addAccount = "add"
    case updateBank = "update"
    case newBank = "new"
}

enum DetailsOrInsights: String {
    case details = "details"
    case insights = "insights"
}

#if os(iOS)
enum CBKeyboardType {
    case system(UIKeyboardType)
    case custom(CustomKeyboardType)
}

enum CustomKeyboardType {
    case numpad, calculator
}

enum DecimalKeyboardButtonType {
    case number, delete, decimalPoint, posNeg
}


enum CalculatorKeyboardButtonType {
    case number, delete, decimalPoint, posNeg, divide, multiply, subtract, add
}

#endif

enum FileType: String {
    case photo = "photo"
    case pdf = "pdf"
    case csv = "csv"
    case spreadsheet = "spreadsheet"
    
    var mimeType: String {
        switch self {
        case .photo: "image/jpeg"
        case .pdf: "application/pdf"
        case .csv: "text/csv"
        case .spreadsheet: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        }
    }
    
    var ext: String {
        switch self {
        case .photo:
            "jpg"
        case .pdf:
            "pdf"
        case .csv:
            "csv"
        case .spreadsheet:
            "xlsx"
        }
    }
    
    var defaultName: String {
        switch self {
        case .photo:
            "image"
        case .pdf:
            "pdf"
        case .csv:
            "csv"
        case .spreadsheet:
            "xlsx"
        }
    }
    
    static func getByExtension(_ ext: String) -> FileType {
        if ext == "jpg" {
            return .photo
        } else if ext == "pdf" {
            return .pdf
        } else if ext == "csv" {
            return .csv
        } else if ext == "xlsx" {
            return .spreadsheet
        }
        return .photo
    }
}

enum AmountType: String, CaseIterable, Identifiable {
    var id: AmountType { self }
    case positive, negative, all
    
    var prettyValue: String {
        switch self {
        case .positive: return "Only income"
        case .negative: return "Only expenses"
        case .all: return "All"
        }
    }
    
}


//MARK: Core Data Stuff
enum IdType {
    case int(Int)
    case string(String)
}

enum Predicate {
    case single(NSPredicate)
    case compound(NSCompoundPredicate)
    case byId(IdType)
}

enum CoreDataError: Error {
    case notFound
    case reason(String)
}
