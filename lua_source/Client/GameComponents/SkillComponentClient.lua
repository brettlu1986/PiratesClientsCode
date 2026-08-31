-----------------------------------------------------
--File Name    : SkillComponentClient.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-20
--Description  : 船只技能控制（客户端逻辑）
----------------------------------------------------- 
local luaclass = require("luaclass")
local SkillComponentBaseClass = require("SkillComponentBase")
local SkillComponentClient = luaclass("SkillComponentClient", SkillComponentBaseClass)

local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local SkillCastFailedText = require("SkillCastFailedText")
local Proto = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")

SkillComponentClient.bServer = false

function SkillComponentClient:OnActorCreated(pUEActor)
    SkillComponentClient.super.OnActorCreated(self, pUEActor)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SKILL_CAST_BY_ID, self, self.RequestCastSkill)
end

function SkillComponentClient:RequestCastSkill( nSkillID )
    SkillComponentClient.super.RequestCastSkill(self, nSkillID)
end

-- 预释放技能
-- @param Skill 对应技能实例
function SkillComponentClient:PreCastSkill( Skill )
    Skill:PreCast()

    local nTargetInstanceId = -1
    if self.tbTargetPawn then
        nTargetInstanceId = self.tbTargetPawn:GetServerInstanceId()
    end

    local c2d_RequestCastSkill = {}
    c2d_RequestCastSkill.skill_id = Skill.nTemplateId
    c2d_RequestCastSkill.target_instance_id = nTargetInstanceId

    self.RPCNetworkProxy:SendToServer(Proto.c2d_RequestCastSkill , c2d_RequestCastSkill)
end

-- 请求释放技能成功
-- @param nSkillID 技能ID
function SkillComponentClient:CastSkillFailedResponse( nSkillID, nFailedReasonID )
    local Skill = self.tbSkillList[nSkillID]
    if not Skill then
        logerror('SkillComponent CastSkillResponse Failed, Skill is nil')
        return
    end
    self:CastSkillFailed(Skill, nFailedReasonID)
end

-- 请求释放技能成功
-- @param nSkillID 技能ID
function SkillComponentClient:CastSkillSuccessedResponse( nSkillID )
    local Skill = self.tbSkillList[nSkillID]
    if not Skill then
        logerror('SkillComponent CastSkillResponse Failed, Skill is nil')
        return
    end
    self:CastSkill(Skill)
    EventManager:OnFireEvent(ClientEventDef.EV_SKILL_CAST_SUCCESSED, nSkillID)
end

-- 技能释放失败
-- @param nSkillID 技能ID
-- @param nFailedReasonID Cast失败原因ID
function SkillComponentClient:CastSkillFailed( Skill, nFailedReasonID )
    SkillComponentClient.super.CastSkillFailed(self, Skill, nFailedReasonID)
    if not self.Owner.BattleAIComponent.bEnable then
        UIUtils.ShowToast(SkillCastFailedText:GetText(nFailedReasonID))
    end
end

function SkillComponentClient:ResetSkillCD()
    SkillComponentClient.super.ResetSkillCD(self)
    EventManager:OnFireEvent(ClientEventDef.EV_SKILL_RESET_CD)
end

return SkillComponentClient
