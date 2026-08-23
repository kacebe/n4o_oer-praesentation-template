-- html_metadata.lua
--
-- Ergänzt maschinenlesbare Metadaten im HTML-Header einer
-- Quarto-Reveal.js-Präsentation:
-- - description, canonical und license
-- - AMB/OERSI-JSON-LD
-- - ergänzendes Schema.org-JSON-LD
-- - Embedded Metadata für den Zotero Connector
--
-- Erwartete Filterreihenfolge:
-- title_brand.lua -> quarto -> html_metadata.lua -> appendix_slide.lua
-- Dadurch stehen die von Quarto normalisierten by-author-Daten zur Verfügung.
--
-- Die kanonische URL stammt aus citation.url; OER-Angaben aus oer:.
--
-- Entwickelt im August 2026 mit Unterstützung von ChatGPT
-- (OpenAI, GPT-5.6 Sol) und lokal mit Quarto geprüft.

-- Allgemeine Hilfsfunktionen


local function text(value)

  if value == nil then
    return nil
  end

  local ok, result =
    pcall(
      pandoc.utils.stringify,
      value
    )

  if
    not ok
    or result == nil
  then
    return nil
  end

  result =
    tostring(result)
      :gsub("^%s+", "")
      :gsub("%s+$", "")

  if result == "" then
    return nil
  end

  return result

end


local function normalize_space(value)

  if value == nil then
    return nil
  end

  return value
    :gsub("%s+", " ")
    :gsub("^%s+", "")
    :gsub("%s+$", "")

end


local function html_escape(value)

  if value == nil then
    return nil
  end

  return value
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")

end


local function is_url(value)

  if value == nil then
    return false
  end

  return
    value:match("^https?://") ~= nil

end


local function as_array(value)

  if value == nil then
    return {}
  end


  if type(value) ~= "table" then

    return {
      value
    }

  end


  local value_type =
    pandoc.utils.type(value)


  if
    value_type == "Inlines"
    or value_type == "Blocks"
    or value_type == "MetaInlines"
    or value_type == "MetaBlocks"
  then

    return {
      value
    }

  end


  if
    value_type == "List"
    or value_type == "MetaList"
  then

    return value

  end


  if value[1] ~= nil then

    return value

  end


  return {
    value
  }

end


local function string_array(value)

  local result = {}

  for _, item in ipairs(
    as_array(value)
  ) do

    local item_text =
      text(item)

    if item_text ~= nil then

      table.insert(
        result,
        item_text
      )

    end

  end

  return result

end


local function boolean_value(value)

  if value == nil then
    return nil
  end

  if type(value) == "boolean" then
    return value
  end

  local value_text =
    text(value)

  if value_text == nil then
    return nil
  end

  value_text =
    string.lower(
      normalize_space(value_text)
    )

  if value_text == "true" then
    return true
  end

  if value_text == "false" then
    return false
  end

  return nil

end

-- Mehrsprachige Bezeichnungen aus kontrollierten Vokabularen auswerten.


local function localized_value(value)

  if value == nil then
    return nil
  end

  if type(value) == "table" then

    local result = {}

    for key, item in pairs(value) do

      if type(key) == "string" then

        local item_text =
          text(item)

        if item_text ~= nil then

          result[key] =
            item_text

        end

      end

    end

    if next(result) ~= nil then
      return result
    end

  end

  return text(value)

end


local function preferred_label(
  value,
  lang
)

  local localized =
    localized_value(value)

  if localized == nil then
    return nil
  end

  if type(localized) ~= "table" then
    return localized
  end

  if
    lang ~= nil
    and localized[lang] ~= nil
  then
    return localized[lang]
  end

  if localized.de ~= nil then
    return localized.de
  end

  if localized.en ~= nil then
    return localized.en
  end

  for _, item in pairs(localized) do
    return item
  end

  return nil

end

-- Mehrfachwerte ergänzen, ohne vorhandene Einzelwerte zu überschreiben.


local function append_property(
  object,
  property,
  value
)

  if value == nil then
    return
  end

  if object[property] == nil then

    object[property] =
      value

    return
  end

  local current =
    object[property]

  if
    type(current) == "table"
    and current[1] ~= nil
  then

    table.insert(
      current,
      value
    )

  else

    object[property] = {
      current,
      value
    }

  end

end

-- Persistente Identifikatoren normalisieren.


local function normalize_doi(value)

  local doi =
    text(value)

  if doi == nil then
    return nil, nil
  end

  doi =
    normalize_space(doi)

  doi =
    doi
      :gsub(
        "^https?://doi%.org/",
        ""
      )
      :gsub(
        "^doi:%s*",
        ""
      )

  if doi == "" then
    return nil, nil
  end

  return
    doi,
    "https://doi.org/" .. doi

end


local function normalize_orcid(value)

  local orcid =
    text(value)

  if orcid == nil then
    return nil, nil
  end

  orcid =
    normalize_space(orcid)

  local identifier =
    orcid:gsub(
      "^https?://orcid%.org/",
      ""
    )

  if identifier == "" then
    return nil, nil
  end

  return
    identifier,
    "https://orcid.org/" .. identifier

end


local function normalize_ror(value)

  local ror =
    text(value)

  if ror == nil then
    return nil, nil
  end

  ror =
    normalize_space(ror)

  local identifier =
    ror:gsub(
      "^https?://ror%.org/",
      ""
    )

  if identifier == "" then
    return nil, nil
  end

  return
    identifier,
    "https://ror.org/" .. identifier

