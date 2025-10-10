//
//  CBRepeatingTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/1/24.
//


import Foundation
import UniformTypeIdentifiers
import SwiftUI


enum RepeatingTransactionType: String, CaseIterable {
    case regular
    case transfer
    case payment
}

@Observable
class CBRepeatingTransaction: Codable, Identifiable, Hashable, Equatable, Transferable, CanEditAmount {
    var id: String
    var uuid: String?
    var title: String
    var amount: Double {
        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var amountString: String
    var amountTypeLingo: String {
        if payMethod?.accountType == .credit || payMethod?.accountType == .loan {
            amountString.contains("-") ? "Payment" : "Expense"
        } else {
            amountString.contains("-") ? "Expense" : "Income"
        }
    }
    
    var color: Color
    var payMethod: CBPaymentMethod?
    var payMethodPayTo: CBPaymentMethod?
    var category: CBCategory?
    var when: Array<CBRepeatingTransactionWhen>
    var active: Bool
    var action: RepeatingTransactionAction
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    var repeatingTransactionType: XrefItem = XrefModel.getItem(from: .repeatingTransactionType, byEnumID: .regular)

    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""
        self.color = .primary
        self.payMethod = nil
        self.payMethodPayTo = nil
        self.category = nil
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.when = [
            CBRepeatingTransactionWhen(when: "sunday", displayTitle: "Sun", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "monday", displayTitle: "Mon", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "tuesday", displayTitle: "Tue", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "wednesday", displayTitle: "Wed", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "thursday", displayTitle: "Thu", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "friday", displayTitle: "Fri", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "saturday", displayTitle: "Sat", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "january", displayTitle: "Jan", whenType: .month),
            CBRepeatingTransactionWhen(when: "february", displayTitle: "Feb", whenType: .month),
            CBRepeatingTransactionWhen(when: "march", displayTitle: "Mar", whenType: .month),
            CBRepeatingTransactionWhen(when: "april", displayTitle: "Apr", whenType: .month),
            CBRepeatingTransactionWhen(when: "may", displayTitle: "May", whenType: .month),
            CBRepeatingTransactionWhen(when: "june", displayTitle: "Jun", whenType: .month),
            CBRepeatingTransactionWhen(when: "july", displayTitle: "Jul", whenType: .month),
            CBRepeatingTransactionWhen(when: "august", displayTitle: "Aug", whenType: .month),
            CBRepeatingTransactionWhen(when: "september", displayTitle: "Sep", whenType: .month),
            CBRepeatingTransactionWhen(when: "october", displayTitle: "Oct", whenType: .month),
            CBRepeatingTransactionWhen(when: "november", displayTitle: "Nov", whenType: .month),
            CBRepeatingTransactionWhen(when: "december", displayTitle: "Dec", whenType: .month),
            CBRepeatingTransactionWhen(when: "day1", displayTitle: "1", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day2", displayTitle: "2", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day3", displayTitle: "3", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day4", displayTitle: "4", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day5", displayTitle: "5", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day6", displayTitle: "6", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day7", displayTitle: "7", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day8", displayTitle: "8", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day9", displayTitle: "9", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day10", displayTitle: "10", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day11", displayTitle: "11", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day12", displayTitle: "12", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day13", displayTitle: "13", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day14", displayTitle: "14", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day15", displayTitle: "15", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day16", displayTitle: "16", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day17", displayTitle: "17", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day18", displayTitle: "18", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day19", displayTitle: "19", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day20", displayTitle: "20", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day21", displayTitle: "21", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day22", displayTitle: "22", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day23", displayTitle: "23", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day24", displayTitle: "24", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day25", displayTitle: "25", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day26", displayTitle: "26", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day27", displayTitle: "27", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day28", displayTitle: "28", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day29", displayTitle: "29", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day30", displayTitle: "30", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day31", displayTitle: "31", whenType: .dayOfMonth)
        ]
    }
    
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.amountString = ""        
        self.color = .primary
        self.payMethod = nil
        self.payMethodPayTo = nil
        self.category = nil
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
        self.when = [
            CBRepeatingTransactionWhen(when: "sunday", displayTitle: "Sun", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "monday", displayTitle: "Mon", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "tuesday", displayTitle: "Tue", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "wednesday", displayTitle: "Wed", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "thursday", displayTitle: "Thu", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "friday", displayTitle: "Fri", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "saturday", displayTitle: "Sat", whenType: .weekday),
            CBRepeatingTransactionWhen(when: "january", displayTitle: "Jan", whenType: .month),
            CBRepeatingTransactionWhen(when: "february", displayTitle: "Feb", whenType: .month),
            CBRepeatingTransactionWhen(when: "march", displayTitle: "Mar", whenType: .month),
            CBRepeatingTransactionWhen(when: "april", displayTitle: "Apr", whenType: .month),
            CBRepeatingTransactionWhen(when: "may", displayTitle: "May", whenType: .month),
            CBRepeatingTransactionWhen(when: "june", displayTitle: "Jun", whenType: .month),
            CBRepeatingTransactionWhen(when: "july", displayTitle: "Jul", whenType: .month),
            CBRepeatingTransactionWhen(when: "august", displayTitle: "Aug", whenType: .month),
            CBRepeatingTransactionWhen(when: "september", displayTitle: "Sep", whenType: .month),
            CBRepeatingTransactionWhen(when: "october", displayTitle: "Oct", whenType: .month),
            CBRepeatingTransactionWhen(when: "november", displayTitle: "Nov", whenType: .month),
            CBRepeatingTransactionWhen(when: "december", displayTitle: "Dec", whenType: .month),
            CBRepeatingTransactionWhen(when: "day1", displayTitle: "1", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day2", displayTitle: "2", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day3", displayTitle: "3", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day4", displayTitle: "4", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day5", displayTitle: "5", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day6", displayTitle: "6", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day7", displayTitle: "7", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day8", displayTitle: "8", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day9", displayTitle: "9", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day10", displayTitle: "10", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day11", displayTitle: "11", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day12", displayTitle: "12", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day13", displayTitle: "13", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day14", displayTitle: "14", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day15", displayTitle: "15", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day16", displayTitle: "16", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day17", displayTitle: "17", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day18", displayTitle: "18", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day19", displayTitle: "19", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day20", displayTitle: "20", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day21", displayTitle: "21", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day22", displayTitle: "22", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day23", displayTitle: "23", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day24", displayTitle: "24", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day25", displayTitle: "25", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day26", displayTitle: "26", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day27", displayTitle: "27", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day28", displayTitle: "28", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day29", displayTitle: "29", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day30", displayTitle: "30", whenType: .dayOfMonth),
            CBRepeatingTransactionWhen(when: "day31", displayTitle: "31", whenType: .dayOfMonth)
        ]
    }
        
