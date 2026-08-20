# Publiceringslogg

## 2026-04-28 - MVP, arkitektur och datakällor

Målet var att definiera produktidén för MC-parkering, välja första datakälla och skissa en genomförbar iOS-MVP.

### Genomfört

- Formulerade kärnflödet som: destination -> hitta närmaste MC-parkering -> visa bästa kandidater -> navigera vidare.
- Valde Stockholm stads öppna `pmotorcykel`-data/API som första och primära datakälla för dedikerade MC-parkeringar.
- Bekräftade att första versionen ska utgå från explicit platsdata i stället för att försöka tolka generella parkeringsregler.
- Skissade nearest-parking-logik för MVP:
  - geokoda destination till koordinat
  - hämta och cache:a MC-parkeringar
  - beräkna avstånd med rak linje/Haversine i första versionen
  - returnera topp 5 närmaste kandidater
- Valde en SwiftUI-app med MapKit som riktning för iOS-MVP:n.
- Låste tre entry points för samma funktion:
  - Share Extension för delning från Apple Maps, Google Maps, Outlook och liknande appar
  - App Shortcut / Siri via App Intents
  - manuell sökvy i appen
- Bestämde att vald parkering ska kunna öppnas direkt i både Apple Maps och Google Maps för vidare navigering.

### Arkitekturbeslut

- Alla tre entry points ska använda samma gemensamma use case:
  - `FindParkingUseCase.findNearestParking(for:)`
- Rekommenderad ansvarsfördelning sattes till:
  - `ParkingDataClient`
  - `ParkingRepository`
  - `DestinationResolver`
  - `NearestParkingService`
  - `NavigationLauncher`
- Lokal cache ska ligga bakom repository-lagret och delas mellan huvudapp och Share Extension via App Groups.
- Mer avancerad ruttlogik, till exempel avstickare längs färdväg och gångavstånd från parkering till mål, sköts till senare versioner.

### Noteringar

- MVP:n bör börja med Stockholm, där datan är strukturerad och användbar direkt.
- Stöd för andra kommuner bör planeras från början men införas selektivt, eftersom datakällorna är heterogena och ofta mindre strukturerade.
- En framtida gemensam modell bör kunna bära källa, parkeringstyp och förtroendegrad för att hantera flera kommuner och olika datakvalitet.
- Ingen känslig information, inga nycklar och inga lokala miljödetaljer dokumenteras i denna publika logg.

## 2026-08-20 - TestFlight och internt test

Målet var att förbereda MC-parkeringen för TestFlight via App Store Connect och Xcode Cloud, samt skapa ett första internt test.

### Genomfört

- Skapade appen i App Store Connect.
- Kopplade appen till korrekt Bundle Identifier för huvudappen.
- Säkerställde att share extension använder en separat Bundle Identifier.
- Uppdaterade signing i Xcode till organisationens Apple Developer-konto.
- Behöll automatisk signing i Xcode.
- Tog bort lokala utvecklingsfiler från appens resources:
  - `.env`
  - `example.env`
  - `README.md`
  - `fetch_data.py`
  - `optimize_json.py`
- Behöll appens parkeringsdata som app-resource:
  - `MCParkering/mc_parkering_sthlm.json`
- Lade till export compliance-inställning:
  - `ITSAppUsesNonExemptEncryption = NO`
- Satte appkategori till navigation.
- Satte version/build till:
  - Version: `1`
  - Build: `2`
- Verifierade att projektet bygger lokalt i Xcode.
- Pushade projektinställningarna till GitHub så att Xcode Cloud kan bygga utan lokal `.env`.
- Skapade en intern TestFlight-grupp i App Store Connect.
- Lade till kontots användare som intern testare.
- Kopplade builden till den interna TestFlight-gruppen.
- Installerade appen på iPhone via TestFlight.

### Noteringar

- Den lokala API-nyckeln ligger endast i `Scripts/.env`.
- `Scripts/.env` ska inte checkas in i GitHub.
- Appen ska kunna byggas utan `.env`, eftersom den bara behövs för det lokala synk-scriptet.
- Team ID och andra kontodetaljer dokumenteras inte i denna publika logg.
