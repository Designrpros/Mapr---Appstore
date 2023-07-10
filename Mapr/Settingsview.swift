//
//  SettingsView.swift
//  Mapr
//
//  Created by Vegar Berentsen on 03/07/2023.
//
import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @State private var showRestartAlert = false
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(entity: Project.entity(), sortDescriptors: []) var projects: FetchedResults<Project>
    
    // Fetch the current user
    @State private var currentUser: User = UserManager.shared.fetchCurrentUser(in: PersistenceController.shared.container.viewContext)
    
    // Fetch the user's name and email from Apple Sign In
    @ObservedObject private var signInWithAppleManager = SignInWithAppleManager.shared
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("PROFILE")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(signInWithAppleManager.userName)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(signInWithAppleManager.userEmail)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(currentUser.role)
                            .foregroundColor(.gray)
                    }
                    
                    Section {
                        Button(action: {
                            deleteAll()
                            showRestartAlert = true
                        }) {
                            Text("Delete All Projects & Contacts")
                                .foregroundColor(.red)
                        }
                    }
                }.padding()
                .navigationTitle("Settings")
                .alert(isPresented: $showRestartAlert) {
                    Alert(title: Text("Restart Required"), message: Text("Please close and reopen the app to see changes."), dismissButton: .default(Text("OK")))
                }
            }
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
