import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parents[1]
FIXTURE = Path(__file__).parent / "fixtures" / "parking_response.json"
sys.path.insert(0, str(SCRIPTS_DIR))

from update_parking_data import (  # noqa: E402
    ParkingDataError,
    transform_source_data,
    write_dataset,
)


class UpdateParkingDataTests(unittest.TestCase):
    def setUp(self):
        self.payload = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_transforms_flat_and_nested_coordinates(self):
        parkings = transform_source_data(self.payload, min_records=2)

        self.assertEqual([parking["address"] for parking in parkings], [
            "Birger Jarlsgatan",
            "Sturegatan",
        ])
        self.assertEqual(parkings[0]["lat"], 59.341)
        self.assertEqual(parkings[0]["lon"], 18.071)
        self.assertIsNone(parkings[1]["rate"])
        self.assertIsNone(parkings[1]["info"])

    def test_identifiers_and_order_are_stable(self):
        first = transform_source_data(self.payload, min_records=2)
        reversed_payload = {"features": list(reversed(self.payload["features"]))}
        second = transform_source_data(reversed_payload, min_records=2)

        self.assertEqual(first, second)

    def test_rejects_suspiciously_small_dataset(self):
        with self.assertRaises(ParkingDataError):
            transform_source_data(self.payload, min_records=3)

    def test_rejects_invalid_coordinates(self):
        self.payload["features"][0]["geometry"]["coordinates"] = [18.0, 159.0]

        with self.assertRaises(ParkingDataError):
            transform_source_data(self.payload, min_records=2)

    def test_writes_readable_json_atomically(self):
        parkings = transform_source_data(self.payload, min_records=2)

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "parking.json"
            write_dataset(parkings, output)
            text = output.read_text(encoding="utf-8")

        self.assertTrue(text.endswith("\n"))
        self.assertIn("\n  {\n", text)
        self.assertEqual(json.loads(text), parkings)


if __name__ == "__main__":
    unittest.main()
