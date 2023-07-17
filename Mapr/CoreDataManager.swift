import CoreData
import CloudKit


struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Mapr")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                fatalError("No Descriptions found.")
            }
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.Handy-Mapr")
        }
        load()
    }

    private func load() {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Instead of just printing the error, let's handle it
                CoreDataManager.shared.handleLoadError(error)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Initialize CloudKit schema (update this, when making changes to coredata)
        // Comment out or delete this code after the schema has been initialized
        /*
        do {
            try container.initializeCloudKitSchema(options: [.printSchema])
        } catch {
            // Handle the error in a similar way
            CoreDataManager.shared.handleSchemaInitializationError(error)
        }
        */
    }
}

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    let persistenceController = PersistenceController.shared

    var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }

    // Add these properties to your CoreDataManager class
    @Published var showErrorAlert = false
    @Published var errorAlertMessage = ""

    // Your CRUD operations go here
    func fetchContacts() -> [Contact] {
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch contacts: \(error)")
            return []
        }
    }

    func addContact(id: UUID, name: String, email: String, phone: String, address: String) {
        let contact = Contact(context: context)
        contact.name = name
        contact.email = email
        contact.phone = phone
        contact.address = address
        saveContext()
    }

    func deleteContact(_ contact: Contact) {
        context.delete(contact)
        saveContext()
    }

    func updateContact(_ contact: Contact) {
        saveContext()
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func handleLoadError(_ error: NSError) {
        print("Failed to load persistent stores: \(error), \(error.userInfo)")
        errorAlertMessage = "Failed to load data. Please check your iCloud settings and try again."
        showErrorAlert = true
    }

    func handleSchemaInitializationError(_ error: Error) {
        print("Failed to initialize CloudKit schema: \(error.localizedDescription)")
        errorAlertMessage = "Failed to initialize CloudKit schema. Please check your iCloud settings and try again."
        showErrorAlert = true
    }

    @objc func handleRemoteChangeNotification(_ notification: Notification) {
        if let error = notification.userInfo?[NSPersistentStoreSaveError] as? NSError {
            print("CloudKit sync error: \(error), \(error.userInfo)")
            errorAlertMessage = "CloudKit sync error: \(error), \(error.userInfo)"
            showErrorAlert = true
        } else {
            // Handle successful sync here if needed
        }
    }
    
    func addUserToProject(user: UserEntity, project: Project) {
            project.addToUsers(user)
            saveContext()
        }

    func removeUserFromProject(user: UserEntity, project: Project) {
        project.removeFromUsers(user)
        saveContext()
    }
    
    func synchronizeUsers() {
        // 1. Fetch all users from CloudKit
        let publicDatabase = CKContainer(identifier: "iCloud.Handy-Mapr").publicCloudDatabase
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))
        publicDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                // Handle the error here
                print("Error fetching users from CloudKit: \(error)")
            } else if let records = records {
                // 2. Fetch all users from CoreData
                let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                do {
                    let userEntities = try self.context.fetch(fetchRequest)
                    // 3. Compare the two arrays
                    let cloudKitUsers = records.map { $0.recordID.recordName }
                    let coreDataUsers = userEntities.compactMap { userEntity in
                        if let recordIDData = userEntity.recordIDData,
                           let recordID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: recordIDData) {
                            return recordID.recordName
                        }
                        return nil
                    }
                    let extraUsers = Set(coreDataUsers).subtracting(cloudKitUsers)
                    // 4. Delete the extra entities
                    for userEntity in userEntities {
                        if let recordIDData = userEntity.recordIDData,
                           let recordID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: recordIDData),
                           extraUsers.contains(recordID.recordName) {
                            self.context.delete(userEntity)
                        }
                    }
                    try self.context.save()
                } catch {
                    // Handle the error here
                    print("Error fetching users from CoreData: \(error)")
                }
            }
        }
    }


}

        
