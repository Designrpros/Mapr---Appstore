//
//  ChecklistListView.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//

import SwiftUI
import CoreData

class CustomChecklistViewModel: ObservableObject {
    @Published var checklistItems: [CustomChecklistItem] = []
    private var viewContext: NSManagedObjectContext?
    private var checklist: CustomChecklist?

    func setup(viewContext: NSManagedObjectContext, checklist: CustomChecklist) {
        self.viewContext = viewContext
        self.checklist = checklist
        fetchChecklistItems()
    }

    func fetchChecklistItems() {
        guard let viewContext = viewContext, let checklist = checklist else { return }
        
        let fetchRequest: NSFetchRequest<CustomChecklistItem> = CustomChecklistItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CustomChecklistItem.creationDate, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "checklist == %@", checklist.objectID)

        do {
            checklistItems = try viewContext.fetch(fetchRequest)
            print(checklistItems) // Print the fetched items
        } catch {
            print("Failed to fetch checklist items: \(error)")
        }
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



struct CustomChecklistItemDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var checklist: CustomChecklist
    @ObservedObject var viewModel: CustomChecklistViewModel

    init(checklist: CustomChecklist, viewContext: NSManagedObjectContext) {
        self.checklist = checklist
        self.viewModel = CustomChecklistViewModel()
        self.viewModel.setup(viewContext: viewContext, checklist: checklist)
    }
    
    
    
    var body: some View {
        ScrollView{
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Item")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
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
                if let childrenSet = checklistItem.childern as? Set<CustomChecklistItem> {
                    let childrenArray = Array(childrenSet).sorted(by: { $0.creationDate ?? Date() < $1.creationDate ?? Date() })
                    ForEach(childrenArray, id: \.id) { child in
                        checklistRow(checklistItem: child)
                            .padding(.leading, 20)
                    }
                }
            }
            
            Button(action: {
                let newChecklistItem = CustomChecklistItem(context: self.viewContext)
                newChecklistItem.id = UUID() // Assign a new UUID to each ChecklistItem object
                newChecklistItem.item = ""
                newChecklistItem.isChecked = false
                newChecklistItem.checklist = checklist
                checklist.addToItems(newChecklistItem) // Add the new item to the checklist's items set
                print("New Checklist Item Created: \(newChecklistItem)") // Print the newChecklistItem
                viewModel.saveContext()
                print("Context Saved") // Print after saving the context
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
            viewModel.setup(viewContext: viewContext, checklist: checklist)
        }
    }
}
    
        private func checklistRow(checklistItem: CustomChecklistItem) -> some View {
            HStack(spacing: 0) {
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
                
                Toggle("", isOn: Binding(get: {
                    checklistItem.isChecked
                }, set: {
                    checklistItem.isChecked = $0
                    viewModel.saveContext()
                }))
                .frame(maxWidth: .infinity)
                .padding()
                .cornerRadius(5)
                
                HStack(spacing: 20) {
                    Button(action: {
                        if let parent = checklistItem.parent {
                            parent.removeFromChildern(checklistItem) // Use the generated accessor method to remove the item from the parent's children set
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
                    
                    if checklistItem.parent == nil {
                        Button(action: {
                            let newChecklistItem = CustomChecklistItem(context: self.viewContext)
                            newChecklistItem.id = UUID() // Assign a new UUID to each ChecklistItem object
                            newChecklistItem.item = ""
                            newChecklistItem.isChecked = false
                            newChecklistItem.creationDate = Date() // Set the creation date to the current date
                            checklistItem.addToChildern(newChecklistItem) // Use the generated accessor method to add the new item to the children set
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
                
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(5)
            
        }
}

extension CustomChecklistItem {
    func addToChildren(_ value: CustomChecklistItem) {
        let items = self.childern as? Set<CustomChecklistItem> ?? []
        var newItems = items
        newItems.insert(value)
        self.childern = newItems as NSSet
    }
}
