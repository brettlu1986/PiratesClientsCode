-----------------------------------------------------
--File Name    : PropertyWrapperNewNew.lua
--Author       : liangcheng
--Create Time  : 2020-02-27
--Description  : 函数接口跟PropertyWrapperNew一样，这个类一切目的只是为了减小内存
-----------------------------------------------------
local luaclass = require("luaclass")
local PropertyWrapperNew =  luaclass("PropertyWrapperNewNew")

local PropertyWrapperType = require("PropertyWrapperType")
local PropName = require("PropName")
local LuaDelegate = require("LuaDelegate")

local modf = math.modf
local fmod = math.fmod
local ceil = math.ceil

local MAX_VALUE_COUNT_PER_OVERLAP_TYPE  = 100000
local MAX_INDEX_OFFSET                  = -100000


-- Overlap类型
local TYPE_ADD              = PropertyWrapperType.TYPE_ADD
local TYPE_MULTIPLY         = PropertyWrapperType.TYPE_MULTIPLY
local TYPE_OVERRIDE         = PropertyWrapperType.TYPE_OVERRIDE

-- 属性类型
local PropertyType          = PropName.PropertyType
local VALUE_INT             = PropertyType.Int
local VALUE_FLOAT           = PropertyType.Float

PropertyWrapperNew.nValueType           = nil
PropertyWrapperNew.varCurrentValue      = nil
PropertyWrapperNew.varOriginValue       = nil
PropertyWrapperNew.fnCallback           = nil
PropertyWrapperNew.CallbackOwner        = nil
PropertyWrapperNew.tbDelegate           = nil
-- PropertyWrapperNew.nPropId              = nil -- 有需要再开
PropertyWrapperNew.bLocked              = nil
PropertyWrapperNew.nConsumeValue        = nil -- 消耗，扣护盾类使用


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

local function ToOverlapId(nOverlapType, nIndex)
    assert(nIndex < MAX_VALUE_COUNT_PER_OVERLAP_TYPE)
    return nOverlapType*MAX_VALUE_COUNT_PER_OVERLAP_TYPE + nIndex
end

local function ToOverlapTypeAndIndex(nTopIndex)
    return modf(nTopIndex / MAX_VALUE_COUNT_PER_OVERLAP_TYPE),
        fmod(nTopIndex, MAX_VALUE_COUNT_PER_OVERLAP_TYPE)
end

local function GenereteNewIndex(self, nOverlapType)
    local nKey = MAX_INDEX_OFFSET - nOverlapType
    local nIndex = self[nKey]
    if(nIndex == nil) then
        nIndex = 1
    else
        nIndex = nIndex + 1
    end
    self[nKey] = nIndex
    return nIndex
end

function PropertyWrapperNew:Init(nPropId, nValueType, varOriginValue)
    --self.nPropId = nPropId
    self.nValueType = nValueType
    self:SetOriginValue(varOriginValue)
end

function PropertyWrapperNew:ReturnToPool()
    self.nValueType = nil
    self.varCurrentValue = nil
    self.varOriginValue = nil
    self.fnCallback = nil
    self.CallbackOwner = nil
    self.tbDelegate = nil
    self.bLocked = nil
    self.nConsumeValue = nil
    self[TYPE_ADD] = nil
    self[TYPE_MULTIPLY] = nil
    self[TYPE_OVERRIDE] = nil
end

function PropertyWrapperNew:SetOriginValue(varOriginValue, bIgnoreLock)
    if self.bLocked and (not bIgnoreLock) then
        error("Cannot modify a locked value.")
    end
    self.varOriginValue = varOriginValue
    UpdateValue(self, true)
end

function PropertyWrapperNew:Overlap(nOverlapType, varValue)
    if self.bLocked then
        error("Cannot change a locked value.")
    end
    assert(IsNumber(self) or nOverlapType == TYPE_OVERRIDE)

    local tbValues = self[nOverlapType]
    if(tbValues == nil) then
        tbValues = {}
        self[nOverlapType] = tbValues
    end

    local nIndex = GenereteNewIndex(self, nOverlapType)
    tbValues[nIndex] = varValue
    UpdateValue(self)
    return ToOverlapId(nOverlapType, nIndex)
end

function PropertyWrapperNew:RemoveOverlap(nOverlapId)
    if self.bLocked then
        error("Cannot change a locked value.")
    end

    local nOverlapType, nIndex = ToOverlapTypeAndIndex(nOverlapId)
    local tbValues = self[nOverlapType]

    local bRemainConsumeValue = false
    if(nOverlapType == TYPE_ADD and self.nConsumeValue ~= nil) then
        local nOldValue = tbValues[nIndex]
        local nConsumeValue = self.nConsumeValue
        if(nConsumeValue > nOldValue) then
            self.nConsumeValue = nConsumeValue - nOldValue
            bRemainConsumeValue = true
        else
            self.nConsumeValue = nil
        end
    end

    tbValues[nIndex] = nil
    if(next(tbValues) == nil) then
        self[nOverlapType] = nil

        -- Add都删了后要把nConsumeValue也清理掉，要不然下次在Add会受影响
        if(bRemainConsumeValue) then
            self.nConsumeValue = nil
        end
    end
    UpdateValue(self)
end

function PropertyWrapperNew:ModifyOverlap(nOverlapId, varValue)
    if self.bLocked then
        error("Cannot change a locked value.")
    end

    local nOverlapType, nIndex = ToOverlapTypeAndIndex(nOverlapId)
    local tbValues = self[nOverlapType]
    assert(tbValues)
    tbValues[nIndex] = varValue
    UpdateValue(self)
end

function PropertyWrapperNew:Reset()
    if self.bLocked then
        error("Cannot change a locked value.")
    end
    self[TYPE_ADD] = nil
    self[TYPE_MULTIPLY] = nil
    self[TYPE_OVERRIDE] = nil
    self.varCurrentValue = self.varOriginValue
    self.nConsumeValue = nil
end

function PropertyWrapperNew:Get()
    return self.varCurrentValue
end

function PropertyWrapperNew:GetOriginValue()
    return self.varOriginValue
end

local function GetValueSum(self, nOverlapType, nInitValue)
    local nRet = nInitValue
    local tbValues = self[nOverlapType]
    if(tbValues) then
        for _, v in pairs(tbValues) do
            nRet = nRet + v
        end
    end
    return nRet
end

function PropertyWrapperNew:GetAddValue()
    return GetValueSum(self, TYPE_ADD, 0)
end

function PropertyWrapperNew:GetMultiplyValue()
    return GetValueSum(self, TYPE_MULTIPLY, 1)
end

function PropertyWrapperNew:CalcOverlapValue(nTempOriginValue)
    local varNewValue = nTempOriginValue
    local bIsNumber = IsNumber(self)

    -- 检查是否有Override数据
    local tbOverrides = self[TYPE_OVERRIDE]
    if(tbOverrides) then
        local nMaxIndex = 0
        for nIndex, Value in pairs(tbOverrides) do
            if(nIndex > nMaxIndex) then
                nMaxIndex = nIndex
                varNewValue = Value
            end
        end
    elseif(bIsNumber) then
        -- 生成overlapid时已判断是否时number，这里就不判了
        varNewValue = varNewValue * self:GetMultiplyValue() + self:GetAddValue()
    end

    if(bIsNumber) then
        -- 注意：这里有可能减成负数
        if(self.nConsumeValue ~= nil) then
            varNewValue = varNewValue - self.nConsumeValue
        end

        -- TODO Song Fuhao : 对于整型的值，默认都先统一向上取整
        if self.nValueType == VALUE_INT then
            varNewValue = ceil(varNewValue)
        end
    end

    return varNewValue
end

function PropertyWrapperNew:GetOverlapValue(nOverlapId)
    local nOverlapType, nIndex = ToOverlapTypeAndIndex(nOverlapId)
    local tbValues = self[nOverlapType]
    assert(tbValues)
    return tbValues[nIndex]
end

function PropertyWrapperNew:SetCallback(fnCallback, CallbackOwner)
    self.fnCallback = fnCallback
    self.CallbackOwner = CallbackOwner
end

function PropertyWrapperNew:Consume(nConsumeValue)
    local nCurrentConsumeValue = nConsumeValue
    if(nCurrentConsumeValue == nil) then
        self.nConsumeValue = nConsumeValue
    else
        self.nConsumeValue = nCurrentConsumeValue + nConsumeValue
    end
    UpdateValue(self)
end

function PropertyWrapperNew:TriggerCallback()
    local varCurrentValue = self.varCurrentValue
    local fnCallback = self.fnCallback
    if fnCallback then
        local Owner = self.CallbackOwner
        if(Owner) then
            fnCallback(Owner, varCurrentValue, self)
        else
            fnCallback(varCurrentValue, self)
        end
    end

    local tbDelegate = self.tbDelegate
    if(tbDelegate) then
        tbDelegate:Fire(varCurrentValue, self)
    end
end

function PropertyWrapperNew:Lock()
    self.bLocked = true
end

function PropertyWrapperNew:BindPropChanged(fnCallback, tbObject)
    self.tbDelegate = self.tbDelegate or LuaDelegate()
    self.tbDelegate:Bind(fnCallback, tbObject)
end

function PropertyWrapperNew:UnbindPropChanged(fnCallback, tbObject)
    if self.tbDelegate then
        self.tbDelegate:Unbind(fnCallback, tbObject)
    end
end

return PropertyWrapperNew