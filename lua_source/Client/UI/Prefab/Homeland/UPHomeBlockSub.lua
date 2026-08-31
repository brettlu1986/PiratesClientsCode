-----------------------------------------------------
--File Name    : UPHomeBlockSub.lua
--Author       : zhiyuan
--Create Time  : 2019-04-23
--Description  : 地块在主界面的交互UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomeBlockSub = luaclass("UPHomeBlockSub", PrefabBase)

local HomelandSystem = require("HomelandSystem")
local HomelandModeDef = require("HomelandModeDef")
local UISetUtils = require("UISetUtils")
local BlockTypeDataTable = require("BlockTypeDataTable")
local UITextDef = require("UITextDef")
local ItemSystem = require("ItemSystem")
local BuildingDataTable = require("BuildingDataTable")
local ClientEventDef = require("ClientEventDef")

UPHomeBlockSub.tbBlockData = nil
UPHomeBlockSub.fnCommit = nil

local function SetBlockName(self, szName)
    self.pWidgetRef.ktxtName:SetText(szName)
end

local function SetBlockImage(self, szImagePath)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBlock, szImagePath:load())
end

local function SetCommitBtn(self, szDesc, Func)
    local pWidgetRef = self.pWidgetRef
    local ktxtCommit = pWidgetRef.ktxtCommit

    ktxtCommit:SetText(szDesc)
    self.fnCommit = Func
end

local function SetBlockInfo(self, nBlockType)
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    SetBlockName(self, tbBlockTypeTemplate.l10nName)
    SetBlockImage(self, tbBlockTypeTemplate.szIcon)
end

local function ShowBuyDetail(self, tbBlockData)
    local nBlockType = tbBlockData.nBlockType
    SetBlockInfo(self, nBlockType)

    local FuncBuyBlock = function()
        HomelandSystem:RequestBuyBlock(tbBlockData.nBlockId)
    end

    SetCommitBtn(self, UITextDef.UI_HOMELAND_BUY_BLOCK, FuncBuyBlock)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end


local function ShowRemoveBuildingDetail(self, tbBlockData)
    local Item = ItemSystem:GetItem(tbBlockData.nItemInstanceId)
    if not Item then
        error("Cannot find item! nBlockId:"..tbBlockData.nBlockId..", nItemInstanceId:"..tbBlockData.nItemInstanceId)
    end
    local tbItemTemplate = Item:GetTemplate()
    SetBlockName(self, tbItemTemplate.l10nName)

    local tbBuildingTemplate = BuildingDataTable:GetTemplate(tbBlockData.nBuildingId)
    SetBlockImage(self, tbBuildingTemplate.szIcon)
    local FuncRemoveBuilding = function()
        self.ulRemoveBuilding:Do(tbBlockData)
    end

    SetCommitBtn(self, UITextDef.UI_HOMELAND_REMOVE_BUILDING, FuncRemoveBuilding)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

local function ShowPlaceBuildingDetail(self, tbBlockData)
    local nBlockType = tbBlockData.nBlockType
    SetBlockInfo(self, nBlockType)

    local FuncBuild = function()
        self.ulPlaceBuilding:Do(tbBlockData)
    end

    SetCommitBtn(self, UITextDef.UI_HOMELAND_PLACE_BUILDING, FuncBuild)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end


local function Refresh(self)
    if self.tbBlockData == nil then
        return
    end
    self:ShowDetail(self.tbBlockData)
end

local function OnLandmarkUpgradeBegin(self)
    Refresh(self)
end

local function OnLandmarkUpgradeComplete(self)
    Refresh(self)
end

local function OnBuyBlock(self)
    Refresh(self)
end

local function OnPlaceItemBuilding(self)
    Refresh(self)
end

local function OnRemoveItemBuilding(self)
    Refresh(self)
end

local function OnCommitBtnClicked(self)
    self.fnCommit()
end

function UPHomeBlockSub:ShowDetail(tbBlockData)
    self.tbBlockData = tbBlockData
    local nMode = HomelandSystem:GetCurrentMode()
    if nMode ~= HomelandModeDef.BUILD then
        logerror("mode is not build!", nMode, tbBlockData.nBlockId)
        return
    end
    if not tbBlockData.bUnlock then
        logerror("block not unlock!", tbBlockData.nBlockId)
        return
    end

    if not tbBlockData.bBought then
        ShowBuyDetail(self, tbBlockData)
    else
        if tbBlockData.nItemInstanceId then
            ShowRemoveBuildingDetail(self, tbBlockData)
        else
            ShowPlaceBuildingDetail(self, tbBlockData)
        end
    end
end

function UPHomeBlockSub:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.tbBlockData = nil
    self.fnCommit = nil
end


----------life cycle----------

function UPHomeBlockSub:OnLoad()
    self.ulRemoveBuilding = self.UILogicHelper:CreateUILogic("ULHomelandBlockRemoveBuilding")
    self.ulPlaceBuilding = self.UILogicHelper:CreateUILogic("ULHomelandBlockPlaceBuilding")
end

function UPHomeBlockSub:OnShow()
end

function UPHomeBlockSub:OnHide()
end

function UPHomeBlockSub:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_BEGIN, self, OnLandmarkUpgradeBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_COMPLETE, self, OnLandmarkUpgradeComplete)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_BUY_BLOCK, self, OnBuyBlock)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLACE_ITEM_BUILDING, self, OnPlaceItemBuilding)
    EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_ITEM_BUILDING, self, OnRemoveItemBuilding)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmbtnCommit.OnClicked, self, OnCommitBtnClicked)
end

return UPHomeBlockSub