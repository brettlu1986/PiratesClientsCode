-----------------------------------------------------
--File Name    : HomelandPlayerStateSystem.lua
--Author       : WuJizhou
--Create Time  : 5/7/2019, 8:57:42 PM
--Description  : HomelandPlayerStateSystem
-----------------------------------------------------
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local HomelandModeDef = require("HomelandModeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local Timer = require("Timer")
local SelfAnimationHelper = require("SelfAnimationHelper")
local HomelandIni = require("HomelandIni")

local HomelandPlayerStateSystem = {}

HomelandPlayerStateSystem.EventHelper = nil
HomelandPlayerStateSystem.pAttachmentActor = nil

local IDENTITY_TRANSFORM = Transform()

local TIMER_NAME = "HomelandPlayerStateTimer"
local bFlag = false
local nCurrentMode = HomelandModeDef.NORMAL

local function CreatePlayerAttachments(self)
    if bFlag then
        return
    end
    local szClass = HomelandIni.tbPlayer.szPlayerAttachmentClass
    local pRes = szClass:load()
    self.pAttachmentActor = EngineExtActorShell.SpawnActorForScript(GWorld, pRes, IDENTITY_TRANSFORM, nil)
    bFlag = true
end

local function DestroyPlayerAttachments(self)
    EngineExtActorShell.DestroyActor(GWorld, self.pAttachmentActor)
end

local function UpdatePlayerStateInBuildingMode(self, pUEActor, bPlayMontage)
    Timer.StopOwnerTimer(self, TIMER_NAME)
    pUEActor:EnableHomelandBuilding(true)
    CreatePlayerAttachments(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nTemplateId = tbPlayer.LobbyPropertyComponent:GetHumanTemplateId()
    if bPlayMontage then
        SelfAnimationHelper:PlayActorAnimation(pUEActor, nTemplateId, HomelandIni.tbPlayer.szChangeToBuildModeMotage)
    end
    self.pAttachmentActor:AttachToPlayer(pUEActor, true)
end

local function UpdatePlayerStateInNormalMode(self, pUEActor, bPlayMontage)
    pUEActor:EnableHomelandBuilding(false)
    CreatePlayerAttachments(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nTemplateId = tbPlayer.LobbyPropertyComponent:GetHumanTemplateId()
    if bPlayMontage then
        local _, nTime = SelfAnimationHelper:PlayActorAnimation(pUEActor, nTemplateId, HomelandIni.tbPlayer.szChangeToNormalModeMotage)
        Timer.StartOwnerTimer(self, TIMER_NAME, function () self.pAttachmentActor:AttachToPlayer(pUEActor, false) end, nTime, false)
    else
        self.pAttachmentActor:AttachToPlayer(pUEActor, false)
    end

end

local function UpdatePlayerStateByMode(self, nMode, bPlayMontage)
    local pUEActor = GamePlayerSelfHelper:GetUEActor()
    if nMode == HomelandModeDef.NORMAL then
        UpdatePlayerStateInNormalMode(self, pUEActor, bPlayMontage)
    elseif nMode == HomelandModeDef.BUILD then
        UpdatePlayerStateInBuildingMode(self, pUEActor, bPlayMontage)
    end
end

local function OnHomelandModeChanged(self, nMode)
    if nMode == nCurrentMode then
        UpdatePlayerStateByMode(self, nMode, false)
    else
        UpdatePlayerStateByMode(self, nMode, true)
    end
    nCurrentMode = nMode
end

function HomelandPlayerStateSystem:OnEnterHomeland()
    nCurrentMode = HomelandModeDef.NORMAL
    self.EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_HOMELAND_MODE, self, OnHomelandModeChanged)
    return true
end

function HomelandPlayerStateSystem:OnLeaveHomeland()
    self.EventHelper:UnregisterAll()
    DestroyPlayerAttachments(self)
    Timer.StopOwnerTimer(self, TIMER_NAME)
    bFlag = false
    return true
end

function HomelandPlayerStateSystem:Init()
    self.EventHelper = SelfEventHelper()
end

function HomelandPlayerStateSystem:Uninit()
    Timer.StopOwnerTimer(self, TIMER_NAME)
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
end



return HomelandPlayerStateSystem