-----------------------------------------------------
--File Name    : PropertyComponentBase.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-10
--Description  : 属性框架逻辑、涵盖基础属性操作逻辑（此文件内不应该具有任何具体业务逻辑）
--               根据DefinePropertys中定义，框架会自动添加去类型前缀Get函数
--               如：Define("nHp", ...)，会自动生成GetHp()函数
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local PropertyComponentBase = luaclass("PropertyComponentBase", GameComponentBaseClass)

local PropName              = require("PropName")
local PropertyWrapperPool   = require("PropertyWrapperPool")
local PropertyWrapperType   = require("PropertyWrapperType")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")

PropertyComponentBase.tbProperties = nil

-- 根据PropId获取到对应的PropertyWrapper
local function GetPropertyWrapper(self, nPropId)
    assert(nPropId, "GetPropertyWrapper failed, nPropId is nil.")
    return self.tbProperties[nPropId]
end

local function SyncClientValueFromRep(self, nPropId, varRepValue)
    local Property = GetPropertyWrapper(self, nPropId)
    return Property:SetOriginValue(varRepValue, true)
end

-- 定义Property属性的具体内部实现
-- fnDefine(self, nPropId, varDefaultValue, fnCallback)
-- @ nPropId            PropName.lua中对应Id
-- @ varDefaultValue    默认值
-- @ fnCallback         值变化时触发的回调函数（可不传）
local function DefineProperty(self, nPropId, varDefaultValue, fnCallback)
    local nValueType = PropName.FindType(nPropId)
    assert(nValueType)
    local Property = PropertyWrapperPool.Accquire(nPropId, nValueType, varDefaultValue)
    Property:SetCallback(fnCallback, self)
    -- 对于同步的变量，客户端需要锁住避免修改
    if PropName.FindRepType(nPropId) and GlobalVariableSystem:IsDedicatedClient() then
        Property:Lock()
    end
    self.tbProperties[nPropId] = Property
end

local function ReleaseProperties(self)
    for nPropId, Property in pairs(self.tbProperties) do
        PropertyWrapperPool.Release(Property)
    end
end

local function RepCallback(self, tbRepProperty, varNewValue)
    SyncClientValueFromRep(self, tbRepProperty._nPropertyId, varNewValue)
end

local function ServerPropertyCallback(self, varNewValue, tbProperty)
    if(tbProperty.tbRep) then
        tbProperty.tbRep:Set(varNewValue)
    end
    if(tbProperty.fnOldCallback) then
        tbProperty.fnOldCallback(self, varNewValue, tbProperty)
    end
end

local function BindRepProperty(self, nPropId, tbProperty)
    --local Property = self.tbProperties[nPropId]
    local varCurrentValue = tbProperty:Get()
    -- local fnRepCallback = function(_, varNewValue)
    --     SyncClientValueFromRep(self, nPropId, varNewValue)
    -- end

    local RepProperty = self.Owner.CustomReplicationComponent:BindMethod(nPropId, varCurrentValue, self, RepCallback, false)
    tbProperty.tbRep = RepProperty

    if GlobalVariableSystem:IsServerLogic() then
        -- Server监听Wrapper的变化事件，并调用RepProperty的Set进行同步
        local fnOldCallback = tbProperty.fnCallback
        tbProperty.fnOldCallback = fnOldCallback
        assert(fnOldCallback == nil or fnOldCallback ~= ServerPropertyCallback)
        tbProperty:SetCallback(ServerPropertyCallback, self)
        -- local fnServerCallback = function(RepPropertyOrSelf, varNewValue, TempProperty)
        --     if(RepPropertyOrSelf ~= self) then
        --         RepPropertyOrSelf:Set(varNewValue)
        --     end
        --     if(fnOldCallback) then
        --         fnOldCallback(self, varNewValue, TempProperty)
        --     end
        -- end
        -- Property:SetCallback(fnServerCallback, RepProperty)
    else
        SyncClientValueFromRep(self, nPropId, RepProperty:Get())
    end
end

local function CheckRepPropertyUnbinded(self)
    -- 检查一下RepProp是不是正常Unbind的了
    for _,tbProperty in pairs(self.tbProperties) do
        if tbProperty.tbRep then
            error("RepProp is not unbind before OnDestroy.")
            break
        end
    end
end

-- 绑定需要Rep的变量
function PropertyComponentBase:BindRepProperties(tbRepIds)
    if GlobalVariableSystem:IsStandalone() then
        return
    end

    local tbProperty
    local tbProperties = self.tbProperties
    for _, nPropId in ipairs(tbRepIds) do
        tbProperty = tbProperties[nPropId]
        if(tbProperty) then
            BindRepProperty(self, nPropId, tbProperty)
        end
    end
end

-- 解绑需要Rep的变量
function PropertyComponentBase:UnbindAllRepProperties()
    if GlobalVariableSystem:IsStandalone() then
        return
    end

    local bServer = GlobalVariableSystem:IsServerLogic()
    for nPropId, tbProperty in pairs(self.tbProperties) do
        if(tbProperty.tbRep) then
            tbProperty.tbRep = nil
            if(bServer) then
                tbProperty:SetCallback(tbProperty.fnOldCallback, tbProperty.fnOldCallback ~= nil and self or nil)
                tbProperty.fnOldCallback = nil
            end
        end
    end
