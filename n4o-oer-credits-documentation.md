# N4O OER Credits Documentation

Stand: 27. August 2026

Vollständig KI-generiert

## Problemstellung: Autorschaft und Rollen im wissenschaftlichen Publizieren

Autorschaft und Beitrag zu einer Publikation sind unterschiedliche Aussagen. Die traditionelle Autor:innenzeile weist Personen als Urheber:innen eines Werkes aus und ist bibliografisch relevant. Sie bildet jedoch nicht ab, welche konkreten Beiträge einzelne Personen geleistet haben. In kollaborativen Forschungs- und Publikationsprozessen können beispielsweise Konzeption, Datenerhebung, Softwareentwicklung, Visualisierung, Redaktion oder Projektmanagement auf unterschiedliche Personen verteilt sein.

Die Contributor Roles Taxonomy CRediT wurde entwickelt, um solche Beiträge strukturiert zu dokumentieren. Sie umfasst 14 Rollen und ergänzt traditionelle Autorschaft. CRediT definiert ausdrücklich nicht, welche Beiträge eine Person zur Autor:in machen. Die Rollen können deshalb sowohl für formale Autor:innen als auch für andere Mitwirkende verwendet werden. Nachweis: https://credit.niso.org/ und https://credit.niso.org/contributor-roles-defined/

Neben CRediT existieren weitere Rollenvokabulare. DataCite unterscheidet Creator und Contributor und verlangt für Contributor einen kontrollierten contributorType. Bibliothekarische Modelle wie MARC Relators beschreiben Funktionen wie Speaker oder Translator. OER-spezifische Modelle wie DALIA und HS-OER-LOM kombinieren oder übernehmen Teile solcher Vokabulare. Die Begriffe sind dabei nicht durchgehend deckungsgleich.

Für Metadatenmodelle folgt daraus, dass drei Ebenen getrennt behandelt werden müssen:

* bibliografischer Status einer Person als Autor:in beziehungsweise sonstige:r Mitwirkende:r
* konkrete Beiträge zur Entstehung eines Werkes
* weitere Funktionen einer Person im Zusammenhang mit der Ressource, beispielsweise Speaker, Editor oder Translator

Eine automatische Ableitung von Autorschaft aus einer Beitragsrolle ist fachlich nicht begründbar. Ebenso ist eine automatische Übersetzung zwischen unterschiedlichen Rollenvokabularen nur dort vertretbar, wo eine eindeutige Entsprechung dokumentiert ist.

## Behandlung durch Quarto

Quarto verwendet author beziehungsweise authors als zentrales Metadatenfeld für Autor:innen. Die Angaben werden intern normalisiert und unter anderem als author, authors und by-author bereitgestellt. by-author enthält die normalisierten Personendaten einschließlich Affiliations und eignet sich für die Verarbeitung in Templates und Lua-Filtern. Nachweis: https://quarto.org/docs/journals/authors.html

Quarto unterstützt innerhalb eines Autor:innenobjekts das Feld roles. Freie Rollenbezeichnungen sind möglich. Werden eine der 14 CRediT-Rollen oder von Quarto erkannte Aliase verwendet, ergänzt Quarto die normalisierte Rollenangabe um Informationen zum CRediT-Vokabular. Nachweis: https://quarto.org/docs/authoring/front-matter.html#author-roles und https://quarto.org/docs/journals/authors.html#roles

Quarto behandelt roles als Beschreibung des Beitrags einer bereits unter author geführten Person. Das Feld entscheidet nicht darüber, ob eine Person Autor:in ist. Eine Person unter author bleibt deshalb auch dann Autor:in, wenn ihre einzige Rolle beispielsweise conceptualization oder visualization lautet.

Nicht zum geschlossenen Quarto-Autor:innenschema gehörende Schlüssel werden bei der Normalisierung unter metadata eingeordnet. Templatespezifische Erweiterungen sind damit technisch möglich, sollten aber semantisch klar von den nativen Quarto-Feldern getrennt werden. Nachweis: https://quarto.org/docs/journals/authors.html#arbitrary-metadata

