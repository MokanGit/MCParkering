# Datapipeline

MCParkering använder Stockholms stads öppna `pmotorcykel`-data som första datakälla. API-data hämtas utanför appens runtime, förenklas och paketeras i appen som JSON.

```text
Stockholms Open Parking API
        -> fetch_data.py
        -> rå GeoJSON-liknande data
        -> optimize_json.py
        -> kompakt appmodell
        -> mc_parkering_sthlm.json i app-bundlen
```

Den nuvarande paketerade filen är cirka 218 KB och innehåller 635 parkeringsposter. Antalet förändras när källdatan uppdateras.

## Varför datan paketeras

- appen startar snabbt och fungerar utan nätverksanrop
- användare och CI behöver ingen API-nyckel
- huvudapp och Share Extension kan läsa samma format
- en extern driftstörning påverkar inte grundfunktionen

Nackdelen är att appens data bara är så aktuell som den senaste kontrollerade uppdateringen.

## Lokal uppdatering

Vanlig apputveckling kräver inte detta flöde. För att uppdatera datasetet behöver du en egen nyckel från dataleverantören.

```bash
cd Scripts
cp example.env .env
# Lägg nyckeln i .env och kör sedan:
python3 fetch_data.py
cp mc_parkering_sthlm.json ../MCParkering/mc_parkering_sthlm.json
python3 optimize_json.py
```

`Scripts/.env` ignoreras av Git och ska aldrig checkas in. Skripten skriver över datasetet, så granska alltid ändringen med Git innan den accepteras.

Efter uppdatering:

1. Kontrollera att resultatet är en JSON-lista och att poster har förväntade fält.
2. Kontrollera antal poster och avvikande koordinater.
3. Bygg både huvudapp och Share Extension utan `.env`.
4. Testa några kända adresser och närmaste-sökningar.
5. Dokumentera källa, hämtningsdatum, antal poster och verifiering i pull requesten eller loggen.

## Appformat

Varje post har följande form:

```json
{
  "id": "UUID",
  "lat": 59.0,
  "lon": 18.0,
  "address": "Exempelgatan",
  "rate": "Avgiftsinformation",
  "info": "Övrig information"
}
```

Koordinaterna lagras som latitud och longitud för att undvika beroende av källans geometri i appkoden.

## Kända begränsningar

- Hämtning och optimering är ännu inte ett enda reproducerbart kommando.
- Optimeringen skapar nya slumpmässiga UUID:n vid varje full uppdatering, vilket ger onödigt stora diffar och instabila identiteter.
- Det finns ännu ingen automatisk validering av koordinater, dubbletter eller tomma obligatoriska fält.
- Datasetets ålder visas inte i appen.
- Datakällans tillgänglighet och schema kan förändras oberoende av appen.

Nästa steg är en deterministisk transformering med validering, metadata och ett tydligt felutfall innan appfilen ersätts.
