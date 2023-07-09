import Foundation
import CoreData
import CloudKit

class UserManager {
    static let shared = UserManager()
    
    private init() {}
    
    func fetchCurrentUser(in context: NSManagedObjectContext) -> User {
        // Fetch the current user from CoreData
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        do {
            let userEntities = try context.fetch(fetchRequest)
            // Assuming there's only one user stored in CoreData
            if let userEntity = userEntities.first {
                return retrieveUserFromCoreData(userEntity: userEntity) ?? User(id: "Unknown", name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
            } else {
                // Handle the case where no user is stored in CoreData
                // This is just a placeholder and you'll need to replace it with your own logic
                return User(id: "Unknown", name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
            }
        } catch {
            // Handle the fetch error
            // This is just a placeholder and you'll need to replace it with your own logic
            print("Failed to fetch user: \(error)")
            return User(id: "Unknown", name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
        }
    }

    
    func retrieveUserFromCoreData(userEntity: UserEntity) -> User {
        let id = userEntity.id?.uuidString ?? "" // Convert UUID to String
        let name = userEntity.name ?? ""
        let email = userEntity.email ?? ""
        let role = userEntity.role ?? ""

        // Check if recordIDData and recordData are not nil
        if let recordIDData = userEntity.recordIDData, let recordData = userEntity.recordData {
            // Convert Data back to CKRecord.ID and CKRecord
            let recordID = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(recordIDData)) as? CKRecord.ID ?? CKRecord.ID()
            let record = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(recordData)) as? CKRecord ?? CKRecord(recordType: "User")
            return User(id: id, name: name, email: email, role: role, recordID: recordID, record: record)
        } else {
            // Return a default User object if recordIDData or recordData is nil
            return User(id: "Unknown", name: name, email: email, role: role, recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
        }
    }




    
    func fetchUsers(searchText: String, in context: NSManagedObjectContext) -> [User] {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR email CONTAINS[cd] %@", searchText, searchText)
        do {
            let userEntities = try context.fetch(fetchRequest)
            return userEntities.compactMap { retrieveUserFromCoreData(userEntity: $0) }
        } catch {
            print("Failed to fetch users: \(error)")
            return []
        }
    }
    
    func saveUserToCoreData(user: User, in managedObjectContext: NSManagedObjectContext) {
        // Only save the user to CoreData if they're not already in it
        if fetchUserEntity(user: user, in: managedObjectContext) == nil {
            let userEntity = UserEntity(context: managedObjectContext)
            userEntity.id = UUID(uuidString: user.id) // Convert String to UUID
            userEntity.name = user.name
            userEntity.email = user.email
            userEntity.role = user.role

            // Convert CKRecord.ID and CKRecord to Data
            let recordIDData = try? NSKeyedArchiver.archivedData(withRootObject: user.recordID, requiringSecureCoding: false)
            let recordData = try? NSKeyedArchiver.archivedData(withRootObject: user.record, requiringSecureCoding: false)

            userEntity.recordIDData = recordIDData
            userEntity.recordData = recordData

            do {
                try managedObjectContext.save()
            } catch {
                print("Failed to save user: \(error)")
            }
        }
    }


    func loadUsersFromCoreData(in managedObjectContext: NSManagedObjectContext) -> [User] {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        do {
            let userEntities = try managedObjectContext.fetch(fetchRequest)
            return userEntities.map { retrieveUserFromCoreData(userEntity: $0) }
        } catch {
            print("Failed to load users: \(error)")
            return []
        }
    }
    
    // Add other user-related functions here
    
    
}