end

-- Relative Ressourcen-URLs anhand der kanonischen URL auflösen.


local function resolve_url(
  value,
  canonical
)

  local url =
    text(value)

  if url == nil then
    return nil
  end

  url =
    normalize_space(url)

  if is_url(url) then
    return url
  end

  if canonical == nil then
    return url
  end


  if url:match("^/") then

    local origin =
      canonical:match(
        "^(https?://[^/]+)"
      )

    if origin ~= nil then

      return
        origin
        .. "/"
        .. url:gsub("^/+", "")

    end

  end


  if canonical:match("/$") then

    return
      canonical
      .. url:gsub("^/+", "")

  end


  local directory =
    canonical:match(
      "^(.*)/[^/]*$"
    )

  if directory ~= nil then

    return
      directory
      .. "/"
      .. url:gsub("^/+", "")

  end


  return url

end

-- Lizenzangaben auf eine kanonische URL abbilden.


local function license_url(meta)

  local license =
    meta.license

  if license == nil then
    return nil
  end


  if
    type(license) == "table"
    and license.url ~= nil
  then

    return
      text(
        license.url
      )

  end


  local value =
    text(license)

  if value == nil then
    return nil
  end


  if is_url(value) then
    return value
  end


  local key =
    string.upper(
      normalize_space(value)
    )


  local licenses = {

    ["CC BY"] =
      "https://creativecommons.org/licenses/by/4.0/",

    ["CC BY 4.0"] =
      "https://creativecommons.org/licenses/by/4.0/",

    ["CC BY-SA"] =
      "https://creativecommons.org/licenses/by-sa/4.0/",

    ["CC BY-SA 4.0"] =
      "https://creativecommons.org/licenses/by-sa/4.0/",

    ["CC0"] =
      "https://creativecommons.org/publicdomain/zero/1.0/",

    ["CC0 1.0"] =
      "https://creativecommons.org/publicdomain/zero/1.0/"
  }


  return licenses[key]

end

-- Autor:innen und Institutionen für AMB und Schema.org aufbereiten.


local function author_name(author)

  if
    author == nil
    or type(author) ~= "table"
  then
    return text(author)
  end


  if type(author.name) == "table" then

    local literal =
      text(
        author.name.literal
      )

    if literal ~= nil then
      return literal
    end


    local parts = {}

    local given =
      text(
        author.name.given
      )

    local family =
      text(
        author.name.family
      )


    if given ~= nil then

      table.insert(
        parts,
        given
      )

    end


    if family ~= nil then

      table.insert(
        parts,
        family
      )

    end


    if #parts > 0 then

      return
        table.concat(
          parts,
          " "
        )

    end

  end


  return text(author.name)

end


local function amb_organization(
  affiliation
)

  if affiliation == nil then
    return nil
  end


  if type(affiliation) ~= "table" then

    local name =
      text(affiliation)

    if name == nil then
      return nil
    end

    return {
      type = "Organization",
      name = name
    }

  end


  local name =
    text(
      affiliation.name
    )

  if name == nil then
    return nil
  end


  local organization = {

    type =
      "Organization",

    name =
      name
  }


  local ror_value =
    affiliation.ror


  if
    ror_value == nil
    and type(affiliation.metadata) == "table"
  then

    ror_value =
      affiliation.metadata.ror

  end


  local _, ror_url =
    normalize_ror(
      ror_value
    )


  if ror_url ~= nil then

    organization.id =
      ror_url

  else

    local url =
      text(
        affiliation.url
      )

    if
      url ~= nil
      and is_url(url)
    then

      organization.id =
        url

    end

  end


  return organization

end


local function amb_person(author)

  local name =
    author_name(author)

  if name == nil then
    return nil
  end


  local person = {

    type =
      "Person",

    name =
      name
  }


  if type(author) ~= "table" then
    return person
  end


  local _, orcid_url =
    normalize_orcid(
      author.orcid
    )


  if orcid_url ~= nil then

    person.id =
      orcid_url

  end

  -- AMB erlaubt hier nur eine einzelne affiliation; verwendet wird die erste Zuordnung.

  local affiliations =
    as_array(
      author.affiliations
      or author.affiliation
    )


  if #affiliations > 0 then

    local affiliation =
      amb_organization(
        affiliations[1]
      )


    if affiliation ~= nil then

      person.affiliation =
        affiliation

    end

  end


  return person

end


local function amb_creators(meta)

  local result = {}


  local source =
    meta["by-author"]
    or meta.authors
    or meta.author


  for _, author in ipairs(
    as_array(source)
  ) do

    local person =
      amb_person(author)


    if person ~= nil then

      table.insert(
        result,
        person
      )

    end

  end


  return result

end


