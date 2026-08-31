-----------------------------------------------------
--File Name    : SkillComponentServer.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-20
--Description  : 技能控制（服务器逻辑）
-----------------------------------------------------
local luaclass = require("luaclass")
local SkillComponentBaseClass = require("SkillComponentBase")
local SkillComponentServer = luaclass("SkillComponentServer", SkillComponentBaseClass)

-- require
local Proto = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SkillCastFailedDef = require("SkillCastFailedDef")

-- 技能可打断状态变化（蓝图事件）
local function OnAllowInterruptChanged(self, bAllowInterrupt)
    self.bAllowInterrupt = bAllowInterrupt
end

-- Montage播放结束（蓝图事件）
local function OnSkillMontageEnded(self, bInterrupted)
    if self.CurrentSkill then
        self.CurrentSkill:HideSkillRange()
        self.CurrentSkill = nil
    end
    self.bAllowInterrupt = false
end

local function RequestHideSkillRange(self)
    if self.CurrentSkill then
        self.CurrentSkill:HideSkillRange()
    end
end

-- 请求释放技能（蓝图接口）
local function RequestCastSkillForBP(self, nSkillID)
    local bRet, nFailedReasonID = self:RequestCastSkill(nSkillID)
    if bRet == false then
        self.pUEComponent.TempCastFailedReasonID = nFailedReasonID
    end
    return bRet
end

-- 判断是否能够释放技能（蓝图接口）
local function CheckConditionForBP(self, nSkillID)
    local Skill = self:GetSkillByID(nSkillID)
    if Skill == nil then
        self.pUEComponent.TempCastFailedReasonID = SkillCastFailedDef.UNKNOWN_SKILL
        return false
    end
    local bRet, nFailedReasonID = self:CheckCondition(Skill)
    if bRet == false then
        self.pUEComponent.TempCastFailedReasonID = nFailedReasonID
    end
    return bRet
end

-- 触发技能ActionGroup（蓝图接口）
local function ExcuteActionGroupForBP(self, nActionGroupIndex)
    if self.CurrentSkill then
        self.CurrentSkill:ExcuteActionGroup(nActionGroupIndex)
    end
end

-- 触发技能ActionGroupEnd（蓝图接口）
local function ExcuteActionGroupEndForBP(self, nActionGroupIndex)
    if self.CurrentSkill then
        self.CurrentSkill:ExcuteActionGroupEnd(nActionGroupIndex)
    end
end

-- 触发子技能（蓝图接口）
local function ExcuteSubSkillForBP(self)
    if self.CurrentSkill then
        self.CurrentSkill:ExcuteSubSkill()
    end
end

local function SendToClient(self, szMessageType, tbMessageBody)
    self.RPCNetworkProxy:SendToClient(self.Owner:GetUEControllerUniqueId(), szMessageType, tbMessageBody)
end

local function IsPlayerOwner(self)
    return self.Owner.ObjectType == GameObjectTypeDef.PlayerSelf
end

local function IsManualPlayerOwner(self)
    return IsPlayerOwner(self) and (self.Owner.BattleAIComponent.bEnable == false)
end

local function OnBattleRetryGame(self)
    self:ResetSkillCD()
end

local function SetAllSkillEnabled(self, bEnabled)
    log("[SkillComponent] SetAllSkillEnabled", bEnabled)
    for _,Skill in pairs(self.tbSkillList) do
        Skill:SetEnabled(bEnabled)
    end
end

local function OnPawnDead(self, tbPlayer)
    if tbPlayer == self.Owner then
        SetAllSkillEnabled(self, false)
    end
end

local function OnIsDyingChanged(self, tbPlayer, bIsDying)
    if tbPlayer == self.Owner then
        SetAllSkillEnabled(self, not bIsDying)
    end
end

-- public
SkillComponentServer.CurrentSkill   = nil
SkillComponentServer.bAllowInterrupt= false
SkillComponentServer.bServer        = true -- override base variable
SkillComponentServer.pRPCComponent  = nil

