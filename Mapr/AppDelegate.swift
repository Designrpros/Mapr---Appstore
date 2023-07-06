import CoreData
import SwiftUI

@main
struct Mapr: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
        #endif
    }
}
