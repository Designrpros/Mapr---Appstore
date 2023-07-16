import SwiftUI
import CoreData

struct ContactListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)],
        animation: .default)
    private var contacts: FetchedResults<Contact>
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var selectedSegment = 0
    
    
    var body: some View {
        VStack {
            if selectedSegment == 0 {
                HStack {
                    TextField("Search...", text: $searchText)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    Button(action: {
                        showingAddContact = true
                    }) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                    .buttonStyle(BorderlessButtonStyle())
                    .sheet(isPresented: $showingAddContact) {
                        AddContactView {
                            // Refresh the contacts array when a new contact is added
                        }
                    }
                }
                .padding([.horizontal, .top])
                
                List {
                    ForEach(filteredContacts, id: \.self) { contact in
                        HStack {
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                    VStack(alignment: .leading) {
                                        Text(contact.name ?? "Unknown")
                                            .font(.headline)
                                        Text(contact.email ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .contextMenu {
                            Button(action: {
                                // Delete the contact from Core Data
                                viewContext.delete(contact)
                                do {
                                    try viewContext.save()
                                } catch {
                                    print("Failed to delete contact: \(error)")
                                }
                            }) {
                                Text("Delete Contact")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            } else {
                Users()
            }
        }.navigationTitle("Contacts & Users")
        CustomContactSegmentedControl(selectedTab: $selectedSegment)
    }
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return Array(contacts)
        } else {
            return Array(contacts).filter {
                $0.name?.contains(searchText) ?? false ||
                $0.email?.contains(searchText) ?? false ||
                $0.phone?.contains(searchText) ?? false ||
                $0.address?.contains(searchText) ?? false
            }
        }
    }
}


struct AddContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var newPhone = ""
    @State private var newAddress = ""
    var onAddContact: (() -> Void)?

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            
            VStack {
                Text("Add Contact")
                    .font(.title)
                    .padding()
                VStack{
                    TextField("Name", text: $newName)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Email", text: $newEmail)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Phone", text: $newPhone)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Address", text: $newAddress)
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
                        let newContact = Contact(context: viewContext)
                        newContact.name = newName
                        newContact.email = newEmail
                        newContact.phone = newPhone
                        newContact.address = newAddress
                        do {
                            try viewContext.save()
                            onAddContact?()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Failed to add contact: \(error)")
                        }
                    }
                }
                .padding()
                .frame(width: 250, height: 50)
            }
            .navigationTitle("Add Contact")
        }
    }
}


struct CustomContactSegmentedControl: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    selectedTab = 0
                }
            }) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 15))
                    Text("Contacts")
                }
                .foregroundColor(selectedTab == 0 ? Color("CostumGray") : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: 30)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(selectedTab == 0 ? Color("CostumGray") : Color.clear),
                    alignment: .top
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: {
                withAnimation {
                    selectedTab = 1
                }
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 15))
                    Text("Users")
                }
                .foregroundColor(selectedTab == 1 ? Color("CostumGray") : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: 30)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(selectedTab == 1 ? Color("CostumGray") : Color.clear),
                    alignment: .top
                )
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .frame(height: 30)
    }
}



