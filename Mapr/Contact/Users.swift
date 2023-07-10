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
    var id: String // Change this to String
    let name: String
    let email: String
    let role: String
    let recordID: CKRecord.ID
    var record: CKRecord

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(email)
        hasher.combine(role)
        hasher.combine(recordID.recordName)
    }
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.role == rhs.role &&
               lhs.recordID.recordName == rhs.recordID.recordName
    }
    func recordToUser(_ record: CKRecord) -> User {
        return User(
            id: record.recordID.recordName, // Use the recordName as the id
            name: record["username"] as? String ?? "Unknown",
            email: record["email"] as? String ?? "Unknown",
            role: record["role"] as? String ?? "Unknown",
            recordID: record.recordID,
            record: record
        )
    }
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
        let container = CKContainer(identifier: "iCloud.Handy-Mapr")
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
            // Remove duplicates before updating the users array
            removeDuplicates(in: PersistenceController.shared.container.viewContext)
            self.users = userEntities.map { retrieveUserFromCoreData(userEntity: $0) }
        } catch {
            print("Failed to fetch selected users: \(error)")
        }
    }


    func removeDuplicates(in managedObjectContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        do {
            let userEntities = try managedObjectContext.fetch(fetchRequest)
            let groupedUserEntities = Dictionary(grouping: userEntities, by: { $0.recordIDData })
            for (_, group) in groupedUserEntities {
                // If there's more than one UserEntity with the same recordIDData, delete the duplicates
                if group.count > 1 {
                    for i in 1..<group.count {
                        managedObjectContext.delete(group[i])
                    }
                }
            }
            try managedObjectContext.save()
        } catch {
            print("Failed to fetch UserEntity: \(error)")
        }
    }


    func recordToUser(_ record: CKRecord) -> User {
        return User(
            id: record.recordID.recordName,
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
                ForEach(userSelection.users, id: \.id) { user in
                    HStack {
                        NavigationLink(destination: UserDetailView(user: user)) {
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
                            // Remove the user from CoreData
                            if let userEntity = fetchUserEntity(user: user, in: managedObjectContext) {
                                print("Fetched UserEntity: \(userEntity)")
                                managedObjectContext.delete(userEntity)
                                do {
                                    try managedObjectContext.save()
                                    // Also remove the user from the users array
                                    userSelection.users.removeAll(where: { $0.id == user.id }) // Use id instead of recordID
                                } catch {
                                    print("Failed to delete user: \(error)")
                                }
                            } else {
                                print("Failed to fetch UserEntity for user: \(user)")
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

func fetchUserEntity(user: User, in managedObjectContext: NSManagedObjectContext) -> UserEntity? {
    let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
    if let recordIDData = try? NSKeyedArchiver.archivedData(withRootObject: user.recordID, requiringSecureCoding: false) {
        fetchRequest.predicate = NSPredicate(format: "recordIDData == %@", recordIDData as CVarArg)
    } else {
        // Handle the error
    }
    do {
        let userEntities = try managedObjectContext.fetch(fetchRequest)
        return userEntities.first
    } catch {
        print("Failed to fetch UserEntity: \(error)")
        return nil
    }
}





class AddUserSelection: ObservableObject {
    @Published var users: [User] = []

    func fetchUsers(searchText: String? = nil) {
        let predicate: NSPredicate
        if let searchText = searchText, !searchText.isEmpty {
            predicate = NSPredicate(format: "username CONTAINS[cd] %@ OR email CONTAINS[cd] %@", searchText, searchText)
        } else {
            predicate = NSPredicate(value: true)
        }
        let query = CKQuery(recordType: "User", predicate: predicate)
        let container = CKContainer(identifier: "iCloud.Handy-Mapr")
        container.publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let records = records {
                    print("Successfully fetched all users")
                    let users = records.map { self.recordToUser($0) }
                    // Filter out duplicate users
                    self.users = Array(Set(users))
                } else if let error = error {
                    print("Failed to fetch users: \(error.localizedDescription)")
                }
            }
        }
    }

    func recordToUser(_ record: CKRecord) -> User {
        return User(
            id: record.recordID.recordName, // Use the recordName as the id
            name: record["username"] as? String ?? "Unknown",
            email: record["email"] as? String ?? "Unknown",
            role: record["role"] as? String ?? "Unknown",
            recordID: record.recordID,
            record: record
        )
    }
}

struct AddUserView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @EnvironmentObject var userSelection: UserSelection
    @ObservedObject var addUserSelection = AddUserSelection()
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
                            addUserSelection.fetchUsers(searchText: newValue) // Use addUserSelection here
                        }
                }
                .padding([.horizontal, .top])
                
                List {
                    ForEach(addUserSelection.users.sorted(by: { $0.name < $1.name }), id: \.id) { user in
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
                addUserSelection.fetchUsers() // Use addUserSelection here
            }
        }
    }
}

func saveUserToCoreData(user: User, in managedObjectContext: NSManagedObjectContext) {
    // Only save the user to CoreData if they're not already in it
    if fetchUserEntity(user: user, in: managedObjectContext) == nil {
        let userEntity = UserEntity(context: managedObjectContext)
        if let uuid = UUID(uuidString: user.id) {
            userEntity.id = uuid
        } else {
            // Handle the error
        }
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
        return User(id: id.uuidString, name: name, email: email, role: role, recordID: recordID, record: record)
        } else {
            // Return a default User object if recordIDData or recordData is nil
            return User(id: id.uuidString, name: name, email: email, role: role, recordID: CKRecord.ID(), record: CKRecord(recordType: "User"))
        }

}






