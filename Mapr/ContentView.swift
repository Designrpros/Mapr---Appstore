import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isShowing = false
    // @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationView {
            VStack {
                switch selectedTab {
                case 0:
                    MapListView()
                        .navigationTitle("Map Locations")
                case 1:
                    ContactListView()
                        .navigationTitle("Contacts")
                default:
                    Text("Invalid selection")
                }
                Spacer()
                TabBar(selectedTab: $selectedTab)
                    .frame(width: 235)
            }

        }.frame(idealWidth: 600, minHeight: 600)
        //.preferredColorScheme(isDarkMode ? .dark : .light)
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