    enum CodingKeys: CodingKey { case id, uuid, title, amount, title_hex_code, payment_method, payment_method_pay_to, category, active, user_id, account_id, device_uuid, when, sunday, monday, tuesday, wednesday, thursday, friday, saturday, january, february, march, april, may, june, july, august, september, october, november, december, day1, day2, day3, day4, day5, day6, day7, day8, day9, day10, day11, day12, day13, day14, day15, day16, day17, day18, day19, day20, day21, day22, day23, day24, day25, day26, day27, day28, day29, day30, day31, entered_by, updated_by, entered_date, updated_date, repeating_transaction_type_id }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(color.toHex(), forKey: .title_hex_code)
        //try container.encode(color.description, forKey: .title_hex_code)
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(payMethodPayTo, forKey: .payment_method_pay_to)
        try container.encode(category, forKey: .category)
        
        try container.encode(when.filter { $0.when == "sunday" }.first!.active, forKey: .sunday)
        try container.encode(when.filter { $0.when == "monday" }.first!.active, forKey: .monday)
        try container.encode(when.filter { $0.when == "tuesday" }.first!.active, forKey: .tuesday)
        try container.encode(when.filter { $0.when == "wednesday" }.first!.active, forKey: .wednesday)
        try container.encode(when.filter { $0.when == "thursday" }.first!.active, forKey: .thursday)
        try container.encode(when.filter { $0.when == "friday" }.first!.active, forKey: .friday)
        try container.encode(when.filter { $0.when == "saturday" }.first!.active, forKey: .saturday)
        try container.encode(when.filter { $0.when == "january" }.first!.active, forKey: .january)
        try container.encode(when.filter { $0.when == "february" }.first!.active, forKey: .february)
        try container.encode(when.filter { $0.when == "march" }.first!.active, forKey: .march)
        try container.encode(when.filter { $0.when == "april" }.first!.active, forKey: .april)
        try container.encode(when.filter { $0.when == "may" }.first!.active, forKey: .may)
        try container.encode(when.filter { $0.when == "june" }.first!.active, forKey: .june)
        try container.encode(when.filter { $0.when == "july" }.first!.active, forKey: .july)
        try container.encode(when.filter { $0.when == "august" }.first!.active, forKey: .august)
        try container.encode(when.filter { $0.when == "september" }.first!.active, forKey: .september)
        try container.encode(when.filter { $0.when == "october" }.first!.active, forKey: .october)
        try container.encode(when.filter { $0.when == "november" }.first!.active, forKey: .november)
        try container.encode(when.filter { $0.when == "december" }.first!.active, forKey: .december)
        try container.encode(when.filter { $0.when == "day1" }.first!.active, forKey: .day1)
        try container.encode(when.filter { $0.when == "day2" }.first!.active, forKey: .day2)
        try container.encode(when.filter { $0.when == "day3" }.first!.active, forKey: .day3)
        try container.encode(when.filter { $0.when == "day4" }.first!.active, forKey: .day4)
        try container.encode(when.filter { $0.when == "day5" }.first!.active, forKey: .day5)
        try container.encode(when.filter { $0.when == "day6" }.first!.active, forKey: .day6)
        try container.encode(when.filter { $0.when == "day7" }.first!.active, forKey: .day7)
        try container.encode(when.filter { $0.when == "day8" }.first!.active, forKey: .day8)
        try container.encode(when.filter { $0.when == "day9" }.first!.active, forKey: .day9)
        try container.encode(when.filter { $0.when == "day10" }.first!.active, forKey: .day10)
        try container.encode(when.filter { $0.when == "day11" }.first!.active, forKey: .day11)
        try container.encode(when.filter { $0.when == "day12" }.first!.active, forKey: .day12)
        try container.encode(when.filter { $0.when == "day13" }.first!.active, forKey: .day13)
        try container.encode(when.filter { $0.when == "day14" }.first!.active, forKey: .day14)
        try container.encode(when.filter { $0.when == "day15" }.first!.active, forKey: .day15)
        try container.encode(when.filter { $0.when == "day16" }.first!.active, forKey: .day16)
        try container.encode(when.filter { $0.when == "day17" }.first!.active, forKey: .day17)
        try container.encode(when.filter { $0.when == "day18" }.first!.active, forKey: .day18)
        try container.encode(when.filter { $0.when == "day19" }.first!.active, forKey: .day19)
        try container.encode(when.filter { $0.when == "day20" }.first!.active, forKey: .day20)
        try container.encode(when.filter { $0.when == "day21" }.first!.active, forKey: .day21)
        try container.encode(when.filter { $0.when == "day22" }.first!.active, forKey: .day22)
        try container.encode(when.filter { $0.when == "day23" }.first!.active, forKey: .day23)
        try container.encode(when.filter { $0.when == "day24" }.first!.active, forKey: .day24)
        try container.encode(when.filter { $0.when == "day25" }.first!.active, forKey: .day25)
        try container.encode(when.filter { $0.when == "day26" }.first!.active, forKey: .day26)
        try container.encode(when.filter { $0.when == "day27" }.first!.active, forKey: .day27)
        try container.encode(when.filter { $0.when == "day28" }.first!.active, forKey: .day28)
        try container.encode(when.filter { $0.when == "day29" }.first!.active, forKey: .day29)
        try container.encode(when.filter { $0.when == "day30" }.first!.active, forKey: .day30)
        try container.encode(when.filter { $0.when == "day31" }.first!.active, forKey: .day31)
        
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        
        try container.encode(repeatingTransactionType.id, forKey: .repeating_transaction_type_id)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try String(container.decode(Int.self, forKey: .id))
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
        self.payMethodPayTo = try container.decode(CBPaymentMethod?.self, forKey: .payment_method_pay_to)
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        self.when = try container.decode(Array<CBRepeatingTransactionWhen>.self, forKey: .when)
                
