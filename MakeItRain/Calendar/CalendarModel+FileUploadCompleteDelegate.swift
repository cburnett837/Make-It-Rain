//
//  CalendarModel+FileUploadCompleteDelegate.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

extension CalendarModel: FileUploadCompletedDelegate {
    func displayCompleteAlert(recordID: String, parentType: XrefFileType, fileType: FileType) {
        var transTitle: String?
        if let trans = justTransactions.filter({ $0.id == recordID }).first {
            transTitle = trans.title
        }
        
        if !isUploadingSmartTransactionFile {
            AppState.shared.alertBasedOnScenePhase(
                title: "Picture Successfully Uploaded",
                subtitle: transTitle,
                symbol: "photo.badge.checkmark",
                symbolColor: .green,
                inAppPreference: .toast
            )
        }
    }
    
    
    func alertUploadingSmartReceiptIfApplicable() {
        if self.isUploadingSmartTransactionFile {
            AppState.shared.showToast(
                title: "Analyzing Receipt",
                subtitle: "You will be alerted when analysis is complete",
                body: "(Powered by ChatGPT)",
                symbol: "brain.fill"
            )
        }
    }
    
    
    func cleanUpPhotoVariables() {
        self.isUploadingSmartTransactionFile = false
        self.smartTransactionDate = nil
        #if os(iOS)
        FileModel.shared.imageFromCamera = nil
        #endif
    }
    
    
    private func transactionInstances(for id: String) -> [CBTransaction] {
        let transactions: [CBTransaction?] = [
            justTransactions.first(where: { $0.id == id }),
            searchedTransactions.first(where: { $0.id == id }),
            tempTransactions.first(where: { $0.id == id }),
            receiptTransactions.first(where: { $0.id == id }),
            dashboardTransactions.first(where: { $0.id == id })
        ]
        
        /// Multiple lists may contain the exact same CBTransaction instance.
        /// Deduplicate by object identity so we don't update the same instance twice.
        var seen = Set<ObjectIdentifier>()
        
        return transactions
            .compactMap { $0 }
            .filter { trans in
                seen.insert(ObjectIdentifier(trans)).inserted
            }
    }


    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
        let file = CBFile(relatedID: recordID, uuid: uuid, parentType: parentType, fileType: fileType)
        
        file.isPlaceholder = true
        
        /// Add the placeholder file to every in-memory instance of this transaction.
        for trans in transactionInstances(for: recordID) {
            if trans.files == nil {
                trans.files = []
            }
            
            trans.files?.append(file)
        }
    }


    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
        for trans in transactionInstances(for: recordID) {
            guard let file = trans.files?.first(where: { $0.uuid == uuid }) else {
                continue
            }
            
            file.isPlaceholder = false
            
            /// Indicate that the file should be itemized so that when
            /// the download completes, it can kick off the itemization task.
            if AppSettings.shared.autoItemizeReceipts {
                file.isItemizing = true
            }
        }
    }


    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
        for trans in transactionInstances(for: recordID) {
            guard let file = trans.files?.first(where: { $0.uuid == uuid }) else {
                continue
            }
            
            file.active = false
        }
    }


    func delete(file: CBFile, parentType: XrefFileType, fileType: FileType) async {
        guard await FileModel.shared.delete(file) else {
            AppState.shared.showAlert("There was a problem trying to delete the picture.")
            return
        }
        
        /// Remove the file from every in-memory instance of this transaction.
        for trans in transactionInstances(for: file.relatedID) {
            trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
        }
    }
    
    
    
    
    
//    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
//        let file = CBFile(relatedID: recordID, uuid: uuid, parentType: parentType, fileType: fileType)
//        file.isPlaceholder = true
//
//        if let index = justTransactions.firstIndex(where: { $0.id == recordID }) {
//            let trans = justTransactions[index]
//
//            if let _ = trans.files {
//                trans.files!.append(file)
//            } else {
//                trans.files = [file]
//            }
//        }
//
//        /// Update the searched transactions if they are in the search list and you update them like normal.
//        if let index = searchedTransactions.firstIndex(where: { $0.id == recordID }) {
//            let trans = searchedTransactions[index]
//
//            if let _ = trans.files {
//                trans.files!.append(file)
//            } else {
//                trans.files = [file]
//            }
//        }
//
//        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let index = tempTransactions.firstIndex(where: { $0.id == recordID }) {
//            let trans = tempTransactions[index]
//
//            if let _ = trans.files {
//                trans.files!.append(file)
//            } else {
//                trans.files = [file]
//            }
//        }
//
//        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let index = receiptTransactions.firstIndex(where: { $0.id == recordID }) {
//            let trans = receiptTransactions[index]
//
//            if let _ = trans.files {
//                trans.files!.append(file)
//            } else {
//                trans.files = [file]
//            }
//        }
//
//
//        if let index = dashboardTransactions.firstIndex(where: { $0.id == recordID }) {
//            let trans = dashboardTransactions[index]
//
//            if let _ = trans.files {
//                trans.files!.append(file)
//            } else {
//                trans.files = [file]
//            }
//        }
//
//
//
////        if let targetMonth = months.filter { $0.actualNum == date.month && $0.year == date.year }.first {
////            let targetDays = targetMonth.days
////            let transactions = targetDays.flatMap({ $0.transactions })
////
////            let index = transactions.firstIndex(where: { $0.id == recordID })
////            if let index {
////                if let _ = transactions[index].files {
////                    transactions[index].files!.append(picture)
////                } else {
////                    transactions[index].files = [picture]
////                }
////            }
////        }
//    }
//
//
//    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
////        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
////        let targetDays = targetMonth.days
////        let transactions = targetDays.flatMap({ $0.transactions })
////
////        if let trans = transactions.filter({$0.id == recordID}).first {
////            let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
////            if let index {
////                trans.files?[index].isPlaceholder = false
////            }
////        }
//
//
//        if let trans = justTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].isPlaceholder = false
//
//                /// Indicate that the file should be itemized, so that when the download completes, it will kick off the itemization task.
//                if AppSettings.shared.autoItemizeReceipts {
//                    trans.files?[index].isItemizing = true
//                }
//            }
//        }
//
//        /// Update the searched transactions if they are in the search list and you update them like normal.
//        if let trans = searchedTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].isPlaceholder = false
//
//                /// Indicate that the file should be itemized, so that when the download completes, it will kick off the itemization task.
//                if AppSettings.shared.autoItemizeReceipts {
//                    trans.files?[index].isItemizing = true
//                }
//            }
//        }
//
//        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let trans = tempTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].isPlaceholder = false
//
//                /// Indicate that the file should be itemized, so that when the download completes, it will kick off the itemization task.
//                if AppSettings.shared.autoItemizeReceipts {
//                    trans.files?[index].isItemizing = true
//                }
//            }
//        }
//
//        /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let trans = receiptTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].isPlaceholder = false
//
//                /// Indicate that the file should be itemized, so that when the download completes, it will kick off the itemization task.
//                if AppSettings.shared.autoItemizeReceipts {
//                    trans.files?[index].isItemizing = true
//                }
//            }
//        }
//
//        if let trans = dashboardTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].isPlaceholder = false
//
//                /// Indicate that the file should be itemized, so that when the download completes, it will kick off the itemization task.
//                if AppSettings.shared.autoItemizeReceipts {
//                    trans.files?[index].isItemizing = true
//                }
//            }
//        }
//    }
//
//
//    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefFileType, fileType: FileType) {
////        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
////        let targetDays = targetMonth.days
////        let transactions = targetDays.flatMap({ $0.transactions })
////
////        if let trans = transactions.filter({$0.id == recordID}).first {
////            let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
////            if let index {
////                trans.files?[index].active = false
////            }
////        }
//
//        if let trans = justTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].active = false
//            }
//        }
//
//        /// Update the searched transactions if they are in the search list and you update them like normal.
//        if let trans = searchedTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].active = false
//            }
//        }
//
//        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let trans = tempTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].active = false
//            }
//        }
//
//        /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//        if let trans = receiptTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].active = false
//            }
//        }
//
//        if let trans = dashboardTransactions.filter({ $0.id == recordID }).first {
//            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
//                trans.files?[index].active = false
//            }
//        }
//    }
//
//
//    func delete(file: CBFile, parentType: XrefFileType, fileType: FileType) async {
////        if await FileModel.shared.delete(picture) {
////            let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
////            let targetDays = targetMonth.days
////            let transactions = targetDays.flatMap({ $0.transactions })
////
////            let index = transactions.firstIndex(where: { $0.id == picture.relatedID })
////            if let index {
////                transactions[index].files?.removeAll(where: { $0.id == picture.id || $0.uuid == picture.uuid })
////            }
////        } else {
////            AppState.shared.showAlert("There was a problem trying to delete the picture.")
////        }
//
//
//
//        if await FileModel.shared.delete(file) {
//            if let trans = justTransactions.filter({ $0.id == file.relatedID }).first {
//                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
//                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
//                //}
//            }
//
//            /// Update the searched transactions if they are in the search list and you update them like normal.
//            if let trans = searchedTransactions.filter({ $0.id == file.relatedID }).first {
//                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
//                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
//                //}
//            }
//
//            /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//            if let trans = tempTransactions.filter({ $0.id == file.relatedID }).first {
//                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
//                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
//                //}
//            }
//
//            /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
//            if let trans = receiptTransactions.filter({ $0.id == file.relatedID }).first {
//                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
//                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
//                //}
//            }
//
//            if let trans = dashboardTransactions.filter({ $0.id == file.relatedID }).first {
//                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
//                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
//                //}
//            }
//
//        } else {
//            AppState.shared.showAlert("There was a problem trying to delete the picture.")
//        }
//    }
}
