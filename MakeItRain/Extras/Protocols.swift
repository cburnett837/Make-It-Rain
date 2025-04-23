//
//  Protocls.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/15/25.
//

import Foundation

protocol CanEditTitleWithLocation: AnyObject, CanHandleLocationsDelegate {
    var title: String {get set}
    var id: String {get set}
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
    var id: String {get set}
    
    var amountTypeLingo: String {get}
}



protocol CanHandleLocationsDelegate {
    var locations: Array<CBLocation> {get set}
    func upsert(_ location: CBLocation)
    func deleteLocation(id: String)
}


@MainActor protocol PhotoUploadCompletedDelegate {
    func addPlaceholderPicture(recordID: String, uuid: String, photoType: XrefItem)
    func markPlaceholderPictureAsReadyForDownload(recordID: String, uuid: String, photoType: XrefItem)
    func markPictureAsFailedToUpload(recordID: String, uuid: String, photoType: XrefItem)
    func displayCompleteAlert(recordID: String, photoType: XrefItem)
    func cleanUpPhotoVariables()
    func delete(picture: CBPicture, photoType: XrefItem) async
    
    /// These are all optional.
    var smartTransactionDate: Date? {get set}
    var isUploadingSmartTransactionPicture: Bool {get set}
    func alertUploadingSmartReceiptIfApplicable()
}
/// To make the protocol variables optional.
extension PhotoUploadCompletedDelegate {
    var smartTransactionDate: Date? { get { return nil } set {} }
    var isUploadingSmartTransactionPicture: Bool { get { return false } set {} }
    func alertUploadingSmartReceiptIfApplicable() {}
    func cleanUpPhotoVariables() {}
}
