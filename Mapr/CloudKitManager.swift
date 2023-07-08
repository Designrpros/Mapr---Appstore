import CloudKit

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let publicDatabase = CKContainer.default().publicCloudDatabase
    @Published var currentUser: User?


    func addUser(username: String, email: String, role: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let record = CKRecord(recordType: "User")
        record["username"] = username
        record["email"] = email
        record["role"] = role

        publicDatabase.save(record) { (savedRecord, error) in
            DispatchQueue.main.async {
                completion(savedRecord, error)
            }
        }
    }

    func fetchUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))

        publicDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                completion(records, error)
            }
        }
    }
    
    
    func deleteUser(user: User, completion: @escaping (Error?) -> Void) {
        guard currentUser?.role == "admin" else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
            return
        }

        // Delete the user
        publicDatabase.delete(withRecordID: user.recordID) { (recordID, error) in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }

    func editUser(user: User, completion: @escaping (Error?) -> Void) {
        guard currentUser?.role == "admin" || currentUser?.role == "employee" || currentUser?.role == "apprentice" else {
            completion(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
            return
        }

        // Edit the user
        publicDatabase.save(user.record) { (record, error) in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }

}
