import SwiftUI
import MapKit
import CoreData
import CloudKit

class ContactState: ObservableObject {
    @Published var selectedContact: Contact?
}


struct LocationDetailView: View {
    @State private var mapItem: MKMapItem
    @Binding var locations: [MKMapItem]
    @State private var showOptions = false
    @State private var selectedTab = 0
    @State private var isShowingNewView = false
    @State private var refreshID = UUID()
    @State private var selectedUsers: [User] = []
    @State private var showingAddUserModal = false
    @ObservedObject var userSelection: UserSelection

    @FetchRequest(
        entity: UserEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \UserEntity.name, ascending: true)]
    ) var userEntities: FetchedResults<UserEntity>

    var coreDataUsers: [User] {
        userEntities.map { userEntity in
            retrieveUserFromCoreData(userEntity: userEntity)
        }
    }

    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.projectName, ascending: true)],
        predicate: NSPredicate(format: "isFinished == %@", NSNumber(value: false))
    ) var unfinishedProjects: FetchedResults<Project>

    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.projectName, ascending: true)],
        predicate: NSPredicate(format: "isFinished == %@", NSNumber(value: true))
    ) var finishedProjects: FetchedResults<Project>

    @Environment(\.managedObjectContext) var managedObjectContext

    init(project: Project, locations: Binding<[MKMapItem]>, userSelection: UserSelection) {
        self.userSelection = userSelection
        _locations = locations
        _projectName = State(initialValue: project.projectName ?? "")
        _projectDescription = State(initialValue: project.projectDescription ?? "")
        _project = ObservedObject(initialValue: project) // Store the project in a @State variable

        // Initialize the mapItem and location properties with default values
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let defaultPlacemark = MKPlacemark(coordinate: defaultCoordinate)
        _mapItem = State(initialValue: MKMapItem(placemark: defaultPlacemark))

        if let location = project.location {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let placemark = MKPlacemark(coordinate: coordinate)
            _mapItem = State(initialValue: MKMapItem(placemark: placemark))
            self.location = location
        } else {
            // Provide a default value for `location` here
            self.location = Location() // Replace `Location()` with an appropriate default value
        }
    }


    @ObservedObject var project: Project
    @State private var isEditingDescription = false
    @State private var isEditingName = false
    @State private var projectName: String
    @State private var projectDescription: String
    
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    
    @State private var addressTitle: String = ""
    @State private var addressSubtitle: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedContact: Contact?
    
    
    @StateObject private var timeTrackerViewModel = TimeTrackerViewModel()
    @StateObject private var materialsViewModel = MaterialsViewModel()
    @StateObject private var checklistViewModel = ChecklistViewModel()
    
    @Environment(\.managedObjectContext) var context

    var location: Location
    
#if os(macOS)
    let projectManager = ProjectManager()
