-- html_metadata.lua
--
-- Erzeugt maschinenlesbare Metadaten im HTML-Header der
-- N4O-Quarto-Reveal.js-Präsentation.
--
-- Ausgaben:
-- - description, canonical und license
-- - AMB/OERSI-JSON-LD
-- - ergänzendes Schema.org-JSON-LD
-- - Embedded Metadata für den Zotero Connector
--
-- Erwartete Filterreihenfolge:
-- title_brand.lua -> quarto -> title_authors.lua
-- -> html_metadata.lua -> appendix_slide.lua
--
-- Personenmodell:
--
-- author
--   bibliografische Autor:innen der OER
--
-- roles
--   Beiträge nach CRediT
--   Die Rollen bestimmen nicht den Autor:innenstatus.
--
-- contributors
--   weitere Mitwirkende, die nicht als Autor:innen geführt werden
--
-- functions
--   zusätzliche Funktionen einer Person gegenüber der Ressource,
--   z. B. speaker. Diese Ebene ist von CRediT getrennt.
--
-- Für das RevealJS-Template gilt:
-- - title_authors.lua erzeugt n4o-authors als zentrale Liste
--   aller Personen mit mindestens einer gültigen CRediT-Rolle.
-- - Ausschließlich n4o-authors wird für Autor:innenmetadaten
--   dieses Filters verwendet.
-- - Personen ohne gültige roles werden weder als AMB creator,
--   Schema.org author noch in Zotero ausgegeben.
-- - Alle gültigen N4O-Autor:innen werden in AMB als creator
--   und in Schema.org als author ausgegeben.
-- - CRediT-Rollen werden zusätzlich als Schema.org Role ausgegeben.
-- - Zotero Presenter wird nicht aus CRediT abgeleitet.
-- - Nur eine explizite Funktion speaker wird für Zotero Presentation
--   auf Presenter abgebildet.
--
-- Quarto erzeugt native <meta name="author">-Elemente selbst.
-- Dieser Filter erzeugt deshalb keine konkurrierenden author-Meta-Tags.


-- ============================================================================
-- GEMEINSAME MODULE UND HILFSFUNKTIONEN
-- ============================================================================


local filter_dir =
  pandoc.path.directory(PANDOC_SCRIPT_FILE)

package.path =
  pandoc.path.join({filter_dir, "modules", "?.lua"})
  .. ";"
  .. package.path

local utils =
  require("n4o.utils")

local credit =
  require("n4o.credit")

local license_data =
  require("n4o.license")


local text =
  utils.text

local normalize_space =
  utils.normalize_space

local normalize_key =
  utils.normalize_key

local html_escape =
  utils.html_escape

local is_url =
  utils.is_url

local as_array =
  utils.as_array

local string_array =
  utils.string_array

local boolean_value =
  utils.boolean_value

local author_name =
  utils.author_name


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


local function set_values(
  object,
  property,
  values
)

  if values == nil then
    return
  end

  if type(values) ~= "table" then
    object[property] =
      values
    return
  end

  if #values == 1 then
    object[property] =
      values[1]
  elseif #values > 1 then
    object[property] =
      values
  end

end


-- ============================================================================
-- IDENTIFIKATOREN UND URLS
-- ============================================================================


local function normalize_doi(value)

  local doi =
    text(value)

  if doi == nil then
    return nil, nil
  end

  doi =
    normalize_space(doi)
      :gsub("^https?://doi%.org/", "")
      :gsub("^doi:%s*", "")

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

  local identifier =
    normalize_space(orcid)
      :gsub("^https?://orcid%.org/", "")

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

  local identifier =
    normalize_space(ror)
      :gsub("^https?://ror%.org/", "")

  if identifier == "" then
    return nil, nil
  end

  return
    identifier,
    "https://ror.org/" .. identifier

end


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


local function license_url(meta)

  return
    license_data.url(
      meta.license
    )

end


-- ============================================================================
-- PERSONEN UND INSTITUTIONEN
-- ============================================================================


