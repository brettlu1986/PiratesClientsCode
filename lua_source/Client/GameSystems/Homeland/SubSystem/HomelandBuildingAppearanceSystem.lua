-----------------------------------------------------
--File Name    : HomelandBuildingAppearanceSystem.lua
--Author       : WuJizhou
--Create Time  : 5/9/2019, 5:20:29 PM
--Description  : HomelandBuildingAppearanceSystem
-----------------------------------------------------
local HomelandBuildingAppearanceSystem = {}

local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local HomelandSystem = require("HomelandSystem")
local HomelandSceneSystem = require("HomelandSceneSystem")
local LandmarkStatusDef = require("LandmarkStatusDef")
local BuildingDataTable = require("BuildingDataTable")
local HomelandIni = require("HomelandIni")


local EventHelper = nil

local function GetBlockActor(nBlockId)
    local tbBlock = HomelandSceneSystem:GetBlock(nBlockId)
    assert(tbBlock)
    return tbBlock.pUEActor
end

local function GetBlockIdByLandmarkType(nLandmarkType)
    return HomelandSystem:GetLandmarkBlockIdInCurrentScene(nLandmarkType)
end


local function OnLandmarkUpgradeBegin(self, nLandmarkType)
    local nBlockId = GetBlockIdByLandmarkType(nLandmarkType)
    local pUEActor = GetBlockActor(nBlockId)
    local szRes = HomelandIni.tbEffect.szBuildingUpgradingRes
    local pRes = szRes:load()
    pUEActor:AttachUpgradeEffect(pRes)
end

local function OnLandmarkUpgradeComplete(self, nLandmarkType, nGrade)
    local nBlockId = GetBlockIdByLandmarkType(nLandmarkType)
    local pUEActor = GetBlockActor(nBlockId)
    pUEActor:DetachUpgradeEffect()
    local szRes = HomelandIni.tbEffect.szBuildingUpgradeCompleteRes
    local pRes = szRes:load()
    pUEActor:AttachEffectToBlock(pRes)
    local nSceneId = HomelandSystem:GetCurrentSceneId()
    local tbTemplate = BuildingDataTable:GetLandmarkTemplate(nSceneId, nLandmarkType, nGrade)
    HomelandSceneSystem:CreateBuilding(nBlockId, tbTemplate.nId)
end

local function OnBuildingLoaded(self, nBuildingTemplateId, nBlockId)
    local tbData = HomelandSystem:GetBlockData(nBlockId)
    if tbData.nStatus == LandmarkStatusDef.UPGRADING then
        local pUEActor = GetBlockActor(nBlockId)
        local szRes = HomelandIni.tbEffect.szBuildingUpgradingRes
        local pRes = szRes:load()
        pUEActor:AttachUpgradeEffect(pRes)
    end
end

local function OnBuildingPlaced(self, nBlockId)
    local pUEActor = GetBlockActor(nBlockId)
    local szRes = HomelandIni.tbEffect.szBuildingPlacedRes
    local pRes = szRes:load()
    pUEActor:AttachEffectToBlock(pRes)
end

local function OnBuildingRemoved(self, nBlockId)
    local pUEActor = GetBlockActor(nBlockId)
    local szRes = HomelandIni.tbEffect.szBuildingRemovedRes
    local pRes = szRes:load()
    pUEActor:AttachEffectToBlock(pRes)
end

local function OnBlockBought(self, nBlockId)
    local pUEActor = GetBlockActor(nBlockId)
    local szRes = HomelandIni.tbEffect.szBlockBoughtRes
    local pRes = szRes:load()
    pUEActor:AttachEffectToBlock(pRes)
end

function HomelandBuildingAppearanceSystem:Init()
    EventHelper = SelfEventHelper()
end

function HomelandBuildingAppearanceSystem:Uninit()
    EventHelper:UnregisterAll()
    EventHelper = nil
end

function HomelandBuildingAppearanceSystem:OnEnterHomeland()
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_BEGIN, self, OnLandmarkUpgradeBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_COMPLETE, self, OnLandmarkUpgradeComplete)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_BUILDING_LOADED, self, OnBuildingLoaded)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLACE_ITEM_BUILDING, self, OnBuildingPlaced)
    EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_ITEM_BUILDING, self, OnBuildingRemoved)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_BUY_BLOCK, self, OnBlockBought)
end

function HomelandBuildingAppearanceSystem:OnLeaveHomeland()
    EventHelper:UnregisterAll()
end


return HomelandBuildingAppearanceSystem