## Status quo: CRediT

CRediT ist seit 2022 als ANSI/NISO Z39.104-2022 standardisiert. Die Taxonomie umfasst Conceptualization, Data curation, Formal analysis, Funding acquisition, Investigation, Methodology, Project administration, Resources, Software, Supervision, Validation, Visualization, Writing – original draft und Writing – review & editing. Nachweis: https://credit.niso.org/ und https://credit.niso.org/contributor-roles-defined/

CRediT beschreibt Arten von Beiträgen, die Personen bei der Entstehung eines wissenschaftlichen Outputs leisten. Die Taxonomie wurde entwickelt, um diese Beiträge differenzierter und transparenter sichtbar zu machen, als dies über eine traditionelle Autor:innenliste allein möglich ist. Sie ergänzt damit die bibliografische Angabe von Autor:innen um eine Beschreibung konkreter Tätigkeiten wie Conceptualization, Methodology, Visualization, Software oder Writing.

CRediT legt jedoch ausdrücklich nicht fest, welche dieser Beiträge eine Person zur Autor:in eines Werkes machen. Die Taxonomie ist daher kein System zur Entscheidung über Autorschaft, sondern ein Vokabular zur Beschreibung geleisteter Beiträge. Eine Person kann beispielsweise als Autor:in eines Werkes geführt werden und als einzigen CRediT-Beitrag Visualization angeben. Umgekehrt kann eine Person einen Beitrag wie Conceptualization oder Software geleistet haben, ohne bibliografisch als Autor:in ausgewiesen zu werden.

CRediT-Rollen dürfen deshalb nicht unmittelbar als bibliografische Rollen interpretiert werden. Eine Rolle wie Conceptualization, Visualization oder Funding acquisition bedeutet weder automatisch Autor:innenschaft noch automatisch den Status als sonstige:r Contributor. Ob eine Person als Autor:in oder als weitere mitwirkende Person geführt wird, muss unabhängig von der CRediT-Rolle bestimmt werden. CRediT beschreibt anschließend, welchen Beitrag diese Person zur Entstehung des Werkes geleistet hat.

## Status quo: DataCite

DataCite Metadata Schema 4.6 unterscheidet Creator und Contributor. Bei Verwendung von Contributor ist contributorType obligatorisch. Das kontrollierte Vokabular umfasst unter anderem ContactPerson, DataCollector, DataCurator, DataManager, Distributor, Editor, Producer, ProjectLeader, ProjectManager, Researcher, RightsHolder, Sponsor, Supervisor und Translator. Nachweis: https://datacite-metadata-schema.readthedocs.io/en/4.6/properties/contributor/ und https://datacite-metadata-schema.readthedocs.io/en/4.6/appendices/appendix-1/contributorType/

DataCite hat für Schema 4.5 ausdrücklich geprüft, das eigene contributorType-Vokabular mit CRediT interoperabel zu machen. Eine vollständige 1:1-Abbildung wurde verworfen, weil die Bedeutungen nicht durchgehend übereinstimmen und CRediT mehrere Rollen pro Person zulässt, während contributorType in Schema 4.x nur einmal angegeben werden kann. Für eine spätere Hauptversion wurde deshalb ein wiederholbares Rollenelement mit externen Vokabularen erwogen. Nachweis: https://datacite.org/wp-content/uploads/2023/09/DataCite_Metadata_Schema_4.5_RFC.pdf

Damit bietet DataCite keinen normativen vollständigen Crosswalk von CRediT zu contributorType.

## Status quo: vorhandene Rollen-Crosswalks

