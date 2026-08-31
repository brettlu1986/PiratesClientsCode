-----------------------------------------------------
--File Name    : ULBuildShip.lua
--Author       : zhiyuan
--Create Time  : 2019-03-12
--Description  : 建造船的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuildShip = luaclass("ULBuildShip", UILogicBase)

local UIDef = require("UIDef")
local LuaDelegateClass = require("LuaDelegate")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipItemHelper = require("ShipItemHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

ULBuildShip.tbPbShipItems = nil
ULBuildShip.OnShipItemPressedDelegate = nil

local function SetItemSelected(self, nPos1, nPos2)
    for i, v1 in pairs(self.tbPbShipItems) do
        for j, v2 in pairs(v1) do
            if i == nPos1 and j == nPos2 then
                v2:SetSelected(true)
            else
                v2:SetSelected(false)
            end
        end
    end
end

local function SetAllItemUnSelected(self)
    for i, v1 in pairs(self.tbPbShipItems) do
        for j, v2 in pairs(v1) do
            v2:SetSelected(false)
        end
    end
end

local function AddPbBuildShip(self, pbBuildItemShip, nGrade, nIndex)
    local tbPbs = self.tbPbShipItems[nGrade]
    if tbPbs == nil then
        self.tbPbShipItems[nGrade] = {}
        tbPbs = self.tbPbShipItems[nGrade]
    end
    tbPbs[nIndex] = pbBuildItemShip
end

local function GetOrCreatePbBuildShip(self, nGrade, nIndex)
    local pWidgetRef =self.pWidgetRef
    local tbPbs = self.tbPbShipItems[nGrade]
    if tbPbs == nil then
        self.tbPbShipItems[nGrade] = {}
        tbPbs = self.tbPbShipItems[nGrade]
    end
    local tbPb = tbPbs[nIndex]
    if tbPb == nil then
        tbPb = self.PrefabHelper:CreatePrefab(UIDef.UP_BUILD_ITEM)
        pWidgetRef["wboxShip"..nGrade]:AddChild(tbPb.pWidgetRef)
        tbPb:SetOnItemPressedDelegate(self.OnShipItemPressedDelegate, nGrade, nIndex)
        tbPb:Collaped()
        AddPbBuildShip(self, tbPb, nGrade, nIndex)
    end
    return tbPb
end

local function OnShipItemSelected(self, pbBuildItem)
    if pbBuildItem:IsSetSelected() then
        self.Owner:CloseTips()
        pbBuildItem:SetSelected(false)
    else
        self.Owner:ShowBuildShipTips(pbBuildItem:GetTemplateId())
        SetItemSelected(self, pbBuildItem:GetPos1(), pbBuildItem:GetPos2())
    end
end

local function RefreshShips(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCurrentShipTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP, true)
    if tbBuildDatas == nil then
        return
    end
    local tbItemCount = {[1] = 0,[2] = 0,[3] = 0}
    for _, v in pairs(tbBuildDatas) do
        local tbTemplate = v.tbBattleItemTemplate
        local nGrade = tbTemplate.nGrade
        local nIndex = tbItemCount[nGrade] + 1
        local pbBuildItemShip = GetOrCreatePbBuildShip(self, nGrade, nIndex)
        tbItemCount[nGrade] = nIndex
        local bIsCurrent = false
        local nItemTemplateId = tbTemplate.nId
        if nItemTemplateId == nCurrentShipTemplateId then
            bIsCurrent = true
        end
        pbBuildItemShip:Refresh(tbTemplate, bIsCurrent)
    end
end

function ULBuildShip:OnLoad()
    self.OnShipItemPressedDelegate = LuaDelegateClass()
    self.tbPbShipItems = {}
end

function ULBuildShip:OnUnload()
end

function ULBuildShip:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnShipItemPressedDelegate, OnShipItemSelected, self)
end

function ULBuildShip:Refresh()
    self.Owner:CloseTips()
    RefreshShips(self)
    SetAllItemUnSelected(self)
end

return ULBuildShip