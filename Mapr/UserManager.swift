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
                return retrieveUserFromEntity(userEntity: userEntity, in: context) ?? User(id: UUID(), name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
            } else {
                // Handle the case where no user is stored in CoreData
                // This is just a placeholder and you'll need to replace it with your own logic
                return User(id: UUID(), name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
            }
        } catch {
            // Handle the fetch error
            // This is just a placeholder and you'll need to replace it with your own logic
            print("Failed to fetch user: \(error)")
            return User(id: UUID(), name: "Unknown", email: "Unknown", role: "Unknown", recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
        }
    }
    
    func retrieveUserFromEntity(userEntity: UserEntity, in managedObjectContext: NSManagedObjectContext) -> User? {
        let id = userEntity.id ?? UUID()
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
            // If recordIDData or recordData is nil, create a default CKRecord
            let recordID = CKRecord.ID()
            let record = CKRecord(recordType: "User")
            return User(id: id, name: name, email: email, role: role, recordID: recordID, record: record)
        }
    }


    
    func fetchUsers(searchText: String, in context: NSManagedObjectContext) -> [User] {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR email CONTAINS[cd] %@", searchText, searchText)
        do {
            let userEntities = try context.fetch(fetchRequest)
            return userEntities.compactMap { retrieveUserFromEntity(userEntity: $0, in: context) }
        } catch {
            print("Failed to fetch users: \(error)")
            return []
        }
    }
    
    // Add other user-related functions here
}