Ein veröffentlichter Contributor Roles Crosswalk von Ted Habermann stellt unter anderem CRediT, Credit Role Ontology, DataCite, DDI und ISO 19115 gegenüber. Der Crosswalk wird ausdrücklich als Ausgangspunkt und nicht als definitive Zuordnung beschrieben. Nachweis: https://doi.org/10.5281/zenodo.4767798

Der Crosswalk bestätigt, dass sich einzelne Rollen sinnvoll annähern lassen, eine generelle automatische Übersetzung aber problematisch ist. Dies gilt insbesondere für Rollen, deren Bezeichnungen ähnlich erscheinen, deren Definitionen jedoch unterschiedliche Tätigkeiten oder Verantwortlichkeiten umfassen.

## Status quo: DALIA und MoDALIA

Das DALIA Interchange Format DIF beschreibt Metadaten für Lehr- und Lernmaterialien. Version 1.4 wurde am 16. Februar 2026 veröffentlicht und führt Contributors ausdrücklich als neues Attribut ein, um über die Liste der Creator hinaus unterschiedliche Beiträge zu einer Bildungsressource abzubilden. Nachweis: https://doi.org/10.5281/zenodo.17871138

Die zugrunde liegende MoDALIA-Ontologie modelliert Contributor Roles als kontrolliertes Vokabular. Dazu gehören unter anderem Annotator, ContactPerson, DataCollector, DataCurator, DataManager, Editor, Interviewee, Interviewer, Producer, ProjectLeader, ProjectManager, Researcher, RightsHolder, SoftwareDeveloper, Speaker, Sponsor, Supervisor, Teacher und Translator. Nachweis: https://dalia.pages.rwth-aachen.de/dalia-ontology/index-en.html

DALIA übernimmt und kombiniert bereits Begriffe aus unterschiedlichen etablierten Vokabularen. Mehrere Rollen orientieren sich an DataCite. Speaker basiert auf dem MARC Relator speaker. SoftwareDeveloper übernimmt die CRediT-Definition für Software. Damit bietet DALIA ein Beispiel für eine kontrollierte Zusammenführung von Rollen, ohne die zugrunde liegenden Vokabulare als vollständig äquivalent zu behandeln. Nachweis: https://dalia.pages.rwth-aachen.de/dalia-ontology/index-en.html

Bereits 2024 dokumentierte DALIA die Zusammenstellung kontrollierter Vokabulare für Contributor- und Nutzerrollen mit dem ausdrücklichen Ziel, Mappings zu anderen Metadatenschemata bereitzustellen. Nachweis: https://doi.org/10.5281/zenodo.10698258

## Status quo: AMB und OERSI

Das Allgemeine Metadatenprofil für Bildungsressourcen AMB unterscheidet creator und contributor. creator bezeichnet die Urheber:innen der Ressource, contributor sonstige Beitragende. Personen können jeweils mit Identifikatoren und Affiliations beschrieben werden. Eine feingranulare kontrollierte Rollenangabe innerhalb von contributor ist im aktuellen Profil nicht vorgesehen. Nachweis: https://dini-ag-kim.github.io/amb/latest/ und aktueller Entwurf: https://dini-ag-kim.github.io/amb/draft/

Das interne Metadatenprofil von OERSI stimmt nach eigener Dokumentation weitgehend mit AMB überein. Für die Interoperabilität mit OERSI ist deshalb insbesondere die korrekte Trennung von creator und contributor relevant; detaillierte Beitragsrollen können im AMB-Kern nicht vollständig transportiert werden. Nachweis: https://oersi.org/pages/en/docs/integrate/metadata-search/

## Status quo: HS-OER-LOM

Das Profil LOM for Higher Education OER Repositories verwendet contribute-Strukturen mit kontrollierten Rollen. Es unterscheidet damit ebenfalls zwischen der beteiligten Entität und ihrer Funktion im Lebenszyklus eines Lernobjekts beziehungsweise seiner Metadaten. Nachweis: https://dini-ag-kim.github.io/hs-oer-lom-profil/latest/

Die LOM-Rollen besitzen eigene Definitionen und können nicht generell mit CRediT gleichgesetzt werden. Ein normativer vollständiger Crosswalk zwischen CRediT und dem HS-OER-LOM-Rollenvokabular wurde nicht festgestellt.

## Status quo: Crossref

Crossref Schema 5.5 unterstützt seit Juli 2026 mehrere Rollen pro Person und die 14 CRediT-Rollen als eigenes Vokabular. Daneben bleibt ein Crossref-eigenes Rollen-Vokabular mit Rollen wie author, corresponding-author, editor, reviewer und translator bestehen. Nachweis: https://www.crossref.org/documentation/schema-library/markup-guide-metadata-segments/contributors und https://www.crossref.org/blog/schema-5.5-now-available-adding-credit-new-record-types-for-blogs-and-posters-and-more/

Crossref zeigt damit einen für N4O wichtigen Lösungsweg: bibliografische beziehungsweise publikationsbezogene Rollen und CRediT-Beitragsrollen werden parallel gespeichert, nicht ineinander übersetzt.

## Status quo: Schema.org

Schema.org unterscheidet unter anderem author und contributor. Zusätzlich erlaubt der Typ Role mit der Eigenschaft roleName, eine Funktion einer Person oder Organisation in einer Beziehung explizit zu beschreiben. roleName kann Text oder eine URL enthalten. Nachweis: https://schema.org/roleName

Schema.org kann daher als maschinenlesbare Ausgabeschicht genutzt werden, um differenziertere Rolleninformationen zu erhalten, auch wenn ein engeres Zielprofil wie AMB diese Informationen nicht vollständig übernimmt.

## Status quo: Zotero

Zotero verwendet ressourcentypspezifische Creator-Typen. Für den Item Type Presentation ist Presenter die Person, die eine Präsentation hält; Zotero bezeichnet Presenter als author for Presentation items. Daneben können Contributor-Einträge verwendet werden. Nachweis: https://www.zotero.org/support/kb/item_types_and_fields

Presenter ist keine CRediT-Rolle. Eine Ableitung von Presenter aus CRediT-Rollen wie Writing, Conceptualization oder Visualization wäre deshalb semantisch nicht gerechtfertigt. Eine explizite funktionale Angabe wie Speaker lässt sich dagegen fachlich wesentlich besser auf Zotero Presenter abbilden.

## Status quo im N4O-RevealJS-Template

Die aktuelle Datei _autor_innen.yml verwendet das native Quarto-Feld author. Für jede Person können ORCID, E-Mail-Adresse, URL, Affiliations und roles angegeben werden. roles wird in der YAML-Datei als optional beschrieben und mit CRediT erläutert. Aktueller Stand: https://github.com/kacebe/n4o_oer-praesentation-template/blob/main/_autor_innen.yml

Der Filter title_authors.lua verwendet CRediT-Rollen derzeit zusätzlich zur Steuerung der sichtbaren Titelfolie. Auf der Titelfolie erscheinen Personen mit Writing – original draft, Writing – review & editing oder dem Quarto-Alias writing. Der Filter verlangt zugleich für jede Person unter author mindestens eine Rollenangabe und erzeugt andernfalls einen Fehler. Aktueller Stand: https://github.com/kacebe/n4o_oer-praesentation-template/blob/main/_filters/title_authors.lua

Diese Darstellungsregel ist von der bibliografischen Autorschaft zu unterscheiden. Alle Personen unter author bleiben im Quarto-Modell Autor:innen, auch wenn sie aufgrund ihrer Rollen nicht auf der Titelfolie erscheinen.

Die aktuelle Appendix-Folie verwendet n4o-title-authors für Zitierempfehlung und Kontaktbereich. Dadurch werden gegenwärtig nur die für die Titelfolie ausgewählten Writing-Autor:innen verarbeitet. Aktueller Stand: https://github.com/kacebe/n4o_oer-praesentation-template/blob/main/_filters/appendix_slide.lua

