import SwiftUI
import WebKit
import CoreLocation

struct StreetView: NSViewRepresentable {
    var coordinate: CLLocationCoordinate2D

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let urlString = "https://maps.googleapis.com/maps/api/streetview?size=400x400&location=\(coordinate.latitude),\(coordinate.longitude)&fov=90&heading=235&pitch=10&key=\(Constants.googleMapsAPIKey)"
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
}
