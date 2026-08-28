-- title_authors.lua
--
-- Validiert die CRediT-Rollen der in Quarto unter author
-- eingetragenen Personen und erzeugt die für N4O maßgeblichen
-- Autor:innenlisten.
--
-- Voraussetzung:
-- - Der eingebaute Quarto-Filter wurde bereits ausgeführt.
-- - Die normalisierten Autor:innendaten stehen unter by-author.
--
-- N4O-Regeln:
--
-- 1. Eine Person wird nur dann in N4O-Ausgaben berücksichtigt,
--    wenn mindestens eine gültige CRediT-Rolle angegeben ist.
--
-- 2. Personen ohne roles bleiben ausschließlich in den
--    Quellmetadaten (_autor_innen.yml) erhalten. Sie erscheinen
--    weder auf Folien noch in Zitationen oder HTML-Metadaten.
--
-- 3. roles wird ausschließlich für Beiträge nach CRediT verwendet.
--
-- 4. Die konkrete CRediT-Rolle bestimmt nicht den bibliografischen
--    Autor:innenstatus. Jede Person in n4o-authors bleibt Autor:in.
--
-- 5. Auf der Titelfolie erscheinen ausschließlich gültige
--    Autor:innen mit:
--
--    - Writing – original draft
--    - Writing – review & editing
--
-- Ergebnisse:
--
-- n4o-authors
--     Alle gültigen N4O-Autor:innen.
--
-- n4o-title-authors
--     Teilmenge von n4o-authors für die Titelfolie.
--
-- author-meta
--     Wird aus n4o-authors neu aufgebaut. Dadurch verwendet auch
--     Quartos native HTML-Ausgabe <meta name="author"> nur gültige
--     N4O-Autor:innen.
--
-- by-author selbst bleibt als von Quarto normalisierte Rohquelle
-- unverändert.


-- ============================================================================
-- GEMEINSAME MODULE
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


-- Für Fehlermeldungen wird bei fehlenden Namensdaten ein expliziter
-- Platzhalter verwendet. Die gemeinsame Namensauflösung selbst liefert nil.
local function author_name(author)

  return
    utils.author_name(author)
    or "unbekannte Person"

end


-- ============================================================================
-- VALIDIERUNG
-- ============================================================================


-- Meldet einen Metadatenfehler.
--
-- Die nachgelagerte Filterlogik darf sich nicht darauf verlassen,
-- dass error() die emulierte Quarto-Filterkette sofort beendet.
-- Deshalb geben die Validierungsfunktionen zusätzlich false zurück.

local function metadata_error(message)

  error(
    "N4O-Metadaten: "
    .. message
  )

end


local function validate_roles_present(author)

  if
    author == nil
    or author.roles == nil
    or #author.roles == 0
  then

    metadata_error(
      "Für "
      .. author_name(author)
      .. " fehlt die erforderliche Angabe 'roles'. "
      .. "Die Person wird nicht in Folien, Zitationen oder "
      .. "HTML-Metadaten berücksichtigt."
    )

    return false

  end


  return true

end


local function validate_credit_roles(author)

  if
    author == nil
    or author.roles == nil
    or #author.roles == 0
  then
    return false
  end


  for _, role in ipairs(author.roles) do

    local canonical =
      credit.canonical_name(role)


    if canonical == nil then

      local supplied =
        credit.raw_name(role)
        or "unbekannte Rolle"


      metadata_error(
        "Die Rolle '"
        .. supplied
        .. "' bei "
        .. author_name(author)
        .. " ist keine unterstützte CRediT-Rolle. "
        .. "Die Person wird nicht in Folien, Zitationen oder "
        .. "HTML-Metadaten berücksichtigt."
      )

      return false

    end

  end


  return true

end


local function has_title_role(author)

  if
    author == nil
    or author.roles == nil
    or #author.roles == 0
  then
    return false
  end


  for _, role in ipairs(author.roles) do

    if credit.is_title_role(role) then
      return true
    end

  end


  return false

end


-- ============================================================================
-- NATIVE QUARTO-AUTOR:INNENMETADATEN
-- ============================================================================


local function make_author_meta(authors)

  local result =
    pandoc.MetaList{}


  for _, author in ipairs(authors) do

    local name =
      author_name(author)


    if
      name ~= nil
      and name ~= "unbekannte Person"
    then

      result:insert(
        pandoc.MetaString(name)
      )

    end

  end


  return result

end


-- ============================================================================
-- METADATENFILTER
-- ============================================================================


function Meta(meta)

  local authors =
    meta["by-author"]


  local valid_authors =
    pandoc.MetaList{}

  local title_authors =
    pandoc.MetaList{}


  -- Fehlt by-author vollständig, werden bewusst leere
  -- N4O-Autor:innenlisten bereitgestellt.

  if
    authors == nil
    or #authors == 0
  then

    meta["n4o-authors"] =
      valid_authors

    meta["n4o-title-authors"] =
      title_authors

    meta["author-meta"] =
      make_author_meta(
        valid_authors
      )


    metadata_error(
      "Es ist keine Autor:in mit gültiger CRediT-Rolle definiert."
    )


    return meta

  end


  -- --------------------------------------------------------------------------
  -- 1. Autor:innen validieren und zentrale N4O-Liste erzeugen
  -- --------------------------------------------------------------------------

  for _, author in ipairs(authors) do

    local valid =
      validate_roles_present(
        author
      )


    if valid then

      valid =
        validate_credit_roles(
          author
        )

    end


    if valid then

      valid_authors:insert(
        author
      )


      if has_title_role(author) then

        title_authors:insert(
          author
        )

      end

    end

  end


  -- --------------------------------------------------------------------------
  -- 2. Zentrale Listen immer setzen
  -- --------------------------------------------------------------------------

  meta["n4o-authors"] =
    valid_authors

  meta["n4o-title-authors"] =
    title_authors


  -- Quartos native HTML-Autor:innenmetadaten ebenfalls auf
  -- die gültigen N4O-Autor:innen beschränken.

  meta["author-meta"] =
    make_author_meta(
      valid_authors
    )


  -- --------------------------------------------------------------------------
  -- 3. Mindestanforderungen prüfen
  -- --------------------------------------------------------------------------

  if #valid_authors == 0 then

    metadata_error(
      "Es ist keine Autor:in mit gültiger CRediT-Rolle definiert."
    )

  end


  if #title_authors == 0 then

    metadata_error(
      "Für die Titelfolie ist keine gültige Autor:in mit "
      .. "der CRediT-Rolle 'Writing – original draft' oder "
      .. "'Writing – review & editing' definiert."
    )

  end


  return meta

end