local function schema_organization(
  affiliation
)

  if affiliation == nil then
    return nil
  end


  if type(affiliation) ~= "table" then

    local name =
      text(affiliation)

    if name == nil then
      return nil
    end


    return {

      ["@type"] =
        "Organization",

      name =
        name
    }

  end


  local organization = {

    ["@type"] =
      "Organization"
  }


  local name =
    text(
      affiliation.name
    )

  local url =
    text(
      affiliation.url
    )


  if name ~= nil then

    organization.name =
      name

  end


  if url ~= nil then

    organization.url =
      url

  end


  local ror_value =
    affiliation.ror


  if
    ror_value == nil
    and type(affiliation.metadata) == "table"
  then

    ror_value =
      affiliation.metadata.ror

  end


  local ror_id, ror_url =
    normalize_ror(
      ror_value
    )


  if ror_url ~= nil then

    organization["@id"] =
      ror_url

    organization.sameAs =
      ror_url

    organization.identifier = {

      ["@type"] =
        "PropertyValue",

      propertyID =
        "ROR",

      value =
        ror_id,

      url =
        ror_url
    }

  end


  local street =
    text(
      affiliation.address
    )

  local city =
    text(
      affiliation.city
    )

  local region =
    text(
      affiliation.region
      or affiliation.state
    )

  local postal_code =
    text(
      affiliation["postal-code"]
      or affiliation.postalCode
    )

  local country =
    text(
      affiliation.country
    )


  if
    street ~= nil
    or city ~= nil
    or region ~= nil
    or postal_code ~= nil
    or country ~= nil
  then

    local address = {

      ["@type"] =
        "PostalAddress"
    }


    if street ~= nil then

      address.streetAddress =
        street

    end


    if city ~= nil then

      address.addressLocality =
        city

    end


    if region ~= nil then

      address.addressRegion =
        region

    end


    if postal_code ~= nil then

      address.postalCode =
        postal_code

    end


    if country ~= nil then

      address.addressCountry =
        country

    end


    organization.address =
      address

  end


  return organization

end


local function schema_person(author)

  local name =
    author_name(author)

  if name == nil then
    return nil
  end


  local person = {

    ["@type"] =
      "Person",

    name =
      name
  }


  if type(author) ~= "table" then
    return person
  end


  if type(author.name) == "table" then

    local given =
      text(
        author.name.given
      )

    local family =
      text(
        author.name.family
      )


    if given ~= nil then

      person.givenName =
        given

    end


    if family ~= nil then

      person.familyName =
        family

    end

  end


  local email =
    text(
      author.email
    )

  local url =
    text(
      author.url
    )


  if email ~= nil then

    person.email =
      email

  end


  if url ~= nil then

    person.url =
      url

  end


  local orcid_id, orcid_url =
    normalize_orcid(
      author.orcid
    )


  if orcid_url ~= nil then

    person["@id"] =
      orcid_url

    person.sameAs =
      orcid_url

    person.identifier = {

      ["@type"] =
        "PropertyValue",

      propertyID =
        "ORCID",

      value =
        orcid_id,

      url =
        orcid_url
    }

  end


  local organizations = {}


  for _, affiliation in ipairs(
    as_array(
      author.affiliations
      or author.affiliation
    )
  ) do

    local organization =
      schema_organization(
        affiliation
      )


    if organization ~= nil then

      table.insert(
        organizations,
        organization
      )

    end

  end


  if #organizations == 1 then

    person.affiliation =
      organizations[1]

  elseif #organizations > 1 then

    person.affiliation =
      organizations

  end


  return person

end

-- Herausgebende Institutionen aufbereiten.


local function amb_publishers(meta)

  local citation =
    meta.citation or {}


  local source =
    citation.publisher
    or meta.publisher


  local result = {}


  for _, publisher in ipairs(
    as_array(source)
  ) do

    local organization =
      amb_organization(
        publisher
      )


    if organization == nil then

      local name =
        text(publisher)


      if name ~= nil then

        organization = {

          type =
            "Organization",

          name =
            name
        }

      end

    end


    if organization ~= nil then

      table.insert(
        result,
        organization
      )

    end

  end


  return result

end

-- Kontrollierte Begriffe für AMB abbilden.


local function amb_concept(
  value,
  require_id
)

  if value == nil then
    return nil
  end


  if type(value) ~= "table" then

    local identifier =
      text(value)


    if
      identifier ~= nil
      and is_url(identifier)
    then

      return {
        id = identifier
      }

    end


    return nil

  end


  local identifier =
    text(
      value.id
      or value["@id"]
    )

  local pref_label =
    localized_value(
      value.prefLabel
      or value.name
    )

  local concept_type =
    text(
      value.type
    )


  if
    require_id
    and identifier == nil
  then
    return nil
  end


  if
    identifier == nil
    and pref_label == nil
  then
    return nil
  end


  local concept = {}


  if identifier ~= nil then

    concept.id =
      identifier

  end


  if concept_type ~= nil then

    concept.type =
      concept_type

  elseif identifier ~= nil then

    concept.type =
      "Concept"

  end


  if pref_label ~= nil then

    concept.prefLabel =
      pref_label

  end


  return concept

end


local function amb_concept_array(
  value,
  require_id
)

  local result = {}


  for _, item in ipairs(
    as_array(value)
  ) do

    local concept =
      amb_concept(
        item,
        require_id
      )


    if concept ~= nil then

      table.insert(
        result,
        concept
      )

    end

  end


  return result

end

-- Beziehungen zu anderen Ressourcen für AMB abbilden.


local function amb_resource_reference(
  value
)

  if
    value == nil
    or type(value) ~= "table"
  then
    return nil
  end


  local identifier =
    text(
      value.id
      or value.url
    )


  if identifier == nil then
    return nil
  end


  local result = {

    id =
      identifier
  }


  local name =
    text(
      value.name
      or value.title
    )


  if name ~= nil then

    result.name =
      name

  end


  return result

end


