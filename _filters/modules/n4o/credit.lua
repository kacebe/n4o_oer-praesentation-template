-- modules/n4o/credit.lua
--
-- Zentrale CRediT-Definitionen für die N4O-Lua-Filter.
--
-- Das Modul ist die einzige Stelle, an der unterstützte Rollen,
-- Quarto-Aliase und kanonische CRediT-URLs gepflegt werden.

local utils =
  require("n4o.utils")

local M = {}


local roles = {

  ["conceptualization"] = {
    label = "Conceptualization",
    url = "https://credit.niso.org/contributor-roles/conceptualization/"
  },

  ["data curation"] = {
    label = "Data curation",
    url = "https://credit.niso.org/contributor-roles/data-curation/"
  },

  ["formal analysis"] = {
    label = "Formal analysis",
    url = "https://credit.niso.org/contributor-roles/formal-analysis/"
  },

  ["funding acquisition"] = {
    label = "Funding acquisition",
    url = "https://credit.niso.org/contributor-roles/funding-acquisition/"
  },

  ["investigation"] = {
    label = "Investigation",
    url = "https://credit.niso.org/contributor-roles/investigation/"
  },

  ["methodology"] = {
    label = "Methodology",
    url = "https://credit.niso.org/contributor-roles/methodology/"
  },

  ["project administration"] = {
    label = "Project administration",
    url = "https://credit.niso.org/contributor-roles/project-administration/"
  },

  ["resources"] = {
    label = "Resources",
    url = "https://credit.niso.org/contributor-roles/resources/"
  },

  ["software"] = {
    label = "Software",
    url = "https://credit.niso.org/contributor-roles/software/"
  },

  ["supervision"] = {
    label = "Supervision",
    url = "https://credit.niso.org/contributor-roles/supervision/"
  },

  ["validation"] = {
    label = "Validation",
    url = "https://credit.niso.org/contributor-roles/validation/"
  },

  ["visualization"] = {
    label = "Visualization",
    url = "https://credit.niso.org/contributor-roles/visualization/"
  },

  ["writing – original draft"] = {
    label = "Writing – original draft",
    url = "https://credit.niso.org/contributor-roles/writing-original-draft/"
  },

  ["writing – review & editing"] = {
    label = "Writing – review & editing",
    url = "https://credit.niso.org/contributor-roles/writing-review-editing/"
  }

}


local aliases = {

  ["analysis"] =
    "formal analysis",

  ["funding"] =
    "funding acquisition",

  ["writing"] =
    "writing – original draft",

  ["editing"] =
    "writing – review & editing"

}


local title_roles = {

  ["writing – original draft"] =
    true,

  ["writing – review & editing"] =
    true

}


-- Rohbezeichnung einer Rolle normalisieren.
function M.raw_name(role)

  if role == nil then
    return nil
  end

  if type(role) == "table" then

    local vocab_term =
      utils.normalize_key(
        role["vocab-term"]
      )

    if vocab_term ~= nil then
      return vocab_term
    end

    local role_value =
      utils.normalize_key(
        role.role
      )

    if role_value ~= nil then
      return role_value
    end

  end

  return
    utils.normalize_key(role)

end


-- Kanonische CRediT-Rollenbezeichnung zurückgeben.
function M.canonical_name(role)

  local name =
    M.raw_name(role)

  if name == nil then
    return nil
  end

  name =
    aliases[name]
    or name

  if roles[name] == nil then
    return nil
  end

  return name

end


-- Prüfen, ob eine Rolle für die Titelfolie qualifiziert.
function M.is_title_role(role)

  local name =
    M.canonical_name(role)

  return
    name ~= nil
    and title_roles[name] == true

end


-- Kanonische Metadaten einer gültigen CRediT-Rolle liefern.
--
-- Falls Quarto einen vocab-term-identifier mitliefert, hat dieser Vorrang
-- vor der im Modul hinterlegten Standard-URL.
function M.info(role)

  local name =
    M.canonical_name(role)

  if name == nil then
    return nil
  end

  local definition =
    roles[name]

  local identifier =
    nil

  if type(role) == "table" then

    identifier =
      utils.text(
        role["vocab-term-identifier"]
        or role["vocab-term-indentifier"]
      )

  end

  return {
    name = name,
    label = definition.label,
    url = identifier or definition.url
  }

end


return M
