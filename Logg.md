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

## 2026-08-20 - Automatiserad uppdatering av parkeringsdata

Målet var att ersätta den manuella `.env`-baserade datauppdateringen med ett säkrare och mer granskningsbart GitHub Actions-flöde.

### Genomfört

- Samlade hämtning, validering och optimering i `Scripts/update_parking_data.py`.
- Flyttade API-nyckeln till GitHub Actions repository secrets.
- Lade till schemalagd körning varje vecka och möjlighet till manuell start.
- Lade till tester med lokal fixture så att transformeringen kan verifieras utan nätverk eller hemligheter.
- Införde kontroll av datamängd, struktur, koordinater och dubbletter innan appfilen ersätts.
- Bytte från slumpmässiga till stabila identifierare och läsbar, deterministiskt sorterad JSON.
- Konfigurerade Actionen att öppna en draft pull request i stället för att skriva direkt till `main`.
- Behöll maintainerkontroll över granskning, merge, Xcode Cloud, TestFlight och App Store.

### Noteringar

- Den första automatiska uppdateringen ger en stor diff när befintliga UUID:n och JSON-formatet normaliseras.
- Efter första sammanslagningen ska diffar främst motsvara faktiska ändringar i källdatan.
- API-nyckeln loggas inte, checkas inte in och följer inte med i appen.

## 2026-08-20 - Look Around och utökad kodkontroll

Målet var att ge användaren en visuell förhandsvisning av den valda MC-parkeringen och samtidigt utöka GitHub-flödet med automatisk säkerhetsanalys.

### Genomfört

- Lade till en interaktiv Look Around-thumbnail i den valda parkeringens detaljblad med SwiftUI och MapKit.
- Använde Apples inbyggda Look Around-kontroll för att öppna den navigerbara helskärmsvyn.
- Visar thumbnailen endast när MapKit returnerar en giltig scen; platser utan täckning lämnar inget tomrum eller felmeddelande i gränssnittet.
- Gjorde detaljbladet rullningsbart och behöll knappen för vägbeskrivning till parkeringen lättillgänglig längst ned.
- Flyttade hämtningen av Look Around-scenen till detaljbladets livscykel efter att telefontest identifierat att en uppgift kopplad till en tom villkorlig vy inte alltid startade.
- Verifierade funktionen på fysisk iPhone och byggde både huvudappen och Share Extension med aktuell Xcode-version.
- Utvecklade funktionen på en separat feature branch och öppnade draft pull request nummer 3 för granskning före sammanslagning till `main`.
- Aktiverade CodeQL i GitHub som ytterligare automatisk säkerhetskontroll på pull requests.

### Noteringar

- Look Around-täckning och bildmaterial tillhandahålls av Apple och kan variera mellan platser och över tid.
- MapKit kan skriva interna telemetri- och renderingsmeddelanden i Xcode-konsolen utan att de innebär ett fel i appen.
- Den första CodeQL-körningen på pull requesten analyserar GitHub Actions och Python. Swift-koden visas inte som en separat CodeQL-analys i den aktuella konfigurationen.
- Manuell testning på fysisk enhet är fortsatt viktig eftersom Look Around är beroende av MapKit, nätverksåtkomst och faktisk geografisk täckning.