local function amb_resource_array(value)

  local result = {}


  for _, item in ipairs(
    as_array(value)
  ) do

    local resource =
      amb_resource_reference(
        item
      )


    if resource ~= nil then

      table.insert(
        result,
        resource
      )

    end

  end


  return result

end

-- AMB/OERSI-JSON-LD erzeugen.
-- Fehlen kanonische URL, Titel oder Sprache, wird kein unvollständiger AMB-Datensatz ausgegeben.


local function build_amb_metadata(meta)

  local citation =
    meta.citation or {}

  local oer =
    meta.oer or {}


  local canonical =
    text(
      citation.url
    )

  local title =
    text(
      meta.title
    )

  local lang =
    text(
      meta.lang
    )


  if
    canonical == nil
    or title == nil
    or lang == nil
  then
    return nil
  end


  local amb = {

    ["@context"] = {

      "https://w3id.org/kim/amb/context.jsonld",

      "https://schema.org",

      {
        ["@language"] =
          lang
      }
    },


    id =
      canonical,


    type = {
      "LearningResource",
      "PresentationDigitalDocument"
    },


    name =
      title
  }


  local description =
    text(
      meta.description
    )


  if description ~= nil then

    amb.description =
      normalize_space(
        description
      )

  end


  local about =
    amb_concept_array(
      oer.about,
      true
    )


  if #about > 0 then

    amb.about =
      about

  end


  local keywords =
    string_array(
      meta.keywords
    )


  if #keywords > 0 then

    amb.keywords =
      keywords

  end


  amb.inLanguage = {
    lang
  }


  local image =
    resolve_url(
      meta.image,
      canonical
    )


  if image ~= nil then

    amb.image =
      image

  end


  local creators =
    amb_creators(
      meta
    )


  if #creators > 0 then

    amb.creator =
      creators

  end


  local date_published =
    text(
      meta["date-meta"]
      or meta.date
    )

  local date_created =
    text(
      meta["date-created"]
    )

  local date_modified =
    text(
      meta["date-modified"]
    )


  if date_created ~= nil then

    amb.dateCreated =
      date_created

  end


  if date_published ~= nil then

    amb.datePublished =
      date_published

  end


  if date_modified ~= nil then

    amb.dateModified =
      date_modified

  end


  local publishers =
    amb_publishers(
      meta
    )


  if #publishers > 0 then

    amb.publisher =
      publishers

  end


  local accessible =
    boolean_value(
      oer.isAccessibleForFree
    )


  if accessible ~= nil then

    amb.isAccessibleForFree =
      accessible

  end


  local license =
    license_url(
      meta
    )


  if license ~= nil then

    amb.license = {
      id =
        license
    }

  end


  local conditions =
    amb_concept(
      oer.conditionsOfAccess,
      true
    )


  if conditions ~= nil then

    amb.conditionsOfAccess =
      conditions

  end


  local resource_types =
    amb_concept_array(
      oer.learningResourceType,
      true
    )


  if #resource_types > 0 then

    amb.learningResourceType =
      resource_types

  end


  local audience =
    amb_concept_array(
      oer.audience,
      true
    )


  if #audience > 0 then

    amb.audience =
      audience

  end


  local teaches =
    amb_concept_array(
      oer.teaches,
      false
    )


  if #teaches > 0 then

    amb.teaches =
      teaches

  end


  local assesses =
    amb_concept_array(
      oer.assesses,
      false
    )


  if #assesses > 0 then

    amb.assesses =
      assesses

  end


  local competency_required =
    amb_concept_array(
      oer.competencyRequired,
      false
    )


  if #competency_required > 0 then

    amb.competencyRequired =
      competency_required

  end


  local educational_level =
    amb_concept_array(
      oer.educationalLevel,
      true
    )


  if #educational_level > 0 then

    amb.educationalLevel =
      educational_level

  end


  if type(oer.interactivityType) == "table" then

    local interactivity =
      amb_concept(
        oer.interactivityType,
        true
      )


    if interactivity ~= nil then

      amb.interactivityType =
        interactivity

    end

  end


  local is_based_on =
    amb_resource_array(
      oer.isBasedOn
    )


  if #is_based_on > 0 then

    amb.isBasedOn =
      is_based_on

  end


  local is_part_of =
    amb_resource_array(
      oer.isPartOf
    )


  if #is_part_of > 0 then

    amb.isPartOf =
      is_part_of

  end


  local has_part =
    amb_resource_array(
      oer.hasPart
    )


  if #has_part > 0 then

    amb.hasPart =
      has_part

  end


  return amb

end

-- Copyright-Angaben in Schema.org-Eigenschaften übertragen.


local function apply_schema_copyright(
  object,
  meta
)

  local copyright =
    meta.copyright


  if copyright == nil then
    return
  end


  if type(copyright) ~= "table" then

    local notice =
      text(copyright)


    if notice ~= nil then

      object.copyrightNotice =
        notice

    end


    return

  end


  local holder =
    text(
      copyright.holder
    )

  local holder_type =
    text(
      copyright["holder-type"]
      or copyright.holder_type
    )

  local year =
    text(
      copyright.year
    )

  local notice =
    text(
      copyright.statement
      or copyright.notice
    )


  if holder ~= nil then

    local holder_node = {

      name =
        holder
    }


    if holder_type ~= nil then

      local normalized =
        string.lower(
          holder_type
        )


      if normalized == "person" then

        holder_node["@type"] =
          "Person"

      elseif normalized == "organization" then

        holder_node["@type"] =
          "Organization"

      end

    end


    object.copyrightHolder =
      holder_node

  end


  if year ~= nil then

    object.copyrightYear =
      tonumber(year)
      or year

  end


  if notice ~= nil then

    object.copyrightNotice =
      notice

  elseif
    holder ~= nil
    or year ~= nil
  then

    local parts = {
      "©"
    }


    if year ~= nil then

      table.insert(
        parts,
        year
      )

    end


    if holder ~= nil then

      table.insert(
        parts,
        holder
      )

    end


    object.copyrightNotice =
      table.concat(
        parts,
        " "
      )

  end

