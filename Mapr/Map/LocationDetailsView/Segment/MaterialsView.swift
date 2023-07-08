import SwiftUI
import CoreData

class MaterialsViewModel: ObservableObject {
    @Published var materials: [Material] = []
    private var viewContext: NSManagedObjectContext?
    private var project: Project?

    func setup(viewContext: NSManagedObjectContext, project: Project) {
        self.viewContext = viewContext
        self.project = project
        fetchMaterials()
    }

    func fetchMaterials() {
        guard let viewContext = viewContext, let project = project else { return }
        
        let fetchRequest: NSFetchRequest<Material> = Material.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Material.number, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "project == %@", project.objectID)

        do {
            materials = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch materials: \(error)")
        }
    }

    func saveContext() {
        guard let viewContext = viewContext else { return }
        
        do {
            try viewContext.save()
            fetchMaterials() // Fetch the materials again after saving the context.
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


struct MaterialsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @ObservedObject var viewModel: MaterialsViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Number")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                Text("Amount")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                Text("Note")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                Text("Price")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                Text("Action")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
            }
            .font(.headline)

            ForEach(viewModel.materials, id: \.id) { material in
                HStack(spacing: 0) {
                    TextField("", value: Binding(get: {
                        Int(material.number)
                    }, set: {
                        material.number = Int64($0)
                        saveContext()
                    }), formatter: NumberFormatter())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(5)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("", value: Binding(get: {
                        Int(material.amount)
                    }, set: {
                        material.amount = Int16($0)
                        saveContext()
                    }), formatter: NumberFormatter())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(5)
                        .textFieldStyle(PlainTextFieldStyle())

                    TextField("Description", text: Binding(get: {
                        material.materialDescription ?? ""
                    }, set: {
                        material.materialDescription = $0
                        saveContext()
                    }))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(5)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("", value: Binding(get: {
                        material.price
                    }, set: {
                        material.price = $0
                        saveContext()
                    }), formatter: NumberFormatter())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .cornerRadius(5)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            viewContext.delete(material)
                            saveContext()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.body)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding()
                    .cornerRadius(5)
                    .frame(maxWidth: .infinity)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }

            Button(action: {
                let newMaterial = Material(context: self.viewContext)
                newMaterial.id = UUID() // Assign a new UUID to each Material object
                newMaterial.number = 1
                newMaterial.amount = 1
                newMaterial.materialDescription = ""
                newMaterial.price = 0.0
                newMaterial.project = project
                saveContext()
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
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            fetchMaterials() // Fetch the materials again after saving the context.
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func fetchMaterials() {
        let fetchRequest: NSFetchRequest<Material> = Material.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Material.number, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "project == %@", project.objectID)

        do {
            viewModel.materials = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch materials: \(error)")
        }
    }
}
