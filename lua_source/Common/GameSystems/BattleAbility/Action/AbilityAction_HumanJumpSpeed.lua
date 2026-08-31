-----------------------------------------------------
--File Name    : AbilityAction_HumanJumpSpeed.lua
--Author       : Zuo Kun
--Create Time  : 2020-03-02
--Description  : 人跳跃速度
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HumanJumpSpeed = luaclass("AbilityAction_HumanJumpSpeed", AbilityActionBase)
local JumpBuffDataTable = require("JumpBuffDataTable")

-- AbilityAction_HumanJumpSpeed.nValue = 0
AbilityAction_HumanJumpSpeed.nJumpBuffId = 0
AbilityAction_HumanJumpSpeed.tbHumanJumpBuffConfig = {}

local function CalcUndoConfig(tbHumanJumpBuffConfig)
    local tbConfig = {}
    tbConfig.nSpeedChange          = 1 / tbHumanJumpBuffConfig.nSpeedChange
    tbConfig.nZVelocityChange      = 1 / tbHumanJumpBuffConfig.nZVelocityChange
    tbConfig.nGravityChange        = 1 / tbHumanJumpBuffConfig.nGravityChange
    tbConfig.nOriginSpeedChange    = 1 / tbHumanJumpBuffConfig.nOriginSpeedChange
    tbConfig.nAirDragChange        = 1 / tbHumanJumpBuffConfig.nAirDragChange
    tbConfig.nAccelChange          = 1 / tbHumanJumpBuffConfig.nAccelChange
    return tbConfig
end

function AbilityAction_HumanJumpSpeed:OnCreate(Owner, tbInitParams)
    self.nJumpBuffId = tbInitParams.JumpBuffId
    self.tbHumanJumpBuffConfig = JumpBuffDataTable:GetTemplate(self.nJumpBuffId)
end

function AbilityAction_HumanJumpSpeed:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent then
            -- tbHumanMovementStateComponent:ChangeSpeedBuffRatio(self.nValue)
            tbHumanMovementStateComponent:SetJumpBuffConfig(self.tbHumanJumpBuffConfig, true)
        end
    end, tbParams)
end

function AbilityAction_HumanJumpSpeed:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent then
            -- tbHumanMovementStateComponent:ChangeSpeedBuffRatio(-self.nValue)
            tbHumanMovementStateComponent:SetJumpBuffConfig(CalcUndoConfig(self.tbHumanJumpBuffConfig), false)
        end
    end, tbParams)
end

return AbilityAction_HumanJumpSpeed
