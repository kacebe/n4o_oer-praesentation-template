-- appendix_slide.lua
--
-- Erzeugt die abschließende Folie
-- „Zitation und Nachnutzung“.
--
-- Die Zitierempfehlung wird lokal mit Pandoc Citeproc
-- und der in _praesentation.yml angegebenen CSL-Datei erzeugt.
--
-- Autor:innen:
-- - Grundlage ist ausschließlich n4o-authors.
-- - n4o-authors wird zuvor von title_authors.lua aus by-author erzeugt.
-- - Enthalten sind nur Personen mit mindestens einer gültigen
--   CRediT-Rolle.
-- - Personen ohne gültige roles werden weder in der Appendix
--   noch in der Zitierempfehlung berücksichtigt.
-- - Die konkrete CRediT-Rolle bestimmt nicht den bibliografischen
--   Autor:innenstatus einer gültigen Person.
-- - n4o-title-authors wird hier nicht verwendet.
--
-- Sichtbare Ausgabe der Appendix:
-- - Zitierempfehlung mit allen Quarto-Autor:innen
-- - alle Quarto-Autor:innen mit ihren roles in einem vollbreiten Block
-- - Veranstaltung
-- - Präsentations- und Repository-URL
-- - Lizenz und Rechte
--
-- Nicht ausgegeben werden:
-- - zusätzliche Contributors
-- - weitere Funktions- oder Rollenvokabulare
-- - maschinenlesbare Metadaten
--
-- Diese werden gegebenenfalls im HTML-Header behandelt.
--
-- Abhängigkeiten:
-- - n4o-authors wird zuvor von title_authors.lua erzeugt.
-- - title-license-badge-* wird zuvor von title_brand.lua erzeugt.
--
-- Die Appendix ist standardmäßig aktiv und kann mit
--
-- appendix-slide: false
--
-- deaktiviert werden.


local SELF_ID =
  "n4o-presentation-self"


-- ============================================================================
-- ALLGEMEINE HILFSFUNKTIONEN
-- ============================================================================


-- Pandoc-Metadaten als Text lesen.

local function text(value)

  if value == nil then
    return nil
  end


  local result =
    pandoc.utils.stringify(value)


  if result == "" then
    return nil
  end


  return result

end


-- Prüfen, ob die Appendix erzeugt werden soll.
--
-- Ohne explizite Angabe ist die Appendix aktiv.

local function appendix_enabled(meta)

  local value =
    meta["appendix-slide"]


  if value == nil then
    return true
  end


  if value == false then
    return false
  end


  local value_text =
    text(value)


  if
    value_text ~= nil
    and string.lower(value_text) == "false"
  then
    return false
  end


  return true

end


-- Zwischenüberschriften bewusst nicht als pandoc.Header erzeugen.
--
-- Reveal.js würde daraus verschachtelte Unterfolien machen.
-- Span + ARIA-Heading erhalten die semantische
-- Überschriftenfunktion.

local function appendix_heading(title)

  return pandoc.Para{
    pandoc.Span(
      {
        pandoc.Str(title)
      },
      pandoc.Attr(
        "",
        {
          "n4o-appendix-heading"
        },
        {
          {
            "role",
            "heading"
          },
          {
            "aria-level",
            "3"
          }
        }
      )
    )
  }

end


-- ============================================================================
-- AUTOR:INNEN
-- ============================================================================


-- Vollständigen Namen aus den von Quarto normalisierten
-- Autor:innendaten lesen.

local function author_name(author)

  if
    author == nil
    or author.name == nil
  then
    return nil
  end


  -- Quarto stellt normalerweise bereits einen vollständigen
  -- Namen unter name.literal bereit.

  local literal =
    text(author.name.literal)


  if literal ~= nil then
    return literal
  end


  -- Fallback für nicht vollständig normalisierte Angaben.

  local given =
    text(author.name.given)

  local family =
    text(author.name.family)


  if
    given ~= nil
    and family ~= nil
  then
    return
      given
      .. " "
      .. family
  end


  return
    given
    or family

end


-- Rollenbezeichnung aus Quartos normalisierten
-- Autor:innendaten lesen.
--
-- Bei einer von Quarto erkannten CRediT-Rolle wird bevorzugt
-- vocab-term verwendet.
--
-- Fallback:
-- - role
-- - unmittelbarer Textwert
--
-- Damit wird die von Quarto vorgenommene Normalisierung genutzt,
-- ohne im Appendix-Filter ein eigenes CRediT-Vokabular zu pflegen.

