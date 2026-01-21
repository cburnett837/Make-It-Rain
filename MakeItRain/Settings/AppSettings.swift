//
//  SettingsModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/30/25.
//

import Foundation
import SwiftUI


struct SettingSubmitModel: Codable {
    var settingId: Int
    var setting: String
    
    init(settingId: Int, setting: String) {
        self.settingId = settingId
        self.setting = setting
    }
    
    enum CodingKeys: CodingKey { case setting_id, setting, user_id, account_id, device_uuid }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settingId, forKey: .setting_id)
        try container.encode(setting, forKey: .setting)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.settingId = try container.decode(Int.self, forKey: .setting_id)
        self.setting = try container.decode(String.self, forKey: .setting)
    }
}

@Observable
class AppSettings: Codable {
    static let shared = AppSettings()
    
    var useWholeNumbers: Bool
    var tightenUpEodTotals: Bool
    var lowBalanceThreshold: Double
    var paymentMethodFilterMode: PaymentMethodFilterMode
    var paymentMethodSortMode: SortMode
    var transactionSortMode: TransactionSortMode
    var categorySortMode: SortMode
    var incomeColor: Color
    
    private init() {
        self.useWholeNumbers = false
        self.tightenUpEodTotals = false
        self.lowBalanceThreshold = 500
        self.paymentMethodFilterMode = .all
        self.paymentMethodSortMode = .title
        self.transactionSortMode = .title
        self.categorySortMode = .title
        self.incomeColor = .blue
    }
        
    enum CodingKeys: CodingKey { case use_whole_numbers, tighten_up_eod_totals, low_balance_threshold, payment_method_filter_mode, payment_method_sort_mode, transaction_sort_mode, category_sort_mode, income_color, user_id, account_id, device_uuid }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(useWholeNumbers, forKey: .use_whole_numbers)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let useWholeNumbers = try container.decode(String.self, forKey: .use_whole_numbers)
        self.useWholeNumbers = useWholeNumbers == "1"
                
        let tightenUpEodTotals = try container.decode(String.self, forKey: .tighten_up_eod_totals)
        self.tightenUpEodTotals = tightenUpEodTotals == "1"
        
        let lowBalanceThreshold = try container.decode(String.self, forKey: .low_balance_threshold)
        self.lowBalanceThreshold = Double(lowBalanceThreshold) ?? 0.0
        
        let paymentMethodFilterMode = try container.decode(String.self, forKey: .payment_method_filter_mode)
        self.paymentMethodFilterMode = PaymentMethodFilterMode.fromString(paymentMethodFilterMode)
        
        let paymentMethodSortMode = try container.decode(String.self, forKey: .payment_method_sort_mode)
        self.paymentMethodSortMode = SortMode.fromString(paymentMethodSortMode)
        
        let transactionSortMode = try container.decode(String.self, forKey: .transaction_sort_mode)
        self.transactionSortMode = TransactionSortMode.fromString(transactionSortMode)
        
        let categorySortMode = try container.decode(String.self, forKey: .category_sort_mode)
        self.categorySortMode = SortMode.fromString(categorySortMode)
        
        let incomeColor = try container.decode(String.self, forKey: .income_color)
        self.incomeColor = Color.fromName(incomeColor)
    }
    
    
    func setFromAnotherInstance(setting: AppSettings) {
        self.useWholeNumbers = setting.useWholeNumbers
        self.tightenUpEodTotals = setting.tightenUpEodTotals
        self.lowBalanceThreshold = setting.lowBalanceThreshold
        self.paymentMethodFilterMode = setting.paymentMethodFilterMode
        self.paymentMethodSortMode = setting.paymentMethodSortMode
        self.transactionSortMode = setting.transactionSortMode
        self.categorySortMode = setting.categorySortMode
        self.incomeColor = setting.incomeColor
    }
    
    
    func fetch() async {
        let model = RequestModel(requestType: "fetch_user_settings", model: AppState.shared.user)
        
        typealias ResultResponse = Result<AppSettings?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            if let model {
                self.setFromAnotherInstance(setting: model)
            }
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to update the user setting.")
        }
    }
        
    
    func sendToServer(setting: SettingSubmitModel) {
        print("-- \(#function)")
        LogManager.log()
        Task {
            let model = RequestModel(requestType: "update_user_setting", model: setting)
            
            typealias ResultResponse = Result<ResultCompleteModel?, AppError>
            async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch await result {
            case .success:
                LogManager.networkingSuccessful()

            case .failure(let error):
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to update the setting.")
            }
        }
    }
}
