-----------------------------------------------------
--File Name    : PropertyWrapper.lua
--Author       : Song Fuhao
--Create Time  : 2017-12-06
--Description  : 这个文件旨在状态中各种属性的叠加，统一计算
-----------------------------------------------------
local luaclass = require("luaclass")
local PropertyWrapper =  luaclass("PropertyWrapper")

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

local INVALID_INDEX = -1

-- 属性类型
local PropertyType  = PropName.PropertyType
local VALUE_INT     = PropertyType.Int
local VALUE_FLOAT   = PropertyType.Float

PropertyWrapper.nTopIndex           = INVALID_INDEX
PropertyWrapper.nPropId             = INVALID_INDEX
PropertyWrapper.nValueType          = INVALID_INDEX
PropertyWrapper.varCurrentValue     = nil
PropertyWrapper.varOriginValue      = nil
PropertyWrapper.tbValueMap          = nil
PropertyWrapper.tbOverlapIdMap      = nil
PropertyWrapper.fnCallback          = nil
PropertyWrapper.bLocked             = false

local function IsNumber(self)
    return (self.nValueType == VALUE_INT) or (self.nValueType == VALUE_FLOAT)
end

local function UpdateValue(self, bForceNotify)
    local varNewValue = self:CalcOverlapValue(self.varOriginValue)
    -- 检查数据是否变化
    if bForceNotify or (self.varCurrentValue ~= varNewValue) then
        self.varCurrentValue = varNewValue
        self:TriggerCallback()
    end
end

function PropertyWrapper:Init(nPropId, nValueType, varOriginValue)
    self.tbValueMap = {{},{},{}}
    self.tbOverlapIdMap = {}
    self.nPropId = nPropId
    self.nValueType = nValueType
    self:SetOriginValue(varOriginValue)
end

function PropertyWrapper:SetOriginValue(varOriginValue, bIgnoreLock)
    if self.bLocked and (not bIgnoreLock) then
        logerror("Cannot modify a locked value. PropName = " .. PropName.FindName(self.nPropId))
        return
    end
    self.varOriginValue = varOriginValue
    UpdateValue(self, true)
end

function PropertyWrapper:Overlap(nOverlapType, varValue)
    if self.bLocked then
        logerror("Cannot change a locked value. PropName = ".. PropName.FindName(self.nPropId))
        return
    end
    local tbValueMap = self.tbValueMap[nOverlapType]
    if tbValueMap then
        local nTopIndex = self.nTopIndex
        nTopIndex = nTopIndex + 1
        tbValueMap[nTopIndex] = varValue
        self.tbOverlapIdMap[nTopIndex] = nOverlapType
        UpdateValue(self)
        self.nTopIndex = nTopIndex
        return nTopIndex
    end
    return -1
end

function PropertyWrapper:RemoveOverlap(nOverlapId)
    if self.bLocked then
        logerror("Cannot change a locked value. PropName = ".. PropName.FindName(self.nPropId))
        return
    end
    local nOverlapType = self.tbOverlapIdMap[nOverlapId]
    if nOverlapType then
        self.tbValueMap[nOverlapType][nOverlapId] = nil
        self.tbOverlapIdMap[nOverlapId] = nil
        UpdateValue(self)
    end
end

function PropertyWrapper:ModifyOverlap(nOverlapId, varValue)
    if self.bLocked then
        logerror("Cannot change a locked value. PropName = ".. PropName.FindName(self.nPropId))
        return
    end
    local nOverlapType = self.tbOverlapIdMap[nOverlapId]
    if nOverlapType then
        self.tbValueMap[nOverlapType][nOverlapId] = varValue
        UpdateValue(self)
    end
end

function PropertyWrapper:Reset()
    if self.bLocked then
        logerror("Cannot change a locked value. PropName = ".. PropName.FindName(self.nPropId))
        return
    end
    self.tbValueMap = {{},{},{}}
    self.tbOverlapIdMap = {}
    self.varCurrentValue = self.varOriginValue
end

function PropertyWrapper:Get()
    return self.varCurrentValue
end

function PropertyWrapper:GetOriginValue()
    return self.varOriginValue
end

function PropertyWrapper:GetAddValue()
    local nAddValue = 0
    for _,v in pairs(self.tbValueMap[PropertyWrapperType.TYPE_ADD]) do
        nAddValue = nAddValue + v
    end
    return nAddValue
end

function PropertyWrapper:GetMultiplyValue()
    local nMultiplyValue = 1
    for _,v in pairs(self.tbValueMap[PropertyWrapperType.TYPE_MULTIPLY]) do
        nMultiplyValue = (nMultiplyValue + v)
    end
    return nMultiplyValue
end

function PropertyWrapper:CalcOverlapValue(nTempOriginValue)
    local varNewValue = nTempOriginValue
    local nMaxOverrideId = INVALID_INDEX
    -- 检查是否有Override数据
    for nOverlapId, varValue in pairs(self.tbValueMap[PropertyWrapperType.TYPE_OVERRIDE]) do
        nMaxOverrideId = math.max(nMaxOverrideId, nOverlapId)
        varNewValue = varValue
    end
    -- 如果没有Override数据，且变量类型为Number
    if (nMaxOverrideId == INVALID_INDEX) and IsNumber(self) then
        local nAddValue = self:GetAddValue()
        local nMultiplyValue = self:GetMultiplyValue()
        varNewValue = varNewValue * nMultiplyValue + nAddValue
    end
    -- TODO Song Fuhao : 对于整型的值，默认都先统一向上取整
    if self.nValueType == VALUE_INT then
        varNewValue = math.ceil(varNewValue)
    end
    return varNewValue
end

function PropertyWrapper:GetOverlapValue(nOverlapId)
    local nOverlapType = self.tbOverlapIdMap[nOverlapId]
    if nOverlapType then
        return self.tbValueMap[nOverlapType][nOverlapId]
    end
end

function PropertyWrapper:BindOnValueChanged(fnCallback)
    self.fnCallback = fnCallback
end

function PropertyWrapper:UnbindOnValueChanged(fnCallback)
    if fnCallback == self.fnCallback then
        self.fnCallback = nil
    end
end

function PropertyWrapper:Consume(nConsumeValue)
    local tbAdditions = self.tbValueMap[PropertyWrapperType.TYPE_ADD]
    for nOverlapId, nValue in pairs(tbAdditions) do
        if nValue > nConsumeValue then
            tbAdditions[nOverlapId] = nValue - nConsumeValue
            break
        else
            tbAdditions[nOverlapId] = 0
            nConsumeValue = nConsumeValue - nValue
        end
    end
    UpdateValue(self)
end

function PropertyWrapper:TriggerCallback()
    if self.fnCallback then
        self.fnCallback(self.varCurrentValue)
    end
end

function PropertyWrapper:Lock()
    self.bLocked = true
end

return PropertyWrapper