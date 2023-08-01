import SwiftUI
import MapKit

struct MapView: View {
    @State private var region: MKCoordinateRegion
    var project: Project
    var annotation: ProjectAnnotation

    init(project: Project) {
        self.project = project
        let coordinate = CLLocationCoordinate2D(latitude: project.location?.latitude ?? 0, longitude: project.location?.longitude ?? 0)
        _region = State(initialValue: MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
        annotation = ProjectAnnotation(project: project)
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [annotation]) { place in
            MapMarker(coordinate: place.coordinate, tint: place.project.isFinished ? .yellow : .red)
        }
    }
}
