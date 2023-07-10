import SwiftUI
import CloudKit

struct UserDetailView: View {
    var user: User  // Assuming you have a User model

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
                Text(user.role)
                    .font(.headline)
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
    }
}

