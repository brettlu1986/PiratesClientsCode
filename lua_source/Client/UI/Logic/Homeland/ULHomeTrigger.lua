-----------------------------------------------------
--File Name    : ULHomeTrigger.lua
--Author       : zhiyuan
--Create Time  : 2019-04-23
--Description  : 家园主界面trigger的逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHomeTrigger = luaclass("ULHomeTrigger", UILogicBase)
local ClientEventDef = require("ClientEventDef")
local HomelandSystem = require("HomelandSystem")
local BlockTypeDataTable = require("BlockTypeDataTable")

ULHomeTrigger.pbHomeBuildingSub = nil
ULHomeTrigger.pbHomeBlockSub = nil

local function EnterMarkland(self, tbBlockData)
    self.Owner:SetModeButtonVisible(false)
    self.pbHomeBuildingSub:ShowLandmarkDetail(tbBlockData)
end

local function EnterDork(self, tbBlockData)
    self.Owner:SetModeButtonVisible(false)
    self.pbHomeBuildingSub:ShowDockDetail(tbBlockData)
end

local function LeaveMarkland(self)
    self.Owner:SetModeButtonVisible(true)
    self.pbHomeBuildingSub:Collapsed()
end

local function EnterNormalBlock(self, tbBlockData)
    self.Owner:SetModeButtonVisible(false)
    self.pbHomeBlockSub:ShowDetail(tbBlockData)
end

local function LeaveNormalBlock(self)
    self.Owner:SetModeButtonVisible(true)
    self.pbHomeBlockSub:Collapsed()
end

local function OnEnterBlockTrigger(self, nBlockId)
    local tbBlockData = HomelandSystem:GetBlockData(nBlockId)
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    if tbBlockData.bIsLandmark then -- 标志性建筑在任何模式下trigger没区别
        EnterMarkland(self, tbBlockData)
    elseif tbBlockTypeTemplate.bIsDork then -- 是码头
        EnterDork(self, tbBlockData)
    else -- 普通地块需要看当前模式决定弹出ui
        EnterNormalBlock(self, tbBlockData)
    end
end

local function OnLeaveBlockTrigger(self, nBlockId)
    local tbBlockData = HomelandSystem:GetBlockData(nBlockId)
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    if tbBlockData.bIsLandmark then -- 标志性建筑在任何模式下trigger没区别
        LeaveMarkland(self)
    elseif tbBlockTypeTemplate.bIsDork then -- 是码头
        LeaveMarkland(self)
    else
        LeaveNormalBlock(self)
    end
end

function ULHomeTrigger:OnShow()
end

function ULHomeTrigger:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbHomeBuildingSub = PrefabHelper:BindPrefab(pWidgetRef.pbHomeBuildingSub)
    self.pbHomeBlockSub = PrefabHelper:BindPrefab(pWidgetRef.pbHomeBlockSub)
end

function ULHomeTrigger:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_BLOCK_ENTER, self, OnEnterBlockTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_BLOCK_LEAVE, self, OnLeaveBlockTrigger)
end

return ULHomeTrigger