        let hexCode = try container.decode(String?.self, forKey: .title_hex_code)
        //#if os(iOS)
        let color = Color.fromHex(hexCode) ?? .primary
        
        if color == .white || color == .black {
            self.color = .primary
        } else {
            self.color = color
        }
        
        //#else
        //self.color = .white
        //#endif

        //let colorDescription = try container.decode(String?.self, forKey: .title_hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
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
        
        
        let repeatingTransactionTypeID = try container.decode(Int?.self, forKey: .repeating_transaction_type_id)
        if let repeatingTransactionTypeID = repeatingTransactionTypeID {
            self.repeatingTransactionType = XrefModel.getItem(from: .repeatingTransactionType, byID: repeatingTransactionTypeID)
        }
        
    }
    
    
    static var empty: CBRepeatingTransaction {
        CBRepeatingTransaction()
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amount == deepCopy.amount
            && self.color == deepCopy.color
            && self.payMethod?.id == deepCopy.payMethod?.id
            && self.payMethodPayTo?.id == deepCopy.payMethodPayTo?.id
            && self.category?.id == deepCopy.category?.id
            && self.repeatingTransactionType == deepCopy.repeatingTransactionType
            && self.when == deepCopy.when {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBRepeatingTransaction?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBRepeatingTransaction.empty
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.color = self.color
            copy.payMethod = self.payMethod
            copy.payMethodPayTo = self.payMethodPayTo
            copy.category = self.category
            copy.repeatingTransactionType = self.repeatingTransactionType
            copy.when = self.when.map {
                $0.deepCopy(.create)
                return $0.deepCopy!
            }
            copy.active = self.active
            //copy.action = self.action
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.color = deepCopy.color
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
                self.payMethodPayTo = deepCopy.payMethodPayTo
                self.category = deepCopy.category
                self.when = deepCopy.when
                self.active = deepCopy.active
                self.repeatingTransactionType = deepCopy.repeatingTransactionType
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    func setFromAnotherInstance(repTransaction: CBRepeatingTransaction) {
        self.title = repTransaction.title
        self.color = repTransaction.color        
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = repTransaction.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.payMethod = repTransaction.payMethod
        self.payMethodPayTo = repTransaction.payMethodPayTo
        self.category = repTransaction.category
        self.when = repTransaction.when
        self.active = repTransaction.active
        self.repeatingTransactionType = repTransaction.repeatingTransactionType
        self.enteredBy = repTransaction.enteredBy
        self.updatedBy = repTransaction.updatedBy
    }
    
    
    static func == (lhs: CBRepeatingTransaction, rhs: CBRepeatingTransaction) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.amount == rhs.amount
        && lhs.color == rhs.color
        && lhs.payMethod?.id == rhs.payMethod?.id
        && lhs.payMethodPayTo?.id == rhs.payMethodPayTo?.id
        && lhs.category?.id == rhs.category?.id
        && lhs.repeatingTransactionType == rhs.repeatingTransactionType
        && lhs.when == rhs.when {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .transaction)
    }
}









