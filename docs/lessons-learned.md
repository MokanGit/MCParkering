# Lessons learned

Detta är ett levande dokument över tekniska och processmässiga lärdomar från MCParkering. En lärdom ska helst kopplas till ett faktiskt försök, en verifiering eller ett ändrat beslut.

## Produkt och avgränsning

### Börja med en tydlig användarresa

Flödet destination eller aktuell position -> närmaste MC-parkering -> navigering gav en tillräckligt smal MVP. Funktioner som ruttavstickare, gångavstånd och flera kommuner kan då utvärderas senare utan att blockera en testbar app.

### Rak linje är användbar men inte hela sanningen

CoreLocations avstånd är snabbt och deterministiskt. Det fungerar för att rangordna kandidater i en första version, men vatten, enkelriktade gator och gångvägar kan göra den geometriskt närmaste platsen sämre i praktiken.

## Apple-plattformen

### Verkliga integrationsflöden kräver en riktig enhet

Simulatorn är bra för snabb UI-utveckling. Platsbehörighet, Share Extension, skillnader mellan delande appar, navigering och TestFlight måste också verifieras på fysisk iPhone.

### Share-data är heterogen

Apple Maps, Google Maps och webbläsare skickar inte samma typ eller format. Robust mottagning behöver prioritera kartobjekt, text och URL, hantera kortlänkar och ge begripliga fel när destinationen inte kan lösas.

### Flera targets påverkar hela releasekedjan

Huvudapp och Share Extension innebär separata identifiers, signinginställningar och buildkontroller. Ett lokalt fungerande huvudtarget räcker inte som releasebevis.

## Data

### Paketerad data är ett medvetet robusthetsval

Lokal JSON ger snabb start, enkel felsökning och builds utan API-nyckel. Kostnaden är att aktualitet och uppdateringsprocess blir projektets ansvar.

### En extern datakälla behöver en intern kontraktsgräns

Stockholms data är tillräckligt strukturerad för MVP:n, men andra kommuner kan erbjuda WFS, filer, regeldata eller inget dedikerat MC-register. En gemensam modell och källa-adaptrar behövs innan fler kommuner läggs till.

### Reproducerbarhet är viktigare än ett engångsskript

Ett dataflöde ska kunna köras om med samma regler, validera resultatet och ge stabila identifierare. Slumpmässiga UUID:n och manuella filsteg gör diffar svårare att granska.

## Arkitektur

### Entry points ska dela användningsfall, inte kopiera beteende

Huvudapp, Share Extension och framtida Siri-stöd bör anropa samma `FindParkingUseCase`. Då blir rangordning, felhantering och datakälla konsekventa och möjliga att enhetstesta.

### Extensions behöver små och tydliga beroenden

Share Extensions har begränsad livstid och varierande indata. Parsing, geosökning och närhetslogik bör därför ligga utanför vyn och controllern.

## AI-assisterad utveckling

### AI är starkast när resultatet går att verifiera

Avgränsade kodändringar, dokumentation, testfall och analys fungerar bra när resultatet kan byggas, jämföras eller provas. Osäkra Apple- och API-antaganden behöver kontrolleras mot den faktiska miljön.

### Mänsklig granskning är en del av metoden

AI kan accelerera implementation, men produktval, integritet, tillgänglighet och releaseacceptans kan inte delegeras. Den mänskliga kontrollen ska dokumenteras som verifiering, inte bara antas.

### Sammanfattade beslut är mer användbara än råa promptloggar

En publik logg bör visa problem, alternativ, beslut, verifiering och resultat. Råa konversationer är ofta brusiga och kan innehålla känslig kontext.

## CI/CD och öppen källkod

### Build utan hemligheter är ett viktigt designkrav

Genom att hålla API-nyckeln i den lokala datapipelinen kan GitHub och Xcode Cloud bygga appen utan att känna till nyckeln. Det gör både öppen utveckling och extern medverkan enklare.

### Bidrag och publicering behöver inte ha samma behörighet

Andra kan förbättra kod, data och dokumentation via pull requests. Projektägaren kan samtidigt behålla ensam kontroll över signing, TestFlight och App Store.

### Dokumentation kan avvika från verkligheten

Versionskrav, licens, status och releaseflöde måste jämföras med repot. En README som beskriver planerad funktion som färdig eller säger att licens saknas trots en `LICENSE`-fil minskar förtroendet.

## Vad vi skulle göra tidigare nästa gång

- skapa test-target innan Share Extension växer
- definiera ett gemensamt use case innan flera entry points implementeras
- automatisera datahämtning, transformering och validering som ett flöde
- separera offentlig diagnostik från potentiellt känsliga destinationer från början
- dokumentera implementerat, planerat och utforskning i tre tydliga kategorier
