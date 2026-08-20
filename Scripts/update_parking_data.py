from __future__ import annotations

import argparse
import json
import os
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path
from typing import Any

API_URL = "https://openparking.stockholm.se/LTF-Tolken/v1/pmotorcykel/all"
REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPOSITORY_ROOT / "MCParkering" / "mc_parkering_sthlm.json"
SOURCE_PREFIX = "https://openparking.stockholm.se/LTF-Tolken/v1/pmotorcykel"


class ParkingDataError(ValueError):
    """Raised when source data cannot safely replace the bundled dataset."""


def fetch_source_data(api_key: str, timeout: int = 30) -> dict[str, Any]:
    query = urllib.parse.urlencode({"outputFormat": "json", "apiKey": api_key})
    request = urllib.request.Request(
        f"{API_URL}?{query}",
        headers={"User-Agent": "MCParkering-data-updater/1.0"},
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        raise ParkingDataError("Kunde inte hämta giltig JSON från datakällan.") from error

    if not isinstance(payload, dict):
        raise ParkingDataError("Datakällans svar måste vara ett JSON-objekt.")
    return payload


def _coordinate_pair(value: Any) -> tuple[float, float] | None:
    if not isinstance(value, (list, tuple)) or len(value) < 2:
        return None

    first, second = value[0], value[1]
    if isinstance(first, (int, float)) and isinstance(second, (int, float)):
        return float(first), float(second)

    for nested in value:
        pair = _coordinate_pair(nested)
        if pair is not None:
            return pair
    return None


def _optional_text(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _stable_id(feature: dict[str, Any], parking: dict[str, Any]) -> str:
    properties = feature.get("properties", {})
    source_id = feature.get("id")
    if source_id is None and isinstance(properties, dict):
        for key in ("FEATURE_OBJECT_ID", "OBJECTID", "ID", "id"):
            if properties.get(key) is not None:
                source_id = properties[key]
                break

    if source_id is None:
        source_id = json.dumps(
            {
                "lat": round(parking["lat"], 7),
                "lon": round(parking["lon"], 7),
                "address": parking["address"],
            },
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        )

    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"{SOURCE_PREFIX}/{source_id}"))


def _normalize_feature(feature: Any, index: int) -> dict[str, Any]:
    if not isinstance(feature, dict):
        raise ParkingDataError(f"Post {index} är inte ett JSON-objekt.")

    geometry = feature.get("geometry")
    properties = feature.get("properties")
    if not isinstance(geometry, dict) or not isinstance(properties, dict):
        raise ParkingDataError(f"Post {index} saknar geometry eller properties.")

    pair = _coordinate_pair(geometry.get("coordinates"))
    if pair is None:
        raise ParkingDataError(f"Post {index} saknar giltiga koordinater.")

    longitude, latitude = pair
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        raise ParkingDataError(f"Post {index} har koordinater utanför giltigt intervall.")

    parking = {
        "lat": latitude,
        "lon": longitude,
        "address": _optional_text(properties.get("ADDRESS")),
        "rate": _optional_text(properties.get("PARKING_RATE")),
        "info": _optional_text(properties.get("OTHER_INFO")),
    }
    return {"id": _stable_id(feature, parking), **parking}


def transform_source_data(
    payload: dict[str, Any], min_records: int = 100
) -> list[dict[str, Any]]:
    features = payload.get("features")
    if not isinstance(features, list):
        raise ParkingDataError("Datakällans svar saknar en features-lista.")
    if len(features) < min_records:
        raise ParkingDataError(
            f"Datakällan innehöll {len(features)} poster; minst {min_records} krävs."
        )

    parkings = [_normalize_feature(feature, index) for index, feature in enumerate(features)]
    ids = [parking["id"] for parking in parkings]
    if len(ids) != len(set(ids)):
        raise ParkingDataError("Datakällan gav dubbletter med samma stabila identifierare.")

    return sorted(
        parkings,
        key=lambda parking: (
            (parking["address"] or "").casefold(),
            parking["lat"],
            parking["lon"],
            parking["id"],
        ),
    )


def write_dataset(parkings: list[dict[str, Any]], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(parkings, ensure_ascii=False, indent=2) + "\n"

    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=output.parent,
        prefix=f".{output.name}.",
        delete=False,
    ) as temporary_file:
        temporary_file.write(serialized)
        temporary_path = Path(temporary_file.name)

    temporary_path.replace(output)


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Hämta, validera och optimera Stockholms MC-parkeringsdata."
    )
    parser.add_argument(
        "--input",
        type=Path,
        help="Läs ett lokalt API-svar i stället för att anropa datakällan.",
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--min-records", type=int, default=100)
    return parser.parse_args()


def main() -> int:
    arguments = _arguments()

    try:
        if arguments.input:
            with arguments.input.open(encoding="utf-8") as source_file:
                payload = json.load(source_file)
        else:
            api_key = os.environ.get("OPEN_PARKING_API_KEY", "").strip()
            if not api_key:
                raise ParkingDataError(
                    "Miljövariabeln OPEN_PARKING_API_KEY är inte konfigurerad."
                )
            payload = fetch_source_data(api_key)

        parkings = transform_source_data(payload, min_records=arguments.min_records)
        write_dataset(parkings, arguments.output)
    except (OSError, json.JSONDecodeError, ParkingDataError) as error:
        print(f"Fel: {error}")
        return 1

    print(f"Skrev {len(parkings)} validerade poster till {arguments.output}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
