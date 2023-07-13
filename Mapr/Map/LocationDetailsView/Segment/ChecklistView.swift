import SwiftUI
import CoreData

class ChecklistViewModel: ObservableObject {
    @Published var checklistItems: [ChecklistItem] = []
    private var viewContext: NSManagedObjectContext?
    private var project: Project?
    @NSManaged public var children: NSSet?


    func setup(viewContext: NSManagedObjectContext, project: Project) {
        self.viewContext = viewContext
        self.project = project
        fetchChecklistItems()
    }

    func fetchChecklistItems() {
        guard let viewContext = viewContext, let project = project else { return }
        
        let fetchRequest: NSFetchRequest<ChecklistItem> = ChecklistItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChecklistItem.creationDate, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "project == %@", project.objectID)

        do {
            checklistItems = try viewContext.fetch(fetchRequest)
            print(checklistItems) // Print the fetched items
        } catch {
            print("Failed to fetch checklist items: \(error)")
        }
    }


    func addItems(from customChecklist: CustomChecklist) {
        guard let viewContext = viewContext else { return }
        
        for customChecklistItem in customChecklist.items as? Set<CustomChecklistItem> ?? [] {
            let newChecklistItem = createChecklistItem(from: customChecklistItem, in: viewContext)
            newChecklistItem.project = project
        }
        
        saveContext()
    }

    private func createChecklistItem(from customChecklistItem: CustomChecklistItem, in context: NSManagedObjectContext) -> ChecklistItem {
        let newChecklistItem = ChecklistItem(context: context)
        newChecklistItem.id = UUID()
        newChecklistItem.item = customChecklistItem.item
        newChecklistItem.isChecked = customChecklistItem.isChecked
        newChecklistItem.creationDate = Date() // Set the creation date to the current date

        if let customChildern = customChecklistItem.childern as? Set<CustomChecklistItem> {
            for customChild in customChildern {
                let newChild = createChecklistItem(from: customChild, in: context)
                newChecklistItem.addToChildren(newChild)
            }
        }

        return newChecklistItem
    }


    private func flatten(items: [ChecklistItem]) -> [ChecklistItem] {
        var flattenedItems: [ChecklistItem] = []
        for item in items {
            flattenedItems.append(item)
            if let childrenSet = item.children as? Set<ChecklistItem> {
                let childrenArray = Array(childrenSet)
                flattenedItems.append(contentsOf: flatten(items: childrenArray))
            }
        }
        return flattenedItems
    }


    func saveContext() {
        guard let viewContext = viewContext else { return }
        
        do {
            try viewContext.save()
            fetchChecklistItems() // Fetch the checklist items again after saving the context.
        } catch {
            print("Failed to save context: \(error)") // Print the error
        }
    }

}


