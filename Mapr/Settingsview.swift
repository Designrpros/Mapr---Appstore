//
//  SettingsView.swift
//  Mapr
//
//  Created by Vegar Berentsen on 03/07/2023.
//
import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var showRestartAlert = false
    @Environment(\.presentationMode) var presentationMode  // Add this property

    var body: some View {
        VStack{
            Form {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .frame(width: 200, height: 200)
            
            Button(action: {
                deleteAll()
                showRestartAlert = true
            }) {
                Text("Delete All")
                    .font(.headline)
                    
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
            
            Button("Cancel") {  // Add this button
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .alert(isPresented: $showRestartAlert) {
            Alert(title: Text("Restart Required"), message: Text("Please close and reopen the app to see changes."), dismissButton: .default(Text("OK")))
        }
    }
    
    
    private func deleteAll() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = Location.fetchRequest()
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = Contact.fetchRequest()
        let fetchRequest3: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let fetchRequest4: NSFetchRequest<NSFetchRequestResult> = ChecklistItem.fetchRequest()
        let fetchRequest5: NSFetchRequest<NSFetchRequestResult> = GalleryImage.fetchRequest()
        let fetchRequest6: NSFetchRequest<NSFetchRequestResult> = Material.fetchRequest()
        let fetchRequest7: NSFetchRequest<NSFetchRequestResult> = TimeTracker.fetchRequest()

        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        let batchDeleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
        let batchDeleteRequest4 = NSBatchDeleteRequest(fetchRequest: fetchRequest4)
        let batchDeleteRequest5 = NSBatchDeleteRequest(fetchRequest: fetchRequest5)
        let batchDeleteRequest6 = NSBatchDeleteRequest(fetchRequest: fetchRequest6)
        let batchDeleteRequest7 = NSBatchDeleteRequest(fetchRequest: fetchRequest7)

        do {
            try managedObjectContext.execute(batchDeleteRequest1)
            try managedObjectContext.execute(batchDeleteRequest2)
            try managedObjectContext.execute(batchDeleteRequest3)
            try managedObjectContext.execute(batchDeleteRequest4)
            try managedObjectContext.execute(batchDeleteRequest5)
            try managedObjectContext.execute(batchDeleteRequest6)
            try managedObjectContext.execute(batchDeleteRequest7)
            try managedObjectContext.save()
        } catch {
            print("Error deleting all entities: \(error)")
        }
    }
}
