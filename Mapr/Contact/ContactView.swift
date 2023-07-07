import SwiftUI
import MapKit


class AddressCoordinates: ObservableObject {
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    
    init(address: String) {
        // get the coordinates from the address string and assign them to latitude and longitude
        getCoordinate(addressString: address) { (coordinate, error) in
            if let coordinate = coordinate {
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude
            }
        }
    }
    
    private func getCoordinate(addressString: String, completionHandler: @escaping(CLLocationCoordinate2D?, Error?) -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    completionHandler(location.coordinate, nil)
                    return
                }
            }
            completionHandler(nil, error)
        }
    }

    func updateCoordinates(_ newCoordinates: CLLocationCoordinate2D) {
        self.latitude = newCoordinates.latitude
        self.longitude = newCoordinates.longitude
    }
}

struct ContactDetailView: View {
    @State var contact: Contact
    @ObservedObject var addressCoordinates: AddressCoordinates
    @State private var showingEditContact = false // Add this line
    @State private var region = MKCoordinateRegion() // Add this line

    init(contact: Contact) {
        self._contact = State(initialValue: contact)
        self.addressCoordinates = AddressCoordinates(address: contact.address ?? "")
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Contact Details")
                    .font(.headline)
                    .padding([.leading, .top])
                
                Spacer()
                
                Button(action: {
                    showingEditContact = true
                }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(BorderlessButtonStyle())
                .sheet(isPresented: $showingEditContact) {
                    EditContactView(contact: $contact)
                }
                .padding([.trailing, .top])
            }
            
            VStack(alignment: .leading) {
                HStack{
                    VStack {
                        HStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .padding()
                            
                            VStack(alignment: .leading ){
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                    Text(contact.name ?? "")
                                }
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text(contact.email ?? "")
                                }
                                
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(contact.phone ?? "")
                                }
                                
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(contact.address ?? "")
                                }
                            }
                        }
                    }
                }
                

                let coordinate = CLLocationCoordinate2D(latitude: addressCoordinates.latitude, longitude: addressCoordinates.longitude)

                Map(coordinateRegion: $region, annotationItems: [AnnotationItem(coordinate: coordinate)]) { item in
                    MapPin(coordinate: item.coordinate, tint: .red)
                }
                .onChange(of: addressCoordinates.latitude) { newLatitude in
                    region.center.latitude = newLatitude
                }
                .onChange(of: addressCoordinates.longitude) { newLongitude in
                    region.center.longitude = newLongitude
                }
                .onAppear {
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
                Spacer()
            }
            .padding()
        }
    }
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct EditContactView: View {
    @Binding var contact: Contact
    @ObservedObject var addressCoordinates: AddressCoordinates
    @State private var addressSearch: String
    @Environment(\.presentationMode) var presentationMode
    var isNewContact: Bool
    var onAddContact: ((Contact) -> Void)? // Callback to handle addition of a new contact

    init(contact: Binding<Contact>, isNewContact: Bool = false, onAddContact: ((Contact) -> Void)? = nil) {
        _contact = contact
        _addressSearch = State(initialValue: contact.wrappedValue.address ?? "")
        self.addressCoordinates = AddressCoordinates(address: contact.wrappedValue.address ?? "")
        self.isNewContact = isNewContact
        self.onAddContact = onAddContact
    }
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geometry in
                    Text(isNewContact ? "Add Contact" : "Edit Contact")
                        .font(.system(size: geometry.size.width * 0.08))
                        .fontWeight(.bold)
                        .padding(20)
                }
                .frame(height: 60) // Set a fixed height for the title
                
                VStack(alignment: .leading) {
                            Text("Name")
                                .font(.headline)
                            TextField("", text: Binding(
                                get: { contact.name ?? "" },
                                set: { contact.name = $0 }
                            ))
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Email")
                                .font(.headline)
                            TextField("", text: Binding(
                                get: { contact.email ?? "" },
                                set: { contact.email = $0 }
                            ))
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Phone")
                                .font(.headline)
                            TextField("", text: Binding(
                                get: { contact.phone ?? "" },
                                set: { contact.phone = $0 }
                            ))
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Address")
                                .font(.headline)
                            TextField("", text: $addressSearch, onCommit: geocodeAddress)
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                
                
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        contact.address = addressSearch
                        if isNewContact, let onAddContact = onAddContact {
                            onAddContact(contact)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding(.top, isNewContact ? 0 : 20)
        }
        .frame(minWidth: 200, idealWidth: 300, maxWidth: .infinity, minHeight: 350, idealHeight: 350, maxHeight: .infinity, alignment: .center)
    }
    
    private func geocodeAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressSearch) { placemarks, error in
            if let error = error {
                // Handle error
                print("Geocoding error: \(error)")
            } else if let placemark = placemarks?.first, let location = placemark.location {
                contact.address = addressSearch
                let newCoordinates = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                addressCoordinates.updateCoordinates(newCoordinates)
            }
        }
    }
}








