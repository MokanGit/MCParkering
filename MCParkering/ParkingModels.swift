import Foundation
import CoreLocation

// Helt ny, extremt bantat datamodell för att maxa performance!
struct ParkingFeature: Codable, Identifiable, Hashable {
    let id: UUID
    let lat: Double
    let lon: Double
    let address: String?
    let rate: String?
    let info: String?
    
    // Snabbkoordinat som slipper räknas ut varje gång
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
