import SwiftUI
import CoreData

#if os(iOS)
import UIKit
import AuthenticationServices
#elseif os(macOS)
import AppKit
#endif

import AuthenticationServices

class SignInWithAppleManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    static let shared = SignInWithAppleManager()
    
    @Published var isSignedIn = false

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

            // Now you can use these values to create a new user in your database
            // Make sure to handle the case where fullName and email are nil, as they will only be provided the first time the user signs in
            let formatter = PersonNameComponentsFormatter()
            let name = formatter.string(from: fullName ?? PersonNameComponents())
            print("User id: \(userIdentifier) Full Name: \(name) Email: \(email ?? "")")

            if let email = email {
                // Add the user to your database
                CloudKitManager.shared.addUser(username: name, email: email) { (record, error) in
                    if let error = error {
                        print("Failed to add user: \(error)")
                    } else {
                        print("User added successfully")
                    }
                }
            }

            isSignedIn = true
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
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
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
#endif

@main
struct Mapr: App {
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
        }
        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
        #endif
    }
}
