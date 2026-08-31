-----------------------------------------------------
--File Name    : UPSettingProgressCommonSub.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-17
--Description  : Setting界面中ProgressBar的基础控件
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingProgressCommonSub = luaclass("UPSettingProgressCommonSub", PrefabBase)

local MathUtil = require("MathUtil")
local LuaDelegate = require("LuaDelegate")

local MIN_BASE_VALUE = 0
local MAX_BASE_VALUE = 1

UPSettingProgressCommonSub.nBaseValue = 0       -- nBaseValue的范围是[0,1]
UPSettingProgressCommonSub.nRealValue = 0       -- nRealValue的范围是[nMinValue,nMaxValue]
UPSettingProgressCommonSub.szDesc = nil         -- 描述文本内容
UPSettingProgressCommonSub.nMinValue = 0        -- nRealValue最小值
UPSettingProgressCommonSub.nMaxValue = 1        -- nRealValue最大值
UPSettingProgressCommonSub.nStepSize = 0.1      -- 点击加减按钮时，每次移动的RealValue大小
UPSettingProgressCommonSub.OnValueChanged = nil -- Value变化的事件，参数为nRealValue
UPSettingProgressCommonSub.fnDescGetter = nil   -- Value变化的事件，参数为nRealValue

local fnDefaultDescGetter = function(nBaseValue)
    return math.floor(nBaseValue * 100) .. "%"
end

local function OnValueChanged(self, nBaseValue, nRealValue)
    self.nBaseValue = nBaseValue
    self.nRealValue = nRealValue
    self.szDesc = self.fnDescGetter(self.nBaseValue, self.nRealValue)
    self.pWidgetRef:SetValue(self.nBaseValue, self.szDesc)
    self.OnValueChanged:Fire(self.nRealValue)
end

local function SetBaseValueInternal(self, nBaseValue)
    nBaseValue = MathUtil.Clamp(nBaseValue, MIN_BASE_VALUE, MAX_BASE_VALUE)
    local nRealValue = self.nMinValue + (self.nMaxValue - self.nMinValue) * nBaseValue
    OnValueChanged(self, nBaseValue, nRealValue)
end

local function SetRealValueInternal(self, nRealValue)
    nRealValue = MathUtil.Clamp(nRealValue, self.nMinValue, self.nMaxValue)
    local nBaseValue = (nRealValue - self.nMinValue) / (self.nMaxValue - self.nMinValue)
    OnValueChanged(self, nBaseValue, nRealValue)
end

local function OnClickedBtnAdd(self)
    SetRealValueInternal(self, self.nRealValue + self.nStepSize)
end

local function OnClickedBtnMinus(self)
    SetRealValueInternal(self, self.nRealValue - self.nStepSize)
end

local function OnSldValueChanged(self, nBaseValue)
    SetBaseValueInternal(self, nBaseValue)
end

function UPSettingProgressCommonSub:OnLoad()
    self.OnValueChanged = LuaDelegate()
    self.fnDescGetter = self.fnDescGetter or fnDefaultDescGetter
end

function UPSettingProgressCommonSub:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAdd.OnClicked, self, OnClickedBtnAdd)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.sldValue.OnValueChanged, self, OnSldValueChanged)
end

--- 自定义
--- @param nRealValue number
--- @param nMinValue number
--- @param nMaxValue number
--- @param fnDescGetter function | "function(nBaseValue) return szDesc end"
function UPSettingProgressCommonSub:Custom(nRealValue, nMinValue, nMaxValue, nStepSize, fnDescGetter)
    self:SetDescGetter(fnDescGetter)
    self:SetMinValue(nMinValue)
    self:SetMaxValue(nMaxValue)
    self:SetValue(nRealValue)
    self:SetButtonSetpSize(nStepSize)
end

-- 设置最小值
--- @param nMinValue number
function UPSettingProgressCommonSub:SetMinValue(nMinValue)
    self.nMinValue = nMinValue
end

-- 设置最大值
--- @param nMaxValue number
function UPSettingProgressCommonSub:SetMaxValue(nMaxValue)
    self.nMaxValue = nMaxValue
end

-- 设置RealValue
--- @param nRealValue number
function UPSettingProgressCommonSub:SetValue(nRealValue)
    local nBaseValue = (nRealValue - self.nMinValue) / (self.nMaxValue - self.nMinValue)
    self:SetBaseValue(nBaseValue)
end

-- 获取RealValue
function UPSettingProgressCommonSub:GetValue()
    return self.nRealValue
end

-- 设置BaseValue
--- @param nBaseValue number
function UPSettingProgressCommonSub:SetBaseValue(nBaseValue)
    SetBaseValueInternal(self, nBaseValue)
end

-- 获取BaseValue
function UPSettingProgressCommonSub:GetBaseValue()
    return self.nBaseValue
end

-- 设置每次点击按钮移动多少数值
--- @param nStepSize number
function UPSettingProgressCommonSub:SetButtonSetpSize(nStepSize)
    self.nStepSize = nStepSize
end

--- 用于设置自定义描述回调
--- @param fnDescGetter function | "function(nBaseValue) return szDesc end"
function UPSettingProgressCommonSub:SetDescGetter(fnDescGetter)
    if fnDescGetter then
        self.fnDescGetter = fnDescGetter
    else
        self.fnDescGetter = fnDefaultDescGetter
    end
end

return UPSettingProgressCommonSub
