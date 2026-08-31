local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbySchedule = luaclass("LobbySchedule", LobbySubBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local LobbySubLevelDataTable = require("LobbySubLevelDataTable")
local MatineeSystem = dynamic_require("MatineeSystem")
local ScheduleTable = require("ScheduleTable")
local ScheduleTypeDef = require("ScheduleTypeDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local AwardSystem = require("AwardSystem")
local AwardSessionType = require("AwardSessionType")
local UIUtils = require("UIUtils")

LobbySchedule.pActor = nil
local DEFAULT_UI_NAME = UIDef.UI_LOBBY_SCHEDULE_SHOW
local MATINEE_ID = 44

local function UninitActor(self)
    if self.pActor ~= nil then
        self.pActor:K2_DestroyActor()
        self.pActor = nil
    end
end


-- 通过Tag从Level中获取对应Actor的Location和Rotation
local function GetActorLocationAndRotationByTag(self)
    local tbSubLevelTemplate = LobbySubLevelDataTable:GetTemplate(self.nSubType, DEFAULT_UI_NAME)
    if not tbSubLevelTemplate then
        return 
    end
    local szActorTag = tbSubLevelTemplate.tbActorTag[1]
    local pLocation, pRotation = self.SubLevelLoadHelper:GetLocationAndRotationByTag(self.nSubType, DEFAULT_UI_NAME, szActorTag)

    return pLocation, pRotation
end

local function SetTransform(self, pActor)
    local pLocation, pRotation = GetActorLocationAndRotationByTag(self)

    EngineExtActorShell.SetActorLocation(pActor, pLocation)
    EngineExtActorShell.SetActorRotation(pActor, pRotation)
end

function LobbySchedule:Init(Owner, nSubType)
    LobbySchedule.super.Init(self, Owner, nSubType)
    return true
end

function LobbySchedule:Uninit()
    UninitActor(self)
    LobbySchedule.super.Uninit(self)
end

function LobbySchedule:Activate(tbParam)
    LobbySchedule.super.Activate(self, tbParam)
    self:SetShouldBeVisible(DEFAULT_UI_NAME, true)
    self:SetCamera(DEFAULT_UI_NAME, 1)
    self:PlayBGMusic(DEFAULT_UI_NAME)
    UIManager:OpenWnd(UIDef.UI_LOBBY_SCHEDULE_SHOW, tbParam)
    UIUtils.BottomMenuHide(true)
end

function LobbySchedule:Deactivate()
    -- self.Owner:ReturnToPrevSub()
    UIManager:CloseWnd(UIDef.UI_LOBBY_SCHEDULE_SHOW)
    UninitActor(self)
    UIUtils.BottomMenuHide(false)
    LobbySchedule.super.Deactivate(self)
end

function LobbySchedule:ShowChestAnimation(szChestActor, tbParam)
    local pActor = EngineExtActorShell.SpawnActorForScript(GWorld, szChestActor:load(), Transform(), nil)
    self.pActor = pActor
    pActor.KMSkeletalMesh:SetForcedLOD(1)
    SetTransform(self, pActor)
    self:SetActorSkeletalMeshLightChannel(DEFAULT_UI_NAME, self.pActor)
    MatineeSystem:PlayMatinee(MATINEE_ID, false, function() 
        local tbTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.CHEST)
        local tbUINames = {}
        if tbParam.szFrom ~= nil then
            table.insert(tbUINames, tbParam.szFrom)
        end
        table.insert(tbUINames, UIDef.UI_SCHEDULE)
        LobbySystem:Activate(LobbySubTypeDef.MAIN, {tbUINames = tbUINames, nId = tbTemp and tbTemp.nId}) 

        local ScheduleAwardSession = AwardSystem:GetAlivedSession(AwardSessionType.ScheduleRouletteAwardSession)
        if ScheduleAwardSession then
            AwardSystem:FinishSession(ScheduleAwardSession)
        else
            log("OnAwardSchedule not find chest session")
        end
    end)   
end

return LobbySchedule