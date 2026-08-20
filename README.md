# MCParkering

MCParkering är en iOS-app för att hitta närliggande, dedikerad MC-parkering i Stockholm. Repot är samtidigt ett öppet exempel på AI-assisterad utveckling i Xcode och ett praktiskt CI/CD-flöde från kodändring till TestFlight.

Projektet har två mål:

- lösa ett konkret problem för motorcyklister
- visa hur människa, AI, Xcode, GitHub, Xcode Cloud och TestFlight kan användas tillsammans med tydlig verifiering och mänskligt releaseansvar

## Produktidé

Kärnflödet är:

```text
Destination eller aktuell position
        -> närmaste MC-parkeringar
        -> välj parkering
        -> starta navigering
```

Huvudappen visar parkeringsplatser på en MapKit-karta och kan markera de tre närmaste platserna från användarens position. En Share Extension kan ta emot platser, adresser och länkar från bland annat Apple Maps, Google Maps och Safari och söka nära den delade destinationen.

## Status

| Funktion | Status |
| --- | --- |
| Karta med MC-parkeringar och användarposition | Implementerad |
| Tre närmaste parkeringar från aktuell position | Implementerad |
| Share Extension för kartobjekt, text och länkar | Implementerad |
| Tolkning av Apple Maps- och Google Maps-delningar | Implementerad, fortsatt testning behövs |
| Navigering till vald parkering i Apple Maps | Implementerad |
| Manuell destinationssökning i huvudappen | Planerad |
| App Shortcut och Siri via App Intents | Planerad |
| Navigering i Google Maps | Planerad |
| Gemensamt `FindParkingUseCase` och App Groups-cache | Planerad |
| Datakällor från fler kommuner | Utforskning |

Se [ROADMAP.md](ROADMAP.md) för prioritering och avgränsning.

## Teknik

- Swift, SwiftUI och UIKit
- MapKit och CoreLocation
- Share Extension
- GitHub Actions och Python för validerad datauppdatering
- GitHub, Xcode Cloud, App Store Connect och TestFlight

Parkeringsdatan kommer från [Stockholms stads Open Parking](https://openparking.stockholm.se/) och paketeras som en lokal JSON-resurs. En schemalagd GitHub Action hämtar och validerar ny data och öppnar en draft pull request. Den skriver aldrig direkt till `main`.

Appen och bidragsgivare behöver ingen API-nyckel. Nyckeln finns endast som GitHub repository secret för det avgränsade uppdateringsflödet.

## Kom igång

Förutsättningar:

- Xcode 26 eller senare
- iOS 26 eller senare enligt nuvarande projektinställningar
- fysisk iPhone rekommenderas för platsdata och Share Extension

```bash
git clone https://github.com/MokanGit/MCParkering.git
cd MCParkering
open MCParkering.xcodeproj
```

Välj `MCParkering`-schemat och kör först i simulatorn. För en fysisk enhet väljer du ett eget Development Team i Xcode för både huvudappen och extension-targeten. Lokala ändringar av team och bundle identifiers ska normalt inte följa med i en pull request.

Den incheckade JSON-filen räcker för vanlig apputveckling. Se [datapipelinen](docs/data-pipeline.md) för den automatiska uppdateringen och hur den kan testas utan hemligheter.

## Testa Share Extension

1. Installera appen på en iPhone.
2. Öppna Apple Maps, Google Maps eller Safari.
3. Dela en plats, adress eller kartlänk.
4. Välj MCParkering i delningsmenyn.
5. Kontrollera att destinationen och närliggande MC-parkeringar visas.
6. Välj en parkering och kontrollera att Apple Maps kan startas.

Delningsformat skiljer sig mellan appar och kan ändras över tid. Beskriv därför alltid avsändande app, iOS-version och delad datatyp i en felrapport.

## AI och kvalitet

AI används som utvecklingspartner för analys, kod, felsökning, dokumentation och testidéer. Projektägaren ansvarar fortfarande för produktbeslut, kodgranskning, integritet, verifiering på Apple-enheter och godkännande av releaser.

Repot publicerar beslut och lärdomar, inte hemligheter eller råa konversationer. Läs mer i [AI-arbetssättet](docs/ai-workflow.md) och [Lessons learned](docs/lessons-learned.md).

## Bidra

Bidrag via issues och pull requests är välkomna. Börja i [CONTRIBUTING.md](CONTRIBUTING.md), där utvecklingsmiljö, testförväntningar och AI-redovisning beskrivs.

Bidragsgivare behöver inte och ska inte ha åtkomst till projektägarens Apple Developer-konto, certifikat, API-nycklar eller App Store Connect. Projektägaren granskar och slår ihop bidrag och är ensam ansvarig för signering, TestFlight och App Store-publicering.

## Dokumentation

- [Arkitektur](docs/architecture.md)
- [AI-assisterat arbetssätt](docs/ai-workflow.md)
- [CI/CD och releaseansvar](docs/ci-cd.md)
- [Datapipeline](docs/data-pipeline.md)
- [Lessons learned](docs/lessons-learned.md)
- [Roadmap](ROADMAP.md)
- [Utvecklings- och publiceringslogg](Logg.md)

## Licens

Projektet publiceras under [CC0 1.0 Universal](LICENSE). Kontrollera alltid eventuella separata villkor och kvalitetsbegränsningar för externa datakällor.
