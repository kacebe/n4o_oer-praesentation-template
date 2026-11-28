"""Test der AMB-Validierung anhand offizieller Beispieldatensätze."""

import unittest

from amb_validator import (
    AMB_VERSION,
    SCHEMA_DIR,
    create_validator,
    load_json,
    validate_metadata,
)


EXAMPLES_DIR = SCHEMA_DIR.parent / "examples"

VALID_DIR = EXAMPLES_DIR / "valid"
INVALID_DIR = EXAMPLES_DIR / "invalid"

# Bekannte Abweichung bei strenger RFC-3339-Formatprüfung
KNOWN_EXCEPTION = "dateTime.json"


class TestAMBSchema(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Validator einmalig für alle Tests initialisieren."""

        cls.validator = create_validator()

    def test_reference_files(self):
        """Vollständigkeit der Referenzdateien überprüfen."""

        self.assertEqual(len(list(SCHEMA_DIR.glob("*.json"))), 40)
        self.assertEqual(len(list(VALID_DIR.glob("*.json"))), 33)
        self.assertEqual(len(list(INVALID_DIR.glob("*.json"))), 35)

    def test_valid_examples(self):
        """Offiziell valide Beispieldatensätze überprüfen."""

        for path in sorted(VALID_DIR.glob("*.json")):

            if path.name == KNOWN_EXCEPTION:
                continue

            with self.subTest(file=path.name):

                metadata = load_json(path)
                errors = validate_metadata(
                    metadata, self.validator
                )

                self.assertEqual(errors, [], msg=str(errors))

    def test_invalid_examples(self):
        """Offiziell invalide Beispieldatensätze überprüfen."""

        for path in sorted(INVALID_DIR.glob("*.json")):

            with self.subTest(file=path.name):

                metadata = load_json(path)
                errors = validate_metadata(
                    metadata, self.validator
                )

                self.assertTrue(
                    errors,
                    msg=f"Unerwartet valide: {path.name}"
                )

    @unittest.expectedFailure
    def test_datetime_exception(self):
        """Dokumentierte Abweichung bei dateTime.json."""

        metadata = load_json(VALID_DIR / KNOWN_EXCEPTION)

        errors = validate_metadata(
            metadata, self.validator
        )

        self.assertEqual(errors, [], msg=str(errors))

    def test_datetime_error_location(self):
        """Überprüfen, ob die bekannte Ausnahme weiterhin
        ausschließlich dateCreated betrifft.
        """

        metadata = load_json(VALID_DIR / KNOWN_EXCEPTION)

        errors = validate_metadata(
            metadata, self.validator
        )

        self.assertEqual(len(errors), 1)
        self.assertEqual(errors[0]["path"], "$.dateCreated")
        self.assertEqual(errors[0]["validator"], "oneOf")


if __name__ == "__main__":

    print(f"AMB-Version: {AMB_VERSION}", flush=True)

    unittest.main(verbosity=2)