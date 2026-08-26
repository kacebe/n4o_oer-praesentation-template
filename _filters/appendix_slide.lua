-- appendix_slide.lua
--
-- Erzeugt die abschließende Folie „Zitation und Nachnutzung“.
-- Die Zitierempfehlung wird lokal mit Pandoc Citeproc und der in
-- _praesentation.yml angegebenen CSL-Datei erzeugt.
--
-- Abhängigkeiten:
-- - by-author wird vom eingebauten Quarto-Filter bereitgestellt.
-- - n4o-title-authors wird von title_authors.lua aus den Writing-Rollen
--   abgeleitet und für Titelfolie, Zitierempfehlung und Kontakt verwendet.
-- - title-license-badge-* wird zuvor von title_brand.lua erzeugt.
--
-- Die Appendix ist standardmäßig aktiv und kann mit
-- appendix-slide: false deaktiviert werden.


local SELF_ID = "n4o-presentation-self"

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

-- Prüfen, ob die Appendix erzeugt werden soll; ohne Angabe ist sie aktiv.

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

-- Zwischenüberschriften bewusst nicht als pandoc.Header erzeugen:
-- Reveal.js würde daraus verschachtelte Unterfolien machen.
-- Span + ARIA-Heading erhalten die semantische Überschriftenfunktion.

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
          { "role", "heading" },
          { "aria-level", "3" }
        }
      )
    )

  }

end

-- Quarto-normalisierte by-author-Daten in CSL-Namen für Citeproc überführen.

local function make_authors(meta)

  local source =
    meta["n4o-title-authors"]

  if source == nil then
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

        csl_author.family =
          pandoc.MetaString(
            text(author.name.family)
          )

        has_name =
          true

      end


      if author.name.given ~= nil then

        csl_author.given =
          pandoc.MetaString(
            text(author.name.given)
          )

        has_name =
          true

      end


      if
        not has_name
        and author.name.literal ~= nil
      then

        csl_author.literal =
          pandoc.MetaString(
            text(author.name.literal)
          )

        has_name =
          true

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
    meta.citation or {}

  local reference =
    pandoc.MetaMap{}


  reference.id =
    pandoc.MetaString(SELF_ID)


  reference.type =
    citation.type
    or pandoc.MetaString("speech")


  if meta.title ~= nil then
    reference.title = meta.title
  end


  local authors =
    make_authors(meta)

  if authors ~= nil then
    reference.author = authors
  end


  if citation.issued ~= nil then
    reference.issued = citation.issued
  end


  if citation.genre ~= nil then
    reference.genre = citation.genre
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

-- Zitierempfehlung lokal mit Pandoc Citeproc und der konfigurierten CSL-Datei erzeugen.

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

      -- ID entfernen, damit kein Konflikt mit dem regulären Literaturverzeichnis entsteht.
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

-- Veranstaltungskontext unabhängig von der Darstellung im CSL-Stil ausgeben.

local function make_event_block(meta)

  local citation =
    meta.citation or {}


  local event_title =
    text(citation["event-title"])

  local container_title =
    text(citation["container-title"])

  local event_place =
    text(citation["event-place"])

  local event_date =
    text(citation["event-date"])

  local collection_title =
    text(citation["collection-title"])


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
          pandoc.Str(event_title)
        }
      }
    )

  end


  if container_title ~= nil then

    blocks:insert(
  pandoc.Para{
    pandoc.Str(container_title)
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
        pandoc.Str(event_place)
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
        pandoc.Str(event_date)
      )

    end


    blocks:insert(
      pandoc.Para(line)
    )

  end


  if collection_title ~= nil then

    blocks:insert(
  pandoc.Para{
    pandoc.Str(collection_title)
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

-- Link mit dekorativem lokalem SVG-Icon; der sichtbare Linktext beschreibt das Ziel.

local function icon_link(icon_path, target, label)

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
          label or target
        )
      },
      target
    )

  }

end

