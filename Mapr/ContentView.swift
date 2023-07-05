import SwiftUI
import AuthenticationServices

class SignInWithAppleManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
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
            // You can now use the received userIdentifier, fullName and email to sign the user in to your app
            isSignedIn = true
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}


struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isShowing = false
    // @AppStorage("isDarkMode") private var isDarkMode = false
    @ObservedObject var signInWithAppleManager = SignInWithAppleManager()

    var body: some View {
        if !signInWithAppleManager.isSignedIn {
            Button(action: signInWithAppleManager.handleSignInWithApple) {
                HStack {
                    Image(systemName: "applelogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Sign in with Apple")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle())
        } else {
            
            NavigationView {
                VStack {
                    switch selectedTab {
                    case 0:
                        MapListView()
                            .navigationTitle("Mapr")
                    case 1:
                        ContactListView()
                            .navigationTitle("Contacts")
                    default:
                        Text("Invalid selection")
                    }
                    Spacer()
                    TabBar(selectedTab: $selectedTab)
                        .frame(minWidth: 235, maxWidth: .infinity)
                }
                
            }.frame(idealWidth: 600, idealHeight: 600)
            //.preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}


struct TabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabButton(icon: "mappin.and.ellipse", tabNumber: 0, selectedTab: $selectedTab)
            TabButton(icon: "person.2.fill", tabNumber: 1, selectedTab: $selectedTab)
        }
        .frame(height: 60)
        .background(Color.accentColor)
    }
}

struct TabButton: View {
    let icon: String
    let tabNumber: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: { selectedTab = tabNumber }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(selectedTab == tabNumber ? Color("CostumGray") : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: 60)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
