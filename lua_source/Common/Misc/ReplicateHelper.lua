local luaclass = require("luaclass")
local ReplicateHelper = luaclass("ReplicateHelper")

local CppDelegate = require("CppDelegate")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
--local BPRPCType = require("BPRPCType")
local PropName = require("PropName")

local tbTempInfo = {}

---------------------------------------------------------------------------------------------------
local NoRepComponentSetFunc = function(pRepComponent, Value, tbInfo)
    tbInfo._Value = Value
    return true
end

local VerifyName = function(tbInfo)
    local szName = tbInfo._szName
    if(szName == nil) then
        szName = PropName.FindName(tbInfo._nPropertyId)
        tbInfo._szName = szName
    end
    return szName
end

-- local DefaultSetFunc = function(pRepComponent, Value, tbInfo)
--     local szName = VerifyName(tbInfo)
--     local OldValue = pRepComponent[szName]
--     if(OldValue == nil) then
--         return false
--     end
--     if(OldValue == Value) then
--         return true
--     end
--     pRepComponent[szName] = Value
--     return true
-- end

-- local DefualtGetFunc = function(pRepComponent, tbInfo)
--     local szName = VerifyName(tbInfo)
--     local Value = pRepComponent[szName]
--     return Value ~= nil, Value
-- end

local SetBool = function(pRepComponent, Value, tbInfo)
    assert(Value ~= nil)
    return pRepComponent:SetBool(tbInfo._nPropertyId, Value)
end

local GetBool = function(pRepComponent, tbInfo)
    return pRepComponent:GetBool(tbInfo._nPropertyId)
end

local SetInt = function(pRepComponent, Value, tbInfo)
    assert(Value ~= nil)
    return pRepComponent:SetInt(tbInfo._nPropertyId, Value)
end

local GetInt = function(pRepComponent, tbInfo)
    return pRepComponent:GetInt(tbInfo._nPropertyId)
end

local SetFloat = function(pRepComponent, Value, tbInfo)
    assert(Value ~= nil)
    return pRepComponent:SetFloat(tbInfo._nPropertyId, Value)
end

local GetFloat = function(pRepComponent, tbInfo)
    return pRepComponent:GetFloat(tbInfo._nPropertyId)
end

local SetProto = function(pRepComponent, Value, tbInfo)
    local szName = VerifyName(tbInfo)
    -- if(pRepComponent[szName] == nil) then
    --     return false
    -- end
    --logdebug("SetProto", szName, debug.traceback())
    -- if(Value == tbInfo._Value) then
    --     return true
    -- end
    -- log("SetProto Key", szName)
    -- log("SetProto Value", Value ~= nil and t2s(Value) or "nil")

    assert(Value == nil or type(Value) == 'table')
    return pRepComponent:SetProto(tbInfo._nPropertyId, szName, Value ~= nil and exposetable(Value) or nil)
end

local GetProto = function(pRepComponent, tbInfo)
    local szName = VerifyName(tbInfo)
    local bRet, Value = pRepComponent:GetProto(tbInfo._nPropertyId, szName)
    if(not bRet) then
        return false
    end
    return true, msgtoluatable(Value)
end

local PropertyType = PropName.PropertyType
local tbSetFuncs =
{
    [PropertyType.Bool]     = SetBool,
    [PropertyType.Int]      = SetInt,
    [PropertyType.Float]    = SetFloat,
    --[PropertyType.String]   = DefaultSetFunc,
    [PropertyType.Proto]    = SetProto,
}

local tbGetFuncs =
{
    [PropertyType.Bool]     = GetBool,
    [PropertyType.Int]      = GetInt,
    [PropertyType.Float]    = GetFloat,
    -- [PropertyType.String]   = DefualtGetFunc,
    [PropertyType.Proto]    = GetProto,
}

-- local tbRPCCallFuncs =
-- {
--     [BPRPCType.Multicast]       = CustomReplicationComponent.Multicast,
--     [BPRPCType.RunOnServer]     = CustomReplicationComponent.SendToServer,
--     [BPRPCType.RunOwningClient] = CustomReplicationComponent.SendToClient,
-- }