#endif
    
    var body: some View {
        
        ZStack {
            ScrollView {
                VStack {
                    ZStack {
                        MapView(project: project)
                            .frame(height: 300)
                            .cornerRadius(20)
                            .padding()
                        VStack{
                            HStack{
                                Spacer()
                                StreetView(coordinate: mapItem.placemark.coordinate)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(20)
                                    .padding()
                                
                            }
                            Spacer()
                            
                        }
                    }
                    HStack {
                        VStack (alignment: .leading) {
                            if isEditingName {
                                TextField("Address Title", text: $addressTitle, onCommit:  {
                                    isEditingName = false
                                    project.addressTitle = addressTitle
                                    do {
                                        try managedObjectContext.save()
                                    } catch {
                                        print("Failed to save address title: \(error)")
                                    }
                                })
                                .font(.title)
                                .textFieldStyle(.plain)
                            } else {
                                Text(addressTitle)
                                    .font(.title)
                                    .onTapGesture {
                                        isEditingName = true
                                    }
                            }
                            
                            if isEditingDescription {
                                TextField("Address Subtitle", text: $addressSubtitle, onCommit:  {
                                    isEditingDescription = false
                                    project.addressSubtitle = addressSubtitle
                                    do {
                                        try managedObjectContext.save()
                                    } catch {
                                        print("Failed to save address subtitle: \(error)")
                                    }
                                })
                                .font(.subheadline)
                                .textFieldStyle(.plain)
                            } else {
                                Text(addressSubtitle)
                                    .font(.subheadline)
                                    .onTapGesture {
                                        isEditingDescription = true
                                    }
                            }
                        }.padding()

                        
                        Spacer()
                        
                        //
                
#if os(macOS)
                        ForEach(selectedUsers, id: \.id) { user in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .help(user.name) // Show the user's name when hovering over the circle
                            }
                            .contextMenu { // Add a context menu to the HStack
                                Button(action: {
                                    // Remove the user from the selectedUsers array
                                    selectedUsers.removeAll(where: { $0.id == user.id })
                                    // Find the corresponding UserEntity
                                    if let userEntity = userEntities.first(where: { $0.id?.uuidString == user.id }) {
                                        // Also remove the user from the project
                                        userEntity.removeFromProject(project)
                                        do {
                                            try managedObjectContext.save()
                                        } catch {
                                            print("Failed to remove user from project: \(error)")
                                        }
                                    }
                                }) {
                                    Label("Remove User", systemImage: "trash")
                                }.buttonStyle(BorderlessButtonStyle())


                            }
                        }

/* THIS IS RELEVANT CODE FOR DTS
                        Button(action: {
                            showingAddUserModal = true
                        }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.systemGray))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: $showingAddUserModal) {
                            AddUserModal(project: project, managedObjectContext: managedObjectContext, userSelection: userSelection, selectedUsers: $selectedUsers, userEntities: userEntities)
                        }
*/

#endif
                        //Button(action: {
                          //  isShowingNewView = true
                        //}) {
                            //Image(systemName: "doc.text")
                            //    .font(.system(size: 20))
                          //      .foregroundColor(Color(.systemGray))
                        //}
                        //.padding()
                        //.buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            showOptions.toggle()
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20))
                                .foregroundColor(Color(.systemGray))
                        }
                        .padding()
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: $showOptions) {
                            OptionsView(refreshID: $refreshID, project: project)
                        }
                    }
                    CustomSegmentedControl(selectedTab: $selectedTab)
                        switch selectedTab {
                        case 0:
                            DetailsView(project: project)
                                .onAppear(perform: saveContext)
                        case 1:
                            TimeTrackerView(project: project, viewModel: timeTrackerViewModel)
                        case 2:
                            MaterialsView(project: project, viewModel: materialsViewModel)
                        case 3:
                            ChecklistView(project: project, viewModel: checklistViewModel)
                            case 4:
                                PreviewView(project: project, timeTrackerViewModel: timeTrackerViewModel, materialsViewModel: materialsViewModel, checklistViewModel: checklistViewModel)
                            
                        default:
                            EmptyView()
                        }

                    
                }
                .navigationTitle("Location Detail")
                .blur(radius: isShowingNewView ? 5 : 0)
                .disabled(isShowingNewView)
                
                if isShowingNewView {
                    NewChildView(isShowing: $isShowingNewView)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.background(Color.black.opacity(0.5))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onAppear {
                // Load the selectedUsers array from CoreData when the view appears
                selectedUsers = project.users?.allObjects.compactMap { $0 as? UserEntity }.map { retrieveUserFromCoreData(userEntity: $0) } ?? []
            }

            .onAppear {
                guard let location = project.location else {
                    return
                }
                addressTitle = location.name ?? "No Address"
                addressSubtitle = "\(location.postalCode ?? ""), \(location.city ?? ""), \(location.country ?? "")"
                contactName = project.contact?.name ?? ""
                contactEmail = project.contact?.email ?? ""
                contactPhone = project.contact?.phone ?? ""
            }
        }
    }
    
    func saveContext() {
        do {
            try managedObjectContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    
struct OptionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var refreshID: UUID
    var project: Project
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddContact = false

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            VStack {
                List {
                    Button(action: {
                        // Toggle the isFinished property of the project
                        project.isFinished.toggle()
                        do {
                            try viewContext.save()
                            // Toggle the refreshID to force a refresh of the view
                            refreshID = UUID()
                        } catch {
                            // Handle the error here
                            print("Failed to update project status: \(error)")
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            // Change the displayed text based on the isFinished property
                            Text(project.isFinished ? "Mark as active" : "Mark as finished")
                        }
                    }
                }
                .frame(minWidth: 100, idealWidth: 300, maxWidth: .infinity, minHeight: 100, idealHeight: 250, maxHeight: .infinity)

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                }
                .padding()
            }
            .navigationTitle("Options")
        }
    }
}


    
    
    struct NewChildView: View {
        @Environment(\.presentationMode) var presentationMode
        @State private var selectedTab = 0
        @Binding var isShowing: Bool
        @State private var searchText = ""
        
        var body: some View {
            VStack {
               // NoteListView(isShowing: $isShowing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AccentColor1"))
        }
    }
}
    

