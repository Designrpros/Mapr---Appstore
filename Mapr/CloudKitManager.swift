import CloudKit

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    let publicDatabase = CKContainer(identifier: "iCloud.Handy-Mapr").publicCloudDatabase
    @Published var currentUser: User?


    var backOffTime = 1.0

    func addUser(username: String, email: String, role: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let record = CKRecord(recordType: "User")
        record["username"] = username
        record["email"] = email
        record["role"] = role

        publicDatabase.save(record) { (savedRecord, error) in
            if let ckerror = error as? CKError, ckerror.code == .requestRateLimited {
                // If the error is a rate limit error, wait for the suggested time before trying again
                let retryAfter = ckerror.userInfo[CKErrorRetryAfterKey] as? Double ?? 0
                DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) {
                    self.addUser(username: username, email: email, role: role, completion: completion)
                }
            } else {
                // If the request was successful or failed for a different reason, call the completion handler
                DispatchQueue.main.async {
                    completion(savedRecord, error)
                }
            }
        }
    }




    func fetchUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        print("Fetching users")
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))

        publicDatabase.perform(query, inZoneWith: nil) { (records, error) in
            print("Rate limit error when fetching users, retrying after \(self.backOffTime) seconds")
            if let ckerror = error as? CKError, ckerror.code == .limitExceeded {
                // If the error is a rate limit error, wait for the back-off time before trying again
                DispatchQueue.main.asyncAfter(deadline: .now() + self.backOffTime) {
                    self.backOffTime *= 2
                    self.fetchUsers(completion: completion)
                }
            } else {
                print("Finished fetching users, error: \(error)")
                // If the request was successful or failed for a different reason, reset the back-off time and call the completion handler
                self.backOffTime = 1.0
                DispatchQueue.main.async {
                    completion(records, error)
                }
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
    
    func createParticipantForUser(user: User, completion: @escaping (CKShare.Participant?, Error?) -> Void) {
        let operation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [CKUserIdentity.LookupInfo(emailAddress: user.email)])
        operation.shareParticipantFetchedBlock = { participant in
            DispatchQueue.main.async {
                completion(participant, nil)
            }
        }
        operation.fetchShareParticipantsCompletionBlock = { error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        CKContainer.default().add(operation)
    }
    
    func checkShareStatus(of record: CKRecord) {
        if let shareReference = record.share {
            let operation = CKFetchRecordsOperation(recordIDs: [shareReference.recordID])
            operation.perRecordCompletionBlock = { fetchedRecord, _, error in
                if let error = error {
                    print("Error fetching share: \(error)")
                } else if let share = fetchedRecord as? CKShare {
                    if share.participants.isEmpty {
                        print("Record is not shared")
                    } else {
                        print("Record is shared with \(share.participants.count) participants")
                    }
                }
            }
            publicDatabase.add(operation)
        } else {
            print("Record is not shared")
        }
    }

}
