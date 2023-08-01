import SwiftUI
import MapKit

class ProjectAnnotation: NSObject, Identifiable, MKAnnotation {
    let id = UUID() // Required for Identifiable
    let project: Project
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: project.location?.latitude ?? 0, longitude: project.location?.longitude ?? 0)
    }

    var title: String? {
        project.location?.name
    }

    #if os(iOS)
    var color: Color {
        return project.isFinished ? .yellow : .red
    }
    #elseif os(macOS)
    var color: Color {
        return project.isFinished ? .yellow : .red
    }
    #endif

    init(project: Project) {
        self.project = project
    }
}

struct AllProjectsMapView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)],
        animation: .default)
    private var locations: FetchedResults<Location>
    
    @State private var showFinishedProjects = true

    @State private var initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
    )
    @State private var userRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
    )

    var body: some View {
        Map(coordinateRegion: $userRegion, annotationItems: filteredAnnotations) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: annotation.color)
        }
        .onAppear {
            updateRegion()
            userRegion = initialRegion
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    showFinishedProjects.toggle()
                }) {
                    Text(showFinishedProjects ? "Hide Finished Projects" : "Show Finished Projects")
                }
            }
        }
    }

    private var annotations: [ProjectAnnotation] {
        var annotations = [ProjectAnnotation]()
        for location in locations {
            if let projectSet = location.projects {
                for project in projectSet.allObjects as! [Project] {
                    let annotation = ProjectAnnotation(project: project)
                    annotations.append(annotation)
                }
            }
        }
        return annotations
    }

    private var filteredAnnotations: [ProjectAnnotation] {
        annotations.filter { showFinishedProjects || !$0.project.isFinished }
    }

    private func updateRegion() {
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0

        for annotation in filteredAnnotations {
            let latitude = annotation.coordinate.latitude
            let longitude = annotation.coordinate.longitude

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

        self.initialRegion = region
    }
}