local function role_label(role)

  if role == nil then
    return nil
  end


  if type(role) == "table" then

    local vocab_term =
      text(
        role["vocab-term"]
      )


    if vocab_term ~= nil then
      return vocab_term
    end


    local role_value =
      text(
        role.role
      )


    if role_value ~= nil then
      return role_value
    end

  end


  return text(role)

end


-- Rollen einer Autor:in als sichtbare Zeile erzeugen.
--
-- n4o-authors enthält regulär nur Personen mit gültigen roles.
-- Die defensive Prüfung verhindert Folgefehler bei unvollständigen
-- oder unerwarteten Metadaten.

local function make_roles_line(author)

  if
    author == nil
    or author.roles == nil
    or #author.roles == 0
  then
    return nil
  end


  local labels = {}


  for _, role in ipairs(author.roles) do

    local label =
      role_label(role)


    if label ~= nil then

      table.insert(
        labels,
        label
      )

    end

  end


  if #labels == 0 then
    return nil
  end


  return pandoc.Para{
    pandoc.Span(
      {
        pandoc.Str(
          table.concat(
            labels,
            " · "
          )
        )
      },
      pandoc.Attr(
        "",
        {
          "n4o-appendix-author-roles"
        }
      )
    )
  }

end


-- Sichtbaren Autor:innenblock erzeugen.
--
-- Grundlage ist ausschließlich n4o-authors.
--
-- Wichtig:
-- - Ausgegeben werden nur die zuvor validierten N4O-Autor:innen.
-- - Jede ausgegebene Person besitzt mindestens eine gültige
--   CRediT-Rolle.
-- - Die konkrete Rolle entscheidet nicht über die Aufnahme.
-- - Kontaktinformationen werden hier nicht ausgegeben.
-- - Contributors und andere Funktionsrollen werden hier
--   nicht ausgegeben.
--
-- DOM-Struktur:
--
-- .n4o-appendix-authors
--   .n4o-appendix-heading
--   .n4o-appendix-authors-grid
--     .n4o-appendix-author
--     .n4o-appendix-author
--     ...
--
-- Die Anzahl der Autor:innen wird zusätzlich über eine Klasse
-- am äußeren Block kenntlich gemacht:
--
-- - n4o-appendix-authors-single
-- - n4o-appendix-authors-two-columns
-- - n4o-appendix-authors-three-columns
--
-- Die Klassen steuern später ausschließlich das Layout im SCSS.

local function make_authors_block(meta)

  local authors =
    meta["n4o-authors"]


  if
    authors == nil
    or #authors == 0
  then
    return nil
  end


  local people =
    pandoc.Blocks{}


  for _, author in ipairs(authors) do

    local name =
      author_name(author)


    if name ~= nil then

      local person =
        pandoc.Blocks{}


      person:insert(
        pandoc.Para{
          pandoc.Span(
            {
              pandoc.Strong{
                pandoc.Str(name)
              }
            },
            pandoc.Attr(
              "",
              {
                "n4o-appendix-author-name"
              }
            )
          )
        }
      )


      local roles =
        make_roles_line(author)


      if roles ~= nil then
        person:insert(roles)
      end


      people:insert(
        pandoc.Div(
          person,
          pandoc.Attr(
            "",
            {
              "n4o-appendix-author"
            }
          )
        )
      )

    end

  end


  local count =
    #people


  if count == 0 then
    return nil
  end


  local layout_class


  if count == 1 then

    layout_class =
      "n4o-appendix-authors-single"

  elseif count <= 4 then

    layout_class =
      "n4o-appendix-authors-two-columns"

  else

    layout_class =
      "n4o-appendix-authors-three-columns"

  end


  local grid =
    pandoc.Div(
      people,
      pandoc.Attr(
        "",
        {
          "n4o-appendix-authors-grid"
        }
      )
    )


  local blocks =
    pandoc.Blocks{
      appendix_heading(
        "Autor:innen und Beiträge"
      ),
      grid
    }


  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "n4o-appendix-authors",
        layout_class
      }
    )
  )

end


-- ============================================================================
-- ZITIEREMPFEHLUNG
-- ============================================================================


-- Validierte n4o-authors-Daten in CSL-Namen
-- für Citeproc überführen.
--
-- Entscheidend:
-- Es werden ausschließlich Personen aus n4o-authors verwendet.
-- Personen ohne gültige CRediT-Rolle gelangen dadurch auch
-- nicht in die bibliografische Zitierempfehlung.

local function make_csl_authors(meta)

  local source =
    meta["n4o-authors"]


  if
    source == nil
    or #source == 0
  then
    return nil
  end


  local authors =
    pandoc.MetaList{}


  for _, author in ipairs(source) do

    if author.name ~= nil then

      local csl_author =
        pandoc.MetaMap{}

      local has_name =
        false


      if author.name.family ~= nil then

        local family =
          text(author.name.family)


        if family ~= nil then

          csl_author.family =
            pandoc.MetaString(family)

          has_name =
            true

        end

      end


      if author.name.given ~= nil then

        local given =
          text(author.name.given)


        if given ~= nil then

          csl_author.given =
            pandoc.MetaString(given)

          has_name =
            true

        end

      end


      if
        not has_name
        and author.name.literal ~= nil
      then

        local literal =
          text(author.name.literal)


        if literal ~= nil then

          csl_author.literal =
            pandoc.MetaString(literal)

          has_name =
            true

        end

      end


      if has_name then
        authors:insert(csl_author)
      end

    end

  end


  if #authors == 0 then
    return nil
  end


  return authors

end


-- CSL-Datensatz für die Präsentation selbst aufbauen.

local function make_reference(meta)

  local citation =
    meta.citation
    or {}


  local reference =
    pandoc.MetaMap{}


  reference.id =
    pandoc.MetaString(
      SELF_ID
    )


  reference.type =
    citation.type
    or pandoc.MetaString(
      "speech"
    )


  if meta.title ~= nil then

    reference.title =
      meta.title

  end


  local authors =
    make_csl_authors(meta)


  if authors ~= nil then

    reference.author =
      authors

  end


  if citation.issued ~= nil then

    reference.issued =
      citation.issued

  end


  if citation.genre ~= nil then

    reference.genre =
      citation.genre

  end


  if citation["event-title"] ~= nil then

    reference["event-title"] =
      citation["event-title"]

  end


  if citation["event-place"] ~= nil then

    reference["event-place"] =
      citation["event-place"]

  end


  if citation["event-date"] ~= nil then

    reference["event-date"] =
      citation["event-date"]

  end


  if citation["container-title"] ~= nil then

    reference["container-title"] =
      citation["container-title"]

  end


  if citation["collection-title"] ~= nil then

    reference["collection-title"] =
      citation["collection-title"]

  end


  if citation.publisher ~= nil then

    reference.publisher =
      citation.publisher

  end


  if citation.version ~= nil then

    reference.version =
      citation.version

  end


  if meta.doi ~= nil then

    reference.DOI =
      meta.doi

  end


  if citation.url ~= nil then

    reference.URL =
      citation.url

  end


  return reference

end


-- Zitierempfehlung lokal mit Pandoc Citeproc und
-- der konfigurierten CSL-Datei erzeugen.

local function make_formatted_reference(meta)

  if meta.csl == nil then
    return nil
  end


  local temp =
    pandoc.read(
      "[@" .. SELF_ID .. "]",
      "markdown"
    )


  temp.meta.references =
    pandoc.MetaList{
      make_reference(meta)
    }


  temp.meta.csl =
    meta.csl


  if meta.lang ~= nil then

    temp.meta.lang =
      meta.lang

  end


  local processed =
    pandoc.utils.citeproc(temp)


  for _, block in ipairs(processed.blocks) do

    if
      block.t == "Div"
      and block.identifier == "refs"
    then

      -- ID entfernen, damit kein Konflikt mit einem
      -- regulären Literaturverzeichnis entsteht.

      block.identifier =
        ""


      block.classes:insert(
        "n4o-appendix-citation-reference"
      )


      return block

    end

  end


  return nil

end


-- ============================================================================
-- VERANSTALTUNG
-- ============================================================================


-- Veranstaltungskontext unabhängig von der Darstellung
-- im CSL-Stil ausgeben.

