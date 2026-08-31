-----------------------------------------------------
--File Name    : UPDebugHumanWeaponListItem.lua
--Author       : WuJizhou
--Create Time  : 2018-12-26
--Description  : Debug人武器面板中武器属性格子
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPDebugHumanWeaponListItem = luaclass("UPDebugHumanWeaponListItem", ListItemBase)

local L10N = require("L10N")

local function OnTextChanged(self, l10nText)
    local szValue = L10N:ToString(l10nText)
    local nValue = tonumber(szValue)
    if nValue then
        self.tbData.nValue = nValue
    end
end


function UPDebugHumanWeaponListItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtValue.OnTextChanged, self, OnTextChanged)
end

-- tbData: {szProperty : "", szName : "", nValue : ""}
function UPDebugHumanWeaponListItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    local szName = tbData.szName
    local nValue = tbData.nValue
    pWidgetRef.txtName:SetText(szName)
    pWidgetRef.txtValue:SetText(nValue)
end

return UPDebugHumanWeaponListItem
