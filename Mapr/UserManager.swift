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
                return retrieveUserFromCoreData(userEntity: userEntity)
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
    
    // Add other user-related functions here
}
