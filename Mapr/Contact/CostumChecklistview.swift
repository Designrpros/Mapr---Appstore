//
//  CostumChecklistview.swift
//  Mapr
//
//  Created by Vegar Berentsen on 10/07/2023.
//

import SwiftUI
import CoreData

struct CustomChecklistView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomChecklist.title, ascending: true)],
        animation: .default)
    private var checklists: FetchedResults<CustomChecklist>
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showingAddChecklistItem = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search...", text: $searchText)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color(.darkGray))
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Button(action: {
                    showingAddChecklistItem = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)
                .buttonStyle(BorderlessButtonStyle())
                .sheet(isPresented: $showingAddChecklistItem) {
                    AddCustomChecklistView(onAddChecklist: nil)
                }

            }
            .padding([.horizontal, .top])
            
            List {
                ForEach(filteredChecklists, id: \.self) { checklist in
                    NavigationLink(destination: CustomChecklistItemDetailView(checklist: checklist, viewContext: viewContext)) {
                        Text(checklist.title ?? "Unknown")
                            .font(.headline)
                    }
                }
            }


        }.navigationTitle("Checklist")
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


struct AddCustomChecklistView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newTitle = ""
    var onAddChecklist: (() -> Void)?

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            
            VStack {
                Text("Add Checklist")
                    .font(.title)
                    .padding()
                VStack{
                    TextField("Title", text: $newTitle)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                }.padding()
                
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                    Button("Add") {
                        let newChecklist = CustomChecklist(context: viewContext)
                        newChecklist.title = newTitle
                        do {
                            try viewContext.save()
                            onAddChecklist?()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Failed to add checklist: \(error)")
                        }
                    }
                }
                .padding()
                .frame(width: 250, height: 50)
            }
            .navigationTitle("Add Checklist")
        }
    }
}

