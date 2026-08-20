# Datapipeline

MCParkering använder Stockholms stads öppna `pmotorcykel`-data som första datakälla. Uppdateringen körs i GitHub Actions och resultatet når aldrig `main` utan mänsklig granskning.

```text
Schemalagd eller manuell GitHub Action
        -> API-nyckel från GitHub Secret
        -> Stockholms Open Parking API
        -> validering och normalisering
        -> stabila identifierare och läsbar JSON
        -> draft pull request
        -> maintainer granskar och slår ihop
```

Appen läser fortfarande en lokal JSON-resurs och gör inga API-anrop vid körning. Det ger snabb start, offline-stöd och builds utan hemligheter.

## GitHub Actions-flödet

Workflow-filen `.github/workflows/update-parking-data.yml` kan:

- startas manuellt från GitHub Actions
- köras varje måndag klockan 04:17 UTC
- avbryta om repository secret `OPEN_PARKING_API_KEY` saknas
- avbryta om API-svaret inte är giltigt eller innehåller färre än 100 poster
- köra tester för koordinater, normalisering och stabila identifierare
- köra samma tester utan secrets när uppdateringskoden ändras i en pull request
- göra JSON-filen läsbar och sorterad för mindre svårgranskade diffar
- öppna eller uppdatera en draft pull request på branchen `automation/update-parking-data`
- avsluta utan commit om källdatan inte har förändrats

Actionen har endast `contents: write` och `pull-requests: write`. Nyckeln skickas till uppdateringssteget men skrivs inte till fil, app-bundle eller logg.

## Konfiguration

Repository-maintainern behöver göra två inställningar på GitHub:

1. Lägg API-nyckeln i `Settings -> Secrets and variables -> Actions` med namnet `OPEN_PARKING_API_KEY`.
2. Tillåt att GitHub Actions skapar pull requests under `Settings -> Actions -> General -> Workflow permissions`.

Nyckeln ska inte läggas i en `.env`-fil eller delas med bidragsgivare.

## Starta en uppdatering

1. Öppna repots flik `Actions`.
2. Välj `Uppdatera parkeringsdata`.
3. Välj `Run workflow` på `main`.
4. Öppna den draft pull request som skapas.
5. Granska antal poster, diff och workflow-resultat.
6. Markera pull requesten som redo och slå ihop den när resultatet ser rimligt ut.

Första körningen ger en ovanligt stor diff eftersom tidigare slumpmässiga UUID:n ersätts med stabila identifierare och JSON-filen formateras över flera rader. Efter den första sammanslagningen ska kommande diffar huvudsakligen visa verkliga dataändringar.

## Lokal verifiering utan API-nyckel

Uppdateringslogiken använder bara Pythons standardbibliotek och kan testas utan nätverk eller hemligheter:

```bash
python3 -m unittest discover -s Scripts/tests -p "test_*.py"

python3 Scripts/update_parking_data.py \
  --input Scripts/tests/fixtures/parking_response.json \
  --min-records 2 \
  --output /tmp/mc-parkering-test.json
```

Vanlig apputveckling och externa bidrag ska använda den incheckade appfilen och behöver inte köra en riktig datahämtning.

## Normaliserat format

Varje post har följande form:

```json
{
  "id": "stabil UUID",
  "lat": 59.0,
  "lon": 18.0,
  "address": "Exempelgatan",
  "rate": "Avgiftsinformation",
  "info": "Övrig information"
}
```

Om API:t har en egen identifierare används den som grund. Annars skapas identiteten deterministiskt från koordinat och adress. Poster sorteras efter adress och koordinat innan de skrivs atomiskt till appfilen.

## Kvarvarande begränsningar

- Datasetets ålder visas ännu inte i appen.
- Schemat kontrolleras mot de fält appen använder, men inte mot ett separat publicerat JSON Schema.
- En förändring av dataleverantörens struktur kan stoppa Actionen och kräva kodändring.
- Rak linje används fortfarande för rangordning i appen; datapipelinen beräknar inte kör- eller gångavstånd.
