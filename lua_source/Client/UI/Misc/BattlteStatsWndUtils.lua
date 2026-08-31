-----------------------------------------------------
--File Name    : BattlteStatsWndUtils.lua
--Author       : Chen Jing
--Create Time  : 2017-04-11
--Description  : BattlteStatsWndUtils
-----------------------------------------------------

local BattlteStatsWndUtils = {}

BattlteStatsWndUtils.GroupType = {
    SUMMARY = 1,
    DATA = 2,
    STATISTICS = 3,
}

BattlteStatsWndUtils.ExtendDataType = {
    NONE  = 0,
    TOWER = 1,
    FLAG  = 2,
} 

BattlteStatsWndUtils.SendedFriendApply = {

}

BattlteStatsWndUtils.CurrentExtendDataType = BattlteStatsWndUtils.ExtendDataType.NONE

function BattlteStatsWndUtils.SetExtendDataType(ExtendDataType)
    BattlteStatsWndUtils.CurrentExtendDataType = ExtendDataType
end

function BattlteStatsWndUtils.GetExtendDataType(tbBattlePlayerStatData)
    return BattlteStatsWndUtils.CurrentExtendDataType
end

return BattlteStatsWndUtils
