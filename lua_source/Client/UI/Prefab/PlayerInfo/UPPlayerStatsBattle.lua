local luaclass = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPPlayerStatsBattle = luaclass("UPPlayerStatsBattle", ListItemBase)

function UPPlayerStatsBattle:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtTitle:SetText(tbData.szKey)
    pWidgetRef.txtValue:SetText(tbData.szValue)
end

return UPPlayerStatsBattle