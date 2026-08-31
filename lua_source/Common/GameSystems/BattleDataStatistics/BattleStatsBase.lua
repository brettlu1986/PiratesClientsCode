-----------------------------------------------------
--File Name    : BattleStatsBase.lua
--Author       : Song Fuhao
--Create Time  : 2017-08-29
--Description  : 战斗内数据统计Base
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleStatsBase = luaclass("BattleStatsBase")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

BattleStatsBase.tbPropertyDefine = nil
BattleStatsBase.tbProperty = nil
BattleStatsBase.StatsType = nil

function BattleStatsBase:Create()
    self.tbPropertyDefine = {}
    self.tbProperty = {}

    self:OnCreate()
    if GlobalVariableSystem:IsServerLogic() then
        self:RegisterDefaultProperty()
    end
end

function BattleStatsBase:Destroy()
    self:OnDestroy()
    self.tbPropertyDefine = nil
    self.tbProperty = nil
end

function BattleStatsBase:RegisterProperty(szKey, varValue)
    if self.tbPropertyDefine[szKey] then
        logwarning("BattleStats register property failed, this key is duplicated :", szKey)
    end
    self.tbPropertyDefine[szKey] = varValue
    self.tbProperty[szKey] = varValue
end

-- 没有定义的Property不能赋值
function BattleStatsBase:SetProperty(szKey, varValue)
    if self.tbPropertyDefine[szKey] then
        self.tbProperty[szKey] = varValue
    else
        logwarning("BattleStats set property failed, this key is not register :", szKey)
    end
end

function BattleStatsBase:GetProperty(szKey)
    local varProperty = self.tbProperty[szKey]
    if varProperty then
        return varProperty
    else
        logwarning("BattleStats get property failed, this key is not register :", szKey)
        return 0
    end
end

function BattleStatsBase:RegisterDefaultProperty()
end

function BattleStatsBase:OnCreate()
end

function BattleStatsBase:OnDestroy()
end

function BattleStatsBase:Reset()
    
end

return BattleStatsBase
