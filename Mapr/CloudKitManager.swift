import CloudKit

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let publicDatabase = CKContainer.default().publicCloudDatabase

    func addUser(username: String, email: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let record = CKRecord(recordType: "User")
        record["username"] = username
        record["email"] = email

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
}