function SkillComponentServer:OnActorCreated(pUEActor)
    SkillComponentServer.super.OnActorCreated(self, pUEActor)

    local Helper = self.EventHelper
    local pUEComponent = self.pUEComponent
    self.pRPCComponent = self.Owner.pUEActor.RPCComponent
    Helper:RegisterCppDelegate(pUEComponent.OnAllowInterruptChanged , self, OnAllowInterruptChanged)
    Helper:RegisterCppDelegate(pUEComponent.OnSkillMontageEnded     , self, OnSkillMontageEnded)

    Helper:RegisterCppDelegate(pUEComponent.OnRequestHideSkillRange , self, RequestHideSkillRange)
    Helper:RegisterCppDelegate(pUEComponent.OnRequestCastSkill      , self, RequestCastSkillForBP)
    Helper:RegisterCppDelegate(pUEComponent.OnCheckCondition        , self, CheckConditionForBP)
    Helper:RegisterCppDelegate(pUEComponent.OnExcuteActionGroup     , self, ExcuteActionGroupForBP)
    Helper:RegisterCppDelegate(pUEComponent.OnExcuteActionGroupEnd  , self, ExcuteActionGroupEndForBP)
    Helper:RegisterCppDelegate(pUEComponent.OnExcuteSubSkill        , self, ExcuteSubSkillForBP)
    Helper:RegisterCppDelegate(pUEComponent.OnSetSkillEnabled       , self, self.SetSkillEnabled)

    Helper:RegisterEvent(CommonEventDef.EV_BATTLE_RETRY_GAME, self, OnBattleRetryGame)
    Helper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    Helper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnIsDyingChanged)
end

-- 技能释放失败
-- @param nSkillID 技能ID
-- @param l10nFailedReason Cast失败原因
function SkillComponentServer:CastSkillFailed(Skill, nFailedReasonID)
    SkillComponentServer.super.CastSkillFailed(self, Skill, nFailedReasonID)
    if IsManualPlayerOwner(self) then
        local d2c_CastSkillFailedResponse = {}
        d2c_CastSkillFailedResponse.skill_id = Skill.nTemplateId
        d2c_CastSkillFailedResponse.failed_reason_id = nFailedReasonID
        SendToClient(self, Proto.d2c_CastSkillFailedResponse, d2c_CastSkillFailedResponse)
    end
end

function SkillComponentServer:CastSkill(Skill)
    SkillComponentServer.super.CastSkill(self, Skill)

    -- send to player client skill cast success
    if IsPlayerOwner(self) then
        local d2c_CastSkillSuccessedResponse = {}
        d2c_CastSkillSuccessedResponse.skill_id = Skill.nTemplateId
        SendToClient(self, Proto.d2c_CastSkillSuccessedResponse, d2c_CastSkillSuccessedResponse)
    end

    -- Multicast skill dialog
    if Skill.tbResTemplate.nDialogId > 0 then
        local d2c_OpenDialogBoard = {}
        d2c_OpenDialogBoard.dialog_id = Skill.tbResTemplate.nDialogId
        d2c_OpenDialogBoard.character_instance_id = self.Owner:GetServerInstanceId()
        self.RPCNetworkProxy:Multicast(Proto.d2c_OpenDialogBoard, d2c_OpenDialogBoard, false)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_PAWN_CAST_SKILL, self.Owner, Skill.nTemplateId)
end

function SkillComponentServer:PlaySkillMontage(Skill, pMontage)
    if self.pRPCComponent then
        self.pRPCComponent:PlaySkillMontage(pMontage)
        Skill:ShowSkillRange(pMontage:GetPlayLength())
        self.CurrentSkill = Skill
    else
        logerror("SkillComponentServer CastSkill Failed, pRPCComponent is nil")
    end
end

function SkillComponentServer:ResetSkillCD()
    SkillComponentServer.super.ResetSkillCD(self)
    if IsPlayerOwner(self) then
        SendToClient(self, Proto.d2c_ResetSkillCD, {})
    end
end

function SkillComponentServer:InterruptSkill()
    if self.bAllowInterrupt and self.pRPCComponent then
        self.pRPCComponent:StopSkillMontage()
    end
end

return SkillComponentServer
