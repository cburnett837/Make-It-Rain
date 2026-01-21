//
//  ContactManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/19/26.
//

import Foundation
import Contacts
import OSLog

@MainActor
@Observable
final class ContactStoreManager {
    /// Contains fetched contacts when the app receives a limited- or full-access authorization status.
    var contacts: [CNContact]
    
    /// Contains the Contacts authorization status for the app.
    var authorizationStatus: CNAuthorizationStatus
    
    private let logger = Logger(subsystem: "ContactsAccess", category: "ContactStoreManager")
    private let store: CNContactStore
    private let keysToFetch: [any CNKeyDescriptor]
    
    init() {
        self.contacts = []
        self.store = CNContactStore()
        self.authorizationStatus = .notDetermined
        self.keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactImageDataKey as any CNKeyDescriptor,
            CNContactImageDataAvailableKey as any CNKeyDescriptor,
            CNContactThumbnailImageDataKey as any CNKeyDescriptor
        ]
    }
    
    /// Fetches the Contacts authorization status of the app.
    func fetchAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    /// Prompts the person for access to Contacts if the authorization status of the app can't be determined.
    func requestAcess() async {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        guard status == .notDetermined else { return }
        
        do {
            try await store.requestAccess(for: .contacts)
            
            // Update the authorization status of the app.
            fetchAuthorizationStatus()
        } catch {
            fetchAuthorizationStatus()
            logger.error("Requesting Contacts access failed: \(error)")
        }
    }
    
        /// Fetches all contacts authorized for the app and whose identifiers match a given list of identifiers.
    func fetchContacts(withIdentifiers identifiers: [String]) async {
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        fetchRequest.sortOrder = .familyName
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        
        let result = await executeFetchRequest(fetchRequest)
        
        contacts.append(contentsOf: result)
    }
    
    /// Fetches all contacts authorized for the app.
    func fetchContacts() async {
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        fetchRequest.sortOrder = .familyName
        
        let result = await executeFetchRequest(fetchRequest)
        contacts = result
    }
    
    /// Executes the fetch request.
    nonisolated private func executeFetchRequest(_ fetchRequest: CNContactFetchRequest) async -> [CNContact] {
        let fetchingTask = Task {
            var result: [CNContact] = []
            
            do {
                try await store.enumerateContacts(with: fetchRequest) { contact, stop in
                    result.append(contact)
                }
            } catch {
                logger.error("Fetching contacts failed: \(error)")
            }
            
            //let resultMapped = result.map({ $0.contact })
            //return resultMapped
            
            return result
        }
        return await (fetchingTask.result).get()
    }
    
//    func fetchMyContact() throws -> CNContact? {
//        let keys: [CNKeyDescriptor] = [
//            CNContactGivenNameKey as CNKeyDescriptor,
//            CNContactFamilyNameKey as CNKeyDescriptor,
//            CNContactPhoneNumbersKey as CNKeyDescriptor,
//            CNContactEmailAddressesKey as CNKeyDescriptor
//        ]
//
//        let contact = try self.store.unifiedMeContactWithKeys(toFetch: keys)
//        return contact
//    }
}


//
//struct Contact: Identifiable {
//    var id: String
//    var givenName: String
//    var familyName: String
//    var fullName: String
//    var initials: String
//    var thumbNail: Data?
//    
//    init(id: String, givenName: String, familyName: String, fullName: String, initials: String, thumbNail: Data? = nil) {
//        self.id = id
//        self.givenName = givenName
//        self.familyName = familyName
//        self.fullName = fullName
//        self.initials = initials
//        self.thumbNail = thumbNail
//    }
//}
//
//extension Contact: Hashable {
//    static func == (lhs: Contact, rhs: Contact) -> Bool {
//        return lhs.id == rhs.id &&
//        lhs.givenName == rhs.givenName &&
//        lhs.familyName == rhs.familyName &&
//        lhs.fullName == rhs.fullName &&
//        lhs.initials == rhs.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//        hasher.combine(givenName)
//        hasher.combine(familyName)
//        hasher.combine(fullName)
//        hasher.combine(initials)
//        hasher.combine(thumbNail)
//    }
//}
//
//
//extension CNContact {
//    /// The formatted name of a contact.
//    var formattedName: String {
//        CNContactFormatter().string(from: self) ?? "Unknown contact"
//    }
//    
//    /// The contact name's initials.
//    var initials: String {
//        String(self.givenName.prefix(1) + self.familyName.prefix(1))
//    }
//    
//    var contact: Contact {
//        Contact(
//            id: self.id.uuidString,
//            givenName: self.givenName,
//            familyName: self.familyName,
//            fullName: self.formattedName,
//            initials: self.initials,
//            thumbNail: self.thumbnailImageData
//        )
//    }
//}

