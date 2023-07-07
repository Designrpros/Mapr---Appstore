//
//  Users.swift
//  Mapr
//
//  Created by Vegar Berentsen on 07/07/2023.
//

import SwiftUI

struct Users: View {
    @State private var searchText = ""
    @State private var showingAddUser = false
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.userName, ascending: true)],
        animation: .default)
    private var users: FetchedResults<User>
    
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
                    AddUserView {
                        // Refresh the user list when a new user is added
                    }
                }
            }
            .padding([.horizontal])
                
            List {
                ForEach(filteredUsers, id: \.self) { user in
                    HStack {
                        NavigationLink(destination: UserDetailView()) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(user.userName ?? "Unknown")
                                        .font(.headline)
                                    Text(user.email ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                    }
                    .contextMenu {
                        Button(action: {
                            // Delete the user from Core Data
                            viewContext.delete(user)
                            do {
                                try viewContext.save()
                            } catch {
                                print("Failed to delete user: \(error)")
                            }
                        }) {
                            Text("Delete User")
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return Array(users)
        } else {
            return Array(users).filter {
                $0.userName?.contains(searchText) ?? false ||
                $0.email?.contains(searchText) ?? false
            }
        }
    }
}


struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newUsername = ""
    @State private var newEmail = ""
    var onAddUser: (() -> Void)?

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            
            VStack {
                Text("Add User")
                    .font(.title)
                    .padding()
                VStack{
                    TextField("Username", text: $newUsername)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Email", text: $newEmail)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                }.padding()
                
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                    Button("Add") {
                        let newUser = User(context: viewContext)
                        newUser.userName = newUsername
                        newUser.email = newEmail
                        do {
                            try viewContext.save()
                            onAddUser?()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Failed to add user: \(error)")
                        }
                    }
                }
                .padding()
                .frame(width: 250, height: 50)
            }
            .navigationTitle("Add User")
        }
    }
}
