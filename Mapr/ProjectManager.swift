//
//  ProjectManager.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//

import SwiftUI
import CloudKit

#if os(macOS)
class ProjectManager {
    func shareProjectWithSelectedUsers(project: Project, selectedUsers: [User]) {
        guard let recordName = project.recordID else {
            print("Project does not have a CKRecord ID")
            return
        }
        
        let recordID = CKRecord.ID(recordName: recordName)
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOperation.fetchRecordsCompletionBlock = { records, error in
            if let error = error {
                print("Failed to fetch CKRecord: \(error)")
                if let nsError = error as NSError? {
                    print("Detailed error: \(nsError.localizedDescription)")
                    print("Debug Description: \(nsError.debugDescription)")
                    print("User Info: \(nsError.userInfo)")
                }
            } else if let projectRecord = records?[recordID] {
                let share = CKShare(rootRecord: projectRecord)
                share[CKShare.SystemFieldKey.title] = "Shared Project" as CKRecordValue?
                share[CKShare.SystemFieldKey.shareType] = "iCloud.Mapr" as CKRecordValue?
                
                // Add each selected user as a participant
                for user in selectedUsers { // <-- Here
                    let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: user.email)
                    let discoverOperation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookupInfo])
                    discoverOperation.userIdentityDiscoveredBlock = { (userIdentity, _) in
                        let fetchParticipantsOperation = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookupInfo])
                        fetchParticipantsOperation.shareParticipantFetchedBlock = { participant in
                            participant.permission = .readWrite
                            share.addParticipant(participant)
                        }
                        CKContainer.default().add(fetchParticipantsOperation)
                    }
                    CKContainer.default().add(discoverOperation)
                }
                
                
                let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [projectRecord, share], recordIDsToDelete: nil)
                modifyRecordsOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecord.ID]?, error: Error?) in
                    if let error = error {
                        print("Failed to create share: \(error)")
                    } else {
                        print("Successfully shared project with selected users")
                    }
                }
                
                CKContainer.default().privateCloudDatabase.add(modifyRecordsOperation)
            }
        }
        CKContainer.default().privateCloudDatabase.add(fetchRecordsOperation)
    }
}
    
#endif
    