@Observable
class CBRepeatingTransactionWhen: Identifiable, Decodable, Hashable, Equatable {
    var id = UUID()
    var displayTitle: String
    var when: String
    var whenType: WhenType
    var active: Bool = false
    
    
    var monthNum: Int? {
        if whenType == .month {
            switch when {
            case "january":
                return 1
            case "february":
                return 2
            case "march":
                return 3
            case "april":
                return 4
            case "may":
                return 5
            case "june":
                return 6
            case "july":
                return 7
            case "august":
                return 8
            case "september":
                return 9
            case "october":
                return 10
            case "november":
                return 11
            case "december":
                return 12
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    init(when: String, displayTitle: String, whenType: WhenType) {
        self.when = when
        self.displayTitle = displayTitle
        self.whenType = whenType
    }
    
    enum CodingKeys: CodingKey { case when, when_type, display_title, active }
                   
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.when = try container.decode(String.self, forKey: .when)
        self.displayTitle = try container.decode(String.self, forKey: .display_title)
        
        let whenType = try container.decode(String.self, forKey: .when_type)
        self.whenType = WhenType(rawValue: whenType)!
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1
    }
    
    
    static func == (lhs: CBRepeatingTransactionWhen, rhs: CBRepeatingTransactionWhen) -> Bool {
        if lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var empty: CBRepeatingTransactionWhen {
        CBRepeatingTransactionWhen(when: "", displayTitle: "", whenType: .specificDate)
    }
    
    var deepCopy: CBRepeatingTransactionWhen?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBRepeatingTransactionWhen.empty
            copy.when = self.when
            copy.displayTitle = self.displayTitle
            copy.whenType = self.whenType
            copy.active = self.active
            self.deepCopy = copy
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.when = deepCopy.when
                self.displayTitle = deepCopy.displayTitle
                self.whenType = deepCopy.whenType
                self.active = deepCopy.active
            }
        case .clear:
            break
        }
    }
}
