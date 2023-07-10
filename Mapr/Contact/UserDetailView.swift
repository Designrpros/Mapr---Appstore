import SwiftUI
import CloudKit

struct UserDetailView: View {
    @State var selectedRoleIndex: Int
    let user: User
    let roles = ["Admin", "User", "Guest"]
    
    init(user: User) {
            self.user = user
            _selectedRoleIndex = State(initialValue: roles.firstIndex(of: user.role) ?? 0)
        }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.gray)
                Text(user.email)
                    .font(.headline)
            }
            
            HStack {
                Image(systemName: "person.fill.questionmark")
                    .foregroundColor(.gray)
                Text(roles[selectedRoleIndex])
                    .font(.headline)
            }
            Picker(selection: $selectedRoleIndex, label: Text("Role")) {
                ForEach(0..<roles.count) {
                    Text(self.roles[$0]).tag($0)
                }
            }

            
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                Text(user.recordID.recordName)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(Text(user.name))
        .onAppear {
            // Set the initial selected role index based on the user's current role
            self.selectedRoleIndex = roles.firstIndex(of: user.role) ?? 0
        }
    }
}