end

-- @protected
function PropertyComponentBase:OnCreate(Owner, tbParams)
    PropertyComponentBase.super.OnCreate(self, Owner, tbParams)
    self.tbProperties = {}
    self:DefineProperties(DefineProperty, tbParams)
end

-- @protected
function PropertyComponentBase:OnDestroy(...)
    -- self.tbProperties = nil
    CheckRepPropertyUnbinded(self)
    ReleaseProperties(self)
    PropertyComponentBase.super.OnDestroy(self, ...)
end

-- -- @protected
-- function PropertyComponentBase:OnActorCreated(pUEActor)
--     PropertyComponentBase.super.OnActorCreated(self, pUEActor)
-- end

-- @protected
function PropertyComponentBase:OnActorDestroyed(pUEActor)
    self:UnbindAllRepProperties()
    PropertyComponentBase.super.OnActorDestroyed(self, pUEActor)
end

-- @protected
-- 集中定义Property属性，可参考ShipPropertyHelper
function PropertyComponentBase:DefineProperties(fnDefine, tbParams)
    -- derived class implement it
end

-- @public
-- 获取变量当前值（对外不暴露PropertyWrapper概念）
function PropertyComponentBase:GetProp(nPropId)
    return GetPropertyWrapper(self, nPropId):Get()
end

-- @public
-- 获取变量原始值
function PropertyComponentBase:GetPropOriginValue(nPropId)
    return GetPropertyWrapper(self, nPropId):GetOriginValue()
end

-- @public
-- 获取变量加法叠加值
function PropertyComponentBase:GetPropAddValue(nPropId)
    return GetPropertyWrapper(self, nPropId):GetAddValue()
end

-- @public
-- 获取变量乘法叠加值
function PropertyComponentBase:GetPropMultiplyValue(nPropId)
    return GetPropertyWrapper(self, nPropId):GetMultiplyValue()
end

-- @public
-- 根据传入的值作为初始值，计算叠加后的值
function PropertyComponentBase:CalcPropOverlapValue(nPropId, nTempOriginValue)
    return GetPropertyWrapper(self, nPropId):CalcOverlapValue(nTempOriginValue)
end

-- @public
-- 设置变量初始值
function PropertyComponentBase:SetPropOriginValue(nPropId, varValue)
    local Property = GetPropertyWrapper(self, nPropId)
    return Property:SetOriginValue(varValue)
end

-- @public
-- 根据参数类型决定叠加方式
function PropertyComponentBase:PropOverlap(nOverlapType, nPropId, varValue)
    local Property = GetPropertyWrapper(self, nPropId)
    return Property:Overlap(nOverlapType, varValue)
end

-- @public
-- 值加法叠加
function PropertyComponentBase:PropOverlap_Add(nPropId, varValue)
    return self:PropOverlap(PropertyWrapperType.TYPE_ADD, nPropId, varValue)
end

-- @public
-- 值乘法叠加
function PropertyComponentBase:PropOverlap_Multiply(nPropId, varValue)
    return self:PropOverlap(PropertyWrapperType.TYPE_MULTIPLY, nPropId, varValue)
end

-- @public
-- 值覆盖叠加
function PropertyComponentBase:PropOverlap_Override(nPropId, varValue)
    return self:PropOverlap(PropertyWrapperType.TYPE_OVERRIDE, nPropId, varValue)
end

-- @public
-- 移除之前的叠加修改
function PropertyComponentBase:RemovePropOverlap(nPropId, nOverlapId)
    local Property = GetPropertyWrapper(self, nPropId)
    Property:RemoveOverlap(nOverlapId)
end

-- @public
-- 修改之前的叠加修改
function PropertyComponentBase:ModifyPropOverlap(nPropId, nOverlapId, varValue)
    local Property = GetPropertyWrapper(self, nPropId)
    Property:ModifyOverlap(nOverlapId, varValue)
end

-- @public
-- 对变量进行消耗
function PropertyComponentBase:ConsumeProp(nPropId, varValue)
    local Property = GetPropertyWrapper(self, nPropId)
    Property:Consume(varValue)
end

-- @public
-- 触发某个变量绑定的值变化回调事件
function PropertyComponentBase:TriggerPropCallback(nPropId)
    local Property = GetPropertyWrapper(self, nPropId)
    Property:TriggerCallback()
end

-- @public
-- 触发所有变量绑定的值变化回调事件
function PropertyComponentBase:TriggerAllPropCallback()
    for _nPropId, Property in pairs(self.tbProperties) do
        Property:TriggerCallback()
    end
end

-- @public
-- 绑定变量值改变事件
function PropertyComponentBase:BindPropChanged(nPropId, fnCallback, tbObject)
    GetPropertyWrapper(self, nPropId):BindPropChanged(fnCallback, tbObject)
end

-- @public
-- 解绑变量值改变事件
function PropertyComponentBase:UnbindPropChanged(nPropId, fnCallback, tbObject)
    GetPropertyWrapper(self, nPropId):UnbindPropChanged(fnCallback, tbObject)
end

return PropertyComponentBase