ReplicateHelper.pRepComponent = nil
ReplicateHelper.tbPropertiesById = nil
ReplicateHelper.OnValueChangedDelegate = nil
ReplicateHelper.OnPostRepNotify = nil
ReplicateHelper.tbPostRepNotify = nil
--ReplicateHelper.tbRecvFuncs = nil
ReplicateHelper.fnErrorCallback = nil

local SetValueToComponent = nil
local GetValueFromComponent = nil
local VerifyComponent = nil

local function TriggerError(self, szErrorInfo, bTriggerCallback)
    assert(self)
    if(bTriggerCallback and self.fnErrorCallback) then
        self.fnErrorCallback(self, szErrorInfo)
    else
        error(szErrorInfo)
    end
end

local function VerifyComponentImp(tbInfo)
    local pRepComponent = tbInfo._Owner.pRepComponent
    if(pRepComponent ~= nil and not isvalidhandle(pRepComponent)) then
        TriggerError(tbInfo._Owner, "ReplicateHelper:VerifyComponent failed, invalid object: "..VerifyName(tbInfo))
        return nil
    end
    return pRepComponent
end

local function SetValueToComponentImp(tbInfo, Value)
    local pRepComponent = VerifyComponent(tbInfo)
    local fnSet = tbSetFuncs[tbInfo._Type]
    assert(fnSet)
    local bRet = fnSet(pRepComponent, Value, tbInfo)
    if(not bRet) then
        TriggerError(tbInfo._Owner, "ReplicateHelper:SetValue failed: "..VerifyName(tbInfo))
        return false
    end
    return true
end

local function GetValueFromComponentImp(tbInfo)
    local pRepComponent = VerifyComponent(tbInfo)
    local fnGet = tbGetFuncs[tbInfo._Type]
    assert(fnGet)
    local bRet, Value = fnGet(pRepComponent, tbInfo)
    if(not bRet) then
        TriggerError(tbInfo._Owner, "ReplicateHelper:GetValue failed: "..VerifyName(tbInfo), true)
        return nil
    end
    return Value
end

local function CallOnChangedFunction(tbInfo, Value)
    if tbInfo._tbObject then
        tbInfo._fnOnChanged(tbInfo._tbObject, tbInfo, Value)
    else
        tbInfo._fnOnChanged(tbInfo, Value)
    end
end

local function SetValue(tbInfo, Value)
    if(SetValueToComponent) then
        SetValueToComponent(tbInfo, Value)
    end
    tbInfo._Value = Value

    if(tbInfo._fnOnChanged and tbInfo._bNotifyOnSet) then
        CallOnChangedFunction(tbInfo, Value)
    end
end

local function GetValue(tbInfo)
    return tbInfo._Value
end

-- local function Reset(tbInfo)
--     tbInfo:Set(tbInfo._DefaultValue)
-- end

local function GetDebugInfo(tbInfo)
    local Value = tbInfo:Get()
    local szValue
    if(Value == nil) then
        szValue = "nil"
    elseif(type(Value) == 'table') then
        szValue = require("dkjson").encode(Value)
    else
        szValue = tostring(Value)
    end
    -- if(GetValueFromComponent and GWithEditor) then
    --     local TempValue = GetValueFromComponent(tbInfo)
    --     if(type(TempValue) == 'table') then
    --         logdebug("C:", require("dkjson").encode(TempValue))
    --         logdebug("L:", require("dkjson").encode(Value))
    --     end
    --     if(tbInfo._Owner.pRepComponent:IsValidProperty(tbInfo._nPropertyId)) then
    --         assert(require("BaseUtil"):CheckEqual(GetValueFromComponent(tbInfo), Value))
    --     end
    -- end
    return string.format("Replication OnValueChanged Name: %s, Value: %s, PropertyId: %d, Type: %d",
        VerifyName(tbInfo),
        szValue,
        tbInfo._nPropertyId,
        tbInfo._Type)