Der Filter html_metadata.lua verwendet dagegen grundsätzlich by-author. Diese Personen werden als AMB-Creator und Schema.org-Author ausgegeben. Für Zotero werden aktuell ebenfalls alle Personen aus by-author über eprints:creators_name als Presenter ausgegeben. Dadurch stimmen die semantische Bedeutung der Quarto-Autorschaft, die Auswahl der Titelfolie und die Zotero-Presenter-Rolle nicht zuverlässig überein. Aktueller Stand: https://github.com/kacebe/n4o_oer-praesentation-template/blob/main/_filters/html_metadata.lua

## Lösung für das gemeinsame Metadatenkonzept der N4O-OER-Templates

Für die N4O-OER-Templates wird Autorschaft künftig als eigenständige bibliografische Aussage behandelt. CRediT-Rollen beschreiben Beiträge, nicht den Autor:innenstatus.

* Personen unter author sind Autor:innen der OER.
* Diese Personen bleiben in den maschinenlesbaren Metadaten Autor:innen beziehungsweise Creator, unabhängig von ihren CRediT-Rollen.
* Eine Rolle Conceptualization, Visualization, Software oder Funding acquisition macht eine unter author eingetragene Person nicht zu einem Contributor.
* Umgekehrt darf aus Writing – original draft oder Writing – review & editing nicht automatisch Autorschaft abgeleitet werden.
* roles bleibt für CRediT-Beiträge reserviert und wird grundsätzlich optional behandelt.
* Für Personen, die an der OER mitwirken, aber nicht als Autor:innen ausgewiesen werden sollen, wird ein eigener N4O-Metadatenbereich contributors vorgesehen.
* Für zusätzliche Funktionen einer Person gegenüber der konkreten Ressource wird ein eigener, von CRediT getrennter Metadatenschlüssel vorgesehen. Der zuvor diskutierte Begriff resource-roles wird verworfen, weil er mit didaktischen Rollen beziehungsweise Funktionen einer Bildungsressource verwechselt werden kann.
* Als Arbeitsbegriff für diesen Schlüssel wird functions verwendet. Hier können kontrollierte Funktionen wie speaker, editor, translator oder software-developer abgelegt werden.
* Die Werte von functions sollen primär an bereits etablierten Rollen aus DALIA, DataCite und MARC Relators orientiert werden. Eigene N4O-Rollen werden nur eingeführt, wenn kein geeigneter etablierter Begriff verfügbar ist.
* Zwischen roles und functions findet keine automatische allgemeine Übersetzung statt.
* Mappings in Zielschemata werden nur verwendet, wenn die semantische Entsprechung hinreichend eindeutig oder durch das Zielvokabular dokumentiert ist.
* Die Herkunft eines gemappten Begriffs soll in der technischen Mapping-Tabelle dokumentiert werden.
* Bei unsicheren oder nur ähnlichen Entsprechungen bleibt die Originalinformation erhalten, statt eine präzisere Bedeutung vorzutäuschen.

Dieses Modell folgt der Trennung, die auch CRediT, DataCite, DALIA, AMB und Crossref in unterschiedlicher Form verwenden: Personenstatus, Beitragsart und weitere Funktion werden nicht als ein einziges Rollensystem behandelt.

## Abbildung auf externe Metadatenschemata

Für AMB und OERSI werden Personen unter author als creator ausgegeben. Personen unter contributors werden als contributor ausgegeben. CRediT-Rollen und weitere Funktionen werden nicht künstlich in AMB-Felder übersetzt, wenn das Profil dafür keine geeignete Struktur vorsieht.

Für Schema.org werden author und contributor entsprechend ausgegeben. Zusätzliche Rolleninformationen können ergänzend über Role und roleName beschrieben werden, sofern die konkrete Implementierung interoperabel bleibt.

