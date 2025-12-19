//
//  PropertyWrappers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/18/25.
//

import Foundation
import SwiftUI


extension NSObject {
    class var className: String {
        return String(describing: self)
    }
}

class LocalKeys: NSObject {
    class Charts: NSObject {
        class Options: NSObject {
            static let showOverviewDataPerMethodOnUnified = "\(LocalKeys.className)_\(Charts.className)_\(Options.className))_showOverviewDataPerMethodOnUnifiedChart"
        }
        
        class IncomeExpense: NSObject {
            static let showExpenses = "\(LocalKeys.className)_\(Charts.className)_\(IncomeExpense.className))_showExpenses"
            static let showIncome = "\(LocalKeys.className)_\(Charts.className)_\(IncomeExpense.className))_showIncome"
            static let showStartingAmount = "\(LocalKeys.className)_\(Charts.className)_\(IncomeExpense.className))_showStartingAmount"
            static let showPayments = "\(LocalKeys.className)_\(Charts.className)_\(IncomeExpense.className))_showPayments"
        }
        
        class ProfitLoss: NSObject {
            static let metrics = "\(LocalKeys.className)_\(Charts.className)_\(ProfitLoss.className))_profitLossMetrics"
            static let style = "\(LocalKeys.className)_\(Charts.className)_\(ProfitLoss.className))_profitLossStyle"
        }
        
        class MetricByPaymentMethod: NSObject {
            static let expenses = "\(LocalKeys.className)_\(Charts.className)_\(MetricByPaymentMethod.className))_expenses"
            static let income = "\(LocalKeys.className)_\(Charts.className)_\(MetricByPaymentMethod.className))_income"
            static let startingAmount = "\(LocalKeys.className)_\(Charts.className)_\(MetricByPaymentMethod.className))_startingAmount"
            static let payments = "\(LocalKeys.className)_\(Charts.className)_\(MetricByPaymentMethod.className))_payments"
        }
        
        class CategoryAnalytics: NSObject {
            static let displayedMetric = "\(LocalKeys.className)_\(Charts.className)_\(CategoryAnalytics.className))_displayedMetric"
        }
    }
}


// MARK: - NOTE! If you want to use properties in a model, and have them be saved, you must read/write them via that model, otherwise views will not update.
    // MARK: - For example, using `@ChartOption(\.chartCropingStyle) var chartCropingStyle` in a view, and writing to the variable with the same UserDefault key via the view-model will not trigger an update in the view using the property wrapper.

@Observable
public class LocalStorage {
    public static let shared = LocalStorage()
    
    private init() { /*print("init")*/ }
    //deinit{ print("deinit") }
    
    
    // MARK: - Local Variables
    public var threshold: Double {
        get { get(\.threshold, key: "threshold", default: 500.00) }
        set { set(\.threshold, key: "threshold", new: newValue) }
    }
    
    public var colorTheme: String {
        get { get(\.colorTheme, key: "colorTheme", default: Color.blue.description) }
        set { set(\.colorTheme, key: "colorTheme", new: newValue) }
    }
    
    public var useWholeNumbers: Bool {
        get { get(\.useWholeNumbers, key: "useWholeNumbers", default: false) }
        set { set(\.useWholeNumbers, key: "useWholeNumbers", new: newValue) }
    }
    
    public var incomeColor: String {
        get { get(\.incomeColor, key: "incomeColor", default: Color.blue.description) }
        set { set(\.incomeColor, key: "incomeColor", new: newValue) }
    }
    
    public var useBusinessLogos: Bool {
        get { get(\.useBusinessLogos, key: "useBusinessLogos", default: true) }
        set { set(\.useBusinessLogos, key: "useBusinessLogos", new: newValue) }
    }
    
    //@AppStorage("lineItemIndicator") var lineItemIndicator: LineItemIndicator = .emoji
    public var lineItemIndicator: LineItemIndicator {
        get { LineItemIndicator.fromString(get(\.lineItemIndicator.rawValue, key: "lineItemIndicator", default: LineItemIndicator.dot.rawValue)) }
        set { set(\.lineItemIndicator.rawValue, key: "lineItemIndicator", new: newValue.rawValue) }
    }
    
