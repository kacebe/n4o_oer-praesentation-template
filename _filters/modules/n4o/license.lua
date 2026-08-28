-- modules/n4o/license.lua
--
-- Gemeinsame Auflösung der vom Template unterstützten
-- Creative-Commons-Lizenzen.

local utils =
  require("n4o.utils")

local M = {}


local definitions = {

  ["https://creativecommons.org/licenses/by/4.0/"] = {
    path = "assets/logos/licenses/cc-by.svg",
    alt = "Creative Commons Namensnennung 4.0 International"
  },

  ["https://creativecommons.org/licenses/by-sa/4.0/"] = {
    path = "assets/logos/licenses/cc-by-sa.svg",
    alt = "Creative Commons Namensnennung – Weitergabe unter gleichen Bedingungen 4.0 International"
  },

  ["https://creativecommons.org/publicdomain/zero/1.0/"] = {
    path = "assets/logos/licenses/cc0.svg",
    alt = "Creative Commons CC0 1.0 Universell"
  }

}


local aliases = {

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


-- Bekannte Creative-Commons-URLs auf die kanonische HTTPS-Form bringen.
-- Unbekannte URLs bleiben unverändert.
local function canonicalize_known_url(value)

  local url =
    utils.text(value)

  if url == nil then
    return nil
  end

  url =
    utils.normalize_space(url)

  local comparable =
    url
      :gsub("[#?].*$", "")
      :gsub("^http://creativecommons%.org/", "https://creativecommons.org/")
      :gsub("/+$", "")
      .. "/"

  if definitions[comparable] ~= nil then
    return comparable
  end

  return url

end


-- Lizenz-URL aus Quarto-Metadaten oder Kurzbezeichnung auflösen.
function M.url(value)

  if value == nil then
    return nil
  end

  if
    type(value) == "table"
    and value.url ~= nil
  then
    return
      canonicalize_known_url(
        value.url
      )
  end

  local raw =
    utils.text(value)

  if raw == nil then
    return nil
  end

  if utils.is_url(raw) then
    return
      canonicalize_known_url(raw)
  end

  local key =
    string.upper(
      utils.normalize_space(raw)
    )

  return aliases[key]

end


-- Badge-Daten nur für explizit unterstützte CC-Lizenzen liefern.
function M.badge(value)

  local url =
    M.url(value)

  if url == nil then
    return nil
  end

  local definition =
    definitions[url]

  if definition == nil then
    return nil
  end

  return {
    url = url,
    path = definition.path,
    alt = definition.alt
  }

end


return M
