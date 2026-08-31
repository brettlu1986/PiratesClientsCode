-----------------------------------------------------
--File Name    : UPWorldMapSymbol.lua
--Description  : Prefab UPWorldMapSymbol
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPWorldMapSymbol = luaclass("UPWorldMapSymbol", ListItemBase)

local UISetUtils = require("UISetUtils")



--[[
    public function
]]


function UPWorldMapSymbol:SetData(tbData, bShow)
    if not tbData then
        logerror("UPWorldMapSymbol:SetData,tbData is nil")
        return
    end
    local pWidgetRef = self.pWidgetRef
    self:SetDataVisible(bShow)
    if tbData.szIconResPath and tbData.szIconResPath ~= "" then
        local pIcon = tbData.szIconResPath:load()
        if pIcon then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgSymbol, pIcon)
        else
            logerror("UPWorldMapSymbol:SetData,pIcon is nil, nCategoryId=",tbData.nId)
        end
    end
    pWidgetRef.txtName:SetText(tbData.l10nDisplayName)
end

function UPWorldMapSymbol:SetDataVisible(bVisible)
    local pVisibility = bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed
    self.pWidgetRef:SetVisibility(pVisibility)
end

return UPWorldMapSymbol
