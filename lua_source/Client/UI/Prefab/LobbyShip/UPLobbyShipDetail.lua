-----------------------------------------------------
--File Name    : UPLobbyShipDetail.lua
--Author       : chenyixin
--Description  : 舰船界面详情UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipDetail = luaclass("UPLobbyShipDetail", PrefabBase)

local MaterialItemHelper = require("MaterialItemHelper")
local UIDef = require("UIDef")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemDataTable = require("BattleItemDataTable")

-- 材料类型
local MATEIRAL_TYPE = {
    ["WOOD"] = 1,
    ["CLOTH"] = 2,
    ["IRON"] = 3,
}

UPLobbyShipDetail.ListHelper = nil
UPLobbyShipDetail.tbMaterialItems = {}

UPLobbyShipDetail.ulShipDetailContent = nil

local function GetMaterialItemDisplayData(tbBuildData, nIndex)
    local tbDisplayData = {}
    local nTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nTemplateId)
    tbDisplayData.szBtnImg = tbItemResTemplate.szIconPath
    tbDisplayData.nCount = tbBuildData[nIndex]
    tbDisplayData.bEnableBtn = false
    return tbDisplayData
end

local function SetMaterialInfo(self, nBattleItemId)
    if not nBattleItemId then
        return 
    end
    local tbBuildData = nil
    local tbTemplate = BattleItemBuildDataTable:GetBuildTemplate(nBattleItemId)
    if tbTemplate then
        tbBuildData = tbTemplate.tbCosts
    else
        tbBuildData = {0,0,0,0}
    end

    for nIndex, tbMaterialItem in pairs(self.tbMaterialItems) do
        local tbDisplayData = GetMaterialItemDisplayData(tbBuildData, nIndex)
        tbMaterialItem:SetItemDisplayData(tbDisplayData)
    end
end

function UPLobbyShipDetail:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    local pWidgetRef = self.pWidgetRef

    self.ulShipDetailContent = self.UILogicHelper:CreateUILogic("ULLobbyShipDetailContent")

    for _, v in pairs(MATEIRAL_TYPE) do
        local tbMaterialItem = self.PrefabHelper:BindPrefab(pWidgetRef["UP_CommonItem" .. v], UIDef.UP_LOBBY_SHIP_COMMON_ITEM)
        self.tbMaterialItems[v] = tbMaterialItem
    end
end

function UPLobbyShipDetail:OnUnload()
end

function UPLobbyShipDetail:OnShow()
end

function UPLobbyShipDetail:OnBindEvent(EventHelper)
end

function UPLobbyShipDetail:SetShipTemplateId(nBattleItemId)
    self.ulShipDetailContent:SetShipTemplateId(nBattleItemId)
    SetMaterialInfo(self, nBattleItemId)
end

function UPLobbyShipDetail:CanShow()
    return self.ulShipDetailContent:CanShow()
end

function UPLobbyShipDetail:SetShowDetailedInfo(bShow)
    self.ulShipDetailContent:SetShowDetailedInfo(bShow)
end

function UPLobbyShipDetail:GetShowDetailedInfo()
    return self.ulShipDetailContent.bShowDetailedInfo
end

return UPLobbyShipDetail