local function make_event_block(meta)

  local citation =
    meta.citation
    or {}


  local event_title =
    text(
      citation["event-title"]
    )

  local container_title =
    text(
      citation["container-title"]
    )

  local event_place =
    text(
      citation["event-place"]
    )

  local event_date =
    text(
      citation["event-date"]
    )

  local collection_title =
    text(
      citation["collection-title"]
    )


  if
    event_title == nil
    and container_title == nil
    and event_place == nil
    and event_date == nil
    and collection_title == nil
  then
    return nil
  end


  local blocks =
    pandoc.Blocks{}


  if event_title ~= nil then

    blocks:insert(
      pandoc.Para{
        pandoc.Strong{
          pandoc.Str(
            event_title
          )
        }
      }
    )

  end


  if container_title ~= nil then

    blocks:insert(
      pandoc.Para{
        pandoc.Str(
          container_title
        )
      }
    )

  end


  if
    event_place ~= nil
    or event_date ~= nil
  then

    local line =
      pandoc.Inlines{}


    if event_place ~= nil then

      line:insert(
        pandoc.Str(
          event_place
        )
      )

    end


    if
      event_place ~= nil
      and event_date ~= nil
    then

      line:insert(
        pandoc.Str(",")
      )

      line:insert(
        pandoc.Space()
      )

    end


    if event_date ~= nil then

      line:insert(
        pandoc.Span(
          {
            pandoc.Str(
              event_date
            )
          },
          pandoc.Attr(
            "",
            {
              "n4o-appendix-event-date"
            },
            {
              {
                "data-n4o-event-date",
                event_date
              }
            }
          )
        )
      )

    end


    blocks:insert(
      pandoc.Para(line)
    )

  end


  if collection_title ~= nil then

    blocks:insert(
      pandoc.Para{
        pandoc.Str(
          collection_title
        )
      }
    )

  end


  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "n4o-appendix-event"
      }
    )
  )

end


-- ============================================================================
-- LINKS UND QUELLEN
-- ============================================================================


-- Link mit dekorativem lokalem SVG-Icon.
--
-- Der sichtbare Linktext beschreibt das Ziel.

local function icon_link(
  icon_path,
  target,
  label
)

  local icon =
    pandoc.Image(
      {},
      icon_path,
      "",
      pandoc.Attr(
        "",
        {
          "n4o-appendix-link-icon"
        }
      )
    )


  return pandoc.Para{

    icon,

    pandoc.Space(),

    pandoc.Link(
      {
        pandoc.Str(
          label
          or target
        )
      },
      target
    )

  }

end


-- Veröffentlichte Präsentation und Repository
-- als Nachnutzungsquellen ausgeben.

local function make_sources_block(meta)

  local citation =
    meta.citation
    or {}


  local presentation_url =
    text(
      citation.url
    )

  local repository_url =
    text(
      meta["repo-url"]
    )


  if
    presentation_url == nil
    and repository_url == nil
  then
    return nil
  end


  local blocks =
    pandoc.Blocks{}


  if presentation_url ~= nil then

    blocks:insert(
      icon_link(
        "assets/icons/easel2.svg",
        presentation_url
      )
    )

  end


  if repository_url ~= nil then

    blocks:insert(
      icon_link(
        "assets/icons/code-slash.svg",
        repository_url
      )
    )

  end


  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "n4o-appendix-sources"
      }
    )
  )

end


-- ============================================================================
-- LIZENZ UND RECHTE
-- ============================================================================


-- Lizenz- und Rechteblock erzeugen.
--
-- Das optionale Lizenz-Badge stammt aus title_brand.lua.
-- Ohne Badge bleibt die textuelle Lizenzinformation erhalten.