local function author_source(meta)

  -- Keine Fallbacks auf by-author, authors oder author.
  --
  -- Dadurch können Personen, die von title_authors.lua wegen
  -- fehlender oder ungültiger CRediT-Rollen ausgeschlossen
  -- wurden, nicht über einen alternativen Datenpfad wieder in
  -- AMB-, Schema.org- oder Zotero-Metadaten gelangen.

  return
    meta["n4o-authors"]

end


local function contributor_source(meta)

  return
    meta.contributors

end


local function affiliation_index(meta)

  local result = {}

  for _, affiliation in ipairs(
    as_array(meta.affiliations)
  ) do

    if type(affiliation) == "table" then

      local id =
        text(
          affiliation.id
        )

      if id ~= nil then
        result[id] =
          affiliation
      end

    end

  end

  return result

end


local function resolve_affiliation(
  affiliation,
  meta
)

  if
    affiliation == nil
    or type(affiliation) ~= "table"
  then
    return affiliation
  end

  local ref =
    text(
      affiliation.ref
    )

  if ref == nil then
    return affiliation
  end

  local index =
    affiliation_index(meta)

  return
    index[ref]
    or affiliation

end


local function person_affiliations(
  person,
  meta
)

  local result = {}

  if
    person == nil
    or type(person) ~= "table"
  then
    return result
  end

  local source =
    person.affiliations
    or person.affiliation

  for _, affiliation in ipairs(
    as_array(source)
  ) do

    local resolved =
      resolve_affiliation(
        affiliation,
        meta
      )

    if resolved ~= nil then
      table.insert(
        result,
        resolved
      )
    end

  end

  return result

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
      type =
        "Organization",
      name =
        name
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


local function amb_person(
  person,
  meta
)

  local name =
    author_name(person)

  if name == nil then
    return nil
  end

  local result = {
    type =
      "Person",
    name =
      name
  }

  if type(person) ~= "table" then
    return result
  end

  local _, orcid_url =
    normalize_orcid(
      person.orcid
    )

  if orcid_url ~= nil then
    result.id =
      orcid_url
  end

  local affiliations =
    person_affiliations(
      person,
      meta
    )

  if #affiliations > 0 then

    local organization =
      amb_organization(
        affiliations[1]
      )

    if organization ~= nil then
      result.affiliation =
        organization
    end

  end

  return result

end


