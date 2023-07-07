//
//  UserDetailView.swift
//  Mapr
//
//  Created by Vegar Berentsen on 07/07/2023.
//

import SwiftUI
import CloudKit

struct UserDetailView: View {
    @State private var showingUpdateUser = false

    var body: some View {
        VStack {
            Text("User Detail View")
            
            Button(action: {
                showingUpdateUser = true
            }) {
                Text("Update User")
            }
            .sheet(isPresented: $showingUpdateUser) {
                UpdateUserView()
            }
        }
    }
}



struct UpdateUserView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var showError = false

    var body: some View {
        VStack {
            TextField("Username", text: $username)
            TextField("Email", text: $email)
            Button("Update") {
                updateUser()
            }
            if showError {
                Text("Please sign in to iCloud to update your user information.")
                    .foregroundColor(.red)
            }
        }
    }

    func updateUser() {
        // Fetch the current user's record
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error {
                print("Failed to fetch user record ID: \(error)")
                DispatchQueue.main.async {
                    showError = true
                }
            } else if let recordID = recordID {
                CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
                    if let error = error {
                        print("Failed to fetch user record: \(error)")
                    } else if let record = record {
                        // Update the user's record with the new username and email
                        record["username"] = username
                        record["email"] = email
                        CKContainer.default().publicCloudDatabase.save(record) { (record, error) in
                            if let error = error {
                                print("Failed to update user record: \(error)")
                            } else {
                                print("User record updated successfully")
                            }
                        }
                    }
                }
            }
        }
    }
}

