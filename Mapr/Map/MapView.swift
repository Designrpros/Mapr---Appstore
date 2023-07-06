import SwiftUI
import MapKit

#if os(iOS)
struct MapView: UIViewRepresentable {
    var project: Project

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: project.location?.coordinate ?? CLLocationCoordinate2D(), latitudinalMeters: 1000, longitudinalMeters: 1000)
        uiView.setRegion(region, animated: true)

        let annotation = ProjectAnnotation(project: project)
        uiView.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? ProjectAnnotation else { return nil }

            let identifier = "project"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            let markerView = annotationView as! MKMarkerAnnotationView
            markerView.markerTintColor = annotation.project.isFinished ? UIColor.yellow : UIColor.red

            return annotationView
        }
    }
}

#elseif os(macOS)
struct MapView: NSViewRepresentable {
    var project: Project

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateNSView(_ nsView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: project.location?.latitude ?? 0, longitude: project.location?.longitude ?? 0), latitudinalMeters: 1000, longitudinalMeters: 1000)
        nsView.setRegion(region, animated: true)

        let annotation = ProjectAnnotation(project: project)
        nsView.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? ProjectAnnotation else { return nil }

            let identifier = "project"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            let markerView = annotationView as! MKMarkerAnnotationView
            markerView.markerTintColor = annotation.project.isFinished ? NSColor.yellow : NSColor.red

            return annotationView
        }
    }
}
#endif
