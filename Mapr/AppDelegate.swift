import CoreData
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var detachedWindow: NSWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Mapr")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Access the persistentContainer to ensure it's initialized
        let _ = self.persistentContainer

        // Create a status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            button.image = NSImage(named: "fist1")
            button.action = #selector(toggleWindow(_:))
        }
        
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            print(url.path)
        }
    }

    
    @objc func toggleWindow(_ sender: Any?) {
        if detachedWindow == nil {
            showDetachedWindow()
        } else {
            closeDetachedWindow()
        }
    }
    
    func showDetachedWindow() {
        let contentView = ContentView()
            .environment(\.managedObjectContext, persistentContainer.viewContext)
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 600, height: 400),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView], // Removed .closable
            backing: .buffered,
            defer: false
        )

        window.level = .floating// Set the window level to "floating"
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        detachedWindow = window
    }

    func showSettingsView() {
        let settingsView = SettingsView()
            .environment(\.managedObjectContext, persistentContainer.viewContext)
        let window = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 600, height: 400),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView], // Removed .closable
            backing: .buffered,
            defer: false
        )

        window.level = .floating// Set the window level to "floating"
        window.center()
        window.setFrameAutosaveName("Settings Window")
        window.contentView = NSHostingView(rootView: settingsView)
        window.makeKeyAndOrderFront(nil)
        detachedWindow = window
    }
    
    func closeDetachedWindow() {
        detachedWindow?.orderOut(nil)
        detachedWindow = nil
    }

}

@main
struct Mapr: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
