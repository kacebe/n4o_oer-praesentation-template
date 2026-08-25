# Quarto OER-Template: Präsentation

Dieses Repository stellt ein **Quarto-Template für Reveal.js-Präsentationen** für FAIRedelte Open Educational Resources (OER) bereit.

Es eignet sich für browserbasierte Präsentationen, die mit Quarto erstellt, als HTML veröffentlicht und mit strukturierten OER-Metadaten ergänzt werden.

## Voraussetzungen

[Quarto ab Version 1.9](https://quarto.org)

## Nutzung als Template

Erstellen Sie ein lokales Verzeichnis und generieren Sie ein neues Quarto-Projekt auf Basis dieses Repositories mit:

```bash
quarto use template kacebe/n4o_oer-praesentation-template
```

Quarto legt ein neues Projektverzeichnis an und kopiert alle benötigten Dateien.

## Erste Schritte

1. Angaben zu Autor:innen und Institutionen in `_autor_innen.yml` anpassen.
2. Beschreibende Metadaten der Präsentation in `_praesentation.yml` anpassen.
3. OER- und Bildungsmetadaten in `_oer_metadata.yml` anpassen.
4. Bei Bedarf Layout und Reveal.js-Einstellungen in `_layout.yml` anpassen.
5. Bei Bedarf Farben, Typografie und Logos in `_brand.yml` anpassen.
6. Inhalte der Präsentation in `template.qmd` bearbeiten.

## Projektstruktur

Die wichtigsten Dateien des Templates sind:

```text
template.qmd
_quarto.yml
_layout.yml
_brand.yml
_autor_innen.yml
_praesentation.yml
_oer_metadata.yml

assets/
backgrounds/
_filters/
_includes/
_partials/
```

Dabei haben die Konfigurationsdateien unterschiedliche Aufgaben:

- `_autor_innen.yml`: Autor:innen und institutionelle Zugehörigkeiten
- `_praesentation.yml`: beschreibende und bibliografische Metadaten der Präsentation
- `_oer_metadata.yml`: OER- und Bildungsmetadaten
- `_layout.yml`: Reveal.js- und Layout-Einstellungen
- `_brand.yml`: Farben, Typografie und Logos
- `_quarto.yml`: Projektkonfiguration und Einbindung der Teilkonfigurationen

Die Verzeichnisse `_filters`, `_includes` und `_partials` enthalten technische Bestandteile des Templates und müssen für die normale Nutzung in der Regel nicht angepasst werden.

## Rendern

Die Präsentation wird mit Quarto gerendert:

```bash
quarto render
```

Die erzeugten Dateien werden im Unterverzeichnis `_site` abgelegt.

## Fork oder Template?

Die Nutzung als Template ist empfohlen, wenn Sie eine eigene Präsentation erstellen möchten.

Ein Fork ist sinnvoll, wenn Sie am Template selbst mitarbeiten oder es weiterentwickeln möchten.

## Dokumentation

Die [Dokumentation der FAIR-OER-Templates](https://nfdi4objects.github.io/oer-template-dokumentation/) liefert ausführliche Hinweise für Lehrende, Praktiker:innen und interessierte Entwickler:innen.

## Lizenz

Das Template in diesem Repository steht unter der Lizenz **[Creative Commons Attribution–ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/legalcode.de)**.

Die Lizenz ist bewusst gewählt, da die Templates keine Software im engeren Sinne sind, sondern **Struktur-, Konfigurations- und Textvorlagen** für Lehr- und Lernmaterialien.

## Förderung

Die Materialien entstanden in dem von der DFG geförderten Projekt [NFDI4Objects – Forschungsdateninfrastruktur für die materiellen Hinterlassenschaften der Menschheitsgeschichte](https://gepris.dfg.de/gepris/projekt/501836407) und wurden von der Task Area 6 an der [Hochschule Mainz](https://www.hs-mainz.de/) entwickelt.

<p align="center">
  <img src="https://www.dfg.de/resource/image/192702/16x9/858/483/8813c508271c12712973e1955ffdc082/86E5C6B4E28AAD65D48521A7A7498BF2/logo-gefoerdert-415.png" alt="Gefördert durch die DFG" width="250">
</p>
