//
//  MaprApp.swift
//  Mapr
//
//  Created by Vegar Berentsen on 04/07/2023.
//

import SwiftUI

@main
struct MaprApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
