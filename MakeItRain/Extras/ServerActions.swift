//
//  ServerActions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/4/25.
//

import Foundation


enum TransactionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_transaction"
        case .edit: return "edit_cb_transaction"
        case .delete: return "delete_cb_transaction"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum RepeatingTransactionAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_repeating_transaction"
        case .edit: return "edit_cb_repeating_transaction"
        case .delete: return "delete_cb_repeating_transaction"
        }
    }
}

enum PaymentMethodAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_payment_method"
        case .edit: return "edit_cb_payment_method"
        case .delete: return "delete_cb_payment_method"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum PlaidBankAction: String {
    case edit, delete
    
    var serverKey: String {
        switch self {
        case .edit: return "edit_cb_plaid_bank"
        case .delete: return "delete_cb_plaid_bank"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "edit": return .edit
        case "delete": return .delete
        default: return .edit
        }
    }
}

enum PlaidAccountAction: String {
    case edit, delete
    
    var serverKey: String {
        switch self {
        case .edit: return "edit_cb_plaid_account"
        case .delete: return "delete_cb_plaid_account"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "edit": return .edit
        case "delete": return .delete
        default: return .edit
        }
    }
}

enum StartingAmountAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_starting_amount"
        case .edit: return "edit_cb_starting_amount"
        case .delete: return "delete_cb_starting_amount"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum KeywordAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_keyword"
        case .edit: return "edit_cb_keyword"
        case .delete: return "delete_cb_keyword"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event"
        case .edit: return "edit_cb_event"
        case .delete: return "delete_cb_event"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventParticipantAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event_participant"
        case .edit: return "edit_cb_event_participant"
        case .delete: return "delete_cb_event_participant"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventItemAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event_item"
        case .edit: return "edit_cb_event_item"
        case .delete: return "delete_cb_event_item"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventTransactionOptionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event_transaction_option"
        case .edit: return "edit_cb_event_transaction_option"
        case .delete: return "delete_cb_event_transaction_option"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventCategoryAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event_category"
        case .edit: return "edit_cb_event_category"
        case .delete: return "delete_cb_event_category"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum EventTransactionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_event_transaction"
        case .edit: return "edit_cb_event_transaction"
        case .delete: return "delete_cb_event_transaction"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum TagAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_tag"
        case .edit: return "edit_cb_tag"
        case .delete: return "delete_cb_tag"
        }
    }
}

enum CategoryAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_category"
        case .edit: return "edit_cb_category"
        case .delete: return "delete_cb_category"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum CategoryGroupAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_category_group"
        case .edit: return "edit_cb_category_group"
        case .delete: return "delete_cb_category_group"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum LocationAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_location"
        case .edit: return "edit_cb_location"
        case .delete: return "delete_cb_location"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum BudgetAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add: return "add_cb_budget"
        case .edit: return "edit_cb_budget"
        case .delete: return "delete_cb_budget"
        }
    }
}

