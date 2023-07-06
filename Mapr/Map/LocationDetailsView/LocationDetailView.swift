import SwiftUI
import MapKit
import CoreData

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

    init(project: Project, locations: Binding<[MKMapItem]>) {
        guard let location = project.location else {
            // Handle the case where the project doesn't have a location.
            // This is just an example. You'll need to decide what's appropriate for your app.
            let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            let placemark = MKPlacemark(coordinate: coordinate)
            _mapItem = State(initialValue: MKMapItem(placemark: placemark))
            _locations = locations
            _projectName = State(initialValue: "Unknown")
            _projectDescription = State(initialValue: "Unknown")
            _project = ObservedObject(initialValue: project) // Store the project in a @State variable
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        _mapItem = State(initialValue: MKMapItem(placemark: placemark))
        _locations = locations
        _projectName = State(initialValue: project.projectName ?? "")
        _projectDescription = State(initialValue: project.projectDescription ?? "")
        _project = ObservedObject(initialValue: project) // Store the project in a @State variable
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

    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ZStack {
                        
                        
                        MapView(mapItem: mapItem, addressTitle: addressTitle)
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
                        .popover(isPresented: $showOptions) {
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
                        #if !os(iOS)
                            case 4:
                                PreviewView(project: project, timeTrackerViewModel: timeTrackerViewModel, materialsViewModel: materialsViewModel, checklistViewModel: checklistViewModel)
                        #endif
                            
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
        

        var body: some View {
                List {
                    //Button(action: {
                    //}) {
                       // HStack {
                      //      Image(systemName: "trash")
                     //           .foregroundColor(.red)
                    //   Text("Delete Project")
                    //         .foregroundColor(.red)
                     //   }
                    //}
                    //Button(action: {
                        // Call your export function here
                    //}) {
                        //HStack {
                       //     Image(systemName: "doc.text")
                      //      Text("Export as PDF")
                     //   }
                    //}
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
                .navigationTitle("Options")
                .background(Color.clear)
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
            .background(Color("AccentColor"))
        }
    }
    
    
}
    
