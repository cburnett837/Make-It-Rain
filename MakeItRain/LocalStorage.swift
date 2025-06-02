//
//  PropertyWrappers.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/18/25.
//

import Foundation
import SwiftUI


// MARK: - NOTE! If you want to use properties in a model, and have them be saved, you must ready/write them via that model, otherwise views will not update.
    // MARK: - For example, using `@ChartOption(\.chartCropingStyle) var chartCropingStyle` in a view, and writing to the variable with the same UserDefault key via the model will not trigger an update in the view using the property wrapper.

@Observable
public class LocalStorage: ChartVariables, LocalVariables {
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
        
    
    // MARK: - Chart Variables
    public var profitLossMetrics: String {
        get { get(\.profitLossMetrics, key: "profitLossMetrics", default: "all") }
        set { set(\.profitLossMetrics, key: "profitLossMetrics", new: newValue) }
    }
    
    public var chartCropingStyle: ChartCropingStyle {
        get { ChartCropingStyle.fromString(get(\.chartCropingStyle.rawValue, key: "chartCropingStyle", default: ChartCropingStyle.showFullCurrentYear.rawValue)) }
        set { set(\.chartCropingStyle.rawValue, key: "chartCropingStyle", new: newValue.rawValue) }
    }
    
    public var showOverviewDataPerMethodOnUnifiedChart: Bool {
        get { get(\.showOverviewDataPerMethodOnUnifiedChart, key: "showOverviewDataPerMethodOnUnifiedChart", default: false) }
        set { set(\.showOverviewDataPerMethodOnUnifiedChart, key: "showOverviewDataPerMethodOnUnifiedChart", new: newValue) }
    }
    
    
    // MARK: - Helper Functions
    private func get<T: Decodable>(_ keyPath: KeyPath<LocalStorage, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        }
        return defaultValue
    }
    
    private func set<T: Encodable>(_ keyPath: KeyPath<LocalStorage, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}



// MARK: - Local Variables
public protocol LocalVariables: AnyObject {
    var threshold: Double { get set }
    var colorTheme: String { get set }
    var useWholeNumbers: Bool { get set }
    var incomeColor: String { get set }
}

@propertyWrapper
public struct Local<T>: DynamicProperty {
    private var defaults: LocalVariables = LocalStorage.shared
    private let keyPath: ReferenceWritableKeyPath<LocalVariables, T>
    
    public init(_ keyPath: ReferenceWritableKeyPath<LocalVariables, T>) {
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



// MARK: - Chart Variables
public protocol ChartVariables: AnyObject {
    var profitLossMetrics: String { get set }
    var chartCropingStyle: ChartCropingStyle { get set }
    var showOverviewDataPerMethodOnUnifiedChart: Bool { get set }
}

@propertyWrapper
public struct ChartOption<T>: DynamicProperty {
    private var defaults: ChartVariables = LocalStorage.shared
    private let keyPath: ReferenceWritableKeyPath<ChartVariables, T>
    
    public init(_ keyPath: ReferenceWritableKeyPath<ChartVariables, T>) {
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






// MARK: - Income And Expense Chart Variables
@propertyWrapper
public struct IncomeAndExpenseChartOption<T>: DynamicProperty {
    private var defaults: IncomeAndExpenseChartStorage = IncomeAndExpenseChartStorage.shared
    private let keyPath: ReferenceWritableKeyPath<IncomeAndExpenseChartStorage, T>
    
    public init(_ keyPath: ReferenceWritableKeyPath<IncomeAndExpenseChartStorage, T>) {
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

@Observable
public class IncomeAndExpenseChartStorage {
    public static let shared = IncomeAndExpenseChartStorage()
    
    private init() { /*print("init")*/ }
    //deinit{ print("deinit") }
    var prefix = "IncomeAndExpenseChartStorage_"
    
    public var showExpenses: Bool {
        get { get(\.showExpenses, key: "\(prefix)showExpenses", default: true) }
        set { set(\.showExpenses, key: "\(prefix)showExpenses", new: newValue) }
    }
    
    public var showIncome: Bool {
        get { get(\.showIncome, key: "\(prefix)showIncome", default: true) }
        set { set(\.showIncome, key: "\(prefix)showIncome", new: newValue) }
    }
    
    public var showStartingAmount: Bool {
        get { get(\.showStartingAmount, key: "\(prefix)showStartingAmount", default: true) }
        set { set(\.showStartingAmount, key: "\(prefix)showStartingAmount", new: newValue) }
    }
    
    public var showPayments: Bool {
        get { get(\.showPayments, key: "\(prefix)showPayments", default: true) }
        set { set(\.showPayments, key: "\(prefix)showPayments", new: newValue) }
    }
    
    
    private func get<T: Decodable>(_ keyPath: KeyPath<IncomeAndExpenseChartStorage, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        }
        return defaultValue
    }
    
    private func set<T: Encodable>(_ keyPath: KeyPath<IncomeAndExpenseChartStorage, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}



