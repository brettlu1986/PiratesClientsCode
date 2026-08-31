-----------------------------------------------------
--File Name    : PropUtil.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-20
--Description  : 这个Utils用来便于调用PropertyComponent
--               接口的时候不区分人船Component，接口具体
--               参数请参见BattlePropertyComponent
-----------------------------------------------------
local PropUtil = {}

local MathUtil = require("MathUtil")

local TARGET_TYPE = {
    AUTO    = 0, -- 自动，按照当前形态确定
    SHIP    = 1, -- 船
    HUMAN   = 2, -- 人
}
PropUtil.TARGET_TYPE = TARGET_TYPE

local function CallComponentFunction(tbCharacter, szFunctionName, ...)
    local PropertyComponent = tbCharacter:GetCurrentPropertyComponent(tbCharacter)
    return PropertyComponent[szFunctionName](PropertyComponent, ...)
end

local function CallComponentFunctionWithType(tbCharacter, nType, szFunctionName, ...)
    local PropertyComponent = PropUtil.GetPropertyComponentByType(tbCharacter, nType)
    return PropertyComponent[szFunctionName](PropertyComponent, ...)
end

-- 获取TargetType对应的ProppertyComponent
function PropUtil.GetPropertyComponentByType(tbCharacter, nType)
    if (nType == nil) or (nType == TARGET_TYPE.AUTO) then
        return tbCharacter:GetCurrentPropertyComponent(tbCharacter)
    elseif nType == TARGET_TYPE.SHIP then
        return tbCharacter.ShipBattlePropertyComponent
    elseif nType == TARGET_TYPE.HUMAN then
        return tbCharacter.HumanBattlePropertyComponent
    else
        error("PropUtil GetPropertyComponentByType failed. No type "..nType.." found.")
        return nil
    end
end

-- 修改属性
function PropUtil.PropOverlap(tbCharacter, ...)
    return CallComponentFunction(tbCharacter, "PropOverlap", ...)
end

function PropUtil.PropOverlapWithType(tbCharacter, nType, ...)
    return CallComponentFunctionWithType(tbCharacter, nType, "PropOverlap", ...)
end

-- 移除属性修改
function PropUtil.RemovePropOverlap(tbCharacter, ...)
    CallComponentFunction(tbCharacter, "RemovePropOverlap", ...)
end

function PropUtil.RemovePropOverlapWithType(tbCharacter, nType, ...)
    CallComponentFunctionWithType(tbCharacter, nType, "RemovePropOverlap", ...)
end

-- 获取属性数值
function PropUtil.GetProp(tbCharacter, ...)
    return CallComponentFunction(tbCharacter, "GetProp", ...)
end

function PropUtil.GetPropWithType(tbCharacter, nType, ...)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetProp", ...)
end

-- 扣血
function PropUtil.ApplyDamage(tbCharacter, ...)
    CallComponentFunction(tbCharacter, "ApplyDamage", ...)
end

function PropUtil.ApplyDamageWithType(tbCharacter, nType, ...)
    CallComponentFunctionWithType(tbCharacter, nType, "ApplyDamage", ...)
end

-- 加血
function PropUtil.ApplyCure(tbCharacter, ...)
    CallComponentFunction(tbCharacter, "ApplyCure", ...)
end

function PropUtil.ApplyCureWithType(tbCharacter, nType, ...)
    CallComponentFunctionWithType(tbCharacter, nType, "ApplyCure", ...)
end

-- 增加能量
function PropUtil.GainEp(tbCharacter, ...)
    CallComponentFunction(tbCharacter, "GainEp", ...)
end

function PropUtil.GainEpWithType(tbCharacter, nType, ...)
    CallComponentFunctionWithType(tbCharacter, nType, "GainEp", ...)
end

-- 消耗能量
function PropUtil.ConsumeEp(tbCharacter, ...)
    CallComponentFunction(tbCharacter, "ConsumeEp", ...)
end

function PropUtil.ConsumeEpWithType(tbCharacter, nType, ...)
    CallComponentFunctionWithType(tbCharacter, nType, "ConsumeEp", ...)
end

-- 获取最大血量数值
function PropUtil.GetMaxHp(tbCharacter)
    return CallComponentFunction(tbCharacter, "GetMaxHp")
end

function PropUtil.GetMaxHpWithType(tbCharacter, nType)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetMaxHp")
end

-- 获取最大能量数值
function PropUtil.GetMaxEp(tbCharacter)
    return CallComponentFunction(tbCharacter, "GetMaxEp")
end

function PropUtil.GetMaxEpWithType(tbCharacter, nType)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetMaxEp")
end

-- 获取当前能量数值
function PropUtil.GetEp(tbCharacter)
    return CallComponentFunction(tbCharacter, "GetEp")
end

function PropUtil.GetEpWithType(tbCharacter, nType)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetEp")
end

-- 获取当前血量数值
function PropUtil.GetHp(tbCharacter)
    return CallComponentFunction(tbCharacter, "GetHp")
end

function PropUtil.GetHpWithType(tbCharacter, nType)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetHp")
end

-- 获取当前血量半分比
function PropUtil.GetHpPercent(tbCharacter)
    return CallComponentFunction(tbCharacter, "GetHpPercent")
end

function PropUtil.GetHpPercentWithType(tbCharacter, nType)
    return CallComponentFunctionWithType(tbCharacter, nType, "GetHpPercent")
end

-- 检查当前血量
function PropUtil.CheckHpValue(tbCharacter, nValue, nMethod)
    return PropUtil.CheckHpValueWithType(tbCharacter, TARGET_TYPE.AUTO, nValue, nMethod)
end

function PropUtil.CheckHpValueWithType(tbCharacter, nType, nValue, nMethod)
    local nHp = PropUtil.GetHpWithType(tbCharacter, nType)
    return MathUtil.CompareValue(nMethod, nHp, nValue)
end

-- 检查当前血量百分比
function PropUtil.CheckHpPercent(tbCharacter, nPercent, nMethod)
    return PropUtil.CheckHpPercentWithType(tbCharacter, TARGET_TYPE.AUTO, nPercent, nMethod)
end

function PropUtil.CheckHpPercentWithType(tbCharacter, nType, nPercent, nMethod)
    local nCurrentPercent = PropUtil.GetHpPercentWithType(tbCharacter, nType)
    return MathUtil.CompareValue(nMethod, nCurrentPercent, nPercent)
end

return PropUtil