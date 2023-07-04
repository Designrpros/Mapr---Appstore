import SwiftUI
import CoreData

struct PreviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @StateObject private var timeTrackerViewModel = TimeTrackerViewModel()
    @StateObject private var materialsViewModel = MaterialsViewModel()
    @StateObject private var checklistViewModel = ChecklistViewModel()
    
    // Date formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    // Number formatter
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }
    
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading)  {
                HStack{
                    VStack(alignment: .leading){
                        Text(project.location?.name ?? "No Address Title")
                            .font(.title)
                        
                        Text("\(project.location?.postalCode ?? ""), \(project.location?.city ?? ""), \(project.location?.country ?? "")")
                            .font(.subheadline)
                        
                        // Project Description
                        Text(project.projectDescription.bound)
                            .padding(.top)
                    }
                    
                    Spacer()
                    
                    // Contact Information
                    VStack(alignment: .leading) {
                        Text("Contact Information")
                            .font(.headline)
                            .padding(.top)
                        
                        if let contact = project.contact {
                            VStack(alignment: .leading){
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text("\(contact.name ?? "Unknown")")
                                }
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("\(contact.email ?? "Unknown")")
                                }
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(" \(contact.phone ?? "Unknown")")
                                }
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(" \(contact.address ?? "Unknown")")
                                }
                            }.padding(.bottom)
                        }
                    }
                    
                    
                }
                
                // Gallery
                VStack(alignment: .leading) {
                    Text("Gallery")
                        .font(.headline)
                        .padding(.top)
                    
                    if let imagesSet = project.galleryImage as? Set<GalleryImage>, !imagesSet.isEmpty {
                        let imagesArray = Array(imagesSet)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                            ForEach(imagesArray, id: \.id) { galleryImage in
                                if let imageData = galleryImage.imageData, let nsImage = NSImage(data: imageData) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                        }
                    } else {
                        Text("No images")
                    }
                }
                
                // TimeTracker data
                VStack(alignment: .leading) {
                    Text("Time Tracker")
                        .font(.headline)
                        .padding(.top)
                    HStack {
                        Text("Date")
                        Spacer()
                        Text("Hours")
                        Spacer()
                        Text("Notes")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    ForEach(timeTrackerViewModel.timeEntries, id: \.id) { timeEntry in
                        HStack {
                            Text(dateFormatter.string(from: timeEntry.date ?? Date()))
                            Spacer()
                            Text(numberFormatter.string(from: NSNumber(value: timeEntry.hours)) ?? "")
                            Spacer()
                            Text(timeEntry.notes ?? "")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    }
                }
                // Materials data
                VStack(alignment: .leading) {
                    Text("Materials")
                        .font(.headline)
                        .padding(.top)
                    HStack {
                        Text("Number")
                        Spacer()
                        Text("Amount")
                        Spacer()
                        Text("Description")
                        Spacer()
                        Text("Price")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    ForEach(materialsViewModel.materials, id: \.id) { material in
                        HStack {
                            Text("\(material.number)")
                            Spacer()
                            Text("\(material.amount)")
                            Spacer()
                            Text(material.materialDescription ?? "")
                            Spacer()
                            Text(numberFormatter.string(from: NSNumber(value: material.price)) ?? "")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    }
                }
                
                // Checklist data
                VStack(alignment: .leading) {
                    Text("Checklist")
                        .font(.headline)
                        .padding(.top)
                    HStack {
                        Text("Item")
                        Spacer()
                        Text("Checked")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    ForEach(checklistViewModel.checklistItems, id: \.id) { checklistItem in
                        checklistRow(checklistItem: checklistItem)
                        if let childrenSet = checklistItem.children as? Set<ChecklistItem> {
                            let childrenArray = Array(childrenSet).sorted(by: { $0.creationDate ?? Date() < $1.creationDate ?? Date() })
                            ForEach(childrenArray, id: \.id) { child in
                                checklistRow(checklistItem: child)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                timeTrackerViewModel.setup(viewContext: viewContext, project: project)
                materialsViewModel.setup(viewContext: viewContext, project: project)
                checklistViewModel.setup(viewContext: viewContext, project: project)
            }
        }
    }
    
    private func checklistRow(checklistItem: ChecklistItem) -> some View {
        HStack {
            Text(checklistItem.item ?? "")
            Spacer()
            Text(checklistItem.isChecked ? "Checked" : "Unchecked")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(5)
    }
}

