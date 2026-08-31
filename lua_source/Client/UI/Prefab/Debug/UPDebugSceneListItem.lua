-----------------------------------------------------
--File Name    : UPDebugSceneListItem.lua
--Author       : Song Fuhao
--Create Time  : 2018-04-19
--Description  : Debug场景面板列表Item
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPDebugSceneListItem = luaclass("UPDebugSceneListItem", ListItemBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GMSystem = dynamic_require("GMSystem")

local tbTypeNames = {
    "港口",
    "单机副本",
    "联网副本",
    "港口外",
}

local function OnClickedBtnGo(self)
    if self.tbData.nType == 1 then
        GMSystem:Exec(string.format("gm me:SwitchScene(%d, 0)", self.tbData.nId))
    elseif self.tbData.nType == 2 then
        GMSystem:Exec(string.format("gm me:EnterLocalDungeon(%d)", self.tbData.nId))
    elseif self.tbData.nType == 3 then
        GMSystem:Exec(string.format("gm me:EnterDungeon(%d)", self.tbData.nId))
    elseif self.tbData.nType == 4 then
        GMSystem:Exec(string.format("gm me:SwitchScene(1, %d)", self.tbData.nId))
    end
    UIManager:CloseWnd(UIDef.UI_DEBUG_WIDGET)
end

function UPDebugSceneListItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo.OnClicked, self, OnClickedBtnGo)
end

function UPDebugSceneListItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    if self.nIndex % 2 == 0 then
        pWidgetRef.imgBG:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.imgBG:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
    if tbData then
        pWidgetRef.txtName:SetText(tbData.szName)
        pWidgetRef.txtType:SetText(tbTypeNames[tbData.nType])
        pWidgetRef.txtSceneId:SetText(tbData.nId)
    end
end

return UPDebugSceneListItem
