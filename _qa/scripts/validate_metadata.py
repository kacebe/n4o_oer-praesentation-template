"""AMB-Metadaten aus gerenderten HTML-Dateien validieren."""

import argparse
import json

from html.parser import HTMLParser
from pathlib import Path

from amb_validator import (
    AMB_VERSION,
    create_validator,
    validate_metadata,
)


SCRIPT_ID = "n4o-amb-metadata"


class AMBExtractor(HTMLParser):
    """AMB-JSON-LD-Block aus HTML extrahieren."""

    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.blocks = []
        self.buffer = []
        self.capturing = False

    def handle_starttag(self, tag, attrs):

        attrs = dict(attrs)

        if tag == "script" and attrs.get("id") == SCRIPT_ID:

            if attrs.get("type") != "application/ld+json":
                raise ValueError(
                    "AMB-Script besitzt einen falschen Medientyp."
                )

            self.capturing = True
            self.buffer = []

    def handle_data(self, data):

        if self.capturing:
            self.buffer.append(data)

    def handle_endtag(self, tag):

        if tag == "script" and self.capturing:

            self.blocks.append("".join(self.buffer))
            self.capturing = False


def reject_duplicate_keys(pairs):
    """Doppelte JSON-Schlüssel als Fehler behandeln."""

    result = {}

    for key, value in pairs:

        if key in result:
            raise ValueError(f"Doppelter JSON-Schlüssel: {key}")

        result[key] = value

    return result


def reject_constant(value):
    """Nicht standardkonforme JSON-Konstanten ablehnen."""

    raise ValueError(f"Unzulässige JSON-Konstante: {value}")


def extract_metadata(path):
    """AMB-Metadaten aus einer HTML-Datei einlesen."""

    parser = AMBExtractor()

    parser.feed(path.read_text(encoding="utf-8"))
    parser.close()

    if parser.capturing:
        raise ValueError("AMB-Script wurde nicht geschlossen.")

    if not parser.blocks:
        raise ValueError("Kein AMB-Metadatenblock gefunden.")

    if len(parser.blocks) > 1:
        raise ValueError("Mehrere AMB-Metadatenblöcke gefunden.")

    return json.loads(
        parser.blocks[0],
        object_pairs_hook=reject_duplicate_keys,
        parse_constant=reject_constant,
    )


def validate_file(path, validator):
    """Eine HTML-Datei extrahieren und validieren."""

    result = {
        "file": str(path),
        "valid": False,
        "errors": [],
    }

    try:

        metadata = extract_metadata(path)

        result["errors"] = validate_metadata(
            metadata, validator
        )

        result["valid"] = not result["errors"]

    except (OSError, ValueError) as error:

        result["errors"].append({
            "path": None,
            "message": str(error),
            "validator": "extraction",
        })

    return result


def main():
    """Kommandozeilenschnittstelle."""

    parser = argparse.ArgumentParser(
        description="AMB-Metadaten in HTML-Dateien validieren."
    )

    parser.add_argument(
        "files",
        nargs="+",
        type=Path,
        help="Zu validierende HTML-Dateien",
    )

    parser.add_argument(
        "--report",
        type=Path,
        help="Pfad zum JSON-Validierungsbericht",
    )

    args = parser.parse_args()

    validator = create_validator()

    results = [
        validate_file(path, validator)
        for path in args.files
    ]

    report = {
        "standard": "AMB",
        "version": AMB_VERSION,
        "valid": all(result["valid"] for result in results),
        "files": results,
    }

    print(f"AMB-Version: {AMB_VERSION}")

    for result in results:

        status = "VALID" if result["valid"] else "INVALID"

        print(f"\n[{status}] {result['file']}")

        for error in result["errors"]:

            print(
                f"  {error['path'] or 'HTML/JSON'}: "
                f"{error['message']}"
            )

    if args.report:

        args.report.parent.mkdir(
            parents=True, exist_ok=True
        )

        args.report.write_text(
            json.dumps(
                report,
                ensure_ascii=False,
                indent=2,
            ) + "\n",
            encoding="utf-8",
        )

        print(f"\nValidierungsbericht: {args.report}")

    return 0 if report["valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())