import UIKit
import SwiftUI
import UniformTypeIdentifiers
import CoreLocation
import MapKit
import OSLog

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        let hosting = UIHostingController(rootView: ShareExtensionView(context: self.extensionContext))
        hosting.view.backgroundColor = .clear
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }
}

private let shareLogger = Logger(subsystem: "MCParkeringShare", category: "ShareExtension")
private let shareDiagnosticsEnabled: Bool = {
#if DEBUG
    true
#else
    false
#endif
}()

#if DEBUG
private func debugShareInfo(_ message: @autoclosure () -> String) {
    shareLogger.info("\(message(), privacy: .public)")
}

private func debugShareError(_ message: @autoclosure () -> String) {
    shareLogger.error("\(message(), privacy: .public)")
}
#else
private func debugShareInfo(_ message: @autoclosure () -> String) {}
private func debugShareError(_ message: @autoclosure () -> String) {}
#endif

struct ShareExtensionView: View {
    var context: NSExtensionContext?
    @StateObject private var dataClient = ParkingDataClient()
    
    @State private var nearestParkings: [ParkingFeature] = []
    @State private var targetCoordinate: CLLocationCoordinate2D?
    @State private var selectedParkingID: UUID?
    
    var selectedParking: ParkingFeature? {
        if let id = selectedParkingID {
            return nearestParkings.first(where: { $0.id == id })
        }
        return nearestParkings.first
    }
    
    @State private var isLoading = true
    @State private var statusText = "Läser in plats..."
    @State private var debugDetails: String?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // KARTA
            if let targetCoord = targetCoordinate {
                Map(selection: $selectedParkingID) {
                    Marker("Mål", systemImage: "star.fill", coordinate: targetCoord)
                        .tint(.red)
                    
                    ForEach(nearestParkings) { parking in
                        Marker(
                            parking.address ?? "MC-Parkering", 
                            coordinate: parking.coordinate
                        )
                        .tag(parking.id)
                        .tint(selectedParkingID == parking.id ? .blue : .green)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView(statusText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGray6))
            }
            
            // INFO OCH KNAPPAR
            VStack(alignment: .leading, spacing: 15) {
                if let parking = selectedParking {
                    Text("Vald MC-Parkering")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(parking.address ?? "Okänd adress")
                        .font(.title2).bold()
                    
                    if let info = parking.info {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill").foregroundColor(.orange)
                            Text(info).font(.subheadline)
                        }
                    }
                    
                    if let rate = parking.rate {
                        HStack(alignment: .top) {
                            Image(systemName: "dollarsign.circle.fill").foregroundColor(.green)
                            Text(rate).font(.subheadline)
                        }
                    }
                    
                    Button(action: openInMaps) {
                        Text("Starta Navigering")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue).cornerRadius(12)
                    }
                } else if !isLoading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(statusText)
                        if shareDiagnosticsEnabled, let debugDetails, !debugDetails.isEmpty {
                            Text(debugDetails)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                }
                
