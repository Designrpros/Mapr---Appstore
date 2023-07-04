import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container1: NSPersistentContainer
    let container2: NSPersistentContainer
    //let container3: NSPersistentContainer

    init(inMemory: Bool = false) {
        container1 = NSPersistentContainer(name: "Location")
        container2 = NSPersistentContainer(name: "Contact")
        //container3 = NSPersistentContainer(name: "NoteItem")
        if inMemory {
            container1.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            container2.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        load(container: container1)
        load(container: container2)
        //load(container: container3)
    }
    
    private func load(container: NSPersistentContainer) {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistenceController = PersistenceController.shared

    // Your CRUD operations go here
    func fetchContacts() -> [Contact] {
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()
        do {
            return try persistenceController.container2.viewContext.fetch(request)
        } catch {
            print("Failed to fetch contacts: \(error)")
            return []
        }
    }

    func addContact(id: UUID, name: String, email: String, phone: String, address: String) {
        let contact = Contact(context: persistenceController.container2.viewContext)
        contact.name = name
        contact.email = email
        contact.phone = phone
        contact.address = address
        saveContext()
    }

    func deleteContact(_ contact: Contact) {
        persistenceController.container2.viewContext.delete(contact)
        saveContext()
    }

    func updateContact(_ contact: Contact) {
        saveContext()
    }

    func saveContext() {
        let context = persistenceController.container2.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