local function schema_person(
  person,
  meta
)

  local name =
    author_name(person)

  if name == nil then
    return nil
  end

  local result = {
    ["@type"] =
      "Person",
    name =
      name
  }

  if type(person) ~= "table" then
    return result
  end

  if type(person.name) == "table" then

    local given =
      text(
        person.name.given
      )

    local family =
      text(
        person.name.family
      )

    if given ~= nil then
      result.givenName =
        given
    end

    if family ~= nil then
      result.familyName =
        family
    end

  end

  local email =
    text(
      person.email
    )

  local url =
    text(
      person.url
    )

  if email ~= nil then
    result.email =
      email
  end

  if url ~= nil then
    result.url =
      url
  end

  local orcid_id, orcid_url =
    normalize_orcid(
      person.orcid
    )

  if orcid_url ~= nil then

    result["@id"] =
      orcid_url

    result.sameAs =
      orcid_url

    result.identifier = {
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
    person_affiliations(
      person,
      meta
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

  set_values(
    result,
    "affiliation",
    organizations
  )

  return result

end


local function person_reference(
  person,
  meta
)

  local schema =
    schema_person(
      person,
      meta
    )

  if schema == nil then
    return nil
  end

  if schema["@id"] ~= nil then
    return {
      ["@id"] =
        schema["@id"]
    }
  end

  return schema

end


-- ============================================================================
-- CRediT
-- ============================================================================


local credit_role_info =
  credit.info


local function schema_credit_roles(
  person,
  meta
)

  local result = {}

  if
    person == nil
    or type(person) ~= "table"
    or person.roles == nil
  then
    return result
  end

  local reference =
    person_reference(
      person,
      meta
    )

  if reference == nil then
    return result
  end

  for _, role in ipairs(
    as_array(person.roles)
  ) do

    local credit =
      credit_role_info(
        role
      )

    if credit ~= nil then

      table.insert(
        result,
        {
          ["@type"] =
            "Role",
          roleName =
            credit.label,
          url =
            credit.url,
          contributor =
            reference
        }
      )

    end

  end

  return result

end


-- ============================================================================
-- ZUSÄTZLICHE FUNKTIONEN
-- ============================================================================


local function person_functions(person)

  if
    person == nil
    or type(person) ~= "table"
  then
    return {}
  end

  local source =
    person.functions

  if
    source == nil
    and type(person.metadata) == "table"
  then
    source =
      person.metadata.functions
  end

  return
    string_array(source)

end


local function has_function(
  person,
  expected
)

  local expected_key =
    normalize_key(expected)

  if expected_key == nil then
    return false
  end

  for _, value in ipairs(
    person_functions(person)
  ) do

    if normalize_key(value) == expected_key then
      return true
    end

  end

  return false

end


local function function_info(value)

  local key =
    normalize_key(value)

  if key == nil then
    return nil
  end

  if key == "speaker" then

    return {
      label =
        "Speaker",
      url =
        "https://purl.org/ontology/modalia#Speaker",
      zotero =
        "presenter"
    }

  end

  -- Noch nicht abschließend gemappte Funktionen werden
  -- semantisch erhalten, aber ohne externe URI ausgegeben.

  return {
    label =
      text(value)
  }

end


local function schema_function_roles(
  person,
  meta
)

  local result = {}

  local reference =
    person_reference(
      person,
      meta
    )

  if reference == nil then
    return result
  end

  for _, value in ipairs(
    person_functions(person)
  ) do

    local info =
      function_info(
        value
      )

    if info ~= nil then

      local role = {
        ["@type"] =
          "Role",
        roleName =
          info.label,
        contributor =
          reference
      }

      if info.url ~= nil then
        role.url =
          info.url
      end

      table.insert(
        result,
        role
      )

    end

  end

  return result

end


-- ============================================================================
-- AMB / OERSI
-- ============================================================================


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
        id =
          identifier
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


local function amb_resource_reference(value)

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


local function amb_people(
  source,
  meta
)

  local result = {}

  for _, person in ipairs(
    as_array(source)
  ) do

    local mapped =
      amb_person(
        person,
        meta
      )

    if mapped ~= nil then
      table.insert(
        result,
        mapped
      )
    end

  end

  return result

end


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
    amb_people(
      author_source(meta),
      meta
    )

  if #creators > 0 then
    amb.creator =
      creators
  end

  local contributors =
    amb_people(
      contributor_source(meta),
      meta
    )

  if #contributors > 0 then
    amb.contributor =
      contributors
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

  if oer.interactivityType ~= nil then

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


-- ============================================================================
-- SCHEMA.ORG
-- ============================================================================


local function schema_term(
  value,
  lang
)

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

  local result = {
    ["@type"] =
      "DefinedTerm"
  }

  if identifier ~= nil then

    result["@id"] =
      identifier

    if is_url(identifier) then
      result.url =
        identifier
    end

  end

  if label ~= nil then
    result.name =
      label
  end

  if term_code ~= nil then
    result.termCode =
      term_code
  end

  if vocabulary ~= nil then
    result.inDefinedTermSet =
      vocabulary
  end

  return result

end


local function schema_terms(
  value,
  lang
)

  local result = {}

  for _, item in ipairs(
    as_array(value)
  ) do

    local term =
      schema_term(
        item,
        lang
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
    normalize_key(
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

    if holder_type == "person" then
      holder_node["@type"] =
        "Person"
    elseif holder_type == "organization" then
      holder_node["@type"] =
        "Organization"
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


local function schema_people(
  source,
  meta
)

  local result = {}

  for _, person in ipairs(
    as_array(source)
  ) do

    local mapped =
      schema_person(
        person,
        meta
      )

    if mapped ~= nil then
      table.insert(
        result,
        mapped
      )
    end

  end

  return result

end


local function schema_contribution_roles(
  source,
  meta
)

  local result = {}

  for _, person in ipairs(
    as_array(source)
  ) do

    for _, role in ipairs(
      schema_credit_roles(
        person,
        meta
      )
    ) do

      table.insert(
        result,
        role
      )

    end

    for _, role in ipairs(
      schema_function_roles(
        person,
        meta
      )
    ) do

      table.insert(
        result,
        role
      )

    end

  end

  return result

end


local function schema_resource_reference(
  value
)

  if value == nil then
    return nil
  end

  if type(value) ~= "table" then

    local identifier =
      text(value)

    if identifier == nil then
      return nil
    end

    if is_url(identifier) then

      return {
        ["@type"] =
          "CreativeWork",
        ["@id"] =
          identifier,
        url =
          identifier
      }

    end

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
    ["@type"] =
      "CreativeWork",
    ["@id"] =
      identifier
  }

  if is_url(identifier) then
    result.url =
      identifier
  end

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


local function schema_resource_array(value)

  local result = {}

  for _, item in ipairs(
    as_array(value)
  ) do

    local resource =
      schema_resource_reference(
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


local function apply_related_works(
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

      local property =
        relation_map[relation]

      local work =
        schema_resource_reference(
          item
        )

      if
        property ~= nil
        and work ~= nil
      then

        local existing =
          object[property]

        if existing == nil then

          object[property] =
            work

        elseif
          type(existing) == "table"
          and existing[1] ~= nil
        then

          table.insert(
            existing,
            work
          )

        else

          object[property] = {
            existing,
            work
          }

        end

      end

    end

  end

end


local function build_schema_presentation(meta)

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

  if lang ~= nil then
    presentation.inLanguage =
      lang
  end

  local keywords =
    string_array(
      meta.keywords
    )

  if #keywords > 0 then
    presentation.keywords =
      keywords
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

  local authors =
    schema_people(
      author_source(meta),
      meta
    )

  set_values(
    presentation,
    "author",
    authors
  )

  local contributors =
    schema_people(
      contributor_source(meta),
      meta
    )

  local contribution_roles = {}

  for _, role in ipairs(
    schema_contribution_roles(
      author_source(meta),
      meta
    )
  ) do

    table.insert(
      contribution_roles,
      role
    )

  end

  for _, role in ipairs(
    schema_contribution_roles(
      contributor_source(meta),
      meta
    )
  ) do

    table.insert(
      contribution_roles,
      role
    )

  end

  for _, person in ipairs(
    contributors
  ) do

    table.insert(
      contribution_roles,
      person
    )

  end

  set_values(
    presentation,
    "contributor",
    contribution_roles
  )

  local publishers = {}

  local publisher_source =
    citation.publisher
    or meta.publisher

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

  set_values(
    presentation,
    "publisher",
    publishers
  )

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

  local version =
    text(
      citation.version
      or dalia.version
    )

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

  local accessible =
    boolean_value(
      oer.isAccessibleForFree
    )

  if accessible ~= nil then
    presentation.isAccessibleForFree =
      accessible
  end

  local status =
    schema_term(
      oer.creativeWorkStatus,
      lang
    )

  if status ~= nil then
    presentation.creativeWorkStatus =
      status
  end

  set_values(
    presentation,
    "about",
    schema_terms(
      oer.about,
      lang
    )
  )

  set_values(
    presentation,
    "learningResourceType",
    schema_terms(
      oer.learningResourceType,
      lang
    )
  )

  set_values(
    presentation,
    "educationalLevel",
    schema_terms(
      oer.educationalLevel,
      lang
    )
  )

  set_values(
    presentation,
    "teaches",
    schema_terms(
      oer.teaches,
      lang
    )
  )

  set_values(
    presentation,
    "assesses",
    schema_terms(
      oer.assesses,
      lang
    )
  )

  set_values(
    presentation,
    "competencyRequired",
    schema_terms(
      oer.competencyRequired,
      lang
    )
  )

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

  local accessibility =
    string_array(
      oer.accessibilityFeature
    )

  set_values(
    presentation,
    "accessibilityFeature",
    accessibility
  )

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
        audiences,
        audience
      )

    end

  end

  for _, audience in ipairs(
    build_dalia_audience(
      dalia.targetGroup,
      lang
    )
  ) do

    table.insert(
      audiences,
      audience
    )

  end

  set_values(
    presentation,
    "audience",
    audiences
  )

  local image =
    resolve_url(
      meta.image,
      canonical
    )

  if image ~= nil then
    presentation.image =
      image
  end

  set_values(
    presentation,
    "isBasedOn",
    schema_resource_array(
      oer.isBasedOn
    )
  )

  set_values(
    presentation,
    "isPartOf",
    schema_resource_array(
      oer.isPartOf
    )
  )

  set_values(
    presentation,
    "hasPart",
    schema_resource_array(
      oer.hasPart
    )
  )

  apply_related_works(
    presentation,
    dalia.relatedWorks
  )

  return
    presentation,
    presentation_id

end


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
      ["@type"] =
        "EventSeries",
      ["@id"] =
        series_id,
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
      ["@type"] =
        "Event",
      ["@id"] =
        event_id,
      name =
        event_title,
      workFeatured = {
        ["@id"] =
          presentation_id
      }
    }

    if event_date ~= nil then
      event.startDate =
        event_date
    end

    if event_place ~= nil then

      event.location = {
        ["@type"] =
          "Place",
        name =
          event_place
      }

    end

    if series_title ~= nil then
      event.superEvent = {
        ["@id"] =
          series_id
      }
    end

    table.insert(
      result,
      event
    )

  end

  if session_title ~= nil then

    local session = {
      ["@type"] =
        "Event",
      ["@id"] =
        session_id,
      name =
        session_title,
      workFeatured = {
        ["@id"] =
          presentation_id
      }
    }

    if event_date ~= nil then
      session.startDate =
        event_date
    end

    if event_place ~= nil then

      session.location = {
        ["@type"] =
          "Place",
        name =
          event_place
      }

    end

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

    table.insert(
      result,
      session
    )

  end

  return result

end


local function build_schema_metadata(meta)

  local presentation,
        presentation_id =
    build_schema_presentation(
      meta
    )

  local graph = {
    presentation
  }

  for _, event in ipairs(
    build_event_nodes(
      meta,
      presentation_id
    )
  ) do

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


-- ============================================================================
-- JSON-LD
-- ============================================================================


local function pretty_json(json)

  local result = {}
  local indent = 0
  local in_string = false
  local escaped = false

  local function newline()

    table.insert(
      result,
      "\n"
      .. string.rep(
        "  ",
        indent
      )
    )

  end

  for index = 1, #json do

    local char =
      json:sub(
        index,
        index
      )

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


-- ============================================================================
-- ZOTERO
-- ============================================================================


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


local function zotero_creator_name(
  person
)

  if
    person ~= nil
    and type(person) == "table"
    and type(person.name) == "table"
  then

    local given =
      text(
        person.name.given
      )

    local family =
      text(
        person.name.family
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
      person
    )

end


local function build_zotero_metadata(meta)

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

  -- Zotero Presentation:
  -- speaker -> Presenter
  -- alle übrigen Personen -> Contributor
  --
  -- CRediT-Rollen werden hierfür ausdrücklich nicht ausgewertet.

  for _, person in ipairs(
    as_array(
      author_source(meta)
    )
  ) do

    local name =
      zotero_creator_name(
        person
      )

    if has_function(
      person,
      "speaker"
    ) then

      add(
        "eprints:creators_name",
        name
      )

    else

      add(
        "eprints:contributors_name",
        name
      )

    end

  end

  for _, person in ipairs(
    as_array(
      contributor_source(meta)
    )
  ) do

    local name =
      zotero_creator_name(
        person
      )

    if has_function(
      person,
      "speaker"
    ) then

      add(
        "eprints:creators_name",
        name
      )

    else

      add(
        "eprints:contributors_name",
        name
      )

    end

  end

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


-- ============================================================================
-- HTML-HEADER
-- ============================================================================


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