                Button("Avbryt") {
                    context?.completeRequest(returningItems: nil)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)
            }
            .padding(25)
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            extractSharedData()
        }
    }
    
    func extractSharedData() {
        let extensionItems = (context?.inputItems as? [NSExtensionItem]) ?? []
        let attachments = extensionItems.flatMap { $0.attachments ?? [] }

        debugShareInfo("Share extension opened with \(extensionItems.count) items and \(attachments.count) attachments")
        for (index, attachment) in attachments.enumerated() {
            let types = attachment.registeredTypeIdentifiers.joined(separator: ", ")
            debugShareInfo("Attachment \(index) types: \(types)")
        }

        guard !attachments.isEmpty else {
            statusText = "Kunde inte läsa datan."
            debugDetails = "Inga bilagor hittades i extensionContext.inputItems."
            debugShareError("No attachments found in extension context")
            isLoading = false
            return
        }
        
        // 1. Leta efter Apple Maps Karta i ALLA attachments (inte bara första)
        if let mapAttachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier("com.apple.mapkit.map-item") }) {
            debugShareInfo("Selected map-item attachment")
            loadMapItem(from: mapAttachment)
            return
        }
        
        // 2. Leta efter Text i ALLA attachments.
        // Google Maps delar ofta användbar adress som text men bara en kortlänk som URL.
        if let textAttachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) {
            let fallbackURLAttachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) })
            loadText(from: textAttachment, fallbackURLAttachment: fallbackURLAttachment)
            return
        }

        // 3. Leta efter Länk som reservväg
        if let urlAttachment = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            debugShareInfo("Selected URL attachment")
            loadURL(from: urlAttachment)
            return
        }
        
        let types = attachments.flatMap { $0.registeredTypeIdentifiers }.joined(separator: "\n")
        DispatchQueue.main.async {
            self.statusText = "Okänt filformat. Fick:\n\(types)"
            self.debugDetails = self.debugSummary(for: extensionItems, attachments: attachments)
            debugShareError("Unsupported attachment types: \(types)")
            self.isLoading = false
        }
    }
    
    private func loadText(from attachment: NSItemProvider, fallbackURLAttachment: NSItemProvider?) {
        let typeToLoad = attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ? UTType.plainText.identifier : UTType.text.identifier
        debugShareInfo("Selected text attachment with type \(typeToLoad)")

        attachment.loadObject(ofClass: NSString.self) { object, error in
            DispatchQueue.main.async {
                let text = (object as? NSString as String?)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !text.isEmpty {
                    debugShareInfo("Decoded shared text: \(text)")
                    self.handleSharedText(text)
                    return
                }

                debugShareInfo("Text attachment was empty. Falling back to URL attachment: \(fallbackURLAttachment != nil)")
                if let fallbackURLAttachment {
                    self.loadURL(from: fallbackURLAttachment)
                    return
                }

                self.statusText = "Ingen adress hittades i texten."
                self.debugDetails = error?.localizedDescription ?? self.describeSharedValue(object)
                debugShareError("Failed to decode text payload. Error: \(error?.localizedDescription ?? "nil"). Payload: \(self.describeSharedValue(object))")
                self.isLoading = false
            }
        }
    }

    private func loadMapItem(from attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: "com.apple.mapkit.map-item") { item, error in
            DispatchQueue.main.async {
                var mapData: Data? = nil
                if let data = item as? Data {
                    mapData = data
                } else if let url = item as? URL {
                    mapData = try? Data(contentsOf: url)
                }
                
                if let data = mapData,
                   let mapItem = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MKMapItem.self, from: data) {
                    debugShareInfo("Decoded map item at \(mapItem.location.coordinate.latitude), \(mapItem.location.coordinate.longitude)")
                    self.updateNearestParkings(for: mapItem.location.coordinate)
                } else {
                    self.statusText = "Kunde inte packa upp kartdatan."
                    self.debugDetails = error?.localizedDescription ?? "Type: \(type(of: item as Any))"
                    debugShareError("Failed to decode map item. Error: \(error?.localizedDescription ?? "nil")")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadURL(from attachment: NSItemProvider) {
        attachment.loadObject(ofClass: NSURL.self) { data, error in
            DispatchQueue.main.async {
                if let url = data as? URL {
                    debugShareInfo("Decoded shared URL: \(url.absoluteString)")
                    self.handleSharedURL(url)
                } else {
                    self.statusText = "Kunde inte tolka länken."
                    self.debugDetails = error?.localizedDescription ?? "Type: \(type(of: data as Any))"
                    debugShareError("Failed to decode URL payload. Error: \(error?.localizedDescription ?? "nil"). Payload type: \(String(describing: type(of: data as Any)))")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleSharedURL(_ url: URL) {
        if let coordinate = extractCoordinate(from: url) {
            debugShareInfo("Extracted coordinate from URL: \(coordinate.latitude), \(coordinate.longitude)")
            updateNearestParkings(for: coordinate)
            return
        }

        let searchTerm = extractSearchTerm(from: url)
        if searchTerm == url.absoluteString, url.host?.contains("goo.gl") == true {
            statusText = "Följer Google Maps-länk..."
            debugDetails = url.absoluteString
            debugShareInfo("Resolving Google short URL: \(url.absoluteString)")
            resolveShortURL(url)
            return
        }

        debugShareInfo("Falling back to search term from URL: \(searchTerm)")
        findParking(from: searchTerm)
    }

    private func handleSharedText(_ text: String) {
        if let coordinate = extractCoordinate(from: text) {
            debugShareInfo("Extracted coordinate from text: \(coordinate.latitude), \(coordinate.longitude)")
            updateNearestParkings(for: coordinate)
            return
        }

        let searchText = extractSearchText(from: text)
        guard !searchText.isEmpty else {
            statusText = "Ingen adress hittades i texten."
            debugDetails = text
            debugShareError("Shared text was empty after normalization")
            isLoading = false
            return
        }

        debugShareInfo("Using shared text as search term: \(searchText)")
        findParking(from: searchText)
    }

    func extractSearchTerm(from url: URL) -> String {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {

            if let q = queryItems.first(where: { $0.name == "q" || $0.name == "query" || $0.name == "destination" || $0.name == "daddr" })?.value,
               !q.isEmpty {
                return q
            }
            if let address = queryItems.first(where: { $0.name == "address" })?.value {
                return address
            }
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if let placeIndex = pathComponents.firstIndex(of: "place"),
           pathComponents.indices.contains(placeIndex + 1) {
            let encodedPlace = pathComponents[placeIndex + 1]
            let place = encodedPlace
                .removingPercentEncoding?
                .replacingOccurrences(of: "+", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let place, !place.isEmpty {
                return place
            }
        }

        return url.absoluteString
    }

    private func extractSearchText(from text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let nonURLLines = lines.filter { !$0.lowercased().hasPrefix("http") }
        if !nonURLLines.isEmpty {
            return nonURLLines.joined(separator: ", ")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractText(from value: NSSecureCoding?) -> String? {
        switch value {
        case let text as String:
            return text
        case let text as NSString:
            return text as String
        case let attributedText as NSAttributedString:
            return attributedText.string
        case let url as URL:
            return url.absoluteString
        case let url as NSURL:
            return url.absoluteString
        case let data as Data:
            return decodeText(from: data)
        case let data as NSData:
            return decodeText(from: data as Data)
        case let array as NSArray:
            return array.compactMap { element in
                extractText(from: element as? NSSecureCoding)
            }.joined(separator: "\n")
        case let dictionary as NSDictionary:
            let values = dictionary.allValues.compactMap { value in
                extractText(from: value as? NSSecureCoding)
            }
            return values.isEmpty ? dictionary.description : values.joined(separator: "\n")
        default:
            return nil
        }
    }

    private func decodeText(from data: Data) -> String? {
        let encodings: [String.Encoding] = [.utf8, .utf16, .unicode, .isoLatin1]
        for encoding in encodings {
            if let string = String(data: data, encoding: encoding),
               !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return string
            }
        }

        return nil
    }

    private func extractCoordinate(from url: URL) -> CLLocationCoordinate2D? {
        if let coordinate = parseCoordinatePair(from: url.absoluteString) {
            return coordinate
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        let coordinateKeys = ["ll", "center", "q", "query", "destination", "daddr"]
        for key in coordinateKeys {
            if let value = queryItems.first(where: { $0.name == key })?.value,
               let coordinate = parseCoordinatePair(from: value) {
                return coordinate
            }
        }

        return nil
    }

    private func resolveShortURL(_ url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error {
                    self.statusText = "Kunde inte öppna Google Maps-länken."
                    self.debugDetails = error.localizedDescription
                    debugShareError("Failed to resolve short URL. Error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                guard let resolvedURL = response?.url else {
                    self.statusText = "Kunde inte öppna Google Maps-länken."
                    self.debugDetails = url.absoluteString
                    debugShareError("Short URL resolved without final response URL")
                    self.isLoading = false
                    return
                }

                debugShareInfo("Resolved Google short URL to: \(resolvedURL.absoluteString)")
                self.handleResolvedShortURL(resolvedURL, fallbackOriginalURL: url)
            }
        }.resume()
    }

    private func handleResolvedShortURL(_ resolvedURL: URL, fallbackOriginalURL: URL) {
        if let unwrappedURL = unwrapGoogleConsentURL(resolvedURL) {
            debugShareInfo("Unwrapped Google consent URL to: \(unwrappedURL.absoluteString)")
            handleResolvedShortURL(unwrappedURL, fallbackOriginalURL: fallbackOriginalURL)
            return
        }

        if let coordinate = extractCoordinate(from: resolvedURL) {
            debugShareInfo("Extracted coordinate from resolved URL: \(coordinate.latitude), \(coordinate.longitude)")
            updateNearestParkings(for: coordinate)
            return
        }

        let resolvedSearchTerm = extractSearchTerm(from: resolvedURL)
        if resolvedSearchTerm != resolvedURL.absoluteString {
            debugShareInfo("Using resolved URL search term: \(resolvedSearchTerm)")
            findParking(from: resolvedSearchTerm)
            return
        }

        statusText = "Google Maps-länken kunde inte tydas."
        debugDetails = resolvedURL.absoluteString == fallbackOriginalURL.absoluteString ? fallbackOriginalURL.absoluteString : resolvedURL.absoluteString
        debugShareError("Resolved URL still unusable: \(resolvedURL.absoluteString)")
        isLoading = false
    }

    private func unwrapGoogleConsentURL(_ url: URL) -> URL? {
        guard url.host?.contains("consent.google.com") == true,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let continueValue = components.queryItems?.first(where: { $0.name == "continue" })?.value,
              let decodedValue = continueValue.removingPercentEncoding,
              let unwrappedURL = URL(string: decodedValue),
              unwrappedURL != url else {
            return nil
        }

        return unwrappedURL
    }

    private func extractCoordinate(from text: String) -> CLLocationCoordinate2D? {
        parseCoordinatePair(from: text)
    }

    private func parseCoordinatePair(from value: String) -> CLLocationCoordinate2D? {
        let pattern = #"(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range),
              let latitudeRange = Range(match.range(at: 1), in: value),
              let longitudeRange = Range(match.range(at: 2), in: value),
              let latitude = Double(value[latitudeRange]),
              let longitude = Double(value[longitudeRange]),
              abs(latitude) <= 90,
              abs(longitude) <= 180 else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func findParking(from text: String) {
        statusText = "Söker efter parkering..."
        debugShareInfo("Starting MKLocalSearch for: \(text)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            DispatchQueue.main.async {
                guard let location = response?.mapItems.first?.location else {
                    self.statusText = "Kunde inte förstå adressen."
                    self.debugDetails = error?.localizedDescription ?? text
                    debugShareError("MKLocalSearch failed. Error: \(error?.localizedDescription ?? "nil")")
                    self.isLoading = false
                    return
                }
                debugShareInfo("MKLocalSearch resolved to \(location.coordinate.latitude), \(location.coordinate.longitude)")
                self.updateNearestParkings(for: location.coordinate)
            }
        }
    }
    
    private func updateNearestParkings(for coordinate: CLLocationCoordinate2D) {
        targetCoordinate = coordinate
        nearestParkings = dataClient.findNearest(to: coordinate, count: 3)
        selectedParkingID = nearestParkings.first?.id
        isLoading = false
        debugDetails = nil
        if nearestParkings.isEmpty {
            statusText = "Hittade inga MC-parkeringar i närheten."
        }
    }

    private func debugSummary(for extensionItems: [NSExtensionItem], attachments: [NSItemProvider]) -> String {
        let itemSummary = extensionItems.enumerated().map { index, item in
            let count = item.attachments?.count ?? 0
            return "Item \(index): \(count) attachments"
        }

        let attachmentSummary = attachments.enumerated().map { index, attachment in
            let types = attachment.registeredTypeIdentifiers.joined(separator: ", ")
            return "Attachment \(index): \(types)"
        }

        return (itemSummary + attachmentSummary).joined(separator: "\n")
    }

    private func describeSharedValue(_ value: Any?) -> String {
        guard let value else {
            return "Shared value was nil."
        }

        if let data = value as? Data {
            return "Type: Data (\(data.count) bytes)"
        }
        if let data = value as? NSData {
            return "Type: NSData (\(data.length) bytes)"
        }

        return "Type: \(type(of: value))\nValue: \(value)"
    }
    
    func openInMaps() {
        guard let nearest = selectedParking else { return }
        
        let location = CLLocation(latitude: nearest.coordinate.latitude, longitude: nearest.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = nearest.address ?? "Parkering"
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
        context?.completeRequest(returningItems: nil)
    }
}
