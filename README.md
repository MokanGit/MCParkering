# MCParkering

En iOS-app för att hitta laglig MC-parkering i Stockholm, byggd med SwiftUI och MapKit.

Appen består av två delar:
- en huvudapp som visar MC-parkeringar på karta och hittar de närmaste platserna utifrån din position
- en Share Extension som tar emot delningar från Apple Maps, Google Maps och Safari och slår upp närmaste MC-parkering nära den delade destinationen

## Preview

Det här projektet är byggt för fysisk iPhone-användning. Huvudflödena är:
- se MC-parkeringar på karta
- hitta de tre närmaste parkeringarna nära din nuvarande position
- dela en plats eller länk från kart- eller webbläsarapp till MCParkering
- starta navigering vidare till vald MC-parkering i Apple Maps

## Features

- SwiftUI-baserad iOS-app
- MapKit-karta med användarposition och markörer
- Snabb lokal uppslagning av närmaste MC-parkering
- Share Extension för inkommande adresser, länkar och kartobjekt
- Stöd för Apple Maps och Google Maps-delningar
- Lokalt JSON-format optimerat för snabb laddning i appen

## Tech Stack

- Swift
- SwiftUI
- MapKit
- CoreLocation
- UIKit för Share Extension-host
- Python-skript för datainsamling och datakonvertering

## Project Structure

```text
MCParkering/
├── MCParkering/                # Huvudapp i SwiftUI
│   ├── ContentView.swift
│   ├── LocationManager.swift
│   ├── ParkingDataClient.swift
│   ├── ParkingModels.swift
│   └── mc_parkering_sthlm.json
├── MCParkeringShare/           # Share Extension
│   ├── Info.plist
│   └── ShareViewController.swift
├── Scripts/                    # Dataskript
│   ├── fetch_data.py
│   └── optimize_json.py
├── example.env
└── README.md
```

## Requirements

- Xcode 15 eller senare
- iOS 17.0 eller senare
- fysisk iPhone rekommenderas för test av platsdata och Share Extension
- Apple Developer-signering för enkel distribution till andra testare

## Getting Started

1. Öppna `MCParkering.xcodeproj` i Xcode.
2. Välj ditt `Development Team` för både `MCParkering` och `MCParkeringShare`.
3. Kontrollera att båda targets använder `iOS 17.0+`.
4. Bygg och kör appen på en fysisk enhet.

## Running the App

1. Anslut iPhone till Macen.
2. Välj enheten som run destination i Xcode.
3. Kör appen med `Cmd + R`.
4. Godkänn platsbehörighet när appen frågar efter den.

## Testing the Share Extension

1. Installera appen på telefonen.
2. Öppna Apple Maps, Google Maps eller Safari.
3. Dela en plats eller länk.
4. Välj `MCParkering` i share sheet.
5. Appen försöker hitta närmaste MC-parkering nära destinationen.

## Data Source

Parkeringsdatan bygger på Stockholms stads öppna data:

- [Stockholms Stad Open Parking](https://openparking.stockholm.se/)

## Data Scripts

I `Scripts/` finns två hjälpskript:

- `fetch_data.py`: hämtar rådata från API:t
- `optimize_json.py`: konverterar rådatan till ett kompakt JSON-format för appen

För att använda skripten:

1. Kopiera `example.env` eller `Scripts/example.env` till `Scripts/.env`
2. Fyll i din API-nyckel
3. Kör skripten från `Scripts/`

## Beta Distribution

Praktiska alternativ för testdistribution:

- Xcode-installation direkt till egen telefon
- TestFlight för interna och externa testare

För bredare beta-test är TestFlight den rimliga vägen, särskilt eftersom projektet innehåller en Share Extension.

## Notes

- Share Extension-flödet är känsligt för hur andra appar delar data, särskilt Google Maps-kortlänkar
- Projektet innehåller diagnostik för att felsöka delningsflödet under utveckling
- Produktionsdistribution bör använda Release-konfiguration och TestFlight

## License

Ingen licens angiven ännu.
