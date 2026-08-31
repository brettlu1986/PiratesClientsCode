-----------------------------------------------------
--File Name    : BattleItemUnequipCheckFailureDef.lua
--Author       : zhiyuan
--Create Time  : 2018-10-16
--Description  : 物品卸下的检查结果定义
-----------------------------------------------------

local ProtoDC = require("DungeonCommonProtoNames")

local BattleItemUnequipCheckFailureDef =  {
    INVENTORY_CAPACITY_NOT_ENOUGHT   = 1   -- 背包容量不足（已承载容量太大，背包不能卸下，不能替换成容量小的背包）
}

function BattleItemUnequipCheckFailureDef:ToReturnCode(nCheckResult)
    if nCheckResult == BattleItemUnequipCheckFailureDef.INVENTORY_CAPACITY_NOT_ENOUGHT then
        return ProtoDC.ItemReturnCode.INVENTORY_CAPACITY_NOT_ENOUGHT
    end
end

return BattleItemUnequipCheckFailureDef