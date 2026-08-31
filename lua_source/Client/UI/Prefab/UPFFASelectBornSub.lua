local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFASelectBornSub = luaclass("UPFFASelectBornSub", PrefabBase)
local UISetUtils = require("UISetUtils")

UPFFASelectBornSub.szName = nil

function UPFFASelectBornSub:OnLoad()
end

function UPFFASelectBornSub:OnShow()

end 

function UPFFASelectBornSub:SetPlayerInfo(szName, pSlateColor)
    self.szName = szName
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtPlayName:SetText(szName)
    UISetUtils.SetImageBrushTint(pWidgetRef.imgPoint, pSlateColor)
end

return UPFFASelectBornSub