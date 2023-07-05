import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "iCloud.Mapr")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                fatalError("No Descriptions found.")
            }
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.Mapr")
        }
        load()

        // Add observer for NSPersistentStoreRemoteChange events
        NotificationCenter.default.addObserver(CoreDataManager.shared, selector: #selector(CoreDataManager.shared.handleRemoteChangeNotification(_:)), name: .NSPersistentStoreRemoteChange, object: nil)
    }

    private func load() {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Initialize CloudKit schema (update this, when making changes to coredata)
        do {
            try container.initializeCloudKitSchema(options: [.printSchema])
        } catch {
            print("Failed to initialize CloudKit schema: \(error.localizedDescription)")
        }

    }
}

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    let persistenceController = PersistenceController.shared

    var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }

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

    @objc func handleRemoteChangeNotification(_ notification: Notification) {
        if let error = notification.userInfo?[NSPersistentStoreSaveError] as? NSError {
            print("CloudKit sync error: \(error), \(error.userInfo)")
        }
    }
}