    //@AppStorage("phoneLineItemDisplayItem") var phoneLineItemDisplayItem: PhoneLineItemDisplayItem = .both
    public var phoneLineItemDisplayItem: PhoneLineItemDisplayItem {
        get { PhoneLineItemDisplayItem.fromString(get(\.phoneLineItemDisplayItem.rawValue, key: "phoneLineItemDisplayItem", default: PhoneLineItemDisplayItem.both.rawValue)) }
        set { set(\.phoneLineItemDisplayItem.rawValue, key: "phoneLineItemDisplayItem", new: newValue.rawValue) }
    }
    
    //@AppStorage("updatedByOtherUserDisplayMode") var updatedByOtherUserDisplayMode = UpdatedByOtherUserDisplayMode.full
    public var updatedByOtherUserDisplayMode: UpdatedByOtherUserDisplayMode {
        get { UpdatedByOtherUserDisplayMode.fromString(get(\.updatedByOtherUserDisplayMode.rawValue, key: "updatedByOtherUserDisplayMode", default: UpdatedByOtherUserDisplayMode.full.rawValue)) }
        set { set(\.updatedByOtherUserDisplayMode.rawValue, key: "updatedByOtherUserDisplayMode", new: newValue.rawValue) }
    }
   
    //@AppStorage("userColorScheme") var userColorScheme: UserPreferedColorScheme = .userSystem
    public var userColorScheme: UserPreferedColorScheme {
        get { UserPreferedColorScheme.fromString(get(\.userColorScheme.rawValue, key: "userColorScheme", default: UserPreferedColorScheme.userSystem.rawValue)) }
        set { set(\.userColorScheme.rawValue, key: "userColorScheme", new: newValue.rawValue) }
    }
    
    //@AppStorage("showIndividualLoadingSpinner") var showIndividualLoadingSpinner = false
    public var showIndividualLoadingSpinner: Bool {
        get { get(\.showIndividualLoadingSpinner, key: "showIndividualLoadingSpinner", default: false) }
        set { set(\.showIndividualLoadingSpinner, key: "showIndividualLoadingSpinner", new: newValue) }
    }
    
