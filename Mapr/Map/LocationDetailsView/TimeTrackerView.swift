import SwiftUI
import CoreData

class TimeTrackerViewModel: ObservableObject {
    
    @Published var timeEntries: [TimeTracker] = []
    private var viewContext: NSManagedObjectContext?
    private var project: Project?

    func setup(viewContext: NSManagedObjectContext, project: Project) {
        self.viewContext = viewContext
        self.project = project
        fetchTimeEntries()
    }

    func fetchTimeEntries() {
        guard let viewContext = viewContext, let project = project else { return }
        
        let fetchRequest: NSFetchRequest<TimeTracker> = TimeTracker.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TimeTracker.date, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "project == %@", project.objectID)

        do {
            timeEntries = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch time entries: \(error)")
        }
    }

    func saveContext() {
        guard let viewContext = viewContext else { return }
        
        do {
            try viewContext.save()
            fetchTimeEntries() // Fetch the time entries again after saving the context.
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


struct TimeTrackerView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @ObservedObject var viewModel: TimeTrackerViewModel
    var body: some View {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text("Date")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                    Text("Hours")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                    Text("Description")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                    Text("Actions")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                }
                .font(.headline)
                
                ForEach(viewModel.timeEntries, id: \.id) { timeEntry in
                    HStack(spacing: 0) {
                        DatePicker("", selection: Binding(get: {
                            timeEntry.date ?? Date()
                        }, set: {
                            timeEntry.date = $0
                            saveContext()
                        }), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        //.frame(width: 100)
                        .padding()
                        .cornerRadius(5)
                        
                        Picker(selection: Binding(get: {
                            Int(timeEntry.hours * 2)
                        }, set: {
                            timeEntry.hours = Double($0) / 2
                            saveContext()
                        }), label: Text("")) {
                            ForEach(0...48, id: \.self) { halfHour in
                                Text("\(Double(halfHour) / 2, specifier: "%.1f")").tag(halfHour)
                            }
                        }
                        .labelsHidden() // Hide the label
                        .frame(width: 100, alignment: .center) // Set the frame width
                        .clipped() // Clip the view to its bounding frame
                        .padding()
                        .cornerRadius(5)


                    
                    TextField("Description", text: Binding(get: {
                        timeEntry.notes ?? ""
                    }, set: {
                        timeEntry.notes = $0
                        saveContext()
                    }))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                    .font(.system(size: 12))
                    .textFieldStyle(PlainTextFieldStyle())
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            viewContext.delete(timeEntry)
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
                    .frame(width: 100)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }
            
            Button(action: {
                let newTimeEntry = TimeTracker(context: self.viewContext)
                newTimeEntry.id = UUID() // Assign a new UUID to each TimeTracker object
                newTimeEntry.date = Date()
                newTimeEntry.hours = 0.5
                newTimeEntry.notes = ""
                newTimeEntry.project = project
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
            fetchTimeEntries() // Fetch the time entries again after saving the context.
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func fetchTimeEntries() {
            let fetchRequest: NSFetchRequest<TimeTracker> = TimeTracker.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TimeTracker.date, ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "project == %@", project.objectID)

            do {
                viewModel.timeEntries = try viewContext.fetch(fetchRequest)
            } catch {
                print("Failed to fetch time entries: \(error)")
            }
        }
}
