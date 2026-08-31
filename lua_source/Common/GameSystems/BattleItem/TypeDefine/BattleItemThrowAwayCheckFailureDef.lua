local ProtoDC = require("DungeonCommonProtoNames")

local BattleItemThrowAwayCheckFailureDef =  {
    INVENTORY_CAPACITY_NOT_ENOUGHT   = 1   -- 背包容量不足（已承载容量太大，背包不能卸下，不能替换成容量小的背包）
}

function BattleItemThrowAwayCheckFailureDef:ToReturnCode(nCheckResult)
    if nCheckResult == BattleItemThrowAwayCheckFailureDef.INVENTORY_CAPACITY_NOT_ENOUGHT then
        return ProtoDC.ItemReturnCode.INVENTORY_CAPACITY_NOT_ENOUGHT
    end
end

return BattleItemThrowAwayCheckFailureDef