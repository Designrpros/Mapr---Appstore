import SwiftUI
import MapKit
import CoreData
import CloudKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct MapListView: View {
    @State private var searchText = ""
    @State private var locations: [MKMapItem] = []
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.projectName, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>

    @State private var searchResults: [MKMapItem] = []
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedProject: Project? = nil
    @State private var isLinkActive = false
    @State private var showingSettings = false
    @StateObject var userSelection = UserSelection()
    
    var body: some View {
            VStack {
                HStack {
                    TextField("Search...", text: $searchText, onCommit: {
                        searchLocations()
                    })
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                    
                    Button(action: {
                        searchLocations()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding([.horizontal, .top])
                
                List {
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults, id: \.self) { mapItem in
                            HStack {
                                LocationIndicator(mapItem: mapItem)
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(mapItem.name ?? "Unknown")
                                        .font(.headline)
                                    Text(mapItem.placemark.title ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    selectedProject = createProject(from: mapItem)
                                    isLinkActive = true
                                }){
                                    Image(systemName: "mappin")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }.buttonStyle(BorderlessButtonStyle())

                            }
                            .background(
                                Group {
                                    if let selectedProject = selectedProject {
                                        NavigationLink(destination: LocationDetailView(project: selectedProject, locations: $locations, userSelection: userSelection)) {
                                            EmptyView()
                                        }
                                    }
                                }
                            )
                        }
                        
                    }
                    
                    Section(header: VStack(alignment: .leading) {
                        Text("projects")
                    }) {
                        // Add the "All Projects" button here
                        NavigationLink(destination: AllProjectsMapView()) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text("All Projects")
                                        .font(.headline)
                                    Text("Display all projects on the map")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        ForEach(projects.filter { !$0.isFinished }, id: \.self) { project in
                            if let location = project.location {
                                NavigationLink(destination: LocationDetailView(project: project, locations: $locations, userSelection: userSelection)) {
                                    HStack {
                                        Image(systemName: "house.fill")
                                            .foregroundColor(.purple)
                                            .frame(width: 30, height: 30)
                                        VStack(alignment: .leading) {
                                            Text(location.name ?? "Unknown") // Use the name from your Location entity
                                                .font(.headline)
                                            Text("\(location.postalCode ?? ""), \(location.city ?? ""), \(location.country ?? "")") // Display the postal code, city, and country
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        // Delete the project associated with the location
                                        if let project = location.project {
                                            viewContext.delete(project)
                                        }
                                        // Delete the location from Core Data
                                        viewContext.delete(location)
                                        do {
                                            try viewContext.save()
                                        } catch {
                                            print("Failed to delete location: \(error)")
                                        }
                                    }) {
                                        Text("Delete Location")
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                    Section(header: Text("Finished Projects")) {
                        ForEach(projects.filter { $0.isFinished }, id: \.self) { project in
                            if let location = project.location {
                                NavigationLink(destination: LocationDetailView(project: project, locations: $locations, userSelection: userSelection)) {
                                    HStack {
                                        Image(systemName: "house.fill")
                                            .foregroundColor(.yellow)
                                            .frame(width: 30, height: 30)
                                        VStack(alignment: .leading) {
                                            Text(location.name ?? "Unknown") // Use the name from your Location entity
                                                .font(.headline)
                                            Text("\(location.postalCode ?? ""), \(location.city ?? ""), \(location.country ?? "")") // Display the postal code, city, and country
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.onAppear {
                print(projects)
            }
            .toolbar() {
                ToolbarItem(placement: .automatic) {
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gear")
                            }
                        }
                    }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    
    private func createProject(from mapItem: MKMapItem) -> Project {
        let project = Project(context: viewContext)
        let location = Location(context: viewContext)

        // Set the properties of the location based on the mapItem
        location.name = mapItem.name
        location.postalCode = mapItem.placemark.postalCode
        location.city = mapItem.placemark.locality
        location.country = mapItem.placemark.country
        location.latitude = mapItem.placemark.coordinate.latitude
        location.longitude = mapItem.placemark.coordinate.longitude

        // Associate the location with the project
        project.location = location

        // Set the other properties of the project
        project.projectName = mapItem.name

        // Create a new CKRecord for the project
        let newRecord = CKRecord(recordType: "Project")
        // Save the CKRecord's recordID to the project
        project.recordID = newRecord.recordID.recordName

        print("Saving project...")
        do {
            try viewContext.save()
            print("Project saved successfully.")
        } catch {
            print("Failed to save project: \(error)")
        }

        // Update the search results to remove the newly saved location
        if let index = searchResults.firstIndex(where: { $0.name == mapItem.name }) {
            searchResults.remove(at: index)
        }

        // Clear the search text
        searchText = ""

        return project
    }




    
    private func searchLocations() {
        DispatchQueue.global(qos: .userInitiated).async {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = self.searchText
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                guard let response = response else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    let savedLocationNames = Set(self.projects.map { $0.location?.name ?? "" })
                    self.searchResults = response.mapItems.filter { mapItem in
                        guard let name = mapItem.name else { return false }
                        return !savedLocationNames.contains(name)
                    }
                }
            }
        }
    }


    
    private func deleteAllProjects() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = Location.fetchRequest()
        
        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        do {
            try viewContext.execute(batchDeleteRequest1)
            try viewContext.execute(batchDeleteRequest2)
            try viewContext.save()
        } catch {
            print("Error deleting all projects and locations: \(error)")
        }
    }

    
    struct LocationIndicator: View {
        let mapItem: MKMapItem
        
        var body: some View {
            let category = mapItem.pointOfInterestCategory
            
            if category == .publicTransport {
                return AnyView(Image(systemName: "bus").foregroundColor(.red))
            } else if category == .park {
                return AnyView(Image(systemName: "leaf").foregroundColor(.green))
            } else if category == .school {
                return AnyView(Image(systemName: "book").foregroundColor(.blue))
            } else if category == nil {
                return AnyView(Image(systemName: "house").foregroundColor(.purple))
            } else {
                return AnyView(Image(systemName: "mappin.circle.fill").foregroundColor(.gray))
            }
        }
    }
}
