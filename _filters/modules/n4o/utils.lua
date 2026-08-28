-- modules/n4o/utils.lua
--
-- Gemeinsame Hilfsfunktionen für die N4O-Lua-Filter.
--
-- Das Modul bündelt ausschließlich generische Konvertierungs- und
-- Normalisierungsfunktionen. Fachliche Mappings (z. B. CRediT oder
-- Lizenzzuordnungen) liegen in eigenen Modulen.

local M = {}


-- Pandoc-Metadaten robust als getrimmten Text lesen.
function M.text(value)

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


-- Beliebigen Text auf einfache Leerzeichen normalisieren.
function M.normalize_space(value)

  if value == nil then
    return nil
  end

  return tostring(value)
    :gsub("%s+", " ")
    :gsub("^%s+", "")
    :gsub("%s+$", "")

end


-- Metadatenwert als normalisierten Vergleichsschlüssel lesen.
function M.normalize_key(value)

  local value_text =
    M.text(value)

  if value_text == nil then
    return nil
  end

  return
    string.lower(
      M.normalize_space(value_text)
    )

end


-- Text für HTML-Attribute escapen.
function M.html_escape(value)

  if value == nil then
    return nil
  end

  return tostring(value)
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")

end


-- HTTP(S)-URL erkennen.
function M.is_url(value)

  if value == nil then
    return false
  end

  return
    tostring(value):match("^https?://") ~= nil

end


-- Einzelwert oder Metadatenliste einheitlich als Lua-Liste bereitstellen.
function M.as_array(value)

  if value == nil then
    return {}
  end

  if type(value) ~= "table" then
    return { value }
  end

  local value_type =
    pandoc.utils.type(value)

  if
    value_type == "Inlines"
    or value_type == "Blocks"
    or value_type == "MetaInlines"
    or value_type == "MetaBlocks"
  then
    return { value }
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

  return { value }

end


-- Einzelwert oder Liste in eine Liste nicht-leerer Texte überführen.
function M.string_array(value)

  local result = {}

  for _, item in ipairs(
    M.as_array(value)
  ) do

    local item_text =
      M.text(item)

    if item_text ~= nil then
      table.insert(
        result,
        item_text
      )
    end

  end

  return result

end


-- Boolesche Pandoc-/YAML-Werte robust lesen.
function M.boolean_value(value)

  if value == nil then
    return nil
  end

  if type(value) == "boolean" then
    return value
  end

  local value_text =
    M.normalize_key(value)

  if value_text == "true" then
    return true
  end

  if value_text == "false" then
    return false
  end

  return nil

end


-- Vollständigen Personennamen aus Quartos normalisierten Daten lesen.
--
-- Unterstützt sowohl name.literal / name.given / name.family als auch
-- einfache name-Werte. Für nicht-tabellarische Personenwerte wird der
-- Wert selbst als Text verwendet.
function M.author_name(person)

  if person == nil then
    return nil
  end

  if type(person) ~= "table" then
    return M.text(person)
  end

  if type(person.name) == "table" then

    local name_type =
      pandoc.utils.type(person.name)

    if
      name_type == "Inlines"
      or name_type == "MetaInlines"
      or name_type == "Blocks"
      or name_type == "MetaBlocks"
    then
      return M.text(person.name)
    end

    local literal =
      M.text(
        person.name.literal
      )

    if literal ~= nil then
      return literal
    end

    local given =
      M.text(
        person.name.given
      )

    local family =
      M.text(
        person.name.family
      )

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

  return
    M.text(
      person.name
    )

end


return M
