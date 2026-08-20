import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var dataClient = ParkingDataClient()
    @StateObject private var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var nearestParkingIDs: Set<UUID> = []
    
    @State private var selectedParkingID: UUID?
    
    var selectedParking: ParkingFeature? {
        dataClient.parkings.first(where: { $0.id == selectedParkingID })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            Map(position: $cameraPosition, selection: $selectedParkingID) {
                
                ForEach(dataClient.parkings) { parking in
                    Marker(
                        parking.address ?? "MC-Parkering",
                        coordinate: parking.coordinate
                    )
                    .tag(parking.id)
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
        .sheet(isPresented: Binding(
            get: { selectedParkingID != nil },
            set: { isPresented in if !isPresented { selectedParkingID = nil } }
        )) {
            if let parking = selectedParking {
                ParkingDetailSheet(parking: parking)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct ParkingDetailSheet: View {
    let parking: ParkingFeature

    @State private var lookAroundScene: MKLookAroundScene?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(parking.address ?? "Okänd adress")
                    .font(.title2.bold())

                if let lookAroundScene {
                    ParkingLookAroundThumbnail(scene: lookAroundScene)
                }

                if let info = parking.info {
                    Label {
                        Text(info)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }

                if let rate = parking.rate {
                    Label {
                        Text(rate)
                    } icon: {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                let location = CLLocation(latitude: parking.coordinate.latitude, longitude: parking.coordinate.longitude)
                let mapItem = MKMapItem(location: location, address: nil)
                mapItem.name = parking.address ?? "MC-Parkering"

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
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .task(id: parking.id) {
            await loadLookAroundScene()
        }
    }

    @MainActor
    private func loadLookAroundScene() async {
        lookAroundScene = nil
        let request = MKLookAroundSceneRequest(coordinate: parking.coordinate)

        do {
            let scene = try await request.scene
            guard !Task.isCancelled else { return }
            lookAroundScene = scene
        } catch {
            // No thumbnail is shown when Look Around imagery is unavailable.
        }
    }
}

private struct ParkingLookAroundThumbnail: View {
    let scene: MKLookAroundScene

    var body: some View {
        LookAroundPreview(
            initialScene: scene,
            allowsNavigation: true
        )
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