local function make_rights_block(meta)

  local license =
    meta.license
    or {}

  local copyright =
    meta.copyright
    or {}


  local license_text =
    text(
      license.text
    )

  local license_url =
    text(
      license.url
    )

  local badge_path =
    text(
      meta["title-license-badge-path"]
    )

  local badge_alt =
    text(
      meta["title-license-badge-alt"]
    )

  local copyright_year =
    text(
      copyright.year
    )

  local copyright_holder =
    text(
      copyright.holder
    )


  if
    license_text == nil
    and badge_path == nil
    and copyright_year == nil
    and copyright_holder == nil
  then
    return nil
  end


  local blocks =
    pandoc.Blocks{}


  -- Copyright

  if
    copyright_year ~= nil
    or copyright_holder ~= nil
  then

    local copyright_line =
      pandoc.Inlines{
        pandoc.Str("©")
      }


    if copyright_year ~= nil then

      copyright_line:insert(
        pandoc.Space()
      )

      copyright_line:insert(
        pandoc.Str(
          copyright_year
        )
      )

    end


    if copyright_holder ~= nil then

      copyright_line:insert(
        pandoc.Space()
      )

      copyright_line:insert(
        pandoc.Str(
          copyright_holder
        )
      )

    end


    blocks:insert(
      pandoc.Para(
        copyright_line
      )
    )

  end


  -- Lizenz-Badge

  if badge_path ~= nil then

    local badge =
      pandoc.Image(
        {
          pandoc.Str(
            badge_alt
            or license_text
            or "Lizenz"
          )
        },
        badge_path
      )


    if license_url ~= nil then

      blocks:insert(
        pandoc.Para{
          pandoc.Link(
            {
              badge
            },
            license_url
          )
        }
      )

    else

      blocks:insert(
        pandoc.Para{
          badge
        }
      )

    end

  end


  -- Lizenztext

  if license_text ~= nil then

    local license_markdown =
      "Soweit nicht anders gekennzeichnet: "
      .. "Gerne nachnutzen, teilen und weiterentwickeln. "
      .. "Diese Präsentation steht unter "


    if license_url ~= nil then

      license_markdown =
        license_markdown
        .. "["
        .. license_text
        .. "]("
        .. license_url
        .. ")"

    else

      license_markdown =
        license_markdown
        .. license_text

    end


    license_markdown =
      license_markdown
      .. ". Bitte nennen Sie die Urheber:innen "
      .. "und kennzeichnen Sie Änderungen."


    local license_doc =
      pandoc.read(
        license_markdown,
        "markdown"
      )


    if #license_doc.blocks > 0 then

      blocks:insert(
        license_doc.blocks[1]
      )

    end

  end


  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "n4o-appendix-rights"
      }
    )
  )

end


-- ============================================================================
-- APPENDIX-FOLIE
-- ============================================================================


-- Appendix-Folie an das Dokument anhängen.
--
-- Bei slide-level: 2 erzeugt nur der Header der Ebene 2
-- eine neue Reveal.js-Folie.

function Pandoc(doc)

  if not appendix_enabled(doc.meta) then
    return doc
  end


  local reference =
    make_formatted_reference(
      doc.meta
    )

  local event =
    make_event_block(
      doc.meta
    )

  local sources =
    make_sources_block(
      doc.meta
    )

  local authors =
    make_authors_block(
      doc.meta
    )

  local rights =
    make_rights_block(
      doc.meta
    )


  -- Folienüberschrift

  doc.blocks:insert(
    pandoc.Header(
      2,
      "Zitation und Nachnutzung",
      pandoc.Attr(
        "",
        {
          "n4o-appendix-slide"
        }
      )
    )
  )


  -- Zitierempfehlung: volle Breite

  local citation_blocks =
    pandoc.Blocks{
      appendix_heading(
        "Zitierempfehlung für diese Präsentation"
      )
    }


  if reference ~= nil then

    citation_blocks:insert(
      reference
    )

  else

    citation_blocks:insert(
      pandoc.Para{
        pandoc.Str(
          "Zitierempfehlung konnte nicht erzeugt werden."
        )
      }
    )

  end


  doc.blocks:insert(
    pandoc.Div(
      citation_blocks,
      pandoc.Attr(
        "",
        {
          "n4o-appendix-citation"
        }
      )
    )
  )


  -- Autor:innen und CRediT-Beiträge: volle Breite
  --
  -- Der Autor:innenblock steht bewusst außerhalb des unteren
  -- Zweispaltenrasters. Dadurch kann er seine Inhalte abhängig
  -- von der Personenzahl auf eine, zwei oder drei Spalten verteilen.

  if authors ~= nil then
    doc.blocks:insert(authors)
  end


  -- Unterer Zweispaltenbereich
  --
  -- links:  Veranstaltung und Quellen
  -- rechts: Lizenz und Rechte

  local left =
    pandoc.Blocks{}


  if event ~= nil then
    left:insert(event)
  end


  if sources ~= nil then
    left:insert(sources)
  end


  local left_column =
    pandoc.Div(
      left,
      pandoc.Attr(
        "",
        {
          "n4o-appendix-column",
          "n4o-appendix-column-left"
        }
      )
    )


  local right =
    pandoc.Blocks{}


  if rights ~= nil then
    right:insert(rights)
  end


  local right_column =
    pandoc.Div(
      right,
      pandoc.Attr(
        "",
        {
          "n4o-appendix-column",
          "n4o-appendix-column-right"
        }
      )
    )


  doc.blocks:insert(
    pandoc.Div(
      {
        left_column,
        right_column
      },
      pandoc.Attr(
        "",
        {
          "n4o-appendix-grid",
          "n4o-appendix-bottom-grid"
        }
      )
    )
  )


  return doc

end

