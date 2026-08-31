-----------------------------------------------------
--File Name    : HomelandTreasureSystem.lua
--Author       : WuJizhou
--Create Time  : 5/20/2019, 1:20:29 PM
--Description  : HomelandTreasureSystem
-----------------------------------------------------
local HomelandTreasureSystem = {}

local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local HomelandIni = require("HomelandIni")
local TreasurePlaceDataTable = require("TreasurePlaceDataTable")
local HomelandSystem = require("HomelandSystem")
local HomelandSceneSystem = require("HomelandSceneSystem")
local LandmarkTypeDef = require("LandmarkTypeDef")
local UEActorHelper = require("UEActorHelper")

local EventHelper = nil
local nTreasureCountInLobby = 0
local nTreasureCountInHomeland = 0
local nLastUpdateTotalCurrencyCount = 0
local bInHomeland = false
local bInit = false
local pTreasureActor = nil

local function GetTreasureBlockActor()
    local nBlockId = HomelandSystem:GetLandmarkBlockIdInCurrentScene(LandmarkTypeDef.TREASURE_SHOP)
    local BlockGameObject = HomelandSceneSystem:GetBlock(nBlockId)
    assert(BlockGameObject)
    return BlockGameObject.pUEActor
end

local function GetTreasurePlaceRes()
    local nSceneId = HomelandSystem:GetCurrentSceneId()
    local tbTemplates = TreasurePlaceDataTable:GetAllTemplates(nSceneId)
    for _, v in ipairs(tbTemplates) do
        if v.nMinValue <= nTreasureCountInHomeland then
            return v.szResPath
        end
    end
end

local function GetCurrencyTemplateId()
    return HomelandIni.tbTreasure.nCurrencyTemplateId
end

local function GetLobbyTreasureActorTag()
    return HomelandIni.tbTreasure.szLobbyActorTag
end

local function GetCurrencyCount()
    local nTemplateId = GetCurrencyTemplateId()
    local nCount = CurrencySystem:GetCurrencyCount(nTemplateId)
    return nCount
end

local function UpdateHomelandTreasureActor(self)
    if pTreasureActor then
        UEActorHelper:DestroyActor(pTreasureActor)
    end
    local pBlockActor = GetTreasureBlockActor()
    local pTransform = pBlockActor:GetTransform()
    local szRes = GetTreasurePlaceRes()
    if szRes and szRes ~= "" then
        pTreasureActor = UEActorHelper:CreateActorByClass(szRes:load(), pTransform)
    end
end

local function UpdateLobbyTreasureActors(self)
    local bHasTreasureInLobby = self:HasTreasureInLobby()
    local LobbyTreasureActors = ExtendBlueprintFunctions.GetLevelActorsByTag(GWorld, GetLobbyTreasureActorTag())
    if LobbyTreasureActors then
        for _, TreasureActor in ipairs(LobbyTreasureActors) do
            TreasureActor:SetActorHiddenInGame(not bHasTreasureInLobby)
        end
    end
end

local function OnCurrencyChanged(self)
    local nCount = GetCurrencyCount()
    if not bInHomeland then
        local nDelta = nCount - nLastUpdateTotalCurrencyCount
        nTreasureCountInLobby = math.max(0, nTreasureCountInLobby + nDelta)
        nLastUpdateTotalCurrencyCount = nCount
        UpdateLobbyTreasureActors(self)
    else
        nLastUpdateTotalCurrencyCount = nCount
        nTreasureCountInHomeland = nCount
        UpdateHomelandTreasureActor(self)
    end
end

local function UpdateCurrencyToLatest(self)
    local nCount = GetCurrencyCount()
    nTreasureCountInLobby = 0
    nTreasureCountInHomeland = nCount
end

local function OnTransportTreasureArrived(self)
    if bInHomeland then
        UpdateCurrencyToLatest(self)
        UpdateHomelandTreasureActor(self)
    end
end

local function OnHomelandReady(self)
    UpdateHomelandTreasureActor(self)
end

-- local function OnPlayerSelfReady(self)
--     if not bInit then
--         local nCount = GetCurrencyCount()
--         nTreasureCountInHomeland = nCount
--         nLastUpdateTotalCurrencyCount = nCount
--         nTreasureCountInLobby = 0
--         bInit = true
--     end
-- end

local function OnLobbyReady(self)
    if not bInit then
        local nCount = GetCurrencyCount()
        nTreasureCountInHomeland = nCount
        nLastUpdateTotalCurrencyCount = nCount
        nTreasureCountInLobby = 0
        bInit = true
    end
    UpdateLobbyTreasureActors(self)
end


function HomelandTreasureSystem:HasTreasureInLobby()
    return nTreasureCountInLobby > 0
end

function HomelandTreasureSystem:Init()
    EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(ClientEventDef.EV_CURRENCY_COUNT_SYNC, self, OnCurrencyChanged)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_TRANSPORT_TREASURE_ARRIVED, self, OnTransportTreasureArrived)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnLobbyReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_READY, self, OnHomelandReady)
    bInHomeland = false
    nTreasureCountInLobby = 0
    nTreasureCountInHomeland = 0
    nLastUpdateTotalCurrencyCount = 0
    bInit = false
end

function HomelandTreasureSystem:Uninit()
    EventHelper:UnregisterAll()
    EventHelper = nil
    bInHomeland = false
    nTreasureCountInLobby = 0
    nTreasureCountInHomeland = 0
    nLastUpdateTotalCurrencyCount = 0
    bInit = false
end

function HomelandTreasureSystem:OnEnterHomeland()
    bInHomeland = true
end

function HomelandTreasureSystem:OnLeaveHomeland()
    UpdateCurrencyToLatest(self)
    pTreasureActor = nil
    bInHomeland = false
end


return HomelandTreasureSystem