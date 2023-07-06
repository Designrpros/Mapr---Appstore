import SwiftUI
import MapKit

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

#if os(iOS)
struct AllProjectsMapView: UIViewRepresentable {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<Location>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        
        print("Updating map view with locations: \(locations)")
        
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0
        
        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = location.name
            uiView.addAnnotation(annotation)
            
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
            uiView.setRegion(region, animated: true)
        } else {
            print("Invalid region")
        }
    }
}
    
class Coordinator: NSObject, MKMapViewDelegate {
    var parent: AllProjectsMapView

    init(_ parent: AllProjectsMapView) {
        self.parent = parent
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "project"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        if let projectAnnotation = annotation as? ProjectAnnotation {
            let pinView = annotationView as! MKPinAnnotationView
            pinView.pinTintColor = projectAnnotation.project.isFinished ? UIColor.yellow : UIColor.red
        }

        return annotationView
    }
}

#elseif os(macOS)
struct AllProjectsMapView: NSViewRepresentable {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<Location>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
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
}

class Coordinator: NSObject, MKMapViewDelegate {
   var parent: AllProjectsMapView

   init(_ parent: AllProjectsMapView) {
       self.parent = parent
   }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? ProjectAnnotation else { return nil }

        let identifier = "project"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.canShowCallout = true
        annotationView?.markerTintColor = annotation.project.isFinished ? .yellow : .red

        return annotationView
    }
}
#endif

class ProjectAnnotation: MKPointAnnotation {
    let project: Project

    init(project: Project) {
        self.project = project
        super.init()
        self.coordinate = CLLocationCoordinate2D(latitude: project.location?.latitude ?? 0, longitude: project.location?.longitude ?? 0)
        self.title = project.location?.name
    }
}
