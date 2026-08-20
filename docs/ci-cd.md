# CI/CD och releaseansvar

Projektets releaseflöde är byggt för att källkoden ska kunna vara öppen samtidigt som Apple-konton, signering och publicering förblir under projektägarens kontroll.

## Nuvarande flöde

```mermaid
flowchart LR
    DEV[Lokal utveckling och test] --> GH[GitHub main]
    GH --> XC[Xcode Cloud build]
    XC --> ASC[App Store Connect]
    ASC --> TF[Intern TestFlight-grupp]
    TF --> DEVICE[Test på fysisk iPhone]
```

Appen har byggts utan lokal `.env`, skickats genom Xcode Cloud och installerats via en intern TestFlight-grupp. API-nyckeln används endast vid lokal datahämtning och är inte en del av appbygget.

## Två separata spår

### Bidragsspåret

1. Bidragsgivaren skapar en fork eller branch.
2. Ändringen byggs och testas lokalt.
3. En pull request beskriver lösning, verifiering och eventuell AI-användning.
4. Projektägaren granskar och slår ihop godkända bidrag.

Detta spår kräver inte App Store Connect, distributionscertifikat eller projektägarens Apple Developer-konto.

### Releasespåret

1. Projektägaren väljer vilka ändringar som ska ingå.
2. Version och unikt buildnummer kontrolleras.
3. Release-konfigurationen byggs via Xcode Cloud.
4. Bygget behandlas i App Store Connect.
5. Projektägaren kopplar rätt build till intern eller extern TestFlight-grupp.
6. Kritiska flöden verifieras på fysisk enhet.
7. Projektägaren beslutar separat om App Store-publicering.

## Hemligheter och signering

| Information | Hantering |
| --- | --- |
| Parkerings-API-nyckel | Endast lokal `Scripts/.env`, aldrig i Git eller app-bundle |
| Apple-inloggning | Hanteras utanför repot av projektägaren |
| Certifikat och privata nycklar | Delas inte och checkas aldrig in |
| Provisioning och distribution | Automatisk signing/Xcode Cloud under projektägarens kontroll |
| Parkeringsdata | Publik, optimerad JSON får ingå i appen |

En pull request ska aldrig kräva en produktionshemlighet för att kunna granskas.

## Releasechecklista

- [ ] Godkända ändringar finns på avsedd commit.
- [ ] Huvudapp och Share Extension bygger i Release-konfiguration.
- [ ] Appen bygger utan `.env` och andra lokala utvecklingsfiler.
- [ ] Version och buildnummer är korrekta och buildnumret är unikt.
- [ ] Behörigheter, signing, bundle identifiers och extension-konfiguration är kontrollerade.
- [ ] Kartan, platsbehörighet, närmaste-sökning och Apple Maps-navigation fungerar.
- [ ] Relevanta Share Extension-flöden är testade på fysisk iPhone.
- [ ] Diagnostik innehåller inte hemligheter eller känsliga destinationer.
- [ ] TestFlight-noteringar beskriver vad testaren ska fokusera på.
- [ ] Resultat och kända begränsningar dokumenteras i `Logg.md`.

## Nästa förbättringar

- automatiska build- och testkontroller på pull requests
- ett riktigt unit test-target och ett litet stabilt testdataset
- automatiserad kontroll att förbjudna filer inte ingår i app-resurser
- verifiering av datasetets schema och aktualitet
- tydligare versionsstrategi och release notes från sammanslagna ändringar
- en dokumenterad rutin för att stoppa eller ersätta en felaktig TestFlight-build

CI ska ge bevis på teknisk kvalitet. CD och publicering förblir ett uttryckligt mänskligt beslut.
