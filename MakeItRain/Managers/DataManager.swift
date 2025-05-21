//
//  DataManager.swift
//  JarvisPhoneApp
//
//  Created by Cody Burnett on 7/30/24.
//

import Foundation
import CoreData

actor DataManager {
    static let shared: DataManager = DataManager()
    let container = NSPersistentContainer(name: "PersistentModel")
    
    private init() {
        //#warning("🟣 Purple warning: Performing I/O on the main thread can cause hangs.")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                LogManager.error("Core Data failed to load: \(error), \(error.userInfo)")
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        LogManager.log("Core Data initialized")
    }
    
    func save(file: String = #file, line: Int = #line, function: String = #function) -> Result<Bool, CoreDataError> {
        //NSLog("\(file):\(line) : \(function)")
        print("-- \(#function) -- Called from: \(file):\(line) : \(function)")

        do {
            try container.viewContext.performAndWait {
                try container.viewContext.save()
            }
            print("CoreData save successful")
            LogManager.log("CoreData save successful")
            return .success(true)
            
        } catch(let error) {
            print(error)
            
            AppState.shared.showAlert("There was a problem saving the cache. Please try again.")
            //fatalError(error.localizedDescription)
            LogManager.error("CoreData save failed - \(error.localizedDescription).")
            return .failure(.reason(error.localizedDescription))
        }
    }
    
    
    func getMany<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil, sort: Array<NSSortDescriptor>? = nil, limit: Int? = nil, offset: Int? = nil) throws -> Array<T>? {
        do {
            let fetchRequest = T.fetchRequest()
            switch predicate {
            case nil: break
            case .single(let predicate): fetchRequest.predicate = predicate
            case .compound(let predicate): fetchRequest.predicate = predicate
            case .byId(let idType):
                switch idType {
                case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
                case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
                }
            }
            
            if sort != nil { fetchRequest.sortDescriptors = sort }
            if limit != nil { fetchRequest.fetchLimit = limit! }
            if offset != nil { fetchRequest.fetchOffset = offset! }
            let fetchResults = try container.viewContext.performAndWait {
                print("\(#function) - Running on the main thread: \(Thread.isMainThread)")
                return try container.viewContext.fetch(fetchRequest)
            }
            return (fetchResults as? [T]) ?? []
            
            
        } catch {
            LogManager.error(error.localizedDescription)
            //return nil
            throw CoreDataError.reason(error.localizedDescription)
            
        }
    }
    
    //#warning("Purple error: Performing I/O on the main thread by reading or writing to a database can cause hangs.")
    //#warning("https://developer.apple.com/documentation/xcode/diagnosing-performance-issues-early")
    func getOne<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil, sort: Array<NSSortDescriptor>? = nil, limit: Int? = nil, offset: Int? = nil, createIfNotFound: Bool) -> T? {
        do {
            let fetchRequest = T.fetchRequest()
            switch predicate {
            case nil: break
            case .single(let predicate): fetchRequest.predicate = predicate
            case .compound(let predicate): fetchRequest.predicate = predicate
            case .byId(let idType):
                switch idType {
                case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
                case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
                }
            }
            
            if sort != nil { fetchRequest.sortDescriptors = sort }
            if limit != nil { fetchRequest.fetchLimit = limit! }
            if offset != nil { fetchRequest.fetchOffset = offset! }
        
            
            let fetchResults = try container.viewContext.performAndWait {
                let results = try container.viewContext.fetch(fetchRequest)
                
                if results.isEmpty {
                    return createIfNotFound ? T(context: container.viewContext) : nil
                } else {
                    return results.first! as? T
                }
            }
            
            return fetchResults
                        
            
        } catch {
            LogManager.error(error.localizedDescription)
            return nil
        }
    }
    
    
    func createBlank<T: NSManagedObject>(type entity: T.Type) -> T? {
        return T(context: container.viewContext)            
    }
    
    
    
    func delete<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil) -> Result<Bool, CoreDataError> {
        guard let entity = getOne(type: T.self, predicate: predicate, createIfNotFound: false) else {
            LogManager.error("Could not find entity")
            return .failure(.reason("Could not find entity"))
        }
        
//        let canDelete = container.canDeleteRecord(forManagedObjectWith: entity.objectID)
//        LogManager.log("Can delete entity (\(entity.objectID)? \(canDelete)")
        let _ = container.viewContext.perform {
            self.container.viewContext.delete(entity)
        }
        return save()
    }
    
    
    
    func deleteAll<T: NSManagedObject>(for entity: T.Type, predicate: Predicate? = nil, shouldSave: Bool = true) -> Result<Bool, CoreDataError>? {
        let fetchRequest = T.fetchRequest()
        switch predicate {
        case nil: break
        case .single(let predicate): fetchRequest.predicate = predicate
        case .compound(let predicate): fetchRequest.predicate = predicate
        case .byId(let idType):
            switch idType {
            case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
            case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            }
        }
                
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        // Configure the request to return the IDs of the objects it deletes.
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        do {
            // Execute the request.
            let deleteResult = try container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
            
            // Extract the IDs of the deleted managed objectss from the request's result.
            if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
                
                // Merge the deletions into the app's managed object context.
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [container.viewContext]
                )
            }
        } catch {
            print(error.localizedDescription)
            LogManager.error(error.localizedDescription)
        }
        if shouldSave {
            return save()
        }
        return nil
        
    }
}