Für DataCite werden Personen unter author als Creator behandelt. Personen unter contributors können als Contributor ausgegeben werden, sofern ein geeigneter contributorType angegeben werden kann. CRediT-Rollen werden nicht automatisch auf DataCite contributorType reduziert.

Für DALIA werden Autor:innenstatus und Contribution-Strukturen getrennt behandelt. Die in DALIA beziehungsweise MoDALIA etablierten Contributor Roles dienen als bevorzugte Referenz für Funktionen, die über CRediT hinausgehen.

Für Crossref können CRediT-Rollen in Schema 5.5 direkt als CRediT-Vokabular ausgegeben werden. Eine vorherige Übersetzung in Crossref-Rollen ist nicht erforderlich.

Für Zotero muss das Mapping ressourcentypspezifisch erfolgen. Beim Typ Presentation wird Presenter nur für Personen erzeugt, für die eine geeignete funktionale Information wie speaker vorliegt. CRediT-Rollen werden nicht zur Ableitung von Presenter verwendet. Andere Autor:innen oder Mitwirkende müssen entsprechend den Möglichkeiten des Zotero-Datenmodells behandelt werden.

## Festlegungen für das N4O-RevealJS-Template

Die sichtbare Titelfolie bleibt in der bestehenden Form erhalten. Die bisherige Auswahl der dort angezeigten Personen wird im Rahmen dieser konzeptionellen Änderung nicht verändert.

Die Appendix-Folie wird personenseitig auf die Quarto-Autor:innen und ihre CRediT-Rollen beschränkt. Zusätzliche contributors oder functions werden dort nicht ausgegeben. Damit bleibt die Appendix eine kompakte menschenlesbare Dokumentation der Autor:innen und ihrer Beiträge und wird nicht zu einer vollständigen Ausgabe aller maschinenlesbaren Metadaten.

Für die Appendix werden künftig alle für die Appendix vorgesehenen Quarto-Autor:innen aus dem normalisierten author beziehungsweise by-author-Modell verarbeitet; die Ausgabe darf nicht ausschließlich von n4o-title-authors abhängen. Das Layout ist für zwei und mehr Autor:innen zu testen und gegebenenfalls anzupassen.

Die vollständige Differenzierung wird im HTML-Header umgesetzt.

* meta name="author" beschreibt die bibliografischen Autor:innen und darf nicht anhand einzelner CRediT-Rollen gefiltert werden.
* AMB/OERSI erhält creator für Autor:innen und contributor für weitere Mitwirkende.
* Schema.org erhält author beziehungsweise contributor und kann ergänzend Rolleninformationen aufnehmen.
* CRediT-Rollen bleiben als eigene semantische Information erhalten.
* Zusätzliche functions werden nur in geeignete Zielrollen gemappt.
* Zotero Presenter wird nicht aus author oder CRediT abgeleitet, sondern aus einer expliziten geeigneten Funktionsangabe wie speaker.
* Verlustbehaftete Mappings werden vermieden oder als solche dokumentiert.

## Übertragbarkeit auf weitere N4O-OER-Templates

Das Personen- und Rollenmodell ist als gemeinsamer Metadatenkern für die N4O-OER-Templates vorgesehen. Es soll perspektivisch auch für Skript und Übung gelten.

Die konkrete sichtbare Darstellung in Skript und Übung wird nicht im RevealJS-Template festgelegt. Sie wird später für die jeweiligen Templates separat entschieden. Gemeinsam bleiben die semantischen Grundregeln: author definiert Autorschaft, roles beschreibt CRediT-Beiträge, contributors beschreibt weitere Mitwirkende und functions beschreibt zusätzliche kontrollierte Funktionen.

Damit kann die Templatefamilie ein gemeinsames Metadatenkonzept verwenden, während die jeweiligen Ausgabeformate unterschiedliche Darstellungen und technische Ziel-Mappings implementieren.
