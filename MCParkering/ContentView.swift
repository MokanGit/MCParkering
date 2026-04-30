import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var dataClient = ParkingDataClient()
    @StateObject private var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var nearestParkingIDs: Set<UUID> = []
    
    // NYHET: Ett minne för vilken parkering vi har klickat på just nu
    @State private var selectedParkingID: UUID?
    
    // Hjälpvariabel: Letar upp hela parkeringsobjektet baserat på ID:t vi klickade på
    var selectedParking: ParkingFeature? {
        dataClient.parkings.first(where: { $0.id == selectedParkingID })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // NYHET: Vi lägger till "selection" så kartan vet vilken nål som är vald
            Map(position: $cameraPosition, selection: $selectedParkingID) {
                
                ForEach(dataClient.parkings) { parking in
                    Marker(
                        parking.address ?? "MC-Parkering",
                        coordinate: parking.coordinate
                    )
                    .tag(parking.id) // NYHET: .tag gör nålen klickbar!
                    .tint(nearestParkingIDs.contains(parking.id) ? .green : .blue)
                }
                
                UserAnnotation()
            }
            .ignoresSafeArea()
            
            // Knappar i botten
            VStack {
                HStack {
                    Spacer()
                    Button(action: { cameraPosition = .userLocation(fallback: .automatic) }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
                
                Button(action: {
                    if let userLocation = locationManager.userLocation {
                        let nearest = dataClient.findNearest(to: userLocation, count: 3)
                        nearestParkingIDs = Set(nearest.map { $0.id })
                    }
                }) {
                    Text("Hitta närmaste")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        // NYHET: Rutan (Sheet) som glider upp när selectedParkingID inte längre är tom (nil)
        .sheet(isPresented: Binding(
            get: { selectedParkingID != nil },
            set: { isPresented in if !isPresented { selectedParkingID = nil } }
        )) {
            // Skickar över rätt parkering till vår nya infovy!
            if let parking = selectedParking {
                ParkingDetailSheet(parking: parking)
                    .presentationDetents([.height(280)]) // Gör så rutan bara tar upp nedre delen av skärmen
            }
        }
    }
}

// NYHET: Själva designen för info-rutan!
// Denna ligger utanför ContentView för att hålla koden städad.
struct ParkingDetailSheet: View {
    let parking: ParkingFeature
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            // Adressen som stor rubrik
            Text(parking.address ?? "Okänd adress")
                .font(.title2)
                .bold()
            
            // Städdagar och annan info
            if let info = parking.info {
                HStack(alignment: .top) {
                    Image(systemName: "info.circle.fill").foregroundColor(.orange)
                    Text(info).font(.subheadline)
                }
            }
            
            // Avgifter och tider
            if let rate = parking.rate {
                HStack(alignment: .top) {
                    Image(systemName: "dollarsign.circle.fill").foregroundColor(.green)
                    Text(rate).font(.subheadline)
                }
            }
            
            Spacer()
            
            // Knappen för att starta vägbeskrivning i Apple Maps
            Button(action: {
                // Vi bygger ett "MapItem" som Apple Maps förstår
                let location = CLLocation(latitude: parking.coordinate.latitude, longitude: parking.coordinate.longitude)
                let mapItem = MKMapItem(location: location, address: nil)
                mapItem.name = parking.address ?? "MC-Parkering"

                
                // Öppnar riktiga Kartor-appen med bilkörning inställt!
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            }) {
                Text("Kör hit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(15)
            }
        }
        .padding(25)
    }
}
