local BattleGameStatePropertyBinder = {}

local PropNameGameState = require("PropNameGameState")
local ReplicateHelper = require("ReplicateHelper")
local PropName = require("PropName")

BattleGameStatePropertyBinder.bValueValid  = false
BattleGameStatePropertyBinder.tbProperties = nil
BattleGameStatePropertyBinder.tbCallbacks  = nil

local tbTypeToDefaultValue = {}
tbTypeToDefaultValue[PropName.PropertyType.Bool]    = false
tbTypeToDefaultValue[PropName.PropertyType.Int]     = 0
tbTypeToDefaultValue[PropName.PropertyType.Float]   = 0.0
tbTypeToDefaultValue[PropName.PropertyType.String]  = ""
tbTypeToDefaultValue[PropName.PropertyType.Proto]   = nil
tbTypeToDefaultValue[PropName.PropertyType.Table]   = nil

local GetValueFromRepComponent = ReplicateHelper.GetValueFromRepComponent

local function FindCallback(self, nPropName, Callback, CallbackOwner)
    if not self.tbCallbacks[nPropName] then
        return nil
    end

    for Index, tbCurCallback in pairs(self.tbCallbacks[nPropName]) do
        if tbCurCallback.Callback == Callback and tbCurCallback.CallbackOwner == CallbackOwner then
            return Index
        end
    end

    return nil
end

local function OnPropertyCallback(nPropName, self, ...)
    local tbCallbacks = self.tbCallbacks[nPropName]

    if tbCallbacks then
        for _, tbCurCallback in pairs(tbCallbacks) do
            tbCurCallback.Callback(tbCurCallback.CallbackOwner, ...)
        end
    end
end

local function BindPropertiesByType(self, tbGameState, nGameStateType)
    local RepIds = PropNameGameState.GetIdsByType(nGameStateType)
    if RepIds then
        for _, nPropName in pairs(RepIds) do
            local nPropType = PropName.FindType(nPropName)
            self.tbProperties[nPropName] = tbGameState:BindProperty(nPropName, tbTypeToDefaultValue[nPropType], self, function(Self, __, ...) OnPropertyCallback(nPropName, Self, ...) end, false)
            
            --提供GameState语法糖
            local szProtoName = PropName.FindName(nPropName)
            if tbGameState[szProtoName] then
                error("BattleGameStatePropertyBinder:BindPropertiesByType tbGameState.szProtoName exist. ".. szProtoName)
            end
    
            tbGameState[szProtoName] = self.tbProperties[nPropName]
        end
    end
end

local function OnAllPropertiesInited(self, tbGameState)
    self.bValueValid = true

    for nPropName, tbInfo in pairs(self.tbProperties) do
        OnPropertyCallback(nPropName, self, tbInfo:Get())
    end
end


--public function.
function BattleGameStatePropertyBinder:Init()
    self.bValueValid  = false
    self.tbProperties = {}
    self.tbCallbacks  = {}
end

function BattleGameStatePropertyBinder:Uninit()
    self.bValueValid  = false
    self.tbProperties = nil
    self.tbCallbacks  = nil
end

function BattleGameStatePropertyBinder:DefinePropertiesByType(tbGameState, nGameStatePropType)
    BindPropertiesByType(self, tbGameState, nGameStatePropType)
    tbGameState.nGameStatePropType:Set(nGameStatePropType)

    OnAllPropertiesInited(self, tbGameState)
end

function BattleGameStatePropertyBinder:DefinePropertiesWhenGameStateReady(tbGameState)
    local nGameStatePropType = GetValueFromRepComponent(tbGameState.pGameState.CustomReplication , PropNameGameState.nGameStatePropType)
    BindPropertiesByType(self, tbGameState, nGameStatePropType)

    OnAllPropertiesInited(self, tbGameState)
end

--bTriggerIfPropertyValid 如果绑定的时候显式设置为true，那么绑定的时候如果发现已经有有效数据的话，则在本函数内部则直接调用callback函数
function BattleGameStatePropertyBinder:Bind(nPropName, CallbackOwner, Callback, bTriggerIfPropertyValid)
    if FindCallback(self, nPropName, Callback, CallbackOwner) then
        logerror("BattleGameStatePropertyBinder:Bind duplication.", nPropName)
        return
    end

    local tbCallback = {}
    tbCallback.Callback = Callback
    tbCallback.CallbackOwner = CallbackOwner

    self.tbCallbacks[nPropName] = self.tbCallbacks[nPropName] or {}
    table.insert( self.tbCallbacks[nPropName], tbCallback )

    if bTriggerIfPropertyValid and self.bValueValid and self.tbProperties[nPropName] then
        Callback(CallbackOwner, self.tbProperties[nPropName]:Get())
    end
end

function BattleGameStatePropertyBinder:UnBind(nPropName, CallbackOwner, Callback)
    local nIndex = FindCallback(self, nPropName, Callback, CallbackOwner)
    if not nIndex then
        logerror("BattleGameStatePropertyBinder:UnBind not found. ", nPropName)
        return
    end

    table.remove(self.tbCallbacks[nPropName], nIndex)
end

function BattleGameStatePropertyBinder:RemoveAllMethodByOwner(CallbackOwner)
    if not self.tbCallbacks then
        return
    end

    for nPropName, tbCallbacks in pairs(self.tbCallbacks) do
        local tbDeleteIndexs = {}
        for Index, tbCurCallback in pairs(tbCallbacks) do
            if tbCurCallback.CallbackOwner == CallbackOwner then
                table.insert(tbDeleteIndexs, 1, Index)
            end
        end

        for _, CurIndex in pairs(tbDeleteIndexs) do
            table.remove(tbCallbacks, CurIndex)
        end
    end
end

return BattleGameStatePropertyBinder