    //@AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    public var categorySortMode: SortMode {
        get { SortMode.fromString(get(\.categorySortMode.rawValue, key: "categorySortMode", default: SortMode.title.rawValue)) }
        set { set(\.categorySortMode.rawValue, key: "categorySortMode", new: newValue.rawValue) }
    }
    
    //@AppStorage("paymentMethodSortMode") var paymentMethodSortMode: SortMode = .title
    public var paymentMethodSortMode: SortMode {
        get { SortMode.fromString(get(\.paymentMethodSortMode.rawValue, key: "paymentMethodSortMode", default: SortMode.title.rawValue)) }
        set { set(\.paymentMethodSortMode.rawValue, key: "paymentMethodSortMode", new: newValue.rawValue) }
    }
    
    //@AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    public var transactionSortMode: TransactionSortMode {
        get { TransactionSortMode.fromString(get(\.transactionSortMode.rawValue, key: "transactionSortMode", default: TransactionSortMode.title.rawValue)) }
        set { set(\.transactionSortMode.rawValue, key: "transactionSortMode", new: newValue.rawValue) }
    }
    
    //@AppStorage("tightenUpEodTotals") var tightenUpEodTotals = true
    public var tightenUpEodTotals: Bool {
        get { get(\.tightenUpEodTotals, key: "tightenUpEodTotals", default: true) }
        set { set(\.tightenUpEodTotals, key: "tightenUpEodTotals", new: newValue) }
    }
        
    //@AppStorage("debugPrint") var debugPrint = false
    public var debugPrint: Bool {
        get { get(\.debugPrint, key: "debugPrint", default: false) }
        set { set(\.debugPrint, key: "debugPrint", new: newValue) }
    }
    
    //@AppStorage("startInFullScreen") var startInFullScreen = false
    public var startInFullScreen: Bool {
        get { get(\.startInFullScreen, key: "startInFullScreen", default: false) }
        set { set(\.startInFullScreen, key: "startInFullScreen", new: newValue) }
    }
    
    //@AppStorage("alignWeekdayNamesLeft") var alignWeekdayNamesLeft = true
    public var alignWeekdayNamesLeft: Bool {
        get { get(\.alignWeekdayNamesLeft, key: "alignWeekdayNamesLeft", default: true) }
        set { set(\.alignWeekdayNamesLeft, key: "alignWeekdayNamesLeft", new: newValue) }
    }
        
    //@AppStorage("showPaymentMethodIndicator") var showPaymentMethodIndicator = false
    public var showPaymentMethodIndicator: Bool {
        get { get(\.showPaymentMethodIndicator, key: "showPaymentMethodIndicator", default: false) }
        set { set(\.showPaymentMethodIndicator, key: "showPaymentMethodIndicator", new: newValue) }
    }
    
    //@AppStorage("showHashTagsOnLineItems") var showHashTagsOnLineItems: Bool = true
    public var showHashTagsOnLineItems: Bool {
        get { get(\.showHashTagsOnLineItems, key: "showHashTagsOnLineItems", default: true) }
        set { set(\.showHashTagsOnLineItems, key: "showHashTagsOnLineItems", new: newValue) }
    }
    
    //@AppStorage("categoryIndicatorAsSymbol") var categoryIndicatorAsSymbol: Bool = true
    public var categoryIndicatorAsSymbol: Bool {
        get { get(\.categoryIndicatorAsSymbol, key: "categoryIndicatorAsSymbol", default: true) }
        set { set(\.categoryIndicatorAsSymbol, key: "categoryIndicatorAsSymbol", new: newValue) }
    }
    
    //@AppStorage("creditEodView") var creditEodView: CreditEodView = .remainingBalance
    public var creditEodView: CreditEodView {
        get { CreditEodView.fromString(get(\.creditEodView.rawValue, key: "creditEodView", default: CreditEodView.remainingBalance.rawValue)) }
        set { set(\.creditEodView.rawValue, key: "creditEodView", new: newValue.rawValue) }
    }
    
    //@AppStorage("paymentMethodSheetFilterMode") private var paymentMethodSheetFilterMode: PaymentMethodFilterMode = .justPrimary
    public var paymentMethodFilterMode: PaymentMethodFilterMode {
        get { PaymentMethodFilterMode.fromString(get(\.paymentMethodFilterMode.rawValue, key: "paymentMethodFilterMode", default: PaymentMethodFilterMode.all.rawValue)) }
        set { set(\.paymentMethodFilterMode.rawValue, key: "paymentMethodFilterMode", new: newValue.rawValue) }
    }

    
        
    
    // MARK: - Chart Variables
    public var profitLossMetrics: String {
        get { get(\.profitLossMetrics, key: "profitLossMetrics", default: "all") }
        set { set(\.profitLossMetrics, key: "profitLossMetrics", new: newValue) }
    }
    
    public var chartCropingStyle: ChartCropingStyle {
        get { ChartCropingStyle.fromString(get(\.chartCropingStyle.rawValue, key: "chartCropingStyle", default: ChartCropingStyle.showFullCurrentYear.rawValue)) }
        set { set(\.chartCropingStyle.rawValue, key: "chartCropingStyle", new: newValue.rawValue) }
    }
    
//    public var showOverviewDataPerMethodOnUnifiedChart: Bool {
//        get { get(\.showOverviewDataPerMethodOnUnifiedChart, key: "showOverviewDataPerMethodOnUnifiedChart", default: false) }
//        set { set(\.showOverviewDataPerMethodOnUnifiedChart, key: "showOverviewDataPerMethodOnUnifiedChart", new: newValue) }
//    }
//    
    
