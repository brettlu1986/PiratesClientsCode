local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerStatsBase = luaclass("UPPlayerStatsBase", PrefabBase)

function UPPlayerStatsBase:RefreshTitle(szTitle)
    self.pWidgetRef.txtTitle:SetText(szTitle)
end

function UPPlayerStatsBase:RefreshValue(szValue)
    self.pWidgetRef.txtValue:SetText(szValue)
end

return UPPlayerStatsBase