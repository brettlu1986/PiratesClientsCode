local ControlModeSystem = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ProtoDR = require("DungeonRepProtoNames")
local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
-- local ParachutingNewIni = require("ParachutingNewIni")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanMovementStateType = require("HumanMovementStateType")
-- local GameCameraModeGroupDef = require("GameCameraModeGroupDef")

ControlModeSystem.CurrentMode = nil
ControlModeSystem.bTransportState = nil
ControlModeSystem.bParachutionEnd = nil
ControlModeSystem.tbPlayerSelf = nil
ControlModeSystem.nMinOpenParachuteHeight = 0
ControlModeSystem.nMaxOpenParachuteHeight = 0
ControlModeSystem.nSeaLevelHeight = 0
ControlModeSystem.bWaitMovementStateChange = nil
ControlModeSystem.EventHelper = nil

--transport 事件
local function OnRecvTransportInfo(self, rTransportInfo)
    self.nMinOpenParachuteHeight = rTransportInfo.nMinJumpHeight
    self.nMaxOpenParachuteHeight = rTransportInfo.nMaxJumpHeight
    self.nSeaLevelHeight = rTransportInfo.nSeaLevelHeight
end

local function StartTransport(self)
    self.bTransportState = true
    self.bParachutionEnd = false
    if self.tbPlayerSelf and not self.tbPlayerSelf:IsShip() then
        log("ControlModeSystem StartTransport")
        local tbParams = {}
        tbParams.tbPlayerSelf = self.tbPlayerSelf
        local NewMode = self.BattleTransportNewControlMode
        self:Activate(NewMode, tbParams)
    else
        log("ControlModeSystem StartTransport failed ", self.tbPlayerSelf, self.tbPlayerSelf and self.tbPlayerSelf:IsShip())
    end
end

local function OnFFATransportChanged(self, nState)
    -- if nState == ProtoDR.rFFATransportState_EState.MOVING then
    --     StartTransport(self)
	-- end
end

local function OnParachutionEnd(self, bIsShip)
    log("ControlModeSystem OnParachutionEnd")
    self.bTransportState = false
    self.bParachutionEnd = true
    local NewMode
    if bIsShip then
        if self.tbPlayerSelf and self.tbPlayerSelf:IsShip() then
            NewMode = self.BattleShipControlMode
        end
    else
        if self.tbPlayerSelf then
            if self.tbPlayerSelf.HumanMovementStateComponent ~= nil then
                local nCurrentState = self.tbPlayerSelf.HumanMovementStateComponent:GetCurrentState()
                if nCurrentState ~= HumanMovementStateType.Parachutine_State then
                    NewMode = self.BattleHumanControlMode
                else
                    self.bWaitMovementStateChange = true
                end
            else
                -- 进入游戏时，跳伞结束
                log("ControlModeSystem OnParachutionEnd is human but no movmentcomponent")
            end
        end
    end
    if NewMode and self.tbPlayerSelf then
        local tbParams = {}
        tbParams.tbPlayerSelf = self.tbPlayerSelf
        self:Activate(NewMode, tbParams)
    end
end

local function OnEnterDungeonInBattle(self)
    self.bParachutionEnd = true
    UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    UIManager:DestroyWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if not tbCharacter or tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    if nOldState == HumanMovementStateType.Parachutine_State then
        if self.bParachutionEnd and self.bWaitMovementStateChange then
            log("ControlModeSystem OnParachutionEnd and state Changed")
            local tbParams = {}
            tbParams.tbPlayerSelf = self.tbPlayerSelf
            self:Activate(self.BattleHumanControlMode, tbParams)
        end
    end
end

local function OnLeaveBattle(self)
    self.bTransportState = nil
    self.bParachutionEnd = nil
    self.bWaitMovementStateChange = nil
end

local function OnFFAProcessStateChanged(self, nState)
    log("ControlModeSystem state ", nState, self.CurrentMode, self.CurrentMode and self.CurrentMode:GetModeType())
    if nState == ProtoDR.rFFAProcessState_EState.MATINEE then
        StartTransport(self)
        UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
        UIManager:DestroyWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    elseif nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        if not self.CurrentMode or self.CurrentMode:GetModeType() ~= ControlModeDef.TRANSPORTNEW then
            log("enter dungeon when game is start")
            StartTransport(self)
        end
        UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
        UIManager:DestroyWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    end
end

local function OnPlayerLogout(self, tbGamePlayer)
    if(tbGamePlayer == GamePlayerSelfHelper:Get()) then
        self:Deactivate()
    end
end

function ControlModeSystem:Init()
    self:Register()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO, self, OnRecvTransportInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ENTER_DUNGEON_IN_BATTLE, self, OnEnterDungeonInBattle)
end

function ControlModeSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self:Deactivate()
end

function ControlModeSystem:Activate(Mode, tbParams)
    self:Deactivate()

    assert(Mode)
    local Instance = Mode()
    self.CurrentMode = Instance
    Instance:OnActivate(tbParams)
    log("ControlModeSystem:Activate:",Instance:GetModeType())
    return Instance
end

function ControlModeSystem:Deactivate()
    local CurrentMode = self.CurrentMode
    if(CurrentMode == nil) then
        return
    end
    CurrentMode:OnDeactivate()
    self.CurrentMode = nil
end

function ControlModeSystem:GetCurrentModeType()
    if not self.CurrentMode then
        return ControlModeDef.NONE
    end
    return self.CurrentMode:GetModeType()
end

---------------------------------------------------------------------------------
function ControlModeSystem:Register()
    self.BattleShipControlMode = require("BattleShipControlMode")
    self.BattleHumanControlMode = require("BattleHumanControlMode")
    -- self.BattleTransportControlMode = require("BattleTransportControlMode")
    self.BattleTransportNewControlMode = require("BattleTransportNewControlMode")
end

function ControlModeSystem:OnPlayerSelfReady(tbPlayerSelf)
    if(not GlobalVariableSystem:IsInDungeon()) then
        return
    end

    log("ControlModeSystem:OnPlayerSelfReady")
    self.tbPlayerSelf = tbPlayerSelf
    local NewMode
    local tbParams = {}
    if self.bTransportState then
        if tbPlayerSelf:IsHuman() then
            log("ControlModeSystem:OnPlayerSelfReady change to transport start")
            NewMode = self.BattleTransportNewControlMode
        end
        log("ControlModeSystem:OnPlayerSelfReady change to transport end")
    elseif(tbPlayerSelf:IsShip()) then
        if not self.bTransportState then
            NewMode = self.BattleShipControlMode
        end
    else
        NewMode = self.BattleHumanControlMode
    end
    if NewMode then
        tbParams.tbPlayerSelf = tbPlayerSelf
        self:Activate(NewMode, tbParams)
    end
end

function ControlModeSystem:OnPlayerSelfUnready(tbPlayerSelf)
    log("ControlModeSystem:OnPlayerSelfUnready")
    self:Deactivate()
    self.tbPlayerSelf = nil
end

return ControlModeSystem