import urllib.request
import json
import os

# Läs in API-nyckeln från .env-filen
api_key = None
try:
    with open('.env', 'r') as f:
        for line in f:
            if line.startswith('OPEN_PARKING_API_KEY='):
                api_key = line.strip().split('=', 1)[1]
except FileNotFoundError:
    pass

API_KEY = api_key

def fetch_parking_data():
    if not API_KEY:
        print("⚠️ Kunde inte hitta OPEN_PARKING_API_KEY i .env-filen.")
        return

    url = f"https://openparking.stockholm.se/LTF-Tolken/v1/pmotorcykel/all?outputFormat=json&apiKey={API_KEY}"

    try:
        print(f"Hämtar data från Stockholms stad...")
        
        # Gör anropet
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            
            # Spara hela svaret till en lokal fil så vi kan titta på det i lugn och ro
            with open("mc_parkering_sthlm.json", "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                
            features = data.get("features", [])
            print(f"\n✅ Klart! Hämtade {len(features)} stycken MC-parkeringar.")
            print(f"Hela datasetet har sparats i filen 'mc_parkering_sthlm.json' i den här mappen.")
            
            # Skriv ut det första resultatet som ett exempel
            if features:
                print("\n--- Exempel på hur en parkering ser ut i datan ---")
                print(json.dumps(features[0], indent=2, ensure_ascii=False))
                print("---------------------------------------------------")
                
    except Exception as e:
        print(f"❌ Ett fel uppstod vid hämtningen: {e}")

if __name__ == "__main__":
    fetch_parking_data()
