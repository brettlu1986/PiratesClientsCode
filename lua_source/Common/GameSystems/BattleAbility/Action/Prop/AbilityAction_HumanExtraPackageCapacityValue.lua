-----------------------------------------------------
--File Name    : AbilityAction_HumanExtraPackageCapacityValue.lua
--Author       : WuJizhou
--Create Time  : 2019-2-25
--Description  : 增加人背包上限数量固定值
-----------------------------------------------------
local PropName                       = require("PropName")
local ProtoDC                        = require("DungeonCommonProtoNames")
local PropUtil      = require("PropUtil")
local NetworkManager                 = dynamic_require("NetworkManager")

local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_HumanExtraPackageCapacityValue = luaclass("AbilityAction_HumanExtraPackageCapacityValue", AbilityActionPropBase)


function AbilityAction_HumanExtraPackageCapacityValue:GetWrapperName()
    return PropName.nHumanExtraPackageCapacityValue
end

function AbilityAction_HumanExtraPackageCapacityValue:GetTargetType()
    return PropUtil.TARGET_TYPE.HUMAN
end

-- 由于当前需求只是在进入副本最开始修改一次，后续不再修改，故如此写，而且没有写undo，如果后续需求变化，可直接用会rProperty来管理同步
function AbilityAction_HumanExtraPackageCapacityValue:OnDo(tbParams)
    AbilityAction_HumanExtraPackageCapacityValue.super.OnDo(self, tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local d2c_SyncHumanExtraPackageCapacityValue = {}
        d2c_SyncHumanExtraPackageCapacityValue.value = self:GetValue(tbCharacter)
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncHumanExtraPackageCapacityValue, d2c_SyncHumanExtraPackageCapacityValue)
    end, tbParams)
end


return AbilityAction_HumanExtraPackageCapacityValue
