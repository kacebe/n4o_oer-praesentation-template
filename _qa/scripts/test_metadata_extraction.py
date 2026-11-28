"""Automatisierte Tests der AMB-Metadatenextraktion aus HTML."""

import json
import tempfile
import unittest

from pathlib import Path

from amb_validator import (
    SCHEMA_DIR,
    create_validator,
    load_json,
)

from validate_metadata import validate_file


VALID_EXAMPLE = (
    SCHEMA_DIR.parent / "examples" / "valid" / "about.json"
)


class TestMetadataExtraction(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Validator und validen Referenzdatensatz laden."""

        cls.validator = create_validator()

        cls.valid_metadata = json.dumps(
            load_json(VALID_EXAMPLE),
            ensure_ascii=False
        )

    def setUp(self):
        """Temporäres Verzeichnis für jede Testmethode."""

        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)

        self.html_path = (
            Path(self.temp_dir.name) / "test.html"
        )

    def script_block(
        self,
        content,
        script_id="n4o-amb-metadata",
        media_type="application/ld+json",
    ):
        """HTML-Script-Block erzeugen."""

        return (
            f'<script id="{script_id}" type="{media_type}">'
            f'{content}'
            '</script>'
        )

    def validate_html(self, content):
        """Temporäre HTML-Datei schreiben und validieren."""

        html = (
            '<!DOCTYPE html>'
            '<html lang="de">'
            '<head>'
            '<meta charset="utf-8">'
            f'{content}'
            '</head>'
            '<body></body>'
            '</html>'
        )

        self.html_path.write_text(
            html,
            encoding="utf-8"
        )

        return validate_file(
            self.html_path,
            self.validator
        )

    def assert_extraction_error(self, result, message=None):
        """Fehler bei der Extraktion oder JSON-Verarbeitung prüfen."""

        self.assertFalse(result["valid"])
        self.assertTrue(result["errors"])

        self.assertEqual(
            result["errors"][0]["validator"],
            "extraction"
        )

        if message:
            self.assertIn(
                message,
                result["errors"][0]["message"]
            )

    def test_valid_metadata(self):
        """Korrekten AMB-Block akzeptieren."""

        result = self.validate_html(
            self.script_block(self.valid_metadata)
        )

        self.assertTrue(result["valid"], result["errors"])
        self.assertEqual(result["errors"], [])

    def test_additional_jsonld_block(self):
        """Andere JSON-LD-Blöcke ignorieren."""

        content = (
            self.script_block(
                "{}",
                script_id="n4o-schema-metadata"
            )
            + self.script_block(self.valid_metadata)
        )

        result = self.validate_html(content)

        self.assertTrue(result["valid"], result["errors"])

    def test_missing_metadata(self):
        """Fehlenden AMB-Block erkennen."""

        result = self.validate_html("")

        self.assert_extraction_error(
            result,
            "Kein AMB-Metadatenblock"
        )

    def test_duplicate_metadata_blocks(self):
        """Mehrere AMB-Blöcke erkennen."""

        content = (
            self.script_block(self.valid_metadata)
            + self.script_block(self.valid_metadata)
        )

        result = self.validate_html(content)

        self.assert_extraction_error(
            result,
            "Mehrere AMB-Metadatenblöcke"
        )

    def test_wrong_media_type(self):
        """Falschen Medientyp erkennen."""

        result = self.validate_html(
            self.script_block(
                self.valid_metadata,
                media_type="application/json"
            )
        )

        self.assert_extraction_error(
            result,
            "falschen Medientyp"
        )

    def test_unclosed_script(self):
        """Nicht geschlossenen Script-Block erkennen."""

        content = (
            '<script id="n4o-amb-metadata" '
            'type="application/ld+json">'
            + self.valid_metadata
        )

        result = self.validate_html(content)

        self.assert_extraction_error(
            result,
            "nicht geschlossen"
        )

    def test_invalid_json(self):
        """Fehlerhafte JSON-Syntax erkennen."""

        result = self.validate_html(
            self.script_block('{"name": }')
        )

        self.assert_extraction_error(result)

    def test_duplicate_json_keys(self):
        """Doppelte JSON-Schlüssel erkennen."""

        result = self.validate_html(
            self.script_block(
                '{"name": "A", "name": "B"}'
            )
        )

        self.assert_extraction_error(
            result,
            "Doppelter JSON-Schlüssel"
        )

    def test_invalid_json_constants(self):
        """Nicht standardkonforme JSON-Konstanten erkennen."""

        for constant in ("NaN", "Infinity", "-Infinity"):

            with self.subTest(constant=constant):

                result = self.validate_html(
                    self.script_block(
                        '{"value": ' + constant + '}'
                    )
                )

                self.assert_extraction_error(
                    result,
                    "Unzulässige JSON-Konstante"
                )

    def test_schema_violation(self):
        """Syntaktisch korrektes, aber AMB-invalides JSON erkennen."""

        result = self.validate_html(
            self.script_block("{}")
        )

        self.assertFalse(result["valid"])
        self.assertTrue(result["errors"])

        self.assertTrue(
            all(
                error["validator"] != "extraction"
                for error in result["errors"]
            )
        )

    def test_missing_file(self):
        """Nicht vorhandene HTML-Datei erkennen."""

        result = validate_file(
            self.html_path,
            self.validator
        )

        self.assert_extraction_error(result)


if __name__ == "__main__":
    unittest.main(verbosity=2)