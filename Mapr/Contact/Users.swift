//
//  Users.swift
//  Mapr
//
//  Created by Vegar Berentsen on 07/07/2023.
//

import SwiftUI
import CloudKit


struct User: Identifiable {
    let id: UUID
    let name: String
}


class UserSelection: ObservableObject {
    @Published var users: [CKRecord] = []
}

struct Users: View {
    @State private var searchText = ""
    @State private var showingAddUser = false
    @EnvironmentObject var userSelection: UserSelection
    @State private var users: [CKRecord] = []
    
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
                        if !userSelection.users.contains(where: { $0.recordID == newUser.recordID }) {
                            userSelection.users.append(newUser)
                        }
                    }
                }
            }
            .padding([.horizontal, .top])
                
            

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
                    }
                    .contextMenu {
                        Button(action: {
                            // Remove the user from the list
                            DispatchQueue.main.async {
                                userSelection.users.removeAll(where: { $0.recordID == user.recordID })
                            }
                        }) {
                            Text("Remove User from List")
                            Image(systemName: "trash")
                        }
                    }

                }
            }
        }
        .navigationTitle("Add User")
    }
    var filteredUsers: [CKRecord] {
        if searchText.isEmpty {
            return userSelection.users
        } else {
            return userSelection.users.filter {
                ($0["username"] as? String)?.contains(searchText) ?? false ||
                ($0["email"] as? String)?.contains(searchText) ?? false
            }
        }
    }
    func fetchUsers() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "User", predicate: predicate)
        let container = CKContainer(identifier: "iCloud.Mapr")
        container.publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    print("Successfully fetched all users")
                    users = records
                } else if let error = error {
                    print("Failed to fetch users: \(error.localizedDescription)")
                }
            }
        }
    }
}




struct AddUserView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var users: [CKRecord] = []
    @EnvironmentObject var userSelection: UserSelection
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
                            // Save the user to CoreData
                            let newUser = User(id: UUID(), name: user["username"] as? String ?? "Unknown")
                            saveUserToCoreData(user: newUser, in: managedObjectContext)
                            
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
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "User", predicate: predicate)
        let container = CKContainer(identifier: "iCloud.Mapr")
        container.publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    print("Successfully fetched all users")
                    let filteredRecords = records.filter { record in
                        let username = record["username"] as? String ?? ""
                        let email = record["email"] as? String ?? ""
                        return (username.localizedCaseInsensitiveContains(searchText) || email.localizedCaseInsensitiveContains(searchText)) && !userSelection.users.contains(where: { $0.recordID == record.recordID })
                    }
                    users = filteredRecords
                    // Print out the records
                    for record in filteredRecords {
                        print("Record: \(record)")
                    }
                } else if let error = error {
                    // Print out the error message
                    print("Failed to fetch users: \(error.localizedDescription)")
                }
            }
        }
    }
}

func saveUserToCoreData(user: User, in managedObjectContext: NSManagedObjectContext) {
    let userEntity = UserEntity(context: managedObjectContext)
    userEntity.id = user.id
    userEntity.name = user.name
    do {
        try managedObjectContext.save()
    } catch {
        print("Failed to save user: \(error)")
    }
}

func retrieveUserFromCoreData(userEntity: UserEntity) -> User {
    let id = userEntity.id ?? UUID()
    let name = userEntity.name ?? ""
    return User(id: id, name: name)
}



