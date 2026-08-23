-- title_brand.lua
--
-- Bereitet visuelle Ressourcen für die Reveal.js-Titelfolie auf:
-- - Logos aus _brand.yml
-- - lokales Creative-Commons-Lizenz-Badge
--
-- Die Darstellung und Positionierung erfolgen in title-slide.html und SCSS.

local brand = require("modules/brand/brand")


-- Pandoc-Metadaten als Text lesen.
local function text(value)

  if value == nil then
    return nil
  end

  return pandoc.utils.stringify(value)

end


-- Ein Brand-Logo als Metadaten für title-slide.html bereitstellen.
local function add_logo(meta, brand_name, meta_name)

  local logo = brand.get_logo("light", brand_name)

  if logo == nil then
    return
  end

  if logo.path ~= nil then

    meta[meta_name .. "-path"] =
      pandoc.MetaString(
        pandoc.utils.stringify(logo.path)
      )

  end

  if logo.alt ~= nil then

    meta[meta_name .. "-alt"] =
      pandoc.MetaString(
        pandoc.utils.stringify(logo.alt)
      )

  end

end


-- Creative-Commons-Badge anhand der kanonischen Lizenz-URL bestimmen.
-- Dadurch bleibt die Zuordnung unabhängig von frei formuliertem license.text.
local function add_license_badge(meta)

  if meta.license == nil or meta.license.url == nil then
    return
  end

  local license_url = text(meta.license.url)

  if license_url == nil then
    return
  end

  local badges = {

    ["https://creativecommons.org/licenses/by/4.0/"] = {
      path = "assets/logos/licenses/cc-by.svg",
      alt  = "Creative Commons Namensnennung 4.0 International"
    },

    ["https://creativecommons.org/licenses/by-sa/4.0/"] = {
      path = "assets/logos/licenses/cc-by-sa.svg",
      alt  = "Creative Commons Namensnennung – Weitergabe unter gleichen Bedingungen 4.0 International"
    },

    ["https://creativecommons.org/publicdomain/zero/1.0/"] = {
      path = "assets/logos/licenses/cc0.svg",
      alt  = "Creative Commons CC0 1.0 Universell"
    }

  }

  local badge = badges[license_url]

  if badge == nil then
    return
  end

  meta["title-license-badge-path"] =
    pandoc.MetaString(badge.path)

  meta["title-license-badge-alt"] =
    pandoc.MetaString(badge.alt)

end


function Meta(meta)

  -- logo.large aus _brand.yml wird als primäres Projektlogo verwendet.
  add_logo(
    meta,
    "large",
    "title-brand-logo"
  )

  add_logo(
    meta,
    "institution-logo",
    "title-institution-logo"
  )

  add_logo(
    meta,
    "event-logo",
    "title-event-logo"
  )

  add_logo(
    meta,
    "partner-1",
    "title-partner-1-logo"
  )

  add_logo(
    meta,
    "partner-2",
    "title-partner-2-logo"
  )

  add_license_badge(meta)

  return meta

end