//    // MARK: - IncomeAndExpenseChartVariables
//    public var incomeAndExpenseChartShowExpenses: Bool {
//        get { get(\.incomeAndExpenseChartShowExpenses, key: "incomeAndExpenseChartShowExpenses", default: true) }
//        set { set(\.incomeAndExpenseChartShowExpenses, key: "incomeAndExpenseChartShowExpenses", new: newValue) }
//    }
//    
//    public var incomeAndExpenseChartShowIncome: Bool {
//        get { get(\.incomeAndExpenseChartShowIncome, key: "incomeAndExpenseChartShowIncome", default: true) }
//        set { set(\.incomeAndExpenseChartShowIncome, key: "incomeAndExpenseChartShowIncome", new: newValue) }
//    }
//    
//    public var incomeAndExpenseChartShowStartingAmount: Bool {
//        get { get(\.incomeAndExpenseChartShowStartingAmount, key: "incomeAndExpenseChartShowStartingAmount", default: true) }
//        set { set(\.incomeAndExpenseChartShowStartingAmount, key: "incomeAndExpenseChartShowStartingAmount", new: newValue) }
//    }
//    
//    public var incomeAndExpenseChartShowPayments: Bool {
//        get { get(\.incomeAndExpenseChartShowPayments, key: "incomeAndExpenseChartShowPayments", default: true) }
//        set { set(\.incomeAndExpenseChartShowPayments, key: "incomeAndExpenseChartShowPayments", new: newValue) }
//    }
//    
    
    
    // MARK: - Helper Functions
    func get<T: Decodable>(_ keyPath: KeyPath<LocalStorage, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        }
        return defaultValue
    }
    
    func set<T: Encodable>(_ keyPath: KeyPath<LocalStorage, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}







// MARK: - Local Variables
//public protocol LocalVariables: AnyObject {
//    var threshold: Double { get set }
//    var colorTheme: String { get set }
//    var useWholeNumbers: Bool { get set }
//    var incomeColor: String { get set }
//}
//
//@propertyWrapper
//public struct Local<T>: DynamicProperty {
//    private var defaults: LocalVariables = LocalStorage.shared
//    private let keyPath: ReferenceWritableKeyPath<LocalVariables, T>
//    
//    public init(_ keyPath: ReferenceWritableKeyPath<LocalVariables, T>) {
//        self.keyPath = keyPath
//    }
//
//    public var wrappedValue: T {
//        get { defaults[keyPath: keyPath] }
//        nonmutating set { defaults[keyPath: keyPath] = newValue }
//    }
//
//    public var projectedValue: Binding<T> {
//        Binding(
//            get: { defaults[keyPath: keyPath] },
//            set: { defaults[keyPath: keyPath] = $0 }
//        )
//    }
//}


@propertyWrapper
public struct Local<T>: DynamicProperty {
    private var defaults: LocalStorage = LocalStorage.shared
    private let keyPath: ReferenceWritableKeyPath<LocalStorage, T>
    
