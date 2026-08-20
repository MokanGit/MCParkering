# Bidra till MCParkering

Tack för att du vill förbättra MCParkering. Bidrag kan vara kod, tester, dokumentation, tillgänglighetsförbättringar, felrapporter eller analys av öppna parkeringsdata.

## Ansvarsfördelning

Projektet använder en maintainerstyrd releaseprocess:

- bidragsgivare utvecklar i egen fork eller branch och skickar pull requests
- projektägaren granskar och beslutar vad som slås ihop
- projektägaren ansvarar ensam för Apple-signering, versionsnummer, Xcode Cloud, TestFlight och App Store
- certifikat, privata nycklar, API-nycklar och åtkomst till Apple-konton delas aldrig med bidragsgivare

Det går alltså att bidra fullt ut utan åtkomst till distributionsmiljön.

## Innan du börjar

För mindre fel och dokumentationsändringar kan du öppna en pull request direkt. Öppna först ett issue för större funktioner, nya datakällor eller arkitekturändringar så att inriktningen kan diskuteras innan mycket arbete läggs ned.

Kontrollera också [ROADMAP.md](ROADMAP.md) och befintliga issues för att undvika dubbelarbete.

## Utvecklingsflöde

1. Skapa en fork av repot.
2. Skapa en avgränsad branch, exempelvis `feature/manual-search` eller `fix/share-google-link`.
3. Öppna `MCParkering.xcodeproj` i Xcode 26 eller senare.
4. Bygg huvudappen och `MCParkeringShare`.
5. Testa den ändrade funktionen i simulator och, när relevant, på fysisk iPhone.
6. Håll ändringen fokuserad och uppdatera dokumentation eller tester när beteendet ändras.
7. Skicka en pull request mot `main`.

Den paketerade parkeringsdatan gör att appen kan byggas utan API-nyckel. Följ bara [data-pipelinen](docs/data-pipeline.md) om bidraget kräver ett uppdaterat dataset.

## Lokal signering

Simulatorbyggen kräver normalt inte åtkomst till projektägarens Apple-konto. För körning på egen fysisk enhet:

1. Välj ditt eget Development Team för både appen och Share Extension.
2. Använd vid behov egna, unika bundle identifiers lokalt.
3. Behåll relationen mellan appens identifierare och extensionens suffix.
4. Ta bort lokala konto-, team- och identifierarändringar från pull requesten om de inte är själva syftet med bidraget.

Be aldrig om projektägarens certifikat eller privata nycklar för att kunna bidra.

## Verifiering

Det finns ännu inget komplett automatiserat testpaket. Redovisa därför exakt vad du har verifierat.

Minimikontroll för ändringar i huvudappen:

- projektet bygger utan lokala hemligheter
- kartan laddas
- nekad och beviljad platsbehörighet hanteras utan krasch
- `Hitta närmaste` markerar upp till tre platser
- vald parkering kan öppnas i Apple Maps

Minimikontroll för ändringar i Share Extension:

- extension-targeten bygger
- delning från berörda appar testas på fysisk iPhone
- avbryt fungerar
- ogiltig eller ofullständig delningsdata ger begripligt fel i stället för krasch
- navigering startar för vald parkering

Bifoga skärmbilder eller en kort skärminspelning när gränssnittet ändras.

## Pull request

En pull request ska beskriva:

- problemet och varför ändringen behövs
- vald lösning och viktiga avvägningar
- hur ändringen har testats
- kända begränsningar eller kvarvarande arbete
- om AI användes väsentligt och hur resultatet granskades

AI-assisterade bidrag är välkomna. Bidragsgivaren ansvarar för all inskickad kod på samma sätt som handskriven kod. Inkludera inte råa promptloggar om de innehåller personuppgifter, lokala sökvägar, nycklar eller annat känsligt innehåll.

## Kod och omfattning

- Följ befintlig Swift- och SwiftUI-stil tills en formatterare eller linter har införts.
- Separera refaktorering från beteendeförändringar när det är praktiskt möjligt.
- Lägg inte in nya tredjepartsberoenden utan att motivera behov, underhåll och integritetskonsekvenser.
- Logga inte delade adresser, destinationer eller koordinater som offentlig diagnostik i produktionsbyggen.
- Checka aldrig in `.env`, API-nycklar, Apple-certifikat, provisioning profiles eller användarspecifik Xcode-data.

## Data och licens

Nya datakällor ska dokumentera ursprung, licens eller användningsvillkor, uppdateringsfrekvens och kända kvalitetsproblem. Skicka endast material som du har rätt att bidra med. Accepterade bidrag publiceras under repots [CC0 1.0 Universal-licens](LICENSE).
