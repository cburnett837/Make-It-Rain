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
    
    private init() {
        self.useWholeNumbers = false
    }
    
    var useWholeNumbers: Bool {
        didSet {
            self.sendToServer(setting: .init(settingId: 54, setting: useWholeNumbers ? "1" : "0"))
        }
    }
    //var trimTotals: Bool
    //var lowBalanceThreshold: String
    //var paymentMethodFilterMode: PaymentMethodFilterMode
    //var paymentMethodSortMode: SortMode
    //var transactionSortMode: TransactionSortMode
    //var categorySortMode: SortMode
    //var incomeColor: Color
        
    enum CodingKeys: CodingKey { case use_whole_numbers, user_id, account_id, device_uuid }

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
    }
    
    
    func setFromAnotherInstance(setting: AppSettings) {
        self.useWholeNumbers = setting.useWholeNumbers
    }
        
    func sendToServer(setting: SettingSubmitModel) {
        print("-- \(#function)")
        LogManager.log()
        Task {
            let model = RequestModel(requestType: "update_user_setting", model: setting)
            
            typealias ResultResponse = Result<ResultCompleteModel?, AppError>
            async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch await result {
            case .success(let model):
                LogManager.networkingSuccessful()

            case .failure(let error):
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to update the user setting.")
            }
        }
    }
}
