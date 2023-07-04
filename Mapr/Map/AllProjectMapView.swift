import SwiftUI
import MapKit

struct AllProjectsMapView: NSViewRepresentable {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<Location>

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        return mapView
    }

    func updateNSView(_ nsView: MKMapView, context: Context) {
        nsView.removeAnnotations(nsView.annotations)
        
        print("Updating map view with locations: \(locations)")
        
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0

        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = location.name
            nsView.addAnnotation(annotation)

            let latitude = location.latitude
            let longitude = location.longitude
            
            minLatitude = min(minLatitude, latitude)
            maxLatitude = max(maxLatitude, latitude)
            minLongitude = min(minLongitude, longitude)
            maxLongitude = max(maxLongitude, longitude)
        }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2.0
        let centerLongitude = (minLongitude + maxLongitude) / 2.0
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        
        let latitudeDelta = maxLatitude - minLatitude + 0.05
        let longitudeDelta = maxLongitude - minLongitude + 0.05

        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)

        if isValid(region: region) {
            nsView.setRegion(region, animated: true)
        } else {
            print("Invalid region")
        }
    }
    
    func isValid(region: MKCoordinateRegion) -> Bool {
        let latitude = region.center.latitude
        let longitude = region.center.longitude
        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta

        if latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           latitudeDelta > 0 && longitudeDelta > 0 {
            return true
        }
        return false
    }
}
