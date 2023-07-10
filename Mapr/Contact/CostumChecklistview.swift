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
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomChecklistItem.title, ascending: true)],
        animation: .default)
    private var checklistItems: FetchedResults<CustomChecklistItem>
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
                    AddCustomChecklistItemView {
                        // Refresh the checklist items array when a new item is added
                    }
                }
            }
            .padding([.horizontal, .top])
            
            List {
                ForEach(filteredChecklistItems, id: \.self) { checklistItem in
                    HStack {
                        NavigationLink(destination: CustomChecklistItemDetailView(checklistItem: checklistItem)) {
                            HStack {
                                Image(systemName: checklistItem.isChecked ? "checkmark.square" : "square")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(checklistItem.title ?? "Unknown")
                                        .font(.headline)
                                    Text(checklistItem.item ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                    }
                    .contextMenu {
                        Button(action: {
                            // Delete the checklist item from Core Data
                            viewContext.delete(checklistItem)
                            do {
                                try viewContext.save()
                            } catch {
                                print("Failed to delete checklist item: \(error)")
                            }
                        }) {
                            Text("Delete Item")
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }.navigationTitle("Checklist")
    }
    
    var filteredChecklistItems: [CustomChecklistItem] {
        if searchText.isEmpty {
            return Array(checklistItems)
        } else {
            return Array(checklistItems).filter {
                $0.title?.contains(searchText) ?? false ||
                $0.item?.contains(searchText) ?? false
            }
        }
    }
}

struct AddCustomChecklistItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newTitle = ""
    @State private var newItem = ""
    var onAddChecklistItem: (() -> Void)?

    var body: some View {
        ZStack {
            Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
            }
            
            VStack {
                Text("Add Checklist Item")
                    .font(.title)
                    .padding()
                VStack{
                    TextField("Title", text: $newTitle)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(.darkGray))
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Item", text: $newItem)
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
                        let newChecklistItem = CustomChecklistItem(context: viewContext)
                        newChecklistItem.title = newTitle
                        newChecklistItem.item = newItem
                        newChecklistItem.isChecked = false
                        do {
                            try viewContext.save()
                            onAddChecklistItem?()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Failed to add checklist item: \(error)")
                        }
                    }
                }
                .padding()
                .frame(width: 250, height: 50)
            }
            .navigationTitle("Add Checklist Item")
        }
    }
}
