//
//  Users.swift
//  Mapr
//
//  Created by Vegar Berentsen on 07/07/2023.
//

import SwiftUI
import CloudKit
import CoreData


struct User: Identifiable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let role: String
    let recordID: CKRecord.ID
    var record: CKRecord
}


class UserSelection: ObservableObject {
    @Published var users: [User] = []

    func fetchUsers(searchText: String? = nil) {
        let predicate: NSPredicate
        if let searchText = searchText, !searchText.isEmpty {
            predicate = NSPredicate(format: "username CONTAINS[cd] %@ OR email CONTAINS[cd] %@", searchText, searchText)
        } else {
            predicate = NSPredicate(value: true)
        }
        let query = CKQuery(recordType: "User", predicate: predicate)
        let container = CKContainer(identifier: "iCloud.Mapr")
        container.publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    print("Successfully fetched all users")
                    self.users = records.map { self.recordToUser($0) }
                } else if let error = error {
                    print("Failed to fetch users: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchSelectedUsers() {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        do {
            let userEntities = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            self.users = userEntities.map { retrieveUserFromCoreData(userEntity: $0) }
        } catch {
            print("Failed to fetch selected users: \(error)")
        }
    }

    func recordToUser(_ record: CKRecord) -> User {
        return User(
            id: UUID(),
            name: record["username"] as? String ?? "Unknown",
            email: record["email"] as? String ?? "Unknown",
            role: record["role"] as? String ?? "Unknown",
            recordID: record.recordID,
            record: record
        )
    }
}

struct Users: View {
    @State private var searchText = ""
    @State private var showingAddUser = false
    @EnvironmentObject var userSelection: UserSelection
    @Environment(\.managedObjectContext) var managedObjectContext
    
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
                ForEach(userSelection.users, id: \.self) { user in
                    HStack {
                        NavigationLink(destination: UserDetailView()) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
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
                                if let index = userSelection.users.firstIndex(where: { $0.recordID == user.recordID }) {
                                    // Delete user from Core Data
                                    let userEntity = UserEntity(context: managedObjectContext)
                                    userEntity.id = user.id
                                    managedObjectContext.delete(userEntity)
                                    do {
                                        try managedObjectContext.save()
                                    } catch {
                                        print("Failed to delete user: \(error)")
                                    }
                                    
                                    // Delete user from array
                                    userSelection.users.remove(at: index)
                                }
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
        .onAppear {
            userSelection.fetchSelectedUsers()
        }
    }
}


struct AddUserView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @EnvironmentObject var userSelection: UserSelection
    var onAddUser: ((User) -> Void)?
    
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
                            userSelection.fetchUsers(searchText: newValue)
                        }
                }
                .padding([.horizontal, .top])
                
                List {
                    ForEach(userSelection.users, id: \.self) { user in
                        Button(action: {
                            // Save the user to CoreData
                            saveUserToCoreData(user: user, in: managedObjectContext)
                            
                            onAddUser?(user)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
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
            .onAppear {
                userSelection.fetchUsers()
            }
        }
    }
}

func saveUserToCoreData(user: User, in managedObjectContext: NSManagedObjectContext) {
    let userEntity = UserEntity(context: managedObjectContext)
    userEntity.id = user.id
    userEntity.name = user.name
    userEntity.email = user.email
    userEntity.role = user.role

    // Convert CKRecord.ID and CKRecord to Data
    let recordIDData = try? NSKeyedArchiver.archivedData(withRootObject: user.recordID, requiringSecureCoding: false)
    let recordData = try? NSKeyedArchiver.archivedData(withRootObject: user.record, requiringSecureCoding: false)

    userEntity.recordIDData = recordIDData
    userEntity.recordData = recordData

    do {
        try managedObjectContext.save()
    } catch {
        print("Failed to save user: \(error)")
    }
}

func retrieveUserFromCoreData(userEntity: UserEntity) -> User {
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
        // Return a default User object if recordIDData or recordData is nil
        return User(id: id, name: name, email: email, role: role, recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
    }
}






