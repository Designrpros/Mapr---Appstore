import SwiftUI
import MapKit

#if os(iOS)
struct MapView: UIViewRepresentable {
    var mapItem: MKMapItem
    var addressTitle: String

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: mapItem.placemark.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        uiView.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = addressTitle
        uiView.addAnnotation(annotation)
    }
}
#elseif os(macOS)
struct MapView: NSViewRepresentable {
    var mapItem: MKMapItem
    var addressTitle: String

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        return mapView
    }

    func updateNSView(_ nsView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: mapItem.placemark.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        nsView.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = addressTitle
        nsView.addAnnotation(annotation)
    }
}
#endif