end

local function OnValueChanged(self, nPropertyId)
    local tbInfo = self.tbPropertiesById[nPropertyId]
    if(tbInfo == nil) then
        TriggerError(self, "ReplicateHelper:OnValueChanged failed, cannot find propertyid: "..nPropertyId, true)
        return
    end
    local NewValue = GetValueFromComponent(tbInfo)

    if(tbInfo._Value ~= NewValue) then
        tbInfo._Value = NewValue
        if(tbInfo._fnOnChanged) then
            if GlobalVariableSystem.bEnableReplicatedLog then
                log(GetDebugInfo(tbInfo))
            end
            CallOnChangedFunction(tbInfo, NewValue)
        end
    end
end

-- local function Dispatch(self, pWrapper, ...)
--     if(pWrapper ~= nil and pWrapper:IsError()) then
--         TriggerError(self, "ReplicateHelper dispatch failed", true)
--         return
--     end

--     for _, v in ipairs(self.tbRecvFuncs) do
--         v(...)
--     end
-- end

function ReplicateHelper:SetRepComponent(pRepComponent)
    assert(pRepComponent and self.pRepComponent == nil)
    self.pRepComponent = pRepComponent

    assert(self.OnValueChangedDelegate == nil)
    self.OnValueChangedDelegate = CppDelegate:BindMethod(pRepComponent.OnValueChanged,
        self, OnValueChanged)

    assert(self.tbPropertiesById)
    for nPropertyId, _ in pairs(self.tbPropertiesById) do
        OnValueChanged(self, nPropertyId)
    end
end

function ReplicateHelper:Init(pActor, fnErrorCallback)
    assert(pActor)

    if(GlobalVariableSystem:IsStandaloneServer()) then
        SetValueToComponent = nil
        GetValueFromComponent = nil
        VerifyComponent = nil
    else
        SetValueToComponent = SetValueToComponentImp
        GetValueFromComponent = GetValueFromComponentImp
        VerifyComponent = VerifyComponentImp
    end

    self.tbPropertiesById = {}
    --self.tbRecvFuncs = {}
    self.fnErrorCallback = fnErrorCallback

    return true
end

function ReplicateHelper:Uninit()
    local pDelegate
    pDelegate = self.OnValueChangedDelegate
    if(pDelegate) then
        pDelegate:Unbind()
        self.OnValueChangedDelegate = nil
    end

    pDelegate = self.OnPostRepNotify
    if(pDelegate) then
        pDelegate:Unbind()
        self.OnPostRepNotify = nil
    end

    --self.tbRecvFuncs = nil
    self.pRepComponent = nil
    self.tbPropertiesById = nil
    self.tbPostRepNotify = nil
end

-- function ReplicateHelper:BindRPCRecvFunc(fnRecv)
--     assert(fnRecv ~= nil)
--     table.insert(self.tbRecvFuncs, fnRecv)
-- end

-- function ReplicateHelper:SendRPCRequest(nRPCType, ...)
--     if(self.pRepComponent) then
--         local fnCallFunc = tbRPCCallFuncs[nRPCType]
--         if(fnCallFunc == nil) then
--             TriggerError(self, "Invalid rpc type")
--         end
--         fnCallFunc(self.pRepComponent, packtowrapper(...))
--     else
--         Dispatch(self, nil, ...)
--     end
-- end

-- function ReplicateHelper:ResetAll()
--     for _, v in pairs(self.tbPropertiesById) do
--         v:Reset()
--     end
-- end

