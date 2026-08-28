-- title_brand.lua
--
-- Bereitet visuelle Ressourcen für die Reveal.js-Titelfolie auf:
-- - Logos aus _brand.yml
-- - lokales Creative-Commons-Lizenz-Badge
--
-- Die Darstellung und Positionierung erfolgen in title-slide.html und SCSS.

local brand =
  require("modules/brand/brand")

local filter_dir =
  pandoc.path.directory(PANDOC_SCRIPT_FILE)

package.path =
  pandoc.path.join({filter_dir, "modules", "?.lua"})
  .. ";"
  .. package.path

local utils =
  require("n4o.utils")

local license =
  require("n4o.license")


-- Ein Brand-Logo als Metadaten für title-slide.html bereitstellen.
local function add_logo(
  meta,
  brand_name,
  meta_name
)

  local logo =
    brand.get_logo(
      "light",
      brand_name
    )

  if logo == nil then
    return
  end

  local path =
    utils.text(
      logo.path
    )

  local alt =
    utils.text(
      logo.alt
    )

  if path ~= nil then

    meta[meta_name .. "-path"] =
      pandoc.MetaString(path)

  end

  if alt ~= nil then

    meta[meta_name .. "-alt"] =
      pandoc.MetaString(alt)

  end

end


-- Creative-Commons-Badge anhand der Lizenzmetadaten bestimmen.
--
-- Die Zuordnung wird zentral in modules/n4o/license.lua gepflegt und
-- bleibt dadurch zwischen Titel-, Appendix- und HTML-Metadaten konsistent.
local function add_license_badge(meta)

  local badge =
    license.badge(
      meta.license
    )

  if badge == nil then
    return
  end

  meta["title-license-badge-path"] =
    pandoc.MetaString(
      badge.path
    )

  meta["title-license-badge-alt"] =
    pandoc.MetaString(
      badge.alt
    )

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
