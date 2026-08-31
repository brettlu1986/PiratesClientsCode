-----------------------------------------------------
--File Name    : AbilityAction_HumanFootStepSoundSetting.lua
--Author       : LiHui
--Create Time  : 2020-03-10
--Description  : 人脚步声设置
-----------------------------------------------------
local luaclass = require("luaclass")
local PropName = require("PropName")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HumanFootStepSoundSetting = luaclass("AbilityAction_HumanFootStepSoundSetting", AbilityActionBase)

AbilityAction_HumanFootStepSoundSetting.nValue = -1

function AbilityAction_HumanFootStepSoundSetting:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
end

function AbilityAction_HumanFootStepSoundSetting:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if tbCharacter.HumanBattlePropertyComponent then
            tbCharacter.HumanBattlePropertyComponent:SetPropOriginValue(PropName.nHumanFootStepSoundSettingIndex, self.nValue)
        end
    end, tbParams)
end

function AbilityAction_HumanFootStepSoundSetting:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        if tbCharacter.HumanBattlePropertyComponent then
            tbCharacter.HumanBattlePropertyComponent:SetPropOriginValue(PropName.nHumanFootStepSoundSettingIndex, -1)
        end
    end, tbParams)
end

return AbilityAction_HumanFootStepSoundSetting
