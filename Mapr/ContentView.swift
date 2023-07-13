import SwiftUI
import AuthenticationServices


struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isShowing = false
    
    @ObservedObject var signInWithAppleManager = SignInWithAppleManager.shared
    @ObservedObject var coreDataManager = CoreDataManager.shared

    var body: some View {
            NavigationView {
                VStack {
                    switch selectedTab {
                    case 0:
                        MapListView()
                            .navigationTitle("Mapr")
                    case 1:
                        ContactListView()
                            .navigationTitle("Contacts")
                    case 2:
                        CustomChecklistView()
                            .navigationTitle("Costum Checklist")
                    default:
                        Text("Invalid selection")
                    }
                    Spacer()
                    TabBar(selectedTab: $selectedTab)
                        .frame(minWidth: 235, maxWidth: .infinity)
                }
                
            }.frame(idealWidth: 600, idealHeight: 600)
            //.preferredColorScheme(isDarkMode ? .dark : .light)
                .alert(isPresented: $coreDataManager.showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(coreDataManager.errorAlertMessage), dismissButton: .default(Text("OK")))
                    
                }
        }
    }



struct TabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabButton(icon: "mappin.and.ellipse", tabNumber: 0, selectedTab: $selectedTab)
            TabButton(icon: "person.2.fill", tabNumber: 1, selectedTab: $selectedTab)
            TabButton(icon: "list.bullet", tabNumber: 2, selectedTab: $selectedTab)
        }
        .frame(height: 60)
        .background(Color("AccentColor1"))
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
