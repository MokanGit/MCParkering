import json
import uuid

with open('../MCParkering/mc_parkering_sthlm.json', 'r') as f:
    data = json.load(f)

if isinstance(data, list):
    print("Already optimized!")
    exit(0)

optimized = []
for feature in data.get('features', []):
    coords = feature['geometry']['coordinates']
    if isinstance(coords[0], list):
        lon, lat = coords[0][0], coords[0][1]
    else:
        lon, lat = coords[0], coords[1]
        
    props = feature['properties']
    
    optimized.append({
        'id': str(uuid.uuid4()),
        'lat': lat,
        'lon': lon,
        'address': props.get('ADDRESS'),
        'rate': props.get('PARKING_RATE'),
        'info': props.get('OTHER_INFO')
    })

with open('../MCParkering/mc_parkering_sthlm.json', 'w') as f:
    json.dump(optimized, f)
