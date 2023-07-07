// CloudKitManager.swift

import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    let container = CKContainer(identifier: "iCloud.Handy-mapr") // Define the container here

    func fetchUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))
        container.publicCloudDatabase.perform(query, inZoneWith: nil, completionHandler: completion) // Use the container here
    }
    
    func addUser(username: String, email: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let newUserRecord = CKRecord(recordType: "User")
        newUserRecord["username"] = username
        newUserRecord["email"] = email
        container.publicCloudDatabase.save(newUserRecord, completionHandler: completion) // Use the container here
    }
    
    // Add other methods as needed...
}
