//
//  Protocls.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/15/25.
//

import Foundation
import SwiftUI

protocol CanHandleLogo: AnyObject {
    var logo: Data? {get set}
    var id: String {get}
    var color: Color {get set}
    var logoParentType: XrefItem {get}
}

protocol CanUpdateTitleColor: AnyObject {
    var logo: Data? {get set}
    var id: String {get}
    var color: Color {get set}
    var logoParentType: XrefItem {get}
}


protocol CanHandleUserAvatar: AnyObject {
    var avatar: Data? {get set}
    var id: Int {get}
}

protocol CanEditTitleWithLocation: AnyObject, CanHandleLocationsDelegate {
    var title: String {get set}
    var id: String {get}
    var locations: Array<CBLocation> {get set}
    var factorInCalculations: Bool {get set}
}
/// To make the protocol variables optional.
extension CanEditTitleWithLocation {
    var factorInCalculations: Bool { get { return true } set {} }
}

protocol CanEditAmount: AnyObject {
    var amount: Double {get}
    var amountString: String {get set}
    var id: String {get}
    
    var amountTypeLingo: String {get}
}

protocol CanHandleLocationsDelegate {
    var title: String {get set}
    func setTitle(_ text: String)
    var locations: Array<CBLocation> {get set}
    func upsert(_ location: CBLocation)
    func deleteLocation(id: String)
}

@MainActor protocol FileUploadCompletedDelegate {
    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType)
    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType)
    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType)
    func displayCompleteAlert(recordID: String, parentType: XrefItem, fileType: FileType)
    func cleanUpPhotoVariables()
    func delete(file: CBFile, parentType: XrefItem, fileType: FileType) async
    
    /// These are all optional.
    var smartTransactionDate: Date? {get set}
    var isUploadingSmartTransactionFile: Bool {get set}
    func alertUploadingSmartReceiptIfApplicable()
}
/// To make the protocol variables optional.
extension FileUploadCompletedDelegate {
    var smartTransactionDate: Date? { get { return nil } set {} }
    var isUploadingSmartTransactionFile: Bool { get { return false } set {} }
    func alertUploadingSmartReceiptIfApplicable() {}
    func cleanUpPhotoVariables() {}
}
