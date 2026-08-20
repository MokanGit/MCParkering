# Publiceringslogg

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