//@MainActor
//class DataManagerOG {
//    static let shared: DataManager = DataManager()
//    let container = NSPersistentContainer(name: "PersistentModel")
//    
//    private init() {
//        #warning("🟣 Purple warning: Performing I/O on the main thread can cause hangs.")
//        container.loadPersistentStores { description, error in
//            if let error = error as NSError? {
//                LogManager.error("Core Data failed to load: \(error), \(error.userInfo)")
//                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
//            }
//        }
//        
//        LogManager.log("Core Data initialized")
//    }
//    
//    func save(file: String = #file, line: Int = #line, function: String = #function) -> Result<Bool, CoreDataError> {
//        //NSLog("\(file):\(line) : \(function)")
//
//        do {
//            try container.viewContext.save()
//            LogManager.log("CoreData save successful")
//            return .success(true)
//            
//        } catch(let error) {
//            print(error)
//            
//            AppState.shared.showAlert("There was a problem saving the cache. Please try again.")
//            //fatalError(error.localizedDescription)
//            LogManager.error("CoreData save failed - \(error.localizedDescription).")
//            return .failure(.reason(error.localizedDescription))
//        }
//    }
//    
//    
//    func getMany<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil, sort: Array<NSSortDescriptor>? = nil, limit: Int? = nil, offset: Int? = nil) throws -> Array<T>? {
//        do {
//            let fetchRequest = T.fetchRequest()
//            switch predicate {
//            case nil: break
//            case .single(let predicate): fetchRequest.predicate = predicate
//            case .compound(let predicate): fetchRequest.predicate = predicate
//            case .byId(let idType):
//                switch idType {
//                case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
//                case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//                }
//            }
//            
//            if sort != nil { fetchRequest.sortDescriptors = sort }
//            if limit != nil { fetchRequest.fetchLimit = limit! }
//            if offset != nil { fetchRequest.fetchOffset = offset! }
//        
//            let fetchResults = try container.viewContext.fetch(fetchRequest)
//            return (fetchResults as? [T]) ?? []
//            
//        } catch {
//            LogManager.error(error.localizedDescription)
//            //return nil
//            throw CoreDataError.reason(error.localizedDescription)
//            
//        }
//    }
//    
//    #warning("Purple error: Performing I/O on the main thread by reading or writing to a database can cause hangs.")
//    #warning("https://developer.apple.com/documentation/xcode/diagnosing-performance-issues-early")
//    func getOne<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil, sort: Array<NSSortDescriptor>? = nil, limit: Int? = nil, offset: Int? = nil, createIfNotFound: Bool) -> T? {
//        do {
//            let fetchRequest = T.fetchRequest()
//            switch predicate {
//            case nil: break
//            case .single(let predicate): fetchRequest.predicate = predicate
//            case .compound(let predicate): fetchRequest.predicate = predicate
//            case .byId(let idType):
//                switch idType {
//                case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
//                case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//                }
//            }
//            
//            if sort != nil { fetchRequest.sortDescriptors = sort }
//            if limit != nil { fetchRequest.fetchLimit = limit! }
//            if offset != nil { fetchRequest.fetchOffset = offset! }
//        
//            let fetchResults = try container.viewContext.fetch(fetchRequest)
//            if fetchResults.isEmpty {
//                return createIfNotFound ? T(context: container.viewContext) : nil
//            } else {
//                return fetchResults.first! as? T
//            }
//        } catch {
//            LogManager.error(error.localizedDescription)
//            return nil
//        }
//    }
//    
//    
//    func createBlank<T: NSManagedObject>(type entity: T.Type) -> T? {
//        return T(context: container.viewContext)
//    }
//    
//    
//    
//    @MainActor func delete<T: NSManagedObject>(type entity: T.Type, predicate: Predicate? = nil) -> Result<Bool, CoreDataError> {
//        guard let entity = getOne(type: T.self, predicate: predicate, createIfNotFound: false) else {
//            LogManager.error("Could not find entity")
//            return .failure(.reason("Could not find entity"))
//        }
//        
////        let canDelete = container.canDeleteRecord(forManagedObjectWith: entity.objectID)
////        LogManager.log("Can delete entity (\(entity.objectID)? \(canDelete)")
//        
//        container.viewContext.delete(entity)
//        return save()
//    }
//    
//    
//    
//    @MainActor func deleteAll<T: NSManagedObject>(for entity: T.Type, predicate: Predicate? = nil, shouldSave: Bool = true) -> Result<Bool, CoreDataError>? {
//        let fetchRequest = T.fetchRequest()
//        switch predicate {
//        case nil: break
//        case .single(let predicate): fetchRequest.predicate = predicate
//        case .compound(let predicate): fetchRequest.predicate = predicate
//        case .byId(let idType):
//            switch idType {
//            case .int(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
//            case .string(let id): fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//            }
//        }
//                
//        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        // Configure the request to return the IDs of the objects it deletes.
//        batchDeleteRequest.resultType = .resultTypeObjectIDs
//        do {
//            // Execute the request.
//            let deleteResult = try container.viewContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
//            
//            // Extract the IDs of the deleted managed objectss from the request's result.
//            if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
//                
//                // Merge the deletions into the app's managed object context.
//                NSManagedObjectContext.mergeChanges(
//                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
//                    into: [container.viewContext]
//                )
//            }
//        } catch {
//            print(error.localizedDescription)
//            LogManager.error(error.localizedDescription)
//        }
//        if shouldSave {
//            return save()
//        }
//        return nil
//        
//    }
//}
