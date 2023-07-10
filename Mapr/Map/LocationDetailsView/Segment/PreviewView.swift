import SwiftUI
import CoreData

#if os(macOS)

struct PreviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @ObservedObject var timeTrackerViewModel: TimeTrackerViewModel
    @ObservedObject var materialsViewModel: MaterialsViewModel
    @ObservedObject var checklistViewModel: ChecklistViewModel
    
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
    
    
    // Add this state to manage showing an alert when the PDF is saved
    @State private var isPDFSaved = false
    
    var body: some View {
        Button("Save as PDF") {
            saveAsPDF(pdfView: previewContent)
        }
        
        ScrollView {
                previewContent
        }
        
    }
    
    
    @ViewBuilder
    var previewContent: some View {
        VStack (alignment: .leading)  {
            HStack{
                VStack(alignment: .leading){
                    Text(project.location?.name ?? "No Address Title")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading) // Add this line

                    Text("\(project.location?.postalCode ?? ""), \(project.location?.city ?? ""), \(project.location?.country ?? "")")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading) // Add this line

                    // Project Description
                    Text(project.projectDescription.bound)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading) // Add this line
                }

                Spacer()

                // Contact Information
                VStack(alignment: .leading) {
                    Text("Contact Information")
                        .font(.headline)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading) // Add this line

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
                          .frame(maxWidth: .infinity, alignment: .leading) // Add this line
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

    private func saveAsPDF(pdfView: some View) {
        // Estimate the height of your content
        let itemHeight = CGFloat(50) // Estimate of the height of each item in your lists
        let otherContentHeight = CGFloat(500) // Estimate of the height of the other content

        let timeEntriesHeight = itemHeight * CGFloat(timeTrackerViewModel.timeEntries.count)
        let materialsHeight = itemHeight * CGFloat(materialsViewModel.materials.count)
        let checklistItemsHeight = itemHeight * CGFloat(checklistViewModel.checklistItems.count)

        let contentHeight = timeEntriesHeight + materialsHeight + checklistItemsHeight + otherContentHeight

        let pdfWidth = CGFloat(595) // Width of a standard A4 page
        let pdfHeight = CGFloat(842) // Height of a standard A4 page
        let pageCount = Int(ceil(contentHeight / pdfHeight)) // Calculate the number of pages

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let directoryURL = panel.url {
                let pdfURL = directoryURL.appendingPathComponent("preview.pdf")

                let renderer = ImageRenderer(content: pdfView)
                renderer.render { size, context in
                    var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    guard let pdfContext = CGContext(pdfURL as CFURL, mediaBox: &box, nil) else {
                        return
                    }

                    let margin = CGFloat(20) // Adjust this to change the margin size
                    let contentRect = CGRect(x: margin, y: margin, width: box.width - 2 * margin, height: box.height - 2 * margin)

                    // Draw the rest of the pages
                    for pageIndex in 0..<pageCount {
                        // Create a new view for each page
                        let pageView = pdfView
                            .frame(width: contentRect.width, height: contentRect.height)
                            .offset(y: -CGFloat(pageIndex) * contentRect.height)

                        let renderer = ImageRenderer(content: pageView)
                        guard let cgImage = renderer.cgImage else { continue }

                        pdfContext.beginPDFPage(nil)
                        pdfContext.draw(cgImage, in: contentRect)
                        pdfContext.endPDFPage()
                    }

                    pdfContext.closePDF()

                    DispatchQueue.main.async {
                        isPDFSaved = true
                    }
                }
            }
        }
    }

}
#endif