function ReplicateHelper:Bind(nPropertyId, DefaultValue, tbObject, fnOnChanged, bNotifyOnServer)
    local szName = PropName.FindName(nPropertyId)
    assert(szName ~= nil)

    if(self.tbPropertiesById[nPropertyId] ~= nil) then
        TriggerError(self, "ReplicateHelper:Bind failed, duplicated name: "..szName)
        return nil
    end

    local bStandaloneServer = GlobalVariableSystem:IsStandaloneServer()
    local bDedicatedServer = GlobalVariableSystem:IsDedicatedServer()
    local pRepComponent = self.pRepComponent
    if(bDedicatedServer and not isvalidhandle(pRepComponent)) then
        TriggerError(self, "ReplicateHelper:Define failed, not valid pRepComponent")
        return nil
    end

    local Type = PropName.FindType(nPropertyId)
    assert(Type)
    local fnSet = tbSetFuncs[Type]
    if(pRepComponent == nil) then
        fnSet = NoRepComponentSetFunc
    -- else
    --     TriggerError(self, "ReplicateHelper:Define failed, can not find type: "..szName)
    --     return nil
    end

    local tbInfo = {}
    tbInfo._Owner = self
    tbInfo._nPropertyId = nPropertyId
    --tbInfo._szName = szName
    tbInfo._tbObject = tbObject
    tbInfo._fnOnChanged = fnOnChanged
    tbInfo._Type = Type
    tbInfo._bNotifyOnSet = (bNotifyOnServer or bStandaloneServer) or nil
    tbInfo._Value = DefaultValue
    self.tbPropertiesById[nPropertyId] = tbInfo

    tbInfo.Get = GetValue
    --tbInfo.GetDebugInfo = GetDebugInfo
    if(GlobalVariableSystem:IsServerLogic()) then
        tbInfo.Set = SetValue
        --tbInfo.Reset = Reset
    else
        if(pRepComponent) then
            tbInfo._Value = GetValueFromComponent(tbInfo)
        end
    end

    if(GlobalVariableSystem:IsServerLogic()) then
        local bRet = fnSet(pRepComponent, DefaultValue, tbInfo)
        if(not bRet) then
            TriggerError(self, "ReplicateHelper:Define failed, set value failed: "..szName)
            return nil
        end
    end

    return tbInfo
end

function ReplicateHelper:IsValid()
    return self.tbPropertiesById ~= nil
end

local function OnPostRepNotifyCallback(self)
    for _, v in ipairs(self.tbPostRepNotify) do
        v()
    end
end

function ReplicateHelper:AddPostRepNotifyCallback(tbNotifyProperties, fnCallback)
    assert(fnCallback and tbNotifyProperties)

    local tbPostRepNotify = self.tbPostRepNotify
    if(tbPostRepNotify == nil) then
        assert(self.OnPostRepNotify == nil)
        assert(self.pRepComponent ~= nil)
        self.OnPostRepNotify = CppDelegate:BindMethod(self.pRepComponent.OnPostRepNotify,
            self, OnPostRepNotifyCallback)

        tbPostRepNotify = {}
        self.tbPostRepNotify = tbPostRepNotify
    end

    self.pRepComponent:AddRepNotifyProperties(tbNotifyProperties)
    table.insert(tbPostRepNotify, fnCallback)
end

-- C++那边没remove notify property，等有需求在开开这函数吧
-- function ReplicateHelper:RemovePostRepNotifyCallback(fnCallback)
--     assert(fnCallback)

--     for i, v in ipairs(self.tbPostRepNotify) do
--         if(fnCallback == v) then
--             table.remove(self.tbPostRepNotify, i)
--             break
--         end
--     end
-- end

function ReplicateHelper.GetValueFromRepComponent(pRepComponent, nPropertyId)
    local szName = PropName.FindName(nPropertyId)
    assert(szName ~= nil)

    if(not isvalidhandle(pRepComponent)) then
        error("ReplicateHelper:GetValueFromRepComponent failed, invalid pRepComponent")
    end

    local Type = PropName.FindType(nPropertyId)
    assert(Type)

    local fnGet = tbGetFuncs[Type]
    assert(fnGet)

    tbTempInfo._nPropertyId = nPropertyId
    local bRet, Value = fnGet(pRepComponent, tbTempInfo)
    return bRet and Value or nil
end

return ReplicateHelper