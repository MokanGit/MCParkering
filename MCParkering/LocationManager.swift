import Foundation
import CoreLocation
import Combine

// Denna klass pratar med iPhone-GPS:en och säger till skärmen när vi rör oss
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // Här sparar vi din position. @Published gör att kartan uppdateras när du rör dig!
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        requestAuthorizationIfNeeded()
        updateLocationUpdates(for: manager.authorizationStatus)
    }
    
    // Denna inbyggda funktion anropas automatiskt varje gång telefonen flyttar sig
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        updateLocationUpdates(for: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code != .locationUnknown else {
            return
        }

        userLocation = nil
    }

    private func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    private func updateLocationUpdates(for status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
            userLocation = nil
        case .notDetermined:
            break
        @unknown default:
            manager.stopUpdatingLocation()
        }
    }
}
