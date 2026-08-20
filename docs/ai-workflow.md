# AI-assisterat arbetssätt

MCParkering används som ett praktiskt exempel på hur AI kan vara en del av vanlig iOS-utveckling utan att ersätta mänskligt ansvar. Målet är inte att maximera mängden AI-genererad kod, utan att göra problemlösning, beslut och verifiering synliga.

## Ansvar

AI kan hjälpa till med:

- utforskning av API:er och Apple-ramverk
- förslag på arkitektur och avgränsning
- implementation, refaktorering och dokumentation
- testfall, felsökningshypoteser och granskning
- sammanfattning av beslut i utvecklingsloggen

Människan ansvarar för:

- produktmål och prioritering
- att kontext och krav är korrekta
- granskning av kod, datahantering och integritet
- verifiering i Xcode, simulator och på fysisk enhet
- Apple-signering och alla releasebeslut

## Arbetscykel

```text
Problem
  -> samla faktisk kontext från repo och enhet
  -> avgränsa en liten förändring
  -> AI föreslår eller implementerar
  -> mänsklig granskning
  -> build, test och verklig enhetskontroll
  -> dokumentera beslut och kvarvarande risk
```

Arbetet hålls i små steg så att varje ändring går att förstå, återställa och verifiera. När AI gör ett antagande ska det antingen bekräftas i koden eller beskrivas öppet som en osäkerhet.

## Dokumentera ett AI-arbetsmoment

Använd gärna följande rubriker i [utvecklingsloggen](../Logg.md), ett issue eller en pull request:

### Problem

Vilket användar- eller utvecklingsproblem skulle lösas?

### AI-bidrag

Vad hjälpte AI till med: analys, kod, felsökning, testidéer eller dokumentation?

### Mänskligt beslut

Vilket alternativ valdes, vad valdes bort och varför?

### Verifiering

Vilken build, vilket test eller vilken kontroll på fysisk enhet genomfördes?

### Resultat

Vad fungerar nu och vad återstår?

## Kvalitetsprinciper

- Kompilerbar kod är inte samma sak som korrekt produktbeteende.
- Apple-specifika flöden måste testas i sin riktiga kontext, särskilt Share Extensions, signing och navigering.
- AI-genererade kommentarer och namn ska städas så att koden blir enhetlig och långsiktigt begriplig.
- Nya beroenden, datakällor och behörigheter kräver en separat mänsklig bedömning.
- AI får inte fylla luckor i dokumentationen genom att beskriva planerade funktioner som implementerade.

## Offentlig dokumentation

Repot dokumenterar processen genom sammanfattade beslut och verifierbara resultat. Följande publiceras inte:

- API-nycklar, certifikat eller tokens
- Apple-konto- eller teamuppgifter
- personuppgifter, exakta användarresor eller känsliga destinationer
- lokala absoluta sökvägar
- råa AI-konversationer som kan innehålla känslig kontext

En bra offentlig logg gör det möjligt att förstå resonemanget utan att återskapa den privata arbetsmiljön.
