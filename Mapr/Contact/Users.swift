//
//  Users.swift
//  Mapr
//
//  Created by Vegar Berentsen on 07/07/2023.
//

import SwiftUI
import CloudKit

struct Users: View {
    @State private var searchText = ""
    @State private var showingAddUser = false
    @State private var users: [CKRecord] = []
    @State private var showingUpdateUser = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search...", text: $searchText)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Button(action: {
                    showingAddUser = true
                }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)
                .buttonStyle(BorderlessButtonStyle())
                .sheet(isPresented: $showingAddUser) {
                    AddUserView { newUser in
                        users.append(newUser)
                    }
                }
            }
            .padding([.horizontal])
            
            Button(action: {
                showingUpdateUser = true
            }) {
                Text("Update User")
            }
            .sheet(isPresented: $showingUpdateUser) {
                UpdateUserView()
            }
                
            List {
                ForEach(filteredUsers, id: \.self) { user in
                    HStack {
                        NavigationLink(destination: UserDetailView()) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(user["username"] as? String ?? "Unknown")
                                        .font(.headline)
                                    Text(user["email"] as? String ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                    }
                    .contextMenu {
                        Button(action: {
                            // Delete the user from CloudKit
                            CKContainer.default().publicCloudDatabase.delete(withRecordID: user.recordID) { (recordID, error) in
                                if let error = error {
                                    print("Failed to delete user: \(error)")
                                } else {
                                    DispatchQueue.main.async {
                                        users.removeAll(where: { $0.recordID == recordID })
                                    }
                                }
                            }
                        }) {
                            Text("Delete User")
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchUsers()
        }
    }
    var filteredUsers: [CKRecord] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter {
                ($0["username"] as? String)?.contains(searchText) ?? false ||
                ($0["email"] as? String)?.contains(searchText) ?? false
            }
        }
    }
    
    func fetchUsers() {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    users = records
                } else if let error = error {
                    print("Failed to fetch users: \(error)")
                }
            }
        }
    }
}




struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var users: [CKRecord] = []
    var onAddUser: ((CKRecord) -> Void)?

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            
            VStack {
                HStack {
                    TextField("Search...", text: $searchText)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            fetchUsers(searchText: newValue)
                        }
                }
                .padding([.horizontal, .top])
                
                List {
                    ForEach(users, id: \.self) { user in
                        Button(action: {
                            onAddUser?(user)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(user["username"] as? String ?? "Unknown")
                                        .font(.headline)
                                    Text(user["email"] as? String ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }.frame(minWidth: 100, idealWidth: 300, maxWidth: .infinity, minHeight: 100, idealHeight: 250, maxHeight: .infinity)

                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        
                }.padding()
            }
            .navigationTitle("Add User")
        }
    }

    func fetchUsers(searchText: String) {
        let predicate = NSPredicate(format: "username CONTAINS[c] %@ OR email CONTAINS[c] %@", searchText, searchText)
        let query = CKQuery(recordType: "User", predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    users = records
                } else if let error = error {
                    print("Failed to fetch users: \(error)")
                }
            }
        }
    }
}



