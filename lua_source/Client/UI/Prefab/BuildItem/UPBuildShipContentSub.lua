local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPBuildShipContentSub = luaclass("UPBuildShipContentSub", ListItemBase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

function UPBuildShipContentSub:OnLoad()
end

function UPBuildShipContentSub:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbData.szName)
    pWidgetRef.txtValue:SetText(tbData.szValue)

    local _,num = math.modf(self.nIndex / 2)
    if num == 0 then
        UISetUtils.SetImageBrushTint(pWidgetRef.imgBg, UIResourceDef.COLOR.GREY.SLATE_COLOR)
    else
        UISetUtils.SetImageBrushTint(pWidgetRef.imgBg, UIResourceDef.COLOR.GREY.SLATE_COLOR)
    end
end

return UPBuildShipContentSub

