"""Lokale Validierung von AMB-Metadaten gegen JSON Schema."""

import json
from pathlib import Path

from jsonschema import Draft7Validator
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT7


AMB_VERSION = "20231019"

QA_DIR = Path(__file__).resolve().parents[1]

SCHEMA_DIR = (
    QA_DIR / "schemas" / "amb" / AMB_VERSION / "schemas"
)


def load_json(path: Path):
    """JSON-Datei einlesen."""

    with path.open(encoding="utf-8") as file:
        return json.load(file)

def check_format_support():
    """Funktionsfähigkeit der Datumsformatprüfung sicherstellen."""

    checker = Draft7Validator.FORMAT_CHECKER

    tests = [
        ("2019-07-03", "date", True),
        ("2019-02-30", "date", False),
        ("2019-07-03", "date-time", False),
        ("2019-07-03T13:13:13", "date-time", False),
        ("2019-07-03T13:13:13Z", "date-time", True),
    ]

    for value, format_name, expected in tests:
        if checker.conforms(value, format_name) != expected:
            raise RuntimeError(
                f"Formatprüfung für {format_name} fehlerhaft. "
                'Installiere jsonschema[format-nongpl].'
            )

def create_validator():
    """AMB-Validator mit lokaler Schema-Registry erzeugen."""

    check_format_support()

    schema_files = sorted(SCHEMA_DIR.glob("*.json"))

    if not schema_files:
        raise FileNotFoundError(
            f"Keine JSON-Schemas gefunden: {SCHEMA_DIR}"
        )

    resources = []

    for schema_file in schema_files:

        schema = load_json(schema_file)

        # Formale Gültigkeit des JSON-Schemas prüfen
        Draft7Validator.check_schema(schema)

        # Schema unter seiner offiziellen URI registrieren
        resources.append(
            (
                schema["$id"],
                Resource.from_contents(
                    schema,
                    default_specification=DRAFT7
                )
            )
        )

    registry = Registry().with_resources(resources)

    main_schema = load_json(SCHEMA_DIR / "schema.json")

    return Draft7Validator(
        main_schema,
        registry=registry,
        format_checker=Draft7Validator.FORMAT_CHECKER
    )


def validate_metadata(metadata, validator):
    """AMB-Metadaten validieren und Fehler zurückgeben."""

    errors = sorted(
        validator.iter_errors(metadata),
        key=lambda error: error.json_path
    )

    return [
        {
            "path": error.json_path,
            "message": error.message,
            "validator": error.validator
        }
        for error in errors
    ]