end

-- DALIA-Angaben in ergänzende Schema.org-Strukturen überführen.


local function build_dalia_audience(
  value,
  lang
)

  local result = {}


  for _, item in ipairs(
    as_array(value)
  ) do

    local identifier =
      nil

    local label =
      nil


    if type(item) == "table" then

      identifier =
        text(
          item.id
          or item["@id"]
        )

      label =
        preferred_label(
          item.prefLabel
          or item.name,
          lang
        )

    else

      label =
        text(item)

    end


    if
      identifier ~= nil
      or label ~= nil
    then

      local audience = {

        ["@type"] =
          "EducationalAudience"
      }


      if identifier ~= nil then

        audience["@id"] =
          identifier

      end


      if label ~= nil then

        audience.name =
          label

        audience.educationalRole =
          label

      end


      table.insert(
        result,
        audience
      )

    end

  end


  return result

end


local function apply_dalia_related_works(
  object,
  value
)

  local relation_map = {

    isTranslationOf =
      "translationOfWork",

    hasTranslation =
      "workTranslation",

    isPartOf =
      "isPartOf",

    hasPart =
      "hasPart"
  }


  for _, item in ipairs(
    as_array(value)
  ) do

    if type(item) == "table" then

      local relation =
        text(
          item.relation
        )

      local identifier =
        text(
          item.id
          or item.url
        )


      local property =
        relation_map[relation]


      if
        property ~= nil
        and identifier ~= nil
      then

        local work = {

          ["@type"] =
            "CreativeWork",

          ["@id"] =
            identifier
        }


        if is_url(identifier) then

          work.url =
            identifier

        end


        local name =
          text(
            item.name
            or item.title
          )


        if name ~= nil then

          work.name =
            name

        end


        append_property(
          object,
          property,
          work
        )

      end

    end

  end

end

-- Ergänzende Schema.org-Beschreibung der Präsentation erzeugen.


local function build_schema_presentation(
  meta
)

  local citation =
    meta.citation or {}

  local oer =
    meta.oer or {}

  local dalia =
    meta.dalia or {}

  local lang =
    text(
      meta.lang
    )

  local canonical =
    text(
      citation.url
    )


  local function schema_term(value)

    if value == nil then
      return nil
    end


    if type(value) ~= "table" then

      local value_text =
        text(value)

      if value_text == nil then
        return nil
      end


      if is_url(value_text) then

        return {
          ["@type"] =
            "DefinedTerm",

          ["@id"] =
            value_text,

          url =
            value_text
        }

      end


      return value_text

    end


    local identifier =
      text(
        value.id
        or value["@id"]
    )

    local label =
      preferred_label(
        value.prefLabel
        or value.name,
        lang
      )

    local term_code =
      text(
        value.termCode
    )

    local vocabulary =
      text(
        value.inDefinedTermSet
        or value.scheme
    )


    if
      identifier == nil
      and label == nil
      and term_code == nil
    then
      return nil
    end


    local term = {
      ["@type"] =
        "DefinedTerm"
    }


    if identifier ~= nil then

      term["@id"] =
        identifier

      if is_url(identifier) then
        term.url =
          identifier
      end

    end


    if label ~= nil then

      term.name =
        label

    end


    if term_code ~= nil then

      term.termCode =
        term_code

    end


    if vocabulary ~= nil then

      term.inDefinedTermSet =
        vocabulary

    end


    return term

  end


  local function schema_terms(value)

    local result = {}


    for _, item in ipairs(
      as_array(value)
    ) do

      local term =
        schema_term(
          item
        )


      if term ~= nil then

        table.insert(
          result,
          term
        )

      end

    end


    return result

  end


  local function set_values(
    object,
    property,
    values
  )

    if #values == 1 then

      object[property] =
        values[1]

    elseif #values > 1 then

      object[property] =
        values

    end

  end

  -- Grundstruktur und stabile Identifikation


  local doi, doi_url =
    normalize_doi(
      meta.doi
      or citation.doi
    )


  local presentation_id =
    canonical
    or doi_url


  local presentation = {

    ["@type"] = {
      "PresentationDigitalDocument",
      "LearningResource"
    },

    encodingFormat =
      "text/html"
  }


  if presentation_id ~= nil then

    presentation["@id"] =
      presentation_id

  end


  if canonical ~= nil then

    presentation.url =
      canonical

  end

  -- Titel und Beschreibung


  local title =
    text(
      meta.title
    )

  local subtitle =
    text(
      meta.subtitle
    )

  local description =
    text(
      meta.description
    )


  if title ~= nil then

    presentation.name =
      title

  end


  if subtitle ~= nil then

    presentation.alternativeHeadline =
      subtitle

  end


  if description ~= nil then

    presentation.description =
      normalize_space(
        description
      )

  end

  -- Sprache


  if lang ~= nil then

    presentation.inLanguage =
      lang

  end

  -- Schlagwörter


  local keywords =
    string_array(
      meta.keywords
    )


  if #keywords > 0 then

    presentation.keywords =
      keywords

  end

  -- Datum


  local date_published =
    text(
      meta["date-meta"]
      or meta.date
    )

  local date_created =
    text(
      meta["date-created"]
    )

  local date_modified =
    text(
      meta["date-modified"]
    )


  if date_created ~= nil then

    presentation.dateCreated =
      date_created

  end


  if date_published ~= nil then

    presentation.datePublished =
      date_published

  end


  if date_modified ~= nil then

    presentation.dateModified =
      date_modified

  end

  -- Autor:innen


  local authors = {}

  local author_source =
    meta["by-author"]
    or meta.authors
    or meta.author


  for _, author in ipairs(
    as_array(author_source)
  ) do

    local person =
      schema_person(
        author
      )


    if person ~= nil then

      table.insert(
        authors,
        person
      )

    end

  end


  if #authors == 1 then

    presentation.author =
      authors[1]

  elseif #authors > 1 then

    presentation.author =
      authors

  end

  -- Publisher


  local publisher_source =
    citation.publisher
    or meta.publisher

  local publishers = {}


  for _, publisher in ipairs(
    as_array(publisher_source)
  ) do

    local organization =
      nil


    if
      type(publisher) == "table"
      and (
        publisher.name ~= nil
        or publisher.url ~= nil
        or publisher.ror ~= nil
      )
    then

      organization =
        schema_organization(
          publisher
        )

    else

      local publisher_name =
        text(
          publisher
        )


      if publisher_name ~= nil then

        organization = {

          ["@type"] =
            "Organization",

          name =
            publisher_name
        }

      end

    end


    if organization ~= nil then

      table.insert(
        publishers,
        organization
      )

    end

  end


  if #publishers == 1 then

    presentation.publisher =
      publishers[1]

  elseif #publishers > 1 then

    presentation.publisher =
      publishers

  end

  -- DOI


  if doi ~= nil then

    presentation.identifier = {

      ["@type"] =
        "PropertyValue",

      propertyID =
        "DOI",

      value =
        doi,

      url =
        doi_url
    }


    presentation.sameAs =
      doi_url

  end

  -- Version und Genre


  local version =
    text(
      citation.version
    )


  if
    version == nil
    and type(dalia) == "table"
  then

    version =
      text(
        dalia.version
      )

  end


  if version ~= nil then

    presentation.version =
      version

  end


  local genre =
    text(
      citation.genre
    )


  if genre ~= nil then

    presentation.genre =
      genre

  end

  -- Lizenz und Copyright


  local license =
    license_url(
      meta
    )


  if license ~= nil then

    presentation.license =
      license

  end


  apply_schema_copyright(
    presentation,
    meta
  )

  -- Freier Zugang


  local accessible =
    boolean_value(
      oer.isAccessibleForFree
    )


  if accessible ~= nil then

    presentation.isAccessibleForFree =
      accessible

  end

  -- Publikationsstatus


  local status =
    schema_term(
      oer.creativeWorkStatus
    )


  if status ~= nil then

    presentation.creativeWorkStatus =
      status

  end

  -- Fachliche Einordnung


  set_values(
    presentation,
    "about",
    schema_terms(
      oer.about
    )
  )

  -- Lernressourcentyp


  set_values(
    presentation,
    "learningResourceType",
    schema_terms(
      oer.learningResourceType
    )
  )

  -- Bildungsstufe


  set_values(
    presentation,
    "educationalLevel",
    schema_terms(
      oer.educationalLevel
    )
  )

  -- Lernziele und Kompetenzen


  set_values(
    presentation,
    "teaches",
    schema_terms(
      oer.teaches
    )
  )


  set_values(
    presentation,
    "assesses",
    schema_terms(
      oer.assesses
    )
  )


  set_values(
    presentation,
    "competencyRequired",
    schema_terms(
      oer.competencyRequired
    )
  )

  -- Zugangsbedingungen


  if oer.conditionsOfAccess ~= nil then

    local conditions =
      nil


    if type(oer.conditionsOfAccess) == "table" then

      conditions =
        preferred_label(
          oer.conditionsOfAccess.prefLabel
          or oer.conditionsOfAccess.name,
          lang
        )

    else

      conditions =
        text(
          oer.conditionsOfAccess
        )

    end


    if conditions ~= nil then

      presentation.conditionsOfAccess =
        conditions

    end

  end

  -- Interaktivität


  if oer.interactivityType ~= nil then

    local interactivity =
      nil


    if type(oer.interactivityType) == "table" then

      interactivity =
        preferred_label(
          oer.interactivityType.prefLabel
          or oer.interactivityType.name,
          lang
        )

    else

      interactivity =
        text(
          oer.interactivityType
        )

    end


    if interactivity ~= nil then

      presentation.interactivityType =
        interactivity

    end

  end

  -- Barrierefreiheit


  local accessibility =
    string_array(
      oer.accessibilityFeature
    )


  if #accessibility == 1 then

    presentation.accessibilityFeature =
      accessibility[1]

  elseif #accessibility > 1 then

    presentation.accessibilityFeature =
      accessibility

  end

  -- Zielgruppen


  local audiences = {}


  for _, item in ipairs(
    as_array(
      oer.audience
    )
  ) do

    local identifier =
      nil

    local label =
      nil


    if type(item) == "table" then

      identifier =
        text(
          item.id
          or item["@id"]
        )

      label =
        preferred_label(
          item.prefLabel
          or item.name,
          lang
        )

    else

      label =
        text(
          item
        )

    end


    if
      identifier ~= nil
      or label ~= nil
    then

      local audience = {

        ["@type"] =
          "EducationalAudience"
      }


      if identifier ~= nil then

        audience["@id"] =
          identifier

      end


      if label ~= nil then

        audience.name =
          label

        audience.educationalRole =
          label

      end


      table.insert(
        audiences,
        audience
      )

    end

  end


  local dalia_audiences =
    build_dalia_audience(
      dalia.targetGroup,
      lang
    )


  for _, audience in ipairs(
    dalia_audiences
  ) do

    table.insert(
      audiences,
      audience
    )

  end


  if #audiences == 1 then

    presentation.audience =
      audiences[1]

  elseif #audiences > 1 then

    presentation.audience =
      audiences

  end

  -- Vorschaubild


  local image =
    resolve_url(
      meta.image,
      canonical
    )


  if image ~= nil then

    presentation.image =
      image

  end

  -- Beziehungen zu anderen Werken


  apply_dalia_related_works(
    presentation,
    dalia.relatedWorks
  )


  return
    presentation,
    presentation_id

end

-- Veranstaltung, Session und Veranstaltungsreihe als Schema.org-Graph erzeugen.


local function build_event_nodes(
  meta,
  presentation_id
)

  local result = {}


  if presentation_id == nil then
    return result
  end


  local citation =
    meta.citation or {}


  local event_title =
    text(
      citation["event-title"]
    )

  local session_title =
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

  local series_title =
    text(
      citation["collection-title"]
    )


  if
    event_title == nil
    and session_title == nil
    and series_title == nil
  then

    return result

  end


  local series_id =
    presentation_id
    .. "#event-series"

  local event_id =
    presentation_id
    .. "#event"

  local session_id =
    presentation_id
    .. "#session"


  if series_title ~= nil then

    local series = {

      ["@id"] =
        series_id,

      ["@type"] =
        "EventSeries",

      name =
        series_title
    }


    table.insert(
      result,
      series
    )

  end


  if event_title ~= nil then

    local event = {

      ["@id"] =
        event_id,

      ["@type"] =
        "Event",

      name =
        event_title
    }


    if event_place ~= nil then

      event.location = {

        ["@type"] =
          "Place",

        name =
          event_place
      }

    end


    if event_date ~= nil then

      event.startDate =
        event_date

    end


    if series_title ~= nil then

      event.superEvent = {
        ["@id"] =
          series_id
      }

    end


    if session_title ~= nil then

      event.subEvent = {
        ["@id"] =
          session_id
      }

    else

      event.workFeatured = {
        ["@id"] =
          presentation_id
      }

    end


    table.insert(
      result,
      event
    )

  end


  if session_title ~= nil then

    local session = {

      ["@id"] =
        session_id,

      ["@type"] =
        "Event",

      name =
        session_title,

      workFeatured = {
        ["@id"] =
          presentation_id
      }
    }


    if event_title ~= nil then

      session.superEvent = {
        ["@id"] =
          event_id
      }

    elseif series_title ~= nil then

      session.superEvent = {
        ["@id"] =
          series_id
      }

    end


    if event_title == nil then

      if event_place ~= nil then

        session.location = {

          ["@type"] =
            "Place",

          name =
            event_place
        }

      end


      if event_date ~= nil then

        session.startDate =
          event_date

      end

    end


    table.insert(
      result,
      session
    )

  end


  if
    series_title ~= nil
    and event_title == nil
    and session_title == nil
  then

    result[1].workFeatured = {
      ["@id"] =
        presentation_id
    }

  end


  return result

end

-- Präsentation und optionale Veranstaltungsobjekte zu Schema.org-JSON-LD zusammenführen.


local function build_schema_metadata(meta)

  local presentation,
        presentation_id =
    build_schema_presentation(
      meta
    )


  local graph = {
    presentation
  }


  local events =
    build_event_nodes(
      meta,
      presentation_id
    )


  for _, event in ipairs(events) do

    table.insert(
      graph,
      event
    )

  end


  return {

    ["@context"] =
      "https://schema.org",

    ["@graph"] =
      graph
  }

end

-- JSON für den HTML-Quelltext lesbar formatieren.


local function pretty_json(json)

  local result = {}

  local indent =
    0

  local indent_string =
    "  "

  local in_string =
    false

  local escaped =
    false


  local function newline()

    table.insert(
      result,

      "\n"
      .. string.rep(
        indent_string,
        indent
      )
    )

  end


  for i = 1, #json do

    local char =
      json:sub(i, i)


    if in_string then

      table.insert(
        result,
        char
      )


      if escaped then

        escaped =
          false

      elseif char == "\\" then

        escaped =
          true

      elseif char == '"' then

        in_string =
          false

      end


    else

      if char == '"' then

        in_string =
          true

        table.insert(
          result,
          char
        )


      elseif
        char == "{"
        or char == "["
      then

        table.insert(
          result,
          char
        )

        indent =
          indent + 1

        newline()


      elseif
        char == "}"
        or char == "]"
      then

        indent =
          math.max(
            0,
            indent - 1
          )

        newline()

        table.insert(
          result,
          char
        )


      elseif char == "," then

        table.insert(
          result,
          char
        )

        newline()


      elseif char == ":" then

        table.insert(
          result,
          ": "
        )


      elseif not char:match("%s") then

        table.insert(
          result,
          char
        )

      end

    end

  end


  return
    table.concat(
      result
    )

end

-- JSON-LD sicher als <script>-Element ausgeben.


local function jsonld_script(
  identifier,
  data
)

  local json =
    pretty_json(
      quarto.json.encode(
        data
      )
    )


  json =
    json:gsub(
      "</",
      "<\\/"
    )


  return
    '<script type="application/ld+json" id="'
    .. identifier
    .. '">\n'
    .. json
    .. '\n</script>'

end

-- Embedded Metadata für den Zotero Connector erzeugen.


local function zotero_meta(
  name,
  value
)

  local value_text =
    text(value)


  if value_text == nil then
    return nil
  end


  return
    '<meta name="'
    .. html_escape(name)
    .. '" content="'
    .. html_escape(
      normalize_space(value_text)
    )
    .. '">'

end


local function zotero_presenter_name(
  author
)

  if
    author ~= nil
    and type(author) == "table"
    and type(author.name) == "table"
  then

    local given =
      text(
        author.name.given
      )

    local family =
      text(
        author.name.family
      )


    if
      family ~= nil
      and given ~= nil
    then

      return
        family
        .. ", "
        .. given

    end


    if family ~= nil then
      return family
    end


    if given ~= nil then
      return given
    end

  end


  return
    author_name(
      author
    )

end


local function build_zotero_metadata(
  meta
)

  local citation =
    meta.citation or {}


  local result = {}


  local function add(
    name,
    value
  )

    local element =
      zotero_meta(
        name,
        value
      )


    if element ~= nil then

      table.insert(
        result,
        element
      )

    end

  end

  -- Zotero-Typ explizit als Presentation setzen, um Fehlklassifikationen zu vermeiden.


  add(
    "z:itemType",
    "presentation"
  )


  add(
    "dc:title",
    meta.title
  )


  add(
    "dcterms:abstract",
    meta.description
  )


  local author_source =
    meta["by-author"]
    or meta.authors
    or meta.author


  for _, author in ipairs(
    as_array(author_source)
  ) do

    add(
      "eprints:creators_name",
      zotero_presenter_name(
        author
      )
    )

  end

  -- Bei Zotero bezeichnet Date primär den Vortragstermin; event-date hat daher Vorrang.


  add(
    "dcterms:issued",

    citation["event-date"]
    or meta["date-meta"]
    or meta.date
  )


  add(
    "z:presentationType",
    citation.genre
  )


  add(
    "z:meetingName",
    citation["event-title"]
  )


  add(
    "z:place",
    citation["event-place"]
  )


  add(
    "z:series",
    citation["collection-title"]
  )


  add(
    "z:sessionTitle",
    citation["container-title"]
  )


  local doi =
    select(
      1,
      normalize_doi(
        meta.doi
        or citation.doi
      )
    )


  add(
    "dc:identifier.DOI",
    doi
  )


  add(
    "z:url",
    citation.url
  )


  add(
    "dc:language",
    meta.lang
  )


  local license =
    meta.license


  if type(license) == "table" then

    add(
      "dc:rights",

      license.text
      or license.url
    )

  else

    add(
      "dc:rights",
      license
    )

  end


    if #result == 0 then
    return nil
  end


  return
    table.concat(
      result,
      "\n"
    )

end

-- Maschinenlesbare Metadaten in den HTML-Header einfügen.


function Pandoc(doc)

  if not quarto.doc.is_format("html") then
    return doc
  end


  local meta =
    doc.meta

  local citation =
    meta.citation or {}


  local description =
    text(
      meta.description
    )

  local canonical =
    text(
      citation.url
    )

  local license =
    license_url(
      meta
    )


  local header = {}

  -- Beschreibung


  if description ~= nil then

    table.insert(
      header,

      '<meta name="description" content="'
      .. html_escape(
        normalize_space(description)
      )
      .. '">'
    )

  end

  -- Kanonische URL


  if canonical ~= nil then

    table.insert(
      header,

      '<link rel="canonical" href="'
      .. html_escape(canonical)
      .. '">'
    )

  end

  -- Lizenz


  if license ~= nil then

    table.insert(
      header,

      '<link rel="license" href="'
      .. html_escape(license)
      .. '">'
    )

  end

  -- Zotero Connector


  local zotero =
    build_zotero_metadata(
      meta
    )


  if zotero ~= nil then


    table.insert(
      header,
      zotero
    )

  end

  -- AMB / OERSI


  local amb =
    build_amb_metadata(
      meta
    )


  if amb ~= nil then

    table.insert(
      header,

      jsonld_script(
        "n4o-amb-metadata",
        amb
      )
    )

  end

  -- Ergänzendes Schema.org


  local schema =
    build_schema_metadata(
      meta
    )


  table.insert(
    header,

    jsonld_script(
      "n4o-schema-metadata",
      schema
    )
  )


  quarto.doc.include_text(
    "in-header",
    table.concat(
      header,
      "\n"
    )
  )


  return doc

end