struct ChecklistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @ObservedObject var viewModel: ChecklistViewModel
    @State private var selectedChecklist: CustomChecklist?
    @State private var showingCustomChecklistModal = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Checked")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                Text("Actions")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
            }
            .font(.headline)
            
            ForEach(viewModel.checklistItems, id: \.id) { checklistItem in
                checklistRow(checklistItem: checklistItem)
                if let childrenSet = checklistItem.children as? Set<ChecklistItem> {
                    let childrenArray = Array(childrenSet).sorted(by: { $0.creationDate ?? Date() < $1.creationDate ?? Date() })
                    ForEach(childrenArray, id: \.id) { child in
                        checklistRow(checklistItem: child)
                            .padding(.leading, 20)
                    }
                }
            }
            
            
            
            
            Button(action: {
                let newChecklistItem = ChecklistItem(context: self.viewContext)
                newChecklistItem.id = UUID() // Assign a new UUID to each ChecklistItem object
                newChecklistItem.item = ""
                newChecklistItem.isChecked = false
                newChecklistItem.project = project
                print(newChecklistItem) // Print the newChecklistItem
                viewModel.saveContext()
            }) {
                Text("Add Row")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 10)
        }
        .padding()
        .onAppear {
            viewModel.setup(viewContext: viewContext, project: project)
            if let selected = selectedChecklist {
                for item in selected.items as? Set<CustomChecklistItem> ?? [] {
                    let newChecklistItem = ChecklistItem(context: viewContext)
                    newChecklistItem.id = UUID()
                    newChecklistItem.item = item.item
                    newChecklistItem.isChecked = item.isChecked
                    newChecklistItem.project = project
                    viewModel.saveContext()
                }
                selectedChecklist = nil
            }
        }
    }
    
    private func checklistRow(checklistItem: ChecklistItem) -> some View {
        VStack {
            HStack(spacing: 35) {
                Toggle("", isOn: Binding(get: {
                    checklistItem.isChecked
                }, set: {
                    checklistItem.isChecked = $0
                    viewModel.saveContext()
                }))
                .padding()
                .cornerRadius(5)

                Spacer()
                
                Button(action: {
                    if let parent = checklistItem.parent {
                        parent.removeFromChildren(checklistItem) // Remove the item from the parent's children
                        if parent.children?.count == 0 {
                            viewContext.delete(parent)
                        }
                    } else {
                        viewContext.delete(checklistItem)
                    }
                    viewModel.saveContext() // Call saveContext on the viewModel
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.body)
                }
                .buttonStyle(BorderlessButtonStyle())

                //Implement a button to add and chose costum checklist here
                
                Button(action: {
                    showingCustomChecklistModal = true
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                        .font(.body)
                }
                .buttonStyle(BorderlessButtonStyle())
                .sheet(isPresented: $showingCustomChecklistModal) {
                    CustomChecklistSelectionView(selectedChecklist: $selectedChecklist, viewModel: viewModel, dismiss: {
                        self.showingCustomChecklistModal = false
                    })
                }

                if checklistItem.parent == nil {
                    Button(action: {
                        let newChecklistItem = ChecklistItem(context: self.viewContext)
                        newChecklistItem.id = UUID() // Assign a new UUID to each ChecklistItem object
                        newChecklistItem.item = ""
                        newChecklistItem.isChecked = false
                        newChecklistItem.creationDate = Date() // Set the creation date to the current date
                        checklistItem.addToChildren(newChecklistItem) // Manually add the new item to the parent's children
                        newChecklistItem.parent = checklistItem // Set the parent of the new item
                        viewModel.saveContext() // Call saveContext on the viewModel
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            .cornerRadius(5)
            .frame(maxWidth: .infinity)

            TextField("Description", text: Binding(get: {
                checklistItem.item ?? ""
            }, set: {
                checklistItem.item = $0
                try? viewContext.save()
            }))
            .frame(maxWidth: .infinity)
            .padding()
            .cornerRadius(5)
            .textFieldStyle(PlainTextFieldStyle())
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(5)
    }

}

struct CustomChecklistSelectionView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomChecklist.title, ascending: true)],
        animation: .default)
    private var checklists: FetchedResults<CustomChecklist>
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @Binding var selectedChecklist: CustomChecklist?
    var viewModel: ChecklistViewModel
    var dismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                dismiss()
            }
            
            VStack {
                HStack {
                    TextField("Search...", text: $searchText)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding([.horizontal, .top])
                
                List {
                    ForEach(filteredChecklists, id: \.self) { checklist in
                        HStack {
                            Button(action: {
                                viewModel.addItems(from: checklist)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .resizable()
                                        .frame(width: 20, height: 20) // Adjusted the icon size
                                    VStack(alignment: .leading) {
                                        Text(checklist.title ?? "Unknown")
                                            .font(.headline)
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            Spacer()
                        }
                        .contextMenu {
                            Button(action: {
                                viewContext.delete(checklist)
                                do {
                                    try viewContext.save()
                                } catch {
                                    print("Failed to delete checklist: \(error)")
                                }
                            }) {
                                Text("Delete Checklist")
                                Image(systemName: "trash")
                            }
                        }
                    }
                }.frame(minWidth: 100, idealWidth: 300, maxWidth: .infinity, minHeight: 100, idealHeight: 250, maxHeight: .infinity)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                }.padding()
            }
            .navigationTitle("Checklists")
        }
    }
    
    var filteredChecklists: [CustomChecklist] {
        if searchText.isEmpty {
            return Array(checklists)
        } else {
            return Array(checklists).filter {
                $0.title?.contains(searchText) ?? false
            }
        }
    }
}