-- Veröffentlichte Präsentation und Repository als Nachnutzungsquellen ausgeben.

local function make_sources_block(meta)

  local citation =
    meta.citation or {}

  local presentation_url =
    text(citation.url)

  local repository_url =
    text(meta["repo-url"])


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

-- Kontaktpersonen aus den für die Titelfolie ausgewählten
-- Writing-Autor:innen ausgeben.
--
-- n4o-title-authors wird zuvor von title_authors.lua erzeugt.
-- Die Person wird auch dann genannt, wenn keine E-Mail-Adresse
-- oder persönliche URL angegeben ist.

local function make_contact_block(meta)

  local authors =
    meta["n4o-title-authors"]


  if authors == nil then
    return nil
  end


  local people =
    pandoc.Blocks{}


  for _, author in ipairs(authors) do

    local email =
      text(author.email)

    local url =
      text(author.url)

    local name =
      nil


    if
      author.name ~= nil
      and author.name.literal ~= nil
    then

      name =
        text(author.name.literal)

    end


    if name ~= nil then

      local person =
        pandoc.Blocks{}


      person:insert(
        pandoc.Para{
          pandoc.Strong{
            pandoc.Str(name)
          }
        }
      )


      if email ~= nil then

        person:insert(
          icon_link(
            "assets/icons/envelope.svg",
            "mailto:" .. email,
            email
          )
        )

      end


      if url ~= nil then

        person:insert(
          icon_link(
            "assets/icons/globe2.svg",
            url,
            url
          )
        )

      end


      people:insert(
        pandoc.Div(
          person,
          pandoc.Attr(
            "",
            {
              "n4o-appendix-contact-person"
            }
          )
        )
      )

    end

  end


  if #people == 0 then
    return nil
  end


  local blocks =
    pandoc.Blocks{}


  for _, person in ipairs(people) do
    blocks:insert(person)
  end


  return pandoc.Div(
    blocks,
    pandoc.Attr(
      "",
      {
        "n4o-appendix-contact"
      }
    )
  )

end

-- Lizenz- und Rechteblock erzeugen.
-- Das optionale Lizenz-Badge stammt aus title_brand.lua; ohne Badge bleibt der Text.

local function make_rights_block(meta)

  local license =
    meta.license or {}

  local copyright =
    meta.copyright or {}


  local license_text =
    text(license.text)

  local license_url =
    text(license.url)

  local badge_path =
    text(meta["title-license-badge-path"])

  local badge_alt =
    text(meta["title-license-badge-alt"])

  local copyright_year =
    text(copyright.year)

  local copyright_holder =
    text(copyright.holder)


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
        pandoc.Str(copyright_year)
      )

    end


    if copyright_holder ~= nil then

      copyright_line:insert(
        pandoc.Space()
      )

      copyright_line:insert(
        pandoc.Str(copyright_holder)
      )

    end


    blocks:insert(
      pandoc.Para(
        copyright_line
      )
    )

  end


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


  if license_text ~= nil then

    local license_markdown =
      "Soweit nicht anders gekennzeichnet: Gerne nachnutzen, teilen und weiterentwickeln. "
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
      .. ". Bitte nennen Sie die Urheber:innen und kennzeichnen Sie Änderungen."


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

-- Appendix-Folie an das Dokument anhängen.
-- Bei slide-level: 2 erzeugt nur der Header der Ebene 2 eine neue Reveal.js-Folie.

function Pandoc(doc)

  if not appendix_enabled(doc.meta) then
    return doc
  end


  local reference =
    make_formatted_reference(doc.meta)

  local event =
    make_event_block(doc.meta)

  local sources =
    make_sources_block(doc.meta)

  local contact =
    make_contact_block(doc.meta)

  local rights =
    make_rights_block(doc.meta)


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


  if contact ~= nil then
    right:insert(contact)
  end


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
          "n4o-appendix-grid"
        }
      )
    )
  )


  return doc

end
