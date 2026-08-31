-----------------------------------------------------
--File Name    : AbilityAction_ShipExtraMaterialCapacityRatio.lua
--Author       : WuJizhou
--Create Time  : 2019-2-25
--Description  : 增加船材料上限数量比例
-----------------------------------------------------
local PropName                       = require("PropName")
local ProtoDC                        = require("DungeonCommonProtoNames")
local PropUtil      = require("PropUtil")
local NetworkManager                 = dynamic_require("NetworkManager")

local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipExtraMaterialCapacityRatio = luaclass("AbilityAction_ShipExtraMaterialCapacityRatio", AbilityActionPropBase)


function AbilityAction_ShipExtraMaterialCapacityRatio:GetWrapperName()
    return PropName.nShipExtraMaterialCapacityRatio
end

function AbilityAction_ShipExtraMaterialCapacityRatio:GetTargetType()
    return PropUtil.TARGET_TYPE.SHIP
end

-- 由于当前需求只是在进入副本最开始修改一次，后续不再修改，故如此写，而且没有写undo，如果后续需求变化，可直接用会rProperty来管理同步
function AbilityAction_ShipExtraMaterialCapacityRatio:OnDo(tbParams)
    AbilityAction_ShipExtraMaterialCapacityRatio.super.OnDo(self, tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local d2c_SyncShipExtraMaterialCapacityRatio = {}
        d2c_SyncShipExtraMaterialCapacityRatio.ratio = self:GetValue(tbCharacter)
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncShipExtraMaterialCapacityRatio, d2c_SyncShipExtraMaterialCapacityRatio)
    end, tbParams)
end


return AbilityAction_ShipExtraMaterialCapacityRatio
