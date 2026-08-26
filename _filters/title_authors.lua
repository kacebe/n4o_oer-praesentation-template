-- title_authors.lua
--
-- Ermittelt die Personen, die auf der Titelfolie erscheinen.
--
-- Voraussetzung:
-- - Der eingebaute Quarto-Filter wurde bereits ausgeführt.
-- - Die normalisierten Autor:innendaten stehen unter by-author.
--
-- Auf der Titelfolie erscheinen Personen mit:
--
-- - writing
-- - Writing – original draft
-- - Writing – review & editing
--
-- Quarto normalisiert "writing" auf die CRediT-Rolle
-- "writing – original draft". Ausgewertet wird daher bevorzugt
-- das von Quarto erzeugte Feld "vocab-term".
--
-- Ergebnis:
-- n4o-title-authors
--
-- by-author selbst wird nicht verändert. Damit bleiben alle
-- Autor:innen für Zitation, Appendix und maschinenlesbare
-- Metadaten erhalten.


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


-- Text für Vergleiche normalisieren.

local function normalize(value)

  local result =
    text(value)

  if result == nil then
    return nil
  end

  return
    string.lower(result)
      :gsub("^%s+", "")
      :gsub("%s+$", "")

end


-- CRediT-Rollen, die zur Anzeige auf der Titelfolie führen.

local title_roles = {

  ["writing – original draft"] =
    true,

  ["writing – review & editing"] =
    true,

  -- Fallback, falls der Filter einmal ohne vorherige
  -- CRediT-Normalisierung verwendet wird.
  ["writing"] =
    true

}


-- Name für verständliche Fehlermeldungen ermitteln.

local function author_name(author)

  if
    author ~= nil
    and author.name ~= nil
    and author.name.literal ~= nil
  then

    return
      text(author.name.literal)

  end

  return nil

end


-- Prüfen, ob eine Person eine Writing-Rolle besitzt.

local function has_title_role(author)

  if
    author == nil
    or author.roles == nil
  then
    return false
  end


  for _, role in ipairs(author.roles) do

    local role_name =
      nil


    if type(role) == "table" then

      -- Bei CRediT-Rollen bevorzugt den von Quarto
      -- normalisierten Begriff verwenden.

      role_name =
        normalize(
          role["vocab-term"]
        )


      -- Fallback auf die ursprüngliche Rollenangabe.

      if role_name == nil then

        role_name =
          normalize(
            role.role
          )

      end

    else

      role_name =
        normalize(
          role
        )

    end


    if
      role_name ~= nil
      and title_roles[role_name]
    then
      return true
    end

  end


  return false

end


function Meta(meta)

  local authors =
    meta["by-author"]


  if
    authors == nil
    or #authors == 0
  then

    return meta

  end


  local title_authors =
    pandoc.MetaList{}


  for index, author in ipairs(authors) do

    -- roles ist im N4O-Template für jede Person erforderlich.

    if
      author.roles == nil
      or #author.roles == 0
    then

      local name =
        author_name(author)
        or ("Autor:in " .. index)


      error(
        "N4O-Metadaten: Für "
        .. name
        .. " fehlt die erforderliche Angabe 'roles'."
      )

    end


    if has_title_role(author) then

      title_authors:insert(
        author
      )

    end

  end


  -- Mindestens eine Person muss auf der Titelfolie erscheinen.

  if #title_authors == 0 then

    error(
      "N4O-Metadaten: Mindestens eine Person unter 'author' "
      .. "muss die Rolle 'writing', "
      .. "'Writing – original draft' oder "
      .. "'Writing – review & editing' besitzen."
    )

  end


  meta["n4o-title-authors"] =
    title_authors


  return meta

end