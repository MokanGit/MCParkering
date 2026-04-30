import Foundation
import CoreLocation
import Combine

class ParkingDataClient: ObservableObject {
    
    @Published var parkings: [ParkingFeature] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "mc_parkering_sthlm", withExtension: "json") else {
            print("⚠️ Hittade inte JSON-filen!")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decodedParkings = try decoder.decode([ParkingFeature].self, from: data)
            
            DispatchQueue.main.async {
                self.parkings = decodedParkings
            }
            print("✅ Succé! Laddade in \(decodedParkings.count) optimerade parkeringar från filen.")
            
        } catch {
            print("❌ Kunde inte läsa in eller översätta datan: \(error)")
        }
    }
    
    func findNearest(to location: CLLocationCoordinate2D, count: Int = 3) -> [ParkingFeature] {
        let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        // Sortera alla parkeringar baserat på avstånd (går mycket snabbare nu med platt data)
        let sorted = parkings.sorted { parkingA, parkingB in
            let locA = CLLocation(latitude: parkingA.lat, longitude: parkingA.lon)
            let locB = CLLocation(latitude: parkingB.lat, longitude: parkingB.lon)
            return locA.distance(from: userCLLocation) < locB.distance(from: userCLLocation)
        }
        
        return Array(sorted.prefix(count))
    }
}
