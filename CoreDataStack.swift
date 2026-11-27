//
//  CoreDataStack.swift
//  StudentOrganizer
//
//  Created by QUERUBIN, LEANN MARIE on 10/26/26.
//

import CoreData
  
/// One shared object that owns the Core Data "stack" (model + database + context).
/// Every screen talks to the database through CoreDataStack.shared.
final class CoreDataStack {
  
    static let shared = CoreDataStack()
  
    /// Loads StudentOrganizer.xcdatamodeld and creates the SQLite file on the device.
    let container: NSPersistentContainer
  
    /// The "scratchpad" where we create, change, and delete objects before saving.
    var context: NSManagedObjectContext { container.viewContext }
  
    private init() {
        // The name MUST match the .xcdatamodeld file name exactly.
        container = NSPersistentContainer(name: "StudentOrganizer")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // If the database cannot load, the app cannot work at all.
                fatalError("Core Data failed to load: \(error)")
            }
            print("Database file: \(storeDescription.url?.path ?? "unknown")")
        }
    }
  
    /// Writes any pending changes to the database file.
    @discardableResult
    func save() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            print("Core Data save failed: \(error)")
            return false
        }
    }
} 