// this view should display the content of users view, the added users in users view should display here

struct AddUserModal: View {
    var project: Project
    var managedObjectContext: NSManagedObjectContext
    @ObservedObject var userSelection: UserSelection
    @Binding var selectedUsers: [User]
    var userEntities: FetchedResults<UserEntity>
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var allUsers: [User] = []
    
#if os(macOS)
    let projectManager = ProjectManager()
#endif
    
    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .background(Color(.darkGray))
                .cornerRadius(10)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    fetchUsers(searchText: newValue, in: managedObjectContext)
                }.padding()

            List {
                ForEach(userEntities.filter { userEntity in
                                searchText.isEmpty ||
                                userEntity.name?.lowercased().contains(searchText.lowercased()) ?? false ||
                                userEntity.email?.lowercased().contains(searchText.lowercased()) ?? false
                            }, id: \.self) { userEntity in
                                // Convert UserEntity to User
                                let user = retrieveUserFromCoreData(userEntity: userEntity)
                    Button(action: {
                        // Add the user to the selectedUsers array when selected
                        if !selectedUsers.contains(where: { $0.id == user.id }) {
                            let newUser = User(
                                id: UUID().uuidString, // Convert UUID to String
                                name: user.name,
                                email: user.email,
                                role: user.role,
                                recordID: user.recordID,
                                record: user.record
                            )
                            selectedUsers.append(newUser)
                            // Find the corresponding UserEntity
                            if let userEntity = userEntities.first(where: { $0.id?.uuidString == user.id }) {
                                // Also add the user to the project
                                userEntity.addToProject(project)
                                do {
                                    try managedObjectContext.save()
                                } catch {
                                    print("Failed to add user to project: \(error)")
                                }
                            }
                        }
#if os(macOS)
                        // Share the project with the newly added user
                        projectManager.shareProjectWithSelectedUsers(project: project, selectedUsers: selectedUsers)
#endif
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())

                }
            }
            .frame(minWidth: 100, idealWidth: 300, maxWidth: .infinity, minHeight: 100, idealHeight: 250, maxHeight: .infinity)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
            }
            .padding()
        }
        .navigationTitle("Select User")
    }

    func fetchUsers(searchText: String, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR email CONTAINS[cd] %@", searchText, searchText)
        do {
            let userEntities = try context.fetch(fetchRequest)
            print("Fetched UserEntities: \(userEntities)") // Print the fetched UserEntity objects
            let users = userEntities.map { retrieveUserFromCoreData(userEntity: $0) }
            print("Mapped Users: \(users)") // Print the mapped User objects
            allUsers = users // Update allUsers with the fetched users
        } catch {
            print("Failed to fetch users: \(error)")
            allUsers = [] // Update allUsers to be an empty array
        }
    }



    func recordToUser(_ record: CKRecord) -> User {
        return User(
            id: UUID().uuidString,
            name: record["username"] as? String ?? "Unknown",
            email: record["email"] as? String ?? "Unknown",
            role: record["role"] as? String ?? "Unknown",
            recordID: record.recordID,
            record: record
        )
    }
}


