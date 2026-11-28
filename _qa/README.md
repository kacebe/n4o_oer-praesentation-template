# Qualitätssicherung der N4O RevealJS-OER-Templates

## Zielsetzung

Die Qualitätssicherung (Quality Assurance, QA) dient der automatisierten Überprüfung der durch Quarto und die templatespezifischen Lua-Filter generierten Metadaten.

Sie ermöglicht insbesondere:

- die Prüfung der syntaktischen Validität von JSON-LD-Metadaten;
- die formale Validierung gegen versionierte Metadatenschemas;
- die Erkennung von Regressionen bei Aktualisierungen von Quarto, Pandoc, Lua-Filtern und Validierungsbibliotheken;
- die reproduzierbare lokale und automatisierte Ausführung der Validierung.

Die Komponenten der Qualitätssicherung sind ausschließlich Bestandteil der Entwicklungsumgebung. Sie werden bei der Installation des Templates mittels `quarto use template` nicht übernommen.

## Verzeichnisstruktur

```text
_qa/
├── README.md
├── requirements.txt
├── .venv/
├── schemas/
│   └── amb/
│       ├── REFERENCE.md
│       └── 20231019/
├── scripts/
│   ├── amb_validator.py
│   ├── validate_metadata.py
│   ├── test_amb_schema.py
│   └── test_metadata_extraction.py
├── tests/
└── reports/
```

Die virtuelle Python-Umgebung und die generierten Validierungsberichte werden nicht versioniert.

## Referenzgrundlage

Die derzeit implementierte Validierung basiert auf dem Allgemeinen Metadatenprofil für Bildungsressourcen (AMB).

- Herausgeber: DINI-AG-KIM
- Spezifikationsversion: 20231019
- Schemaformat: JSON Schema Draft 07
- Repository: https://github.com/dini-ag-kim/amb
- Spezifikation: https://w3id.org/kim/amb/20231019/
- Hauptschema: `schemas/amb/20231019/schemas/schema.json`
- Provenienzdokumentation: `schemas/amb/REFERENCE.md`

Die originalen Schemas, JSON-LD-Kontexte und Beispieldatensätze werden unverändert vorgehalten.

Die Auflösung der absoluten Schema-Referenzen erfolgt über eine lokale Schema-Registry. Die formale Validierung benötigt daher keinen Zugriff auf externe Schema-Server.

## Voraussetzungen

Die Implementierung wurde mit folgender Umgebung getestet:

- Ubuntu 24.04 LTS
- Python 3.12.3
- Quarto 1.11.9
- jsonschema 4.26.0
- referencing 0.37.0

Die vollständigen Python-Abhängigkeiten sind in `requirements.txt` dokumentiert.

## Lokale Installation

Alle nachfolgenden Befehle werden im Hauptverzeichnis des Template-Repositorys ausgeführt.

Virtuelle Python-Umgebung erzeugen:

```bash
python3 -m venv _qa/.venv
```

Abhängigkeiten installieren:

```bash
_qa/.venv/bin/python -m pip install -r _qa/requirements.txt
```

Installation überprüfen:

```bash
_qa/.venv/bin/python -m pip check
```

Die Aktivierung der virtuellen Umgebung ist für die Ausführung der Validierung nicht erforderlich.

## Test des Validierungsverfahrens

Sämtliche automatisierten Tests ausführen:

```bash
_qa/.venv/bin/python -m unittest discover \
  -s _qa/scripts \
  -p 'test_*.py' \
  -v
```

Die Tests umfassen:

- Vollständigkeit des AMB-Referenzmaterials;
- Validierung der offiziellen AMB-Beispieldatensätze;
- Überprüfung der Formatvalidierung;
- Extraktion von JSON-LD-Metadaten aus HTML-Dateien;
- Erkennung fehlender oder mehrfach vorhandener Metadatenblöcke;
- Erkennung syntaktisch und formal invalider Metadaten.

### Bekannte Abweichung im AMB-Referenzmaterial

Der offiziell als valide klassifizierte Beispieldatensatz `examples/valid/dateTime.json` enthält eine Datums- und Zeitangabe ohne Zeitzoneninformation:

```json
"dateCreated": "2019-07-03T13:13:13"
```

Diese Angabe besteht die strenge RFC-3339-Formatprüfung nicht.

Die Abweichung wird als erwarteter Testfehler (`expected failure`) behandelt. Ein zusätzlicher Test überprüft, ob der Fehler weiterhin ausschließlich die betreffende Property und Schema-Bedingung betrifft.

Die originalen Referenzdateien werden nicht verändert.

## Lokale Validierung

Das Quarto-Projekt rendern:

```bash
quarto render
```

Die generierten Präsentationen validieren:

```bash
_qa/.venv/bin/python _qa/scripts/validate_metadata.py \
  _site/index.html \
  _site/template.html \
  --report _qa/reports/validation.json
```

Alternativ können beliebige andere HTML-Dateien mit dem entsprechenden AMB-JSON-LD-Block validiert werden.

Die Identifikation des Metadatenblocks erfolgt anhand der Script-ID `n4o-amb-metadata`.

## Validierungsbericht

Der Validierungsbericht wird im JSON-Format ausgegeben und enthält:

- den verwendeten Metadatenstandard;
- die Version der Referenzgrundlage;
- das Gesamtergebnis;
- die Ergebnisse für sämtliche geprüften Dateien;
- festgestellte Fehler einschließlich JSON-Pfad und verletzter Schema-Bedingung.

Das Validierungsskript verwendet folgende Exit-Codes:

| Exit-Code | Bedeutung |
|---|---|
| 0 | Alle übergebenen Dateien wurden erfolgreich validiert. |
| 1 | Mindestens eine Datei konnte nicht erfolgreich validiert werden. |

Weitere Exit-Codes können bei Fehlern der Programmumgebung oder der Kommandozeilenargumente auftreten.

## Automatisierte Validierung mit GitHub Actions

Der Workflow `.github/workflows/validate.yml` führt die Qualitätssicherung automatisiert aus.

Er umfasst:

1. Bereitstellung von Quarto und Python;
2. Installation der Python-Abhängigkeiten;
3. Ausführung der automatisierten Tests;
4. Rendern des Quarto-Projekts;
5. Validierung der generierten Metadaten;
6. Bereitstellung des Validierungsberichts als Workflow-Artefakt, sofern dieser erzeugt werden konnte.

Der Workflow wird bei Pushes auf den Branch `main`, bei Pull Requests gegen `main` sowie bei manueller Auslösung ausgeführt.

Der Validierungsworkflow ist unabhängig vom Publikationsworkflow. Eine fehlgeschlagene Validierung verhindert daher nicht automatisch die Veröffentlichung auf GitHub Pages.

## Aktualisierung der Referenzgrundlagen

Bei einer Aktualisierung des AMB-Schemas oder der Validierungsbibliotheken sind folgende Schritte erforderlich:

1. Herkunft und Version der neuen Referenzgrundlage dokumentieren.
2. Referenzdateien unverändert übernehmen.
3. Vollständigkeit und lokale Auflösbarkeit der Schemas überprüfen.
4. Automatisierte Referenztests ausführen.
5. Bekannte Abweichungen erneut bewerten.
6. Quarto-Projekt rendern und Metadaten validieren.
7. Änderungen der Validierungsergebnisse dokumentieren.

## Grenzen der Validierung

Die derzeitige Implementierung überprüft die syntaktische und formale Konformität der AMB-Metadaten.

Nicht Gegenstand der automatisierten Validierung sind bislang:

- die vollständige semantische Konformität der Metadaten;
- die Auflösbarkeit und inhaltliche Richtigkeit externer Identifikatoren;
- die Übereinstimmung der Metadaten mit kontrollierten Vokabularen über die im JSON-Schema festgelegten Anforderungen hinaus;
- die Schema.org-Metadaten;
- die bibliographischen HTML-Metadaten;
- die Konsistenz zwischen unterschiedlichen Metadatenrepräsentationen.

Die Qualitätssicherungsumgebung ist so aufgebaut, dass weitere Validierungsverfahren ergänzt werden können.