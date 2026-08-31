local luaclass = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPPlayerStatsSurvival = luaclass("UPPlayerStatsSurvival", ListItemBase)

function UPPlayerStatsSurvival:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtTitle:SetText(tbData.szKey)
    pWidgetRef.txtValue:SetText(tbData.szValue)
end

return UPPlayerStatsSurvival