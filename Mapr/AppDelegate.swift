import SwiftUI
import CoreData
import CloudKit
import AuthenticationServices

#if os(iOS)
import UIKit

#elseif os(macOS)
import AppKit
#endif


class SignInWithAppleManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    static let shared = SignInWithAppleManager()
    
    @Published var isSignedIn = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    
    func handleSignInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: fullName ?? PersonNameComponents())
            print("User id: \(userIdentifier) Full Name: \(name) Email: \(email ?? "")")

            let publicDatabase = CKContainer(identifier: "iCloud.Handy-Mapr").publicCloudDatabase

            // Create a predicate to check if the user already exists in the database
            let predicate = NSPredicate(format: "userID == %@", userIdentifier)
            let query = CKQuery(recordType: "User", predicate: predicate)

            // Perform the query
            publicDatabase.perform(query, inZoneWith: nil) { (results, error) in
                if let error = error {
                    // Handle the error here
                    print("Error performing query: \(error)")
                } else if let results = results, !results.isEmpty {
                    // The user already exists in the database, so don't create a new record
                    print("User already exists in the database")
                } else {
                    // The user does not exist in the database, so create a new record
                    let newPublicUserRecord = CKRecord(recordType: "User")
                    newPublicUserRecord["username"] = name.isEmpty ? "defaultName\(userIdentifier.prefix(6))" : name
                    newPublicUserRecord["userID"] = userIdentifier

                    publicDatabase.save(newPublicUserRecord) { (record, error) in
                        if let error = error {
                            // Handle the error here
                            print("Error saving record: \(error)")
                        } else {
                            print("Successfully saved record!")
                        }
                    }
                }
            }

            // Store the user's name and email
            self.userName = name.isEmpty ? "defaultName\(userIdentifier.prefix(6))" : name
            self.userEmail = email ?? ""

            isSignedIn = true
        }
    }


}




#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate, ASAuthorizationControllerDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Handle authorization
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error
    }
}
#elseif os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    let managedObjectContext = CoreDataManager.shared.context

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            print("Core Data file path: \(url)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}
#endif


@main
struct Mapr: App {
    @StateObject private var userSelection = UserSelection()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
                .environmentObject(userSelection)
        }
        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
        #endif
    }
}
