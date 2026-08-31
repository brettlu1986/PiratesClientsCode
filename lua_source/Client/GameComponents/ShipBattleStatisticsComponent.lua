-----------------------------------------------------
--File Name    : ShipBattleStatisticsComponent.lua
--Author       : Chen Jing
--Create Time  : 2018-02-06
--Description  : 战斗内玩家数据统计
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipBattleStatisticsComponent = luaclass("ShipBattleStatisticsComponent", GameComponentBase)


ShipBattleStatisticsComponent.tbPlayerRealTimeData = nil
ShipBattleStatisticsComponent.tbPlayerBattleFinishData = nil


function ShipBattleStatisticsComponent:SetPlayerRealTimeData(tbPlayerRealTimeData)
    self.tbPlayerRealTimeData = tbPlayerRealTimeData
end

function ShipBattleStatisticsComponent:SetPlayerBattleFinishData(tbPlayerBattleFinishData)
    self.tbPlayerBattleFinishData = tbPlayerBattleFinishData
end

function ShipBattleStatisticsComponent:OnCreate( Owner, tbParams )
    local bRet = ShipBattleStatisticsComponent.super.OnCreate(self, Owner, tbParams)
    if not bRet then
        return
    end
    return true
end

function ShipBattleStatisticsComponent:OnDestroy( Owner, tbParams )
    ShipBattleStatisticsComponent.super.OnDestroy(self)
end

return ShipBattleStatisticsComponent