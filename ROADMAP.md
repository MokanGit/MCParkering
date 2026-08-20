# Roadmap

Roadmapen skiljer mellan vad som finns i appen i dag och vad som är tänkt framåt. Den är vägledande; issues och pull requests används för den konkreta planeringen.

## Nuvarande bas

- SwiftUI-karta med Stockholms MC-parkeringar
- användarposition och tre närmaste platser
- detaljvy och navigering i Apple Maps
- Share Extension för kartobjekt, text och länkar
- lokal, optimerad JSON-data
- schemalagd och manuellt startbar datauppdatering via GitHub Actions
- intern distribution via Xcode Cloud och TestFlight

## Nu: kvalitet och gemensam kärna

- [ ] Lägg till unit test-target för JSON-avkodning, koordinattolkning och nearest-parking-logik.
- [ ] Lägg till UI- eller integrationstester för huvudflöden där Apple-ramverken tillåter det.
- [ ] Flytta gemensam logik till `FindParkingUseCase` med tydliga repository- och resolvergränssnitt.
- [ ] Minska ansvaret i `ShareViewController` genom att separera parsing, destinationsupplösning och presentation.
- [ ] Granska diagnostisk loggning så att delade adresser och koordinater inte exponeras i produktionsloggar.
- [x] Gör datapipelinen reproducerbar med validering, stabila identifierare och en granskningsbar draft pull request.
- [ ] Inför automatiska pull request-kontroller för build, tester och eventuell lintning.
- [ ] Lägg till skärmbilder eller en kort demo i README.

## Nästa: komplett destinationsflöde

- [ ] Lägg till manuell destinationssökning i huvudappen.
- [ ] Lägg till App Shortcut och Siri-stöd via App Intents.
- [ ] Låt alla tre entry points använda samma `FindParkingUseCase`.
- [ ] Inför cache och delad data via App Groups för huvudapp och Share Extension.
- [ ] Erbjud Apple Maps och Google Maps som navigeringsmål.
- [ ] Förbättra felhantering, VoiceOver, Dynamic Type och tomma tillstånd.
- [ ] Dokumentera enkel policy för dataaktualitet i appen.

## Senare: bättre relevans och fler datakällor

- [ ] Skapa ett `ParkingSource`-gränssnitt och adapter för Stockholm.
- [ ] Utvärdera kommuner runt Stockholm utifrån tillgänglighet, licens och datakvalitet.
- [ ] Lägg till källa, parkeringstyp, senast uppdaterad och förtroendegrad i den gemensamma modellen.
- [ ] Jämför rak linje med gångavstånd och faktisk rutt.
- [ ] Utforska parkering längs färdväg i stället för enbart närmast destinationen.
- [ ] Utvärdera användarrapporter utan att skapa onödig insamling av platsdata.
- [ ] Förbered lokalisering och stöd utanför Stockholm.

## Definition of done

En funktion betraktas som klar när:

- beteendet och avgränsningen är dokumenterade
- relevanta automatiska eller manuella tester är genomförda
- integritet och tillgänglighet är bedömda
- projektet bygger utan lokala hemligheter
- README eller annan användardokumentation är uppdaterad vid behov
- projektägaren har godkänt ändringen

## Releaseansvar

Roadmapen är öppen för bidrag, men releasebehörighet delegeras inte genom en pull request. Projektägaren beslutar om versionsnummer, signerar appen och publicerar till TestFlight och App Store.