    public init(_ keyPath: ReferenceWritableKeyPath<LocalStorage, T>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: T {
        get { defaults[keyPath: keyPath] }
        nonmutating set { defaults[keyPath: keyPath] = newValue }
    }

    public var projectedValue: Binding<T> {
        Binding(
            get: { defaults[keyPath: keyPath] },
            set: { defaults[keyPath: keyPath] = $0 }
        )
    }
}





//
//
//
//// MARK: - IncomeAndExpenseChartVariables
public protocol IncomeAndExpenseChartVariables: AnyObject {
    var showExpenses: Bool { get set }
    var showIncome: Bool { get set }
    var showStartingAmount: Bool { get set }
    var showPayments: Bool { get set }
}

extension LocalStorage: IncomeAndExpenseChartVariables {
    public var showExpenses: Bool {
        get { get(\.showExpenses, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showExpenses", default: true) }
        set { set(\.showExpenses, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showExpenses", new: newValue) }
    }
    
    public var showIncome: Bool {
        get { get(\.showIncome, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showIncome", default: true) }
        set { set(\.showIncome, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showIncome", new: newValue) }
    }
    
    public var showStartingAmount: Bool {
        get { get(\.showStartingAmount, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showStartingAmount", default: true) }
        set { set(\.showStartingAmount, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showStartingAmount", new: newValue) }
    }
    
    public var showPayments: Bool {
        get { get(\.showPayments, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showPayments", default: true) }
        set { set(\.showPayments, key: "\(String(describing: IncomeAndExpenseChartVariables.self))showPayments", new: newValue) }
    }
}

@propertyWrapper
public struct ChartOptionIncomeAndExpense<T>: DynamicProperty {
    private var defaults: IncomeAndExpenseChartVariables = LocalStorage.shared
    private let keyPath: ReferenceWritableKeyPath<IncomeAndExpenseChartVariables, T>
    
    public init(_ keyPath: ReferenceWritableKeyPath<IncomeAndExpenseChartVariables, T>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: T {
        get { defaults[keyPath: keyPath] }
        nonmutating set { defaults[keyPath: keyPath] = newValue }
    }

    public var projectedValue: Binding<T> {
        Binding(
            get: { defaults[keyPath: keyPath] },
            set: { defaults[keyPath: keyPath] = $0 }
        )
    }
}






// MARK: - ProfitLossChartVariables
//public protocol ProfitLossChartVariables: AnyObject {
//    var showExpenses: Bool { get set }
//    var showIncome: Bool { get set }
//    var showStartingAmount: Bool { get set }
//    var showPayments: Bool { get set }
//}
//
//extension LocalStorage: ProfitLossChartVariables {
//    public var profitLossStyle: Bool {
//        get { get(\.showExpenses, key: "\(String(describing: ProfitLossChartVariables.self))showExpenses", default: true) }
//        set { set(\.showExpenses, key: "\(String(describing: ProfitLossChartVariables.self))showExpenses", new: newValue) }
//    }
//    
//    public var profitLossMetricsMenu: Bool {
//        get { get(\.showIncome, key: "\(String(describing: ProfitLossChartVariables.self))showIncome", default: true) }
//        set { set(\.showIncome, key: "\(String(describing: ProfitLossChartVariables.self))showIncome", new: newValue) }
//    }
//    
//}
//
//@propertyWrapper
//public struct ChartOptionProfitLoss<T>: DynamicProperty {
//    private var defaults: ProfitLossChartVariables = LocalStorage.shared
//    private let keyPath: ReferenceWritableKeyPath<ProfitLossChartVariables, T>
//    
//    public init(_ keyPath: ReferenceWritableKeyPath<ProfitLossChartVariables, T>) {
//        self.keyPath = keyPath
//    }
//
//    public var wrappedValue: T {
//        get { defaults[keyPath: keyPath] }
//        nonmutating set { defaults[keyPath: keyPath] = newValue }
//    }
//
//    public var projectedValue: Binding<T> {
//        Binding(
//            get: { defaults[keyPath: keyPath] },
//            set: { defaults[keyPath: keyPath] = $0 }
//        )
//    }
//}
//
//















// MARK: - Chart Variables
//public protocol ChartVariables: AnyObject {
//    var profitLossMetrics: String { get set }
//    var chartCropingStyle: ChartCropingStyle { get set }
//    var showOverviewDataPerMethodOnUnifiedChart: Bool { get set }
//}
//
//@propertyWrapper
//public struct ChartOption<T>: DynamicProperty {
//    private var defaults: ChartVariables = LocalStorage.shared
//    private let keyPath: ReferenceWritableKeyPath<ChartVariables, T>
//    
//    public init(_ keyPath: ReferenceWritableKeyPath<ChartVariables, T>) {
//        self.keyPath = keyPath
//    }
//
//    public var wrappedValue: T {
//        get { defaults[keyPath: keyPath] }
//        nonmutating set { defaults[keyPath: keyPath] = newValue }
//    }
//
//    public var projectedValue: Binding<T> {
//        Binding(
//            get: { defaults[keyPath: keyPath] },
//            set: { defaults[keyPath: keyPath] = $0 }
//        )
//    